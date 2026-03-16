data "aws_availability_zones" "available" {}
locals {
  az = data.aws_availability_zones.available.names[0]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "demo-igw"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "demo-vpc"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "main-nat-gateway"
  }
}

resource "aws_subnet" "external_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = false

  tags = {
    Name = "external-subnet"
  }
}

resource "aws_subnet" "internal_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = false

  tags = {
    Name = "internal-subnet"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = false
  tags = { Name = "public-subnet" }
}

resource "aws_subnet" "services_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = false
  tags = { Name = "services-subnet" }
}

resource "aws_subnet" "vpn_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = local.az
  map_public_ip_on_launch = true

  tags = {
    Name = "vpn-subnet"
  }
}

resource "aws_route_table" "internal_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internal-rt"
  }
}

resource "aws_route_table" "external_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "external-rt"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table" "services_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "services-rt"
  }
}

resource "aws_route_table" "vpn_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "vpn-rt"
  }
}

resource "aws_route_table_association" "internal_subnet_assoc" {
  subnet_id      = aws_subnet.internal_subnet.id
  route_table_id = aws_route_table.internal_rt.id
}

resource "aws_route_table_association" "external_subnet_assoc" {
  subnet_id      = aws_subnet.external_subnet.id
  route_table_id = aws_route_table.external_rt.id
}

resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "services_assoc" {
  subnet_id      = aws_subnet.services_subnet.id
  route_table_id = aws_route_table.services_rt.id
}

resource "aws_route_table_association" "vpn_assoc" {
  subnet_id      = aws_subnet.vpn_subnet.id
  route_table_id = aws_route_table.vpn_rt.id
}

resource "aws_route" "internal_default" {
  route_table_id         = aws_route_table.internal_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route" "external_default" {
  route_table_id         = aws_route_table.external_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route" "vpn_clients_external" {
  route_table_id         = aws_route_table.external_rt.id
  destination_cidr_block = "10.8.0.0/24"
  network_interface_id   = aws_instance.vpn_instance.primary_network_interface_id
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "vpn_default" {
  route_table_id         = aws_route_table.vpn_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}


resource "aws_security_group" "external_subnet_sg" {
  name   = "external_subnet-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.vpn_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "external-sg"
  }
}

resource "aws_security_group" "internal_subnet_sg" {
  name   = "internal_subnet-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "endpoint_sg" {
  name   = "endpoint-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "endpoint-sg"
  }
}

resource "aws_security_group" "vpn_sg" {
  name   = "vpn-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "WireGuard"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "VPC traffic to VPN router"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.services_subnet.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.services_subnet.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.services_subnet.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  private_dns_enabled = true
}
