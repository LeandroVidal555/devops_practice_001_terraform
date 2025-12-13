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
  policy = file("${path.module}/resources/updater_lambda/updater_lambda.json")
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
resource "aws_cloudwatch_event_rule" "app_alb_created" {
  name        = local.updater_lambda.lambda_name
  description = "Trigger CFront/R53 updater when an ALB is created"

  event_pattern = jsonencode({
    source      = ["aws.elasticloadbalancing"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["elasticloadbalancing.amazonaws.com"]
      eventName   = ["CreateLoadBalancer"]
      responseElements = {
        loadBalancers = {
          loadBalancerName = [local.updater_lambda.alb_app_name]
        }
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
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.updater.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alb_created.arn
}
