# AMI lookup for Ubuntu 20.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# AMI lookup for the latest Kali
data "aws_ami" "kali_linux" {
  most_recent = true
  owners      = ["679593333241"] # Offensive Security

  filter {
    name   = "name"
    values = ["kali-last-snapshot-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
