# Cloudtrail trails NEEDS a write target
# Cheapest storage target: an S3 bucket with short retention
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "expire-fast"
    status = "Enabled"

    expiration {
      days = 1
    }
  }
}

# Required CloudTrail bucket policy
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = templatefile(
    "${path.module}/resources/updater_lambda/cloudtrail_bucket_policy.json",
    {
      bucket_arn = aws_s3_bucket.cloudtrail.arn
      account_id = data.aws_caller_identity.current.account_id
    }
  )
}

# Cheapest trail that still feeds EventBridge
resource "aws_cloudtrail" "eventbridge_mgmt" {
  name           = "${aws_s3_bucket.cloudtrail.id}-eventbridge-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.id

  is_multi_region_trail         = false
  include_global_service_events = true
  enable_log_file_validation    = false

  event_selector {
    include_management_events = true
    read_write_type           = "WriteOnly"
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_s3_bucket_public_access_block.cloudtrail
  ]
}
