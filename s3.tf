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

# Bucket for results
resource "aws_s3_bucket" "assessment_findings" {
  bucket        = "assessment-findings"
  force_destroy = true
}

# Make everything public
resource "aws_s3_bucket_public_access_block" "assessment_findings" {
  bucket = aws_s3_bucket.assessment_findings.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Actual bucket policy
resource "aws_s3_bucket_policy" "assessment_findings" {
  bucket = aws_s3_bucket.assessment_findings.id

  # Must wait for the public access block to be removed first, otherwise
  # Terraform will race and get an Access Denied on the policy put.
  depends_on = [aws_s3_bucket_public_access_block.assessment_findings]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.assessment_findings.arn}/*"
      },
      {
        Sid       = "PublicListBucket"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.assessment_findings.arn
      }
    ]
  })
}

# CORS config for public access
resource "aws_s3_bucket_cors_configuration" "assessment_findings" {
  bucket = aws_s3_bucket.assessment_findings.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

# Website config
resource "aws_s3_bucket_website_configuration" "assessment_findings" {
  bucket = aws_s3_bucket.assessment_findings.id

  index_document {
    suffix = "dashboard.html"
  }
}

# Dashboard page
resource "aws_s3_object" "dashboard" {
  bucket       = aws_s3_bucket.assessment_findings.id
  key          = "dashboard.html"
  source       = "${path.module}/playbooks/files/scoring/dashboard.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/playbooks/files/scoring/dashboard.html")
}

# Output the dashboard URL like a sane person
output "dashboard_url" {
  description = "URL of the scoring dashboard"
  value       = "http://${aws_s3_bucket_website_configuration.assessment_findings.website_endpoint}"
}
