#------------------------------------------------
# Deployment Productive Enviroment:
# - Security Group
# - Launch Configuration
# - Auto-Scaling Group
# - LOad Balances
#------------------------------------------------

provider "aws" {
    region      = "us-east-1"
}

terraform {
  backend "s3" {
    bucket     = "mikedzn-epam-tf"
    key        = "prod/terraform.tfstate"
    region     = "us-east-1"
  }
}

# Find out a list of AZ

data "aws_availability_zones" "az" {}

# Find out the latest version of AMI 

data "aws_ami" "latest_amazon_linux" {
  owners        = ["amazon"]
  most_recent   = true
  filter {
      name      = "name"
#      values    = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
      values    = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

#   Resources creation
#-------------------------------------------------------------------

# Security groups
#-------------------------------------------------------------------

resource "aws_security_group" "LB" {
  name = "Load balancer SG"
  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "Prod_Env" {
  name = "Prod SG"
}

resource "aws_security_group_rule" "HTTP" {
    type = "ingress"
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    source_security_group_id = aws_security_group.LB.id
    security_group_id = aws_security_group.Prod_Env.id
}
resource "aws_security_group_rule" "SSH" {
    type = "ingress"
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.Prod_Env.id
}
resource "aws_security_group_rule" "Outbound" {
    type = "egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.Prod_Env.id
}
# Launch template - Prod_env_LC
#-------------------------------------------------------------------

resource "aws_launch_template" "Prod_env_LT" {
  #name                 = "WebServer"
  name_prefix           = "ProdWebServer-"
  image_id              = data.aws_ami.latest_amazon_linux.id
  instance_type         = "t2.micro"
  security_group_names  = [aws_security_group.Prod_Env.name]
  key_name              = "us-east-11"
  user_data            = filebase64("user_data.sh")
  lifecycle {
    create_before_destroy = true
  }
}

#Auto-Scaling Group - Prod_env_ASG
#-------------------------------------------------------------------

resource "aws_autoscaling_group" "Prod_env_ASG" {

  launch_template{
    id      = aws_launch_template.Prod_env_LT.id
    version = "$Latest"
  }

  name                      = "AGS-${aws_launch_template.Prod_env_LT.name}"
  #name_prefix               = "ASG-"
  max_size                  = 4
  min_size                  = 0
  desired_capacity          = 0
  #vpc_zone_identifier       = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  availability_zones        = [data.aws_availability_zones.az.names[0], data.aws_availability_zones.az.names[1]]
  health_check_type         = "ELB"
  load_balancers            = [aws_elb.Prod_env_ELB.name]
  health_check_grace_period = 90
  
  dynamic "tag" {
     for_each = {
         Name     = "Prod Environment"
         Owner    = "Mykhailo P"
     }
     content {
        key                   = tag.key
        value                 = tag.value
        propagate_at_launch   = true
     }
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Elastic Load Balancer
#--------------------------------------------

resource "aws_elb" "Prod_env_ELB" {
    name = "Prod-ELB"
    availability_zones = [data.aws_availability_zones.az.names[0], data.aws_availability_zones.az.names[1]]
    security_groups = [aws_security_group.LB.id]
    listener {
        lb_port             = 80
        lb_protocol         = "http"
        instance_port       = 80
        instance_protocol   = "http"
    }
    health_check {
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 3
        target              = "HTTP:80/"
        interval            = 10
    }

    tags = {
        Name = "Prod Environment"
    }
}

# LB URL Output
#--------------------------------------------

output "web_loadbalancer_url" {
  value = aws_elb.Prod_env_ELB.dns_name
}
          
resource "null_resource" "LBO" {
  triggers = {
    foo = "bar"
  }
  provisioner "local-exec" {
    command = "echo aws_elb.Prod_env_ELB.dns_name > ex.txt"
  }

  provisioner "local-exec" {
    command = "echo ${aws_elb.Prod_env_ELB.dns_name} >> ex.txt"
  }
  provisioner "local-exec" {
    command = "echo $aws_elb.Prod_env_ELB.dns_name >> ex.txt"
  }
  provisioner "local-exec" {
    command = "export TF_VAR=${aws_elb.Prod_env_ELB.dns_name}"
  }

}