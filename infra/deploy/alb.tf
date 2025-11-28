resource "aws_security_group" "alb" {
  name   = "${local.prefix}-alb"
  vpc_id = aws_vpc.main.id

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
  name               = "${local.prefix}-api"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]
}

# N.B. do not forget to update the `aws_ecs_service`
resource "aws_lb_target_group" "api" {
  name = "${local.prefix}-api"
  # it's inside our VPC; so, HTTP is just fine.
  # basically, the ALB forwards the (HTTPS) request from user
  ## to the internal "ip" (see "target_type") of the running task. (443 --> 8000)
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  target_type = "ip"
  port        = 8000

  health_check {
    path = "/api/healthz/"
  }

}


# alb listens on port 80 (will later change to 443)
# and then forwards the request to our target group.
resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

}