# S3 bucket for redirecting non-www to www
resource "aws_s3_bucket" "root_bucket" {
  bucket = var.domain_name

  tags = var.common_tags
}

resource "aws_s3_bucket_website_configuration" "root_website_config" {
  bucket = aws_s3_bucket.root_bucket.bucket

  redirect_all_requests_to {
    host_name = "https://www.${var.domain_name}"
  }
}

resource "aws_s3_bucket_policy" "root_allow_access_from_public" {
  bucket = aws_s3_bucket.root_bucket.id
  policy = templatefile("templates/s3-policy.json", { bucket = var.domain_name })
}

resource "aws_s3_bucket_acl" "root_acl" {
  bucket = aws_s3_bucket.root_bucket.id
  acl    = "public-read"
}
