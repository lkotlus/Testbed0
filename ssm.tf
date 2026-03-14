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
            "aws s3 sync s3://${aws_s3_bucket.ansible_playbooks.bucket}/playbooks/ /home/ubuntu/playbooks/",
            "sudo -u ubuntu ansible-playbook -i /home/ubuntu/playbooks/inventory.aws_ec2.yml /home/ubuntu/playbooks/main.yml --private-key /home/ubuntu/.ssh/managed_nodes.pem"
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
    aws_instance.attack_box,
    aws_instance.external_site,
    aws_instance.internal_database,
    aws_s3_bucket.ansible_playbooks,
    aws_s3_object.ansible_playbooks
  ]
}
