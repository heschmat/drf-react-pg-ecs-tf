resource "aws_security_group" "alb" {
  name   = "${var.prefix}-alb"
  vpc_id = var.vpc_id

  ingress {
    description = "Allow HTTP traffic from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic for port 8000 (our app)"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "api" {
  name               = "${var.prefix}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets = var.public_subnets
}

resource "aws_lb_target_group" "api" {
  name = "${var.prefix}-target-api"

  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "ip"
  port        = 8000

  health_check {
    path = "/api/healthz/"
  }
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}