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
