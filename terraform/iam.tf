# IAM role for existing EC2 instances to allow AWS SSM command execution.
resource "aws_iam_role" "ec2_ssm" {
  name = var.ec2_iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "innovatech-ssm-role"
    Environment = "devops-deploy"
    Project     = "tienda-perritos"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = var.ec2_instance_profile_name
  role = aws_iam_role.ec2_ssm.name
}
