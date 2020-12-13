resource "aws_security_group" "sg" {
  name   = "task-sg-${var.environment}-${var.application}"
  vpc_id = aws_vpc.vpc.id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
