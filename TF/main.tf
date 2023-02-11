#------------------------------------------------
# Deployment Productive Enviroment:
# - Security Group (security_group.tf)
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

#-------------------------------------------------------------------
#   Resources creation
#-------------------------------------------------------------------

# Launch template - Prod_env_LC
#-------------------------------------------------------------------

resource "aws_launch_template" "Prod_env_LT" {
  name_prefix           = "ProdWebServer-"
  image_id              = data.aws_ami.latest_ubuntu.id
  instance_type         = "t2.micro"
  security_group_names  = [aws_security_group.Prod_Env.name]
  key_name              = "us-east-11"
  user_data             = filebase64("user_data.sh")
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
  max_size                  = 4
  min_size                  = 2
  desired_capacity          = 2
  availability_zones        = [data.aws_availability_zones.az.names[0], data.aws_availability_zones.az.names[1]]
  health_check_type         = "ELB"
  target_group_arns	        = [aws_lb_target_group.LBTG.arn]
  health_check_grace_period = 60
  /*
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
  */
  tags {
    Name     = "Prod Environment"
    Owner    = "Mykhailo P"   
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
//    subnets = [data.aws_subnets.def_sub.ids[0], data.aws_subnets.def_sub.ids[1]]
    subnets = data.aws_subnets.def_sub.ids[*]
    enable_cross_zone_load_balancing = "true"
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
      interval            = "30"
      unhealthy_threshold = "2"
      timeout             = "10"
      path                = "/"
      port                = "80"
  }
}

# Listener for HTTP traffic on ALB
#--------------------------------------------
resource "aws_lb_listener" "lb_listener_http" {
   load_balancer_arn    = aws_lb.Prod_env_ELB.arn
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
          
resource "null_resource" "LBA" {
  triggers = {
    foo = "bar"
  }
  provisioner "local-exec" {
    command = "echo ${aws_lb.Prod_env_ELB.dns_name} > lb.txt"
  }
}