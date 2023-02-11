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

