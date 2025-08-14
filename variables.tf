variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.0.0/28", "10.0.0.16/28"]
}

variable "app_subnets" {
  description = "CIDR blocks for application subnets"
  type        = list(string)
  default     = ["10.0.0.32/28", "10.0.0.48/28"]
}

variable "db_subnets" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.0.64/28", "10.0.0.80/28"]
}

variable "rds_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin" # Change in terraform.tfvars for production
}

variable "rds_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
  default     = "Ujwal123!#ujwal" 
}

variable "ecs_ami" {
  description = "AMI ID for ECS instances"
  type        = string
  default     = "ami-0f918f7e67a3323f0"
}

variable "ec2_ami" {
  description = "AMI ID for Squid EC2 instances"
  type        = string
  default     = "ami-0f918f7e67a3323f0"
}
