################
# IAM
################
data "aws_iam_policy_document" "assume_lambda" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${local.updater_lambda.lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "${local.updater_lambda.lambda_name}-policy"
  policy = file("${path.module}/resources/updater_lambda/updater_lambda_policy.json")
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

################
# Lambda
################
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/resources/updater_lambda/updater_lambda.py"
  output_path = "${path.module}/.terraform-build/${local.updater_lambda.lambda_name}.zip"
}

resource "aws_lambda_function" "updater" {
  function_name = local.updater_lambda.lambda_name
  role          = aws_iam_role.lambda_role.arn

  runtime = local.updater_lambda.python_runtime
  handler = "updater_lambda.handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout     = 30
  memory_size = 256

  environment {
    variables = {
      DISTRIBUTION_ALIAS = local.app_infra.site_url
      ORIGIN_ID          = local.app_infra.api_alb_origin_id
      ALB_NAME           = local.updater_lambda.alb_app_name
    }
  }
}

#####################
# EventBridge
#####################
resource "aws_cloudwatch_event_rule" "alb_created" {
  name        = local.updater_lambda.lambda_name #"${local.updater_lambda.lambda_name}-alb"
  description = "Trigger CFront/R53 updater when an ALB is created"

  event_pattern = jsonencode({
    source      = ["aws.elasticloadbalancing"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["elasticloadbalancing.amazonaws.com"]
      eventName   = ["CreateLoadBalancer"]
      requestParameters = {
        name = [local.updater_lambda.alb_app_name]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "invoke_lambda" {
  rule      = aws_cloudwatch_event_rule.alb_created.name
  target_id = local.updater_lambda.lambda_name
  arn       = aws_lambda_function.updater.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke" #"AllowEventBridgeInvokeALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.updater.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alb_created.arn
}

resource "aws_cloudwatch_event_rule" "cloudfront_created" {
  name        = "${local.updater_lambda.lambda_name}-cf"
  description = "Trigger CFront/R53 updater when a CloudFront distribution is created"

  event_pattern = jsonencode({
    source      = ["aws.cloudfront"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["cloudfront.amazonaws.com"]
      eventName   = ["CreateDistribution"]
    }
  })
}

resource "aws_cloudwatch_event_target" "invoke_lambda_on_cf_create" {
  rule      = aws_cloudwatch_event_rule.cloudfront_created.name
  target_id = local.updater_lambda.lambda_name
  arn       = aws_lambda_function.updater.arn
}

resource "aws_lambda_permission" "allow_eventbridge_cf_create" {
  statement_id  = "AllowEventBridgeInvokeCF"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.updater.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudfront_created.arn
}


# Couudtrail trails NEEDS a write target
# Cheapest storage target: an S3 bucket with short retention
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.env}-${var.common_prefix}-cloudtrail"
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
  name           = "${var.env}-${var.common_prefix}-eventbridge-trail"
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
