# AWS Infrastructure with Terraform

## Project Overview

This project deploys a highly available, scalable 3-tier web application infrastructure on AWS using Terraform. The architecture includes load balancing, containerized application services using ECS, RDS database, and a proxy server for secure outbound connections.

## Architecture Components

### Infrastructure Layers
- **Presentation Layer**: Application Load Balancer (ALB) in public subnets
- **Application Layer**: ECS cluster with Auto Scaling Group in private app subnets  
- **Data Layer**: RDS MySQL database in private database subnets
- **Proxy Layer**: Squid proxy server for outbound internet access

### Key Features
- Multi-AZ deployment across 2 availability zones (ap-south-1a, ap-south-1b)
- Auto-scaling ECS cluster with EC2 launch type
- Application Load Balancer with health checks
- Secure network segmentation with dedicated subnets
- RDS MySQL database with encryption and backup
- Squid proxy for controlled outbound internet access

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Valid AWS key pair (`Ujwal-SRE`) created in the target region
- Appropriate IAM permissions for creating AWS resources

## Project Structure

```
├── .gitignore              # Terraform-specific gitignore
├── provider.tf             # Terraform and AWS provider configuration
├── variables.tf            # Input variables and default values
├── vpc.tf                  # VPC, subnets, and networking components
├── security-group.tf       # Security groups for different tiers
├── alb.tf                  # Application Load Balancer configuration
├── ecs.tf                  # ECS cluster and service definitions
├── asg.tf                  # Auto Scaling Group and launch template
├── ec2.tf                  # EC2 instances and IAM roles
├── rds.tf                  # RDS database configuration
└── output.tf               # Output values
```

## Network Architecture

### VPC Configuration
- **VPC CIDR**: 10.0.0.0/16
- **Region**: ap-south-1 (Asia Pacific - Mumbai)

### Subnet Layout
| Subnet Type | AZ | CIDR Block | Purpose |
|-------------|----|-----------:|---------|
| Public-1 | ap-south-1a | 10.0.0.0/28 | Load balancer, NAT gateway |
| Public-2 | ap-south-1b | 10.0.0.16/28 | Load balancer, NAT gateway |
| App-1 | ap-south-1a | 10.0.0.32/28 | ECS container instances |
| App-2 | ap-south-1b | 10.0.0.48/28 | ECS container instances |
| DB-1 | ap-south-1a | 10.0.0.64/28 | RDS database |
| DB-2 | ap-south-1b | 10.0.0.80/28 | RDS database |

## Security Groups

### ALB Security Group (`ujwal-infra-alb-sg`)
- **Inbound**: HTTP (80) from anywhere (0.0.0.0/0)
- **Outbound**: All traffic

### ECS Security Group (`ujwal-infra-ecs-sg`)
- **Inbound**: HTTP (80) from ALB security group only
- **Outbound**: All traffic

### RDS Security Group (`ujwal-infra-rds-sg`)
- **Inbound**: MySQL (3306) from ECS security group only
- **Outbound**: All traffic

### Squid Security Group (`ujwal-infra-squid-sg`)
- **Inbound**: SSH (22), HTTP (80), HTTPS (443), Custom (8080), Squid (3128)
- **Outbound**: All traffic

## Component Details

### Application Load Balancer
- **Name**: ujwal-alb
- **Type**: Application Load Balancer
- **Scheme**: Internet-facing
- **Listener**: Port 80 (HTTP)
- **Target Group**: ECS instances on port 80
- **Health Check**: HTTP on path "/"

### ECS Cluster
- **Cluster Name**: ujwal-infra-ecs-cluster
- **Launch Type**: EC2
- **Container**: Nginx (latest)
- **Desired Count**: 2 tasks
- **Instance Type**: t3.micro
- **Auto Scaling**: 2-4 instances

### RDS Database
- **Engine**: MySQL
- **Instance Class**: db.t3.micro
- **Storage**: 20 GB
- **Backup**: Automated (7-day retention by default)
- **Multi-AZ**: No (single instance for cost optimization)
- **Encryption**: At rest and in transit

### Squid Proxy Server
- **Instance Type**: t2.micro
- **Purpose**: Outbound internet proxy
- **Port**: 3128
- **Configuration**: Default Squid configuration

## Deployment Instructions

### 1. Clone and Setup
```bash
# Clone the repository
git clone <repository-url>
cd terraform-aws-infrastructure

# Initialize Terraform
terraform init
```

### 2. Configure Variables
Create a `terraform.tfvars` file with your specific values:
```hcl
aws_region = "ap-south-1"
rds_username = "your_db_username"
rds_password = "your_secure_password"
ecs_ami = "ami-0f918f7e67a3323f0"  # ECS-optimized AMI
ec2_ami = "ami-0f918f7e67a3323f0"  # Ubuntu/Amazon Linux AMI
```

### 3. Plan and Deploy
```bash
# Review the deployment plan
terraform plan

# Apply the configuration
terraform apply

# Confirm with 'yes' when prompted
```

### 4. Verify Deployment
```bash
# Get outputs
terraform output

# Test the application
curl http://<alb_dns_name>
```

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for deployment | ap-south-1 | No |
| `vpc_cidr` | VPC CIDR block | 10.0.0.0/16 | No |
| `public_subnets` | Public subnet CIDRs | ["10.0.0.0/28", "10.0.0.16/28"] | No |
| `app_subnets` | Application subnet CIDRs | ["10.0.0.32/28", "10.0.0.48/28"] | No |
| `db_subnets` | Database subnet CIDRs | ["10.0.0.64/28", "10.0.0.80/28"] | No |
| `rds_username` | RDS master username | admin | No |
| `rds_password` | RDS master password | - | Yes |
| `ecs_ami` | ECS-optimized AMI ID | ami-0f918f7e67a3323f0 | No |
| `ec2_ami` | EC2 AMI ID for Squid | ami-0f918f7e67a3323f0 | No |

## Outputs

- `alb_dns_name`: DNS name of the Application Load Balancer
- `rds_endpoint`: RDS database endpoint for application connections

## Monitoring and Logging

### CloudWatch Integration
- ECS cluster metrics automatically available
- ALB access logs can be enabled
- RDS performance insights available

### Health Checks
- ALB health checks on HTTP path "/"
- ECS service health monitoring
- Auto Scaling based on CloudWatch metrics

## Security Best Practices Implemented

1. **Network Segmentation**: Separate subnets for different tiers
2. **Least Privilege**: Security groups allow only required traffic
3. **Database Security**: RDS in private subnets, encrypted at rest
4. **IAM Roles**: EC2 instances use IAM roles instead of access keys
5. **No Hardcoded Secrets**: Sensitive variables marked as sensitive

## Cost Optimization

- **Instance Types**: Using t3.micro and t2.micro for cost efficiency
- **RDS**: Single-AZ deployment (upgrade to Multi-AZ for production)
- **Auto Scaling**: Automatic scaling based on demand
- **Spot Instances**: Can be configured for further cost savings

## Maintenance and Updates

### Terraform State Management
```bash
# Check current state
terraform show

# Import existing resources (if needed)
terraform import aws_instance.example i-1234567890abcdef0

# Destroy infrastructure
terraform destroy
```

### Updates and Patches
- AMI updates: Modify `ecs_ami` and `ec2_ami` variables
- Application updates: Update ECS task definition
- Infrastructure changes: Modify Terraform files and apply

## Troubleshooting

### Common Issues

1. **ALB Health Check Failures**
   - Check security group rules
   - Verify ECS service is running
   - Check target group health status

2. **ECS Tasks Not Starting**
   - Verify IAM role permissions
   - Check ECS agent logs on EC2 instances
   - Ensure sufficient resources available

3. **RDS Connection Issues**
   - Verify security group rules
   - Check database subnet group configuration
   - Ensure credentials are correct

### Useful Commands
```bash
# Check ECS cluster status
aws ecs describe-clusters --clusters ujwal-infra-ecs-cluster

# Check ALB targets
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check RDS status
aws rds describe-db-instances --db-instance-identifier ujwal-infra-rds
```

## Production Considerations

Before deploying to production, consider these enhancements:

1. **High Availability**
   - Enable Multi-AZ for RDS
   - Add NAT Gateways for private subnet internet access
   - Implement cross-region backup

2. **Security Enhancements**
   - Enable AWS Config for compliance monitoring
   - Implement AWS WAF for web application firewall
   - Use AWS Secrets Manager for database credentials
   - Enable VPC Flow Logs

3. **Performance Optimization**
   - Use Application Load Balancer with SSL termination
   - Implement CloudFront CDN
   - Enable RDS read replicas for read-heavy workloads

4. **Monitoring and Alerting**
   - Set up CloudWatch alarms
   - Implement centralized logging with CloudWatch Logs
   - Configure SNS notifications for critical alerts

## Support and Maintenance

For support and maintenance:
- Monitor AWS service health dashboard
- Review CloudWatch metrics regularly
- Keep Terraform and AWS provider versions updated
- Regular security patches for AMIs
- Database maintenance windows during low traffic periods

## License

This infrastructure code is provided as-is for educational and development purposes. Ensure compliance with your organization's policies and AWS best practices before production use.
