resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.this_profile.name
  associate_public_ip_address = true
  user_data                   = var.user_data_file

  tags = { Name = var.name }
}