resource "aws_iam_role" "bastion_role" {
  name = "${var.environment}-bastion-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "bastion_s3_access" {
  name = "${var.environment}-bastion-s3-access"
  role = aws_iam_role.bastion_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::${var.app_s3_bucket}",
        "arn:aws:s3:::${var.app_s3_bucket}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion_cloudwatch" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.environment}-bastion-profile"
  role = aws_iam_role.bastion_role.name
}
