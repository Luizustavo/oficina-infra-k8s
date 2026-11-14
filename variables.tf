variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "sa-east-1"
}

variable "aws_profile" {
  description = "Named AWS CLI profile for local runs. Leave empty in CI, where credentials come from the environment."
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Name prefix used to tag and name all resources"
  type        = string
  default     = "oficina-backend"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to spread public/private subnets across"
  type        = list(string)
  default     = ["sa-east-1a", "sa-east-1b"]
}

variable "k3s_instance_type" {
  description = "EC2 instance type running the single-node k3s cluster"
  type        = string
  # 4 GB: três microsserviços, RabbitMQ, MongoDB, Redis e o agente do New
  # Relic não cabem nos 2 GB da t3.small usada até a Fase 3.
  #
  # Não é t3.medium porque a conta AWS está no plano gratuito, que só aceita
  # tipos elegíveis ao free tier — e o único com 4 GB é a c7i-flex.large.
  # Lista atual: aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true
  default = "c7i-flex.large"
}

variable "k3s_root_volume_size" {
  description = "Root EBS volume size (GB) of the k3s node — holds container images and the local-path volumes of RabbitMQ, MongoDB and Redis"
  type        = number
  default     = 30
}

variable "k3s_node_port" {
  description = "NodePort of the cluster entrypoint (Traefik). The API Gateway in oficina-lambda-auth targets this port"
  type        = number
  default     = 30080
}

variable "service_ecr_repositories" {
  description = "ECR repositories of the microservices besides the OS Service (whose repository is named after project_name)"
  type        = list(string)
  default     = ["oficina-billing-service", "oficina-execution-service"]
}

variable "budget_alert_threshold_usd" {
  description = "Monthly spend (USD) that triggers the AWS Budgets email alert"
  type        = number
  default     = 12
}

variable "budget_alert_email" {
  description = "Email address that receives the AWS Budgets alert"
  type        = string
  default     = "luizgustavodesouzasantos23@gmail.com"
}
