
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
