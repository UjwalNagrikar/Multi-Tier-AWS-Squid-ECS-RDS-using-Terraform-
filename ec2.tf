resource "aws_instance" "squid" {
  ami           = var.ec2_ami
  instance_type = "t2.micro"
  key_name = "Ujwal-SRE"
  associate_public_ip_address = true
  subnet_id     = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.squid_sg.id]

  user_data = <<-EOF
    #!/bin/bash
              apt update -y
              apt install squid -y
              systemctl enable squid
              systemctl start squid
              EOF

  tags =  { Name = "ujwal-infra-squid" }

}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attach" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}
