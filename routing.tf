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
