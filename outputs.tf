output "external_site_id" {
  value = aws_instance.external_site.id
}

output "external_site_private_ip" {
  value = aws_instance.external_site.private_ip
}

output "internal_1_id" {
  value = aws_instance.internal_1.id
}

output "internal_1_private_ip" {
  value = aws_instance.internal_1.private_ip
}

output "internal_2_id" {
  value = aws_instance.internal_2.id
}

output "internal_2_private_ip" {
  value = aws_instance.internal_2.private_ip
}

output "controller_id" {
  value = aws_instance.controller_instance.id
}

output "controller_private_ip" {
  value = aws_instance.controller_instance.private_ip
}

output "wireguard_client_config" {
  sensitive = true
  value     = <<-EOT
    [Interface]
    Address = 10.8.0.2/32
    PrivateKey = ${data.external.wireguard_keys.result.client_private}
    DNS = 1.1.1.1

    [Peer]
    PublicKey = ${data.external.wireguard_keys.result.server_public}
    Endpoint = ${aws_eip.controller_eip.public_ip}:51820
    AllowedIPs = ${aws_subnet.internal_subnet.cidr_block}, ${aws_subnet.external_subnet.cidr_block}
    PersistentKeepalive = 25
  EOT
}
