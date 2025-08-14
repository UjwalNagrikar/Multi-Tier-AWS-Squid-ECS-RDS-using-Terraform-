# DB Security Group
resource "aws_security_group" "db_sg" {
  name        = "ujwal-infra-db-sg"
  description = "Allow DB access"
  vpc_id      = aws_vpc.main.id

  # Allow MySQL from application subnets
  ingress {
    description = "MySQL access from app subnets"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.app_subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ujwal-infra-db-sg"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "ujwal-infra-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id

  tags = {
    Name = "ujwal-infra-db-subnet-group"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier              = "ujwal-infra-rds"
  engine                  = "mysql"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = var.rds_username
  password                = var.rds_password
  skip_final_snapshot     = true
  publicly_accessible     = false

  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name

  tags = {
    Name = "ujwal-infra-rds"
  }
}
