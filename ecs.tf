resource "aws_ecs_cluster" "main" {
  name = "ujwal-infra-ecs-cluster"
  tags = { Name = "ujwal-infra-ecs-cluster" }
}

# Simple Nginx task (bridge mode on EC2)
resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx-task"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = "256"

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx:latest"
      cpu       = 256
      memory    = 512,
      essential = true,
      portMappings = [
        { containerPort = 80, hostPort = 80, protocol = "tcp" }
      ]
    }
  ])

  tags = { Name = "ujwal-infra-nginx-td" }
}

resource "aws_ecs_service" "nginx_service" {
  name            = "ujwal-infra-nginx-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count   = 2
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [
    aws_autoscaling_group.ecs_asg,
    aws_lb_listener.http
  ]

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  tags = { Name = "ujwal-infra-nginx-svc" }
}
