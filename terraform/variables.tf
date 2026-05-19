variable "aws_region" {
  description = "AWS region to create ECR repos and IAM resources."
  type        = string
  default     = "us-east-1"
}

variable "ecr_repository_names" {
  description = "Names of the ECR repositories for the tienda-perritos microservices."
  type        = list(string)
  default     = ["tienda-db", "tienda-backend", "tienda-frontend"]
}

variable "ec2_iam_role_name" {
  description = "IAM role name for EC2 instances that will receive SSM commands."
  type        = string
  default     = "innovatech-ssm-role"
}

variable "ec2_instance_profile_name" {
  description = "Instance profile name for the EC2 role used by AWS SSM."
  type        = string
  default     = "innovatech-ssm-instance-profile"
}
