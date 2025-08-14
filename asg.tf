# Launch template for ECS container instances
resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ujwal-infra-ecs-lt-"
  image_id      = var.ecs_ami
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  # Put instances in app subnets' SG
  network_interfaces {
    security_groups = [aws_security_group.ecs_sg.id]
    delete_on_termination = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
    # Install/start ECS agent on Amazon Linux 2 if needed
    systemctl enable --now ecs
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "ujwal-infra-ecs-node" }
  }
}

resource "aws_autoscaling_group" "ecs_asg" {
  name               = "ujwal-infra-ecs-asg"
  desired_capacity   = 2
  min_size           = 2
  max_size           = 4
  vpc_zone_identifier = [
    aws_subnet.app[0].id,
    aws_subnet.app[1].id
  ]

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ujwal-infra-ecs-node"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_lb_target_group.ecs_tg]
}
