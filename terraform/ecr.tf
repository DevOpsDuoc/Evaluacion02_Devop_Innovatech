# Amazon ECR repositories for each independent microservice.
resource "aws_ecr_repository" "tienda" {
  for_each = toset(var.ecr_repository_names)
  name     = each.value

  image_tag_mutability = "MUTABLE"

  tags = {
    Name        = "innovatech-${each.value}"
    Environment = "devops-deploy"
    Project     = "tienda-perritos"
  }
}
