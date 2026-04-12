# Primary ENI (external subnet + public access) 
resource "aws_network_interface" "controller_instance_primary_eni" {
  subnet_id       = aws_subnet.external_subnet.id
  security_groups = [aws_security_group.external_subnet_sg.id]
  private_ips     = ["10.0.1.10"]
  tags = {
    Name = "controller-primary-eni"
  }
}

# Secondary ENI (internal subnet) 
resource "aws_network_interface" "controller_instance_eni" {
  subnet_id         = aws_subnet.internal_subnet.id
  security_groups   = [aws_security_group.internal_subnet_sg.id]
  source_dest_check = false
  private_ips     = ["10.0.2.10"]
  tags = {
    Name = "controller-secondary-eni"
  }
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
    set -e

    until ping -c1 8.8.8.8 >/dev/null 2>&1; do
        echo "Waiting for network..."
        sleep 5
    done

    #
    # SSM Agent
    #
    snap switch --channel=candidate amazon-ssm-agent
    snap install amazon-ssm-agent --classic
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service

    #
    # Ansible
    #
    apt-get update -y
    apt-get install -y python3-pip
    pip3 install --system ansible awscli boto3 botocore
    ansible-galaxy collection install amazon.aws

    # Get the private key for all managed instances
    echo "${tls_private_key.managed_nodes.private_key_pem}" > /home/ubuntu/.ssh/managed_nodes.pem
    chmod 600 /home/ubuntu/.ssh/managed_nodes.pem
    chown ubuntu:ubuntu /home/ubuntu/.ssh/managed_nodes.pem

    touch /home/ubuntu/complete
    EOF
}
