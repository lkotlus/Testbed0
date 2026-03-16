# Primary ENI (external subnet)
resource "aws_network_interface" "external_site_primary_eni" {
  subnet_id       = aws_subnet.external_subnet.id
  security_groups = [aws_security_group.external_subnet_sg.id]
  tags = {
    Name = "external-site-primary-eni"
  }
}

# Secondary ENI for internal access
resource "aws_network_interface" "external_site_eni" {
  subnet_id       = aws_subnet.internal_subnet.id
  security_groups = [aws_security_group.internal_subnet_sg.id]
  tags = {
    Name = "external-site-secondary-eni"
  }
}

# External site
resource "aws_instance" "external_site" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t2.small"
  iam_instance_profile = aws_iam_instance_profile.managed_instance_profile.name
  key_name             = aws_key_pair.managed_nodes.key_name

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.external_site_primary_eni.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.external_site_eni.id
  }

  tags = {
    Name     = "external-site"
    Features = "flask_custom_serial, mysql"
    Type     = "managed"
  }

  user_data = <<-EOF
    #!/bin/bash

    until ping -c1 8.8.8.8 >/dev/null 2>&1; do
        echo "Waiting for network..."
        sleep 5
    done

    # Installing and starting ssh
    apt-get update
    apt-get install -y openssh-server
    systemctl start ssh
    systemctl enable ssh
    # SSM Agent Snap installation
    snap switch --channel=candidate amazon-ssm-agent
    snap install amazon-ssm-agent --classic
    # Starting/enabling it
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF
}

# Internal machine  1
resource "aws_instance" "internal_1" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.small"
  subnet_id                   = aws_subnet.internal_subnet.id
  vpc_security_group_ids      = [aws_security_group.internal_subnet_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.managed_instance_profile.name
  key_name                    = aws_key_pair.managed_nodes.key_name

  tags = {
    Name     = "internal-1"
    Features = ""
    Type     = "managed"
  }

  user_data = <<-EOF
    #!/bin/bash

    until ping -c1 8.8.8.8 >/dev/null 2>&1; do
        echo "Waiting for network..."
        sleep 5
    done

    # Installing and starting ssh
    apt-get update
    apt-get install -y openssh-server
    systemctl start ssh
    systemctl enable ssh

    # SSM Agent Snap installation
    snap switch --channel=candidate amazon-ssm-agent
    snap install amazon-ssm-agent --classic

    # Starting/enabling it
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF
}

# Internal machine  2
resource "aws_instance" "internal_2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.small"
  subnet_id                   = aws_subnet.internal_subnet.id
  vpc_security_group_ids      = [aws_security_group.internal_subnet_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.managed_instance_profile.name
  key_name                    = aws_key_pair.managed_nodes.key_name

  tags = {
    Name     = "internal-2"
    Features = ""
    Type     = "managed"
  }

  user_data = <<-EOF
    #!/bin/bash

    until ping -c1 8.8.8.8 >/dev/null 2>&1; do
        echo "Waiting for network..."
        sleep 5
    done

    # Installing and starting ssh
    apt-get update
    apt-get install -y openssh-server
    systemctl start ssh
    systemctl enable ssh

    # SSM Agent Snap installation
    snap switch --channel=candidate amazon-ssm-agent
    snap install amazon-ssm-agent --classic

    # Starting/enabling it
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF
}
