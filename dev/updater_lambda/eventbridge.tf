resource "aws_cloudwatch_event_rule" "alb_created" {
  name        = "${var.lambda_name}-alb"
  description = "Trigger CFront/R53 updater when an ALB is created"

  event_pattern = jsonencode({
    source      = ["aws.elasticloadbalancing"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["elasticloadbalancing.amazonaws.com"]
      eventName   = ["CreateLoadBalancer"]
      requestParameters = {
        name = [
          var.alb_app_name,
          var.alb_admin_name
        ]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "invoke_lambda" {
  rule      = aws_cloudwatch_event_rule.alb_created.name
  target_id = var.lambda_name
  arn       = aws_lambda_function.updater.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvokeALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.updater.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alb_created.arn
}

resource "aws_cloudwatch_event_rule" "cloudfront_created" {
  name        = "${var.lambda_name}-cf"
  description = "Trigger CFront/R53 updater when a CloudFront distribution is created"

  event_pattern = jsonencode({
    source      = ["aws.cloudfront"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["cloudfront.amazonaws.com"]
      eventName   = ["CreateDistributionWithTags"]
    }
  })
}

resource "aws_cloudwatch_event_target" "invoke_lambda_on_cf_create" {
  rule      = aws_cloudwatch_event_rule.cloudfront_created.name
  target_id = var.lambda_name
  arn       = aws_lambda_function.updater.arn
}

resource "aws_lambda_permission" "allow_eventbridge_cf_create" {
  statement_id  = "AllowEventBridgeInvokeCF"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.updater.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cloudfront_created.arn
}