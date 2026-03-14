# Primary ENI (external subnet)
resource "aws_network_interface" "controller_instance_primary_eni" {
  subnet_id       = aws_subnet.external_subnet.id
  security_groups = [
    aws_security_group.external_subnet_sg.id,
    aws_security_group.public_sg.id
  ]
  tags = {
    Name = "controller-primary-eni"
  }
}

# Secondary ENI (internal subnet)
resource "aws_network_interface" "controller_instance_eni" {
  subnet_id       = aws_subnet.internal_subnet.id
  security_groups = [aws_security_group.internal_subnet_sg.id]
  tags = {
    Name = "controller-secondary-eni"
  }
}

# EIP
resource "aws_eip" "controller_eip" {
  domain = "vpc"
}

resource "aws_eip_association" "controller_eip_assoc" {
  network_interface_id = aws_network_interface.controller_instance_primary_eni.id
  allocation_id        = aws_eip.controller_eip.id
}

# Controller instance
resource "aws_instance" "controller_instance" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t2.small"
  iam_instance_profile = aws_iam_instance_profile.controller_instance_profile.name

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.controller_instance_primary_eni.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.controller_instance_eni.id
  }

  tags = {
    Name = "controller"
    Type = "controller"
  }

  user_data = <<-EOF
    #!/bin/bash

    # SSM Agent
    snap switch --channel=candidate amazon-ssm-agent
    snap install amazon-ssm-agent --classic
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service

    # Ansible
    apt-get update -y
    apt-get install -y python3-pip
    pip3 install --system ansible awscli boto3 botocore
    ansible-galaxy collection install amazon.aws

    # Get the private key for all managed instances
    echo "${tls_private_key.managed_nodes.private_key_pem}" > /home/ubuntu/.ssh/managed_nodes.pem
    chmod 600 /home/ubuntu/.ssh/managed_nodes.pem
    chown ubuntu:ubuntu /home/ubuntu/.ssh/managed_nodes.pem

    # Show complete user_data
    touch /home/ubuntu/complete
  EOF
}
