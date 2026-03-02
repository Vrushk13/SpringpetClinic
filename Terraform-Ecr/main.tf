provider "aws" {
  region = "ap-south-1"
}

resource "aws_ecr_repository" "petclinic_repo" {
  name                 = "petclinic-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "repository_url" {
  value = aws_ecr_repository.petclinic_repo.repository_url
}
