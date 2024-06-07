resource "aws_vpc" "handytec_data_platform_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name        = "handytec_${var.project}_vpc"
    Environment = var.environment
    Owner       = "esquivelrodriguez123@gmail.com"
    Team        = "DevOps"
    Project     = var.project
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.handytec_data_platform_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zone

  map_public_ip_on_launch = true

  tags = {
    Name = "handytec-${var.project}-public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.handytec_data_platform_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.availability_zone

  map_public_ip_on_launch = false

  tags = {
    Name = "handytec-${var.project}-private-subnet"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.handytec_data_platform_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-1b"

  map_public_ip_on_launch = false

  tags = {
    Name = "handytec-${var.project}-private-subnet-2"
  }
}


resource "aws_internet_gateway" "data_platform_vpc_igw" {
  vpc_id = aws_vpc.handytec_data_platform_vpc.id

  tags = {
    Name = "handytec-${var.project}-vpc-igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.handytec_data_platform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.data_platform_vpc_igw.id
  }

  tags = {
    Name = "handytec-${var.project}-public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "nat_eip" {
  domain   = "vpc"

  tags = {
    Name = "handytec-${var.project}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "handytec-${var.project}-nat-gateway"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.handytec_data_platform_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "handytec-${var.project}-private-route-table"
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_association_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = {
    Name = "RDS subnet group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.handytec_data_platform_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Permitir acceso desde dentro de la VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}