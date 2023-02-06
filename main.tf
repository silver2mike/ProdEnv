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


data "aws_vpc" "def" {
  default = true
}

# Find out subnets
data "aws_subnets" "def_sub" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.def.id]
  }
}

#data "aws_lb_target_group" "target" {
#  name = aws_lb_
#  arn  = var.lb_tg_arn
#  name = var.lb_tg_name
#}

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

#-------------------------------------------------------------------
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
  min_size                  = 1
  desired_capacity          = 1
  #vpc_zone_identifier       = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  availability_zones        = [data.aws_availability_zones.az.names[0], data.aws_availability_zones.az.names[1]]
  health_check_type         = "ELB"
  target_group_arns	=   [aws_lb_target_group.LBTG.arn]
//  load_balancers            = [aws_lb.Prod_env_ELB.name]
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

# Load Balancer
#--------------------------------------------

resource "aws_lb" "Prod_env_ELB" {
    name = "Prod-ELB"
    load_balancer_type = "application"
    internal = false
    security_groups = [aws_security_group.LB.id]
    subnets = [data.aws_subnets.def_sub.ids[0], data.aws_subnets.def_sub.ids[1]]
    enable_cross_zone_load_balancing = "true"
#    listener {
#        lb_port             = 80
#        lb_protocol         = "http"
#        instance_port       = 80
#        instance_protocol   = "http"
#    }
#    health_check {
#        healthy_threshold   = 2
#        unhealthy_threshold = 2
#        timeout             = 3
#        target              = "HTTP:80/"
#        interval            = 10
#    }
#
    tags = {
        Name = "Prod Environment"
    }
}

# Target Group
#--------------------------------------------
resource "aws_lb_target_group" "LBTG" {
  name     = "LB-TG"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.def.id
  health_check {
      healthy_threshold   = "3"
      interval            = "20"
      unhealthy_threshold = "2"
      timeout             = "10"
      path                = "/"
      port                = "80"
  }
}

# Attach the target group for ALB
/*
resource "aws_lb_target_group_attachment"
  tg_attachment_test" {
    target_group_arn = [aws_lb_target_group.LBTG.arn]
    target_id        = "i-0cbbbbbbbb12f"
    port             = 80
}

*/

# Listener for HTTP traffic on ALB
resource "aws_lb_listener" "lb_listener_http" {
   for_each             = aws_lb.Prod_env_ELB.name
   load_balancer_arn    = aws_lb.Prod_env_ELB.id
   port                 = "80"
   protocol             = "HTTP"
   default_action {
    target_group_arn = aws_lb_target_group.LBTG.arn
    type             = "forward"
  }
}

# LB URL Output
#--------------------------------------------

output "loadbalancer_url" {
  value = aws_lb.Prod_env_ELB.dns_name
}
          
resource "null_resource" "LB" {
  triggers = {
    foo = "bar"
  }
  provisioner "local-exec" {
    command = "echo ${aws_lb.Prod_env_ELB.dns_name} > lb.txt"
  }
}