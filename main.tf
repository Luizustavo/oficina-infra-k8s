terraform {
  # 1.11+ é necessário para `use_lockfile` no backend S3 (lock nativo, sem DynamoDB).
  required_version = ">= 1.11.0"

  # O bucket é criado uma única vez por scripts/bootstrap-backend.sh.
  # Blocos backend não aceitam interpolação, então o nome vai literal aqui.
  backend "s3" {
    bucket       = "oficina-backend-tfstate-765465309229"
    key          = "k8s/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Na máquina do dev autenticamos por profile nomeado; no GitHub Actions as
  # credenciais vêm de variáveis de ambiente e nenhum profile existe — passar
  # um nome inexistente lá faria o provider falhar, então mandamos null.
  profile = var.aws_profile != "" ? var.aws_profile : null

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
      Repo      = "oficina-infra-k8s"
    }
  }
}

data "aws_caller_identity" "current" {}
