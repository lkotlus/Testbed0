# Primary ENI (external subnet + public access) 
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
  subnet_id         = aws_subnet.internal_subnet.id
  security_groups   = [aws_security_group.internal_subnet_sg.id]
  source_dest_check = false
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
    set -e

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
    apt-get install -y python3-pip wireguard
    pip3 install --system ansible awscli boto3 botocore
    ansible-galaxy collection install amazon.aws

    # Get the private key for all managed instances
    echo "${tls_private_key.managed_nodes.private_key_pem}" > /home/ubuntu/.ssh/managed_nodes.pem
    chmod 600 /home/ubuntu/.ssh/managed_nodes.pem
    chown ubuntu:ubuntu /home/ubuntu/.ssh/managed_nodes.pem

    #
    # WireGuard setup
    #
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sysctl -p

    PRIMARY_IFACE=$(ip route | grep default | awk '{print $5}' | head -1)

    cat > /etc/wireguard/wg0.conf <<WGCONF
    [Interface]
    Address = 10.8.0.1/24
    ListenPort = 51820
    PrivateKey = ${data.external.wireguard_keys.result.server_private}
    PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $PRIMARY_IFACE -j MASQUERADE
    PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $PRIMARY_IFACE -j MASQUERADE

    PostUp   = iptables -A FORWARD -i wg0 -d 10.0.2.0/24 -j DROP
    PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT
    PostUp   = iptables -t nat -A POSTROUTING -o $PRIMARY_IFACE -j MASQUERADE

    PostDown = iptables -D FORWARD -i wg0 -d 10.0.2.0/24 -j DROP
    PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
    PostDown = iptables -t nat -D POSTROUTING -o $PRIMARY_IFACE -j MASQUERADE

    [Peer]
    PublicKey = ${data.external.wireguard_keys.result.client_public}
    AllowedIPs = 10.8.0.2/32
    WGCONF

    chmod 600 /etc/wireguard/wg0.conf
    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0

    touch /home/ubuntu/complete
    EOF
}

data "external" "wireguard_keys" {
  program = ["bash", "-c", <<-EOT
    SERVER_PRIVATE=$(wg genkey)
    SERVER_PUBLIC=$(echo "$SERVER_PRIVATE" | wg pubkey)
    CLIENT_PRIVATE=$(wg genkey)
    CLIENT_PUBLIC=$(echo "$CLIENT_PRIVATE" | wg pubkey)
    echo "{\"server_private\": \"$SERVER_PRIVATE\", \"server_public\": \"$SERVER_PUBLIC\", \"client_private\": \"$CLIENT_PRIVATE\", \"client_public\": \"$CLIENT_PUBLIC\"}"
  EOT
  ]
}
