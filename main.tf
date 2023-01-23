#------------------------------------------------
# Deployment Productive Enviroment:
# - Security Group
# - Launch Configuration
# - Auto-Scaling Group
# - LOad Balances
#------------------------------------------------

provider "aws" {
#    access_key   = "AKIAQIT7QFGRJ2NP5QY2"
#    secret_key  = ""
    region      = "us-east-1"
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

# Security group - Prod_env_SG
#-------------------------------------------------------------------

resource "aws_security_group" "Prod_env_SG" {
  name = "Production security group"

  dynamic "ingress" {
      for_each = ["80", "443", "22"]
      content {
            from_port   = ingress.value
            to_port     = ingress.value
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
      }
    
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "Production Environment"
    Owner       = "Mykhailo P"
  }
}

# Launch template - Prod_env_LC
#-------------------------------------------------------------------

resource "aws_launch_template" "Prod_env_LT" {
  #name                 = "WebServer"
  name_prefix           = "ProdWebServer-"
  image_id              = data.aws_ami.latest_amazon_linux.id
  instance_type         = "t2.micro"
  security_group_names  = [aws_security_group.Prod_env_SG.name]
  key_name              = "us-east-11"
  # user_data            = filebase64("user_data.sh")
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
  min_size                  = 1
  desired_capacity          = 1
  #vpc_zone_identifier       = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  availability_zones        = [data.aws_availability_zones.az.names[0], data.aws_availability_zones.az.names[1]]
  health_check_type         = "EC2"
  load_balancers            = [aws_elb.Prod_env_ELB.name]
  health_check_grace_period = 30
  
   dynamic "tag" {
       for_each = {
           Name     = "Production Environment"
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
    security_groups = [aws_security_group.Prod_env_SG.id]
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
        Name = "Production Environment"
    }
}

# LB URL Output
#--------------------------------------------

output "web_loadbalancer_url" {
  value = aws_elb.Prod_env_ELB.dns_name
}