#!/usr/bin/env bash
#
# Cria o bucket S3 que guarda o Terraform state de TODOS os repositorios de
# infraestrutura do projeto.
#
# Por que isto e um script e nao Terraform: o backend remoto e um problema do
# ovo e da galinha — o Terraform precisa do bucket para guardar o state, mas
# criar o bucket com Terraform geraria um state que nao tem onde morar. A
# saida honesta e criar esse unico recurso fora do Terraform, uma vez so.
#
# Desde o Terraform 1.11 o backend S3 faz lock nativo com `use_lockfile = true`
# (um arquivo .tflock no proprio bucket), entao NAO existe mais tabela DynamoDB.
#
# O script e idempotente: rodar de novo nao quebra nada.

set -euo pipefail

AWS_PROFILE_NAME="${AWS_PROFILE_NAME:-oficina-fase2}"
AWS_REGION="${AWS_REGION:-sa-east-1}"

export AWS_PAGER=""

ACCOUNT_ID=$(aws sts get-caller-identity \
  --profile "$AWS_PROFILE_NAME" \
  --query Account --output text)

BUCKET="oficina-backend-tfstate-${ACCOUNT_ID}"

echo "Conta AWS : $ACCOUNT_ID"
echo "Regiao    : $AWS_REGION"
echo "Bucket    : $BUCKET"
echo

if aws s3api head-bucket --bucket "$BUCKET" --profile "$AWS_PROFILE_NAME" 2>/dev/null; then
  echo "-> Bucket ja existe, seguindo para as configuracoes."
else
  echo "-> Criando o bucket..."
  # Toda regiao que nao seja us-east-1 exige LocationConstraint explicito.
  aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$AWS_REGION" \
    --create-bucket-configuration "LocationConstraint=${AWS_REGION}" \
    --profile "$AWS_PROFILE_NAME"
fi

# Versionamento: se um apply corromper o state, da para voltar a versao anterior.
echo "-> Habilitando versionamento..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled \
  --profile "$AWS_PROFILE_NAME"

# O state guarda a senha do RDS em texto plano — criptografia nao e opcional.
echo "-> Habilitando criptografia em repouso..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}' \
  --profile "$AWS_PROFILE_NAME"

echo "-> Bloqueando qualquer acesso publico..."
aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --profile "$AWS_PROFILE_NAME"

echo
echo "Pronto. Bucket de state: $BUCKET"
echo
echo "Chaves usadas por cada repositorio:"
echo "  oficina-infra-k8s       -> k8s/terraform.tfstate"
echo "  oficina-infra-database  -> database/terraform.tfstate"
echo "  oficina-lambda-auth     -> lambda/terraform.tfstate"
