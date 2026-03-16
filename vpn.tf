# VPN Instance
resource "aws_instance" "vpn_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.external_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [
                                  aws_security_group.external_subnet_sg.id,
                                  aws_security_group.public_sg.id
                                ]
  source_dest_check           = false

  tags = {
    Name     = "vpn-instance"
  }

  user_data = <<-EOF
    #!/bin/bash

    # Installing and starting ssh
    apt-get update
    apt-get install -y wireguard

    # SSM Agent Snap installation
    snap switch --channel=candidate amazon-ssm-agent
    snap install amazon-ssm-agent --classic

    # Starting/enabling it
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service

    # WireGuard setup
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

    [Peer]
    PublicKey = ${data.external.wireguard_keys.result.client_public}
    AllowedIPs = 10.8.0.2/32
    WGCONF

    chmod 600 /etc/wireguard/wg0.conf
    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
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
