# Document to upload and run playbooks
resource "aws_ssm_document" "run_ansible" {
  name          = "RunAnsiblePlaybooks"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Fetch playbooks from S3 and run Ansible"
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "runAnsible"
        inputs = {
          runCommand = [
            "while [ ! -f /home/ubuntu/complete ]; do sleep 5; done",
            "sudo pip3 install --system ansible awscli boto3 botocore",
            "sudo -u ubuntu pip3 install --system ansible awscli boto3 botocore",
            "sudo -u ubuntu pip3 install ansible awscli boto3 botocore",
            "for i in $(seq 1 10); do echo \"Attempt $i: syncing playbooks...\"; sudo -u ubuntu touch /home/ubuntu/$i; sudo -u ubuntu aws s3 sync s3://${aws_s3_bucket.ansible_playbooks.bucket}/controller_files/ /home/ubuntu/controller_files/; if [ -f /home/ubuntu/controller_files/scoring/scoring_api.service ]; then echo \"Playbooks downloaded successfully.\"; break; fi; echo \"File not found yet, retrying in 20 seconds...\"; sleep 20; done",
            "if [ ! -f /home/ubuntu/controller_files/scoring/scoring_api.service ]; then echo \"Failed to download playbooks after multiple attempts. Exiting.\"; exit 1; fi",
            "sudo -u ubuntu python3 -m venv /home/ubuntu/controller_files/scoring/venv",
            "sudo -u ubuntu /home/ubuntu/controller_files/scoring/venv/bin/pip install --upgrade pip",
            "sudo -u ubuntu /home/ubuntu/controller_files/scoring/venv/bin/pip install \"fastapi[standard]\" boto3",
            "sudo -u ubuntu ansible-galaxy collection install amazon.aws",
            "sudo mv /home/ubuntu/controller_files/scoring/scoring_api.service /etc/systemd/system/scoring_api.service",
            "sudo systemctl daemon-reload",
            "sudo systemctl enable scoring_api",
            "sudo systemctl start scoring_api",
            "sudo -u ubuntu ansible-playbook -i /home/ubuntu/controller_files/playbooks/inventory.aws_ec2.yml /home/ubuntu/controller_files/playbooks/main.yml --private-key /home/ubuntu/.ssh/managed_nodes.pem"
          ]
        }
      }
    ]
  })
}

# Trigger the document on the controller (after instances are ready)
resource "aws_ssm_association" "run_ansible" {
  name = aws_ssm_document.run_ansible.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.controller_instance.id]
  }

  depends_on = [
    aws_instance.controller_instance,
    aws_instance.external_site,
    aws_instance.internal_1,
    aws_instance.internal_2,
    aws_s3_bucket.ansible_playbooks,
    aws_s3_object.ansible_playbooks
  ]
}
