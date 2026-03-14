# Bucket for playbooks
resource "aws_s3_bucket" "ansible_playbooks" {
  bucket = "testbed-ansible-playbooks"
}

# Upload all playbooks to S3
resource "aws_s3_object" "ansible_playbooks" {
  for_each = fileset("${path.module}/playbooks/", "**")
  bucket   = aws_s3_bucket.ansible_playbooks.bucket
  key      = "playbooks/${each.value}"
  source   = "${path.module}/playbooks/${each.value}"
  etag     = filemd5("${path.module}/playbooks/${each.value}")
}
