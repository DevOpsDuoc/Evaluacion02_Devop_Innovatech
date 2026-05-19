output "ecr_repository_urls" {
  description = "Map of ECR repository names to repository URLs for tienda-db, tienda-backend, and tienda-frontend."
  value = {
    for name, repo in aws_ecr_repository.tienda :
    name => repo.repository_url
  }
}

output "ec2_iam_role_name" {
  description = "IAM role name created for EC2 instances to allow AWS SSM command execution."
  value       = aws_iam_role.ec2_ssm.name
}

output "ec2_instance_profile_name" {
  description = "IAM instance profile name to attach to existing EC2 instances for SSM access."
  value       = aws_iam_instance_profile.ec2_ssm_profile.name
}
