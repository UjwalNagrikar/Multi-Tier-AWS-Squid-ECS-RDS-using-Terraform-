resource "aws_lb" "app_alb" {
  name               = "ujwal-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  # EXACTLY one subnet per AZ (a and b)
  subnets = [
    aws_subnet.public[0].id,
    aws_subnet.public[1].id
  ]

  tags = { Name = "ujwal-infra-app-alb" }
}

resource "aws_lb_target_group" "ecs_tg" {
  name        = "ujwal-ecs-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    protocol = "HTTP"
    path     = "/"
    matcher  = "200-399"
  }

  tags = { Name = "ujwal-infra-ecs-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}
