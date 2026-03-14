# Managed nodes key (used for the Ansible controller)
resource "tls_private_key" "managed_nodes" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "managed_nodes" {
  key_name   = "managed-nodes-key"
  public_key = tls_private_key.managed_nodes.public_key_openssh
}
