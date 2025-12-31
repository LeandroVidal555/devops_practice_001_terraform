# SQS ####
##########
resource "aws_sqs_queue" "karpenter_irq" {
  name                      = module.eks.cluster_name
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
}

data "aws_iam_policy_document" "karpenter_irq_queue" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "sqs.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.karpenter_irq.arn]
  }

  statement {
    sid    = "DenyHTTP"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.karpenter_irq.arn]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sqs_queue_policy" "karpenter_irq" {
  queue_url = aws_sqs_queue.karpenter_irq.id
  policy    = data.aws_iam_policy_document.karpenter_irq_queue.json
}

# EventBridge ####
##################
resource "aws_cloudwatch_event_rule" "karpenter_scheduled_change" {
  name          = "${module.eks.cluster_name}-karpenter-scheduled-change"
  event_pattern = jsonencode({ source = ["aws.health"], "detail-type" = ["AWS Health Event"] })
}

resource "aws_cloudwatch_event_rule" "karpenter_spot_irq" {
  name          = "${module.eks.cluster_name}-karpenter-spot-irq"
  event_pattern = jsonencode({ source = ["aws.ec2"], "detail-type" = ["EC2 Spot Instance Interruption Warning"] })
}

resource "aws_cloudwatch_event_rule" "karpenter_rebalance" {
  name          = "${module.eks.cluster_name}-karpenter-rebalance"
  event_pattern = jsonencode({ source = ["aws.ec2"], "detail-type" = ["EC2 Instance Rebalance Recommendation"] })
}

resource "aws_cloudwatch_event_rule" "karpenter_instance_state_change" {
  name          = "${module.eks.cluster_name}-karpenter-instance-state-change"
  event_pattern = jsonencode({ source = ["aws.ec2"], "detail-type" = ["EC2 Instance State-change Notification"] })
}

resource "aws_cloudwatch_event_target" "karpenter_scheduled_change" {
  rule = aws_cloudwatch_event_rule.karpenter_scheduled_change.name
  arn  = aws_sqs_queue.karpenter_irq.arn
}
resource "aws_cloudwatch_event_target" "karpenter_spot_irq" {
  rule = aws_cloudwatch_event_rule.karpenter_spot_irq.name
  arn  = aws_sqs_queue.karpenter_irq.arn
}
resource "aws_cloudwatch_event_target" "karpenter_rebalance" {
  rule = aws_cloudwatch_event_rule.karpenter_rebalance.name
  arn  = aws_sqs_queue.karpenter_irq.arn
}
resource "aws_cloudwatch_event_target" "karpenter_instance_state_change" {
  rule = aws_cloudwatch_event_rule.karpenter_instance_state_change.name
  arn  = aws_sqs_queue.karpenter_irq.arn
}