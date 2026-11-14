# Um repositório de imagens por microsserviço (Fase 4). O do OS Service
# continua com o nome de `project_name` ("oficina-backend"): o CD daquele
# repositório faz push para esse nome.
locals {
  ecr_repositories = toset(concat([var.project_name], var.service_ecr_repositories))
}

resource "aws_ecr_repository" "service" {
  for_each = local.ecr_repositories

  name                 = each.key
  image_tag_mutability = "MUTABLE"
  # Without this, `terraform destroy` fails on a non-empty repository
  # (CI pushes images every deploy) instead of cleaning it up.
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "service" {
  for_each = aws_ecr_repository.service

  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# Até a Fase 3 havia um único repositório, `aws_ecr_repository.app`. Sem estes
# blocos, o Terraform entenderia a troca de endereço como "apagar o antigo e
# criar um novo" — e o `force_delete` levaria junto todas as imagens.
moved {
  from = aws_ecr_repository.app
  to   = aws_ecr_repository.service["oficina-backend"]
}

moved {
  from = aws_ecr_lifecycle_policy.app
  to   = aws_ecr_lifecycle_policy.service["oficina-backend"]
}
