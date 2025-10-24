data "aws_ami" "latest" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = [var.architecture]
  }
  filter {
    name   = "name"
    values = [var.ami_regex]
  }
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.latest.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.this_profile.name
  associate_public_ip_address = true

  user_data                   = var.user_data_file
  user_data_replace_on_change = true

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = var.name }
}