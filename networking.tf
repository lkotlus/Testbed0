# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "demo-igw"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "demo-vpc"
  }
}

resource "aws_subnet" "external_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "external-subnet"
  }
}

resource "aws_subnet" "internal_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "internal-subnet"
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

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "external-rt"
  }
}

resource "aws_route_table_association" "external_subnet_assoc" {
  subnet_id      = aws_subnet.external_subnet.id
  route_table_id = aws_route_table.external_rt.id
}

resource "aws_route_table_association" "internal_subnet_assoc" {
  subnet_id      = aws_subnet.internal_subnet.id
  route_table_id = aws_route_table.internal_rt.id
}

resource "aws_route" "vpn_clients" {
  route_table_id         = aws_route_table.external_rt.id
  destination_cidr_block = "10.8.0.0/24"
  network_interface_id   = aws_instance.vpn_instance.primary_network_interface_id
}

resource "aws_route" "internal_default" {
  route_table_id         = aws_route_table.internal_rt.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.controller_instance_eni.id
}

# Security Group (subnet 1)
resource "aws_security_group" "external_subnet_sg" {
  name   = "external_subnet-sg"
  vpc_id = aws_vpc.main.id

  # Allow ingress from within the SG
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

  tags = {
    Name = "external-sg"
  }
}

# Security Group (subnet 2)
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

# Security Group (public VPN access)
resource "aws_security_group" "public_sg" {
  name   = "public-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "WireGuard VPN"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-sg"
  }
}
