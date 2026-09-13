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
  default     = "t3.small"
}

variable "k3s_node_port" {
  description = "NodePort the app's Kubernetes Service is exposed on"
  type        = number
  default     = 30080
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
