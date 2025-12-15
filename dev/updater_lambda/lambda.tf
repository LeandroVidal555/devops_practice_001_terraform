data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/resources/updater_lambda/updater_lambda.py"
  output_path = "${path.module}/.terraform-build/${var.lambda_name}.zip"
}

resource "aws_lambda_function" "updater" {
  function_name = var.lambda_name
  role          = aws_iam_role.lambda_role.arn

  runtime = var.python_runtime
  handler = "updater_lambda.handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout     = 30
  memory_size = 256

  environment {
    variables = {
      DISTRIBUTION_ALIAS = var.site_url
      ORIGIN_ID          = var.api_alb_origin_id
      ALB_NAME           = var.alb_app_name
      HOSTED_ZONE_ID_PUB = var.hosted_zone_id_pub
      ALB_RECORD_NAMES   = var.alb_domains
      CFRONT_ZONE_ID     = var.cfront_zone_id
    }
  }
}