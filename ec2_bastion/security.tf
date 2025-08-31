data "aws_iam_policy_document" "bastion_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.bastion_assume.json
}

resource "aws_iam_policy" "bastion_general" {
  name   = "${var.name}-general"
  policy = file(var.policy_file)
}

# Attach to your existing bastion role
resource "aws_iam_role_policy_attachment" "bastion_general" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion_general.arn
}

# SSM access + basic ECR read (handy) + CloudWatch logs
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.name}-profile"
  role = aws_iam_role.bastion.name
}

# SG: egress only (no inbound needed with SSM)
resource "aws_security_group" "bastion" {
  name        = "${var.name}-sg"
  description = "Bastion SG (SSM only)"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}