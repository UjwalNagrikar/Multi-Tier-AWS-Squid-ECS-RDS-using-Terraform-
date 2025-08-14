resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "ujwal-infra-prd-vpc" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "ujwal-infra-prd-gw" }
}

# Public subnets (ensure different AZs a/b)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}${count.index == 0 ? "a" : "b"}"
  tags = { Name = "ujwal-infra-pub-sub-${count.index + 1}" }
}

# App subnets
resource "aws_subnet" "app" {
  count             = length(var.app_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnets[count.index]
  availability_zone = "${var.aws_region}${count.index == 0 ? "a" : "b"}"
  tags = { Name = "ujwal-infra-app-sub-${count.index + 1}" }
}

# DB subnets
resource "aws_subnet" "db" {
  count             = length(var.db_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnets[count.index]
  availability_zone = "${var.aws_region}${count.index == 0 ? "a" : "b"}"
  tags = { Name = "ujwal-infra-db-sub-${count.index + 1}" }
}

# Public route table + default route to IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "ujwal-infra-public-rt" }
}

# Associate public RT with public subnets
resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
