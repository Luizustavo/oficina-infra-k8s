# ---------------------------------------------------------------------------
# Contrato de rede consumido pelo repositório oficina-infra-database via
# `terraform_remote_state`. Renomear ou remover qualquer um destes três
# outputs QUEBRA o apply daquele repositório — trate-os como API pública.
# ---------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC where every resource of this project lives"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnets — the RDS subnet group is built from these"
  value       = aws_subnet.private[*].id
}

output "k3s_node_security_group_id" {
  description = "Security group of the k3s node — the RDS SG allows Postgres from it"
  value       = aws_security_group.k3s_node.id
}

# ---------------------------------------------------------------------------
# Operacional
# ---------------------------------------------------------------------------

output "public_subnet_ids" {
  description = "Public subnets hosting the k3s node"
  value       = aws_subnet.public[*].id
}

output "k3s_instance_public_ip" {
  description = "Static (Elastic) IP of the k3s node — the app answers at http://<this-ip>:<k3s_node_port>"
  value       = aws_eip.k3s_node.public_ip
}

output "k3s_instance_id" {
  description = "EC2 instance ID of the k3s node"
  value       = aws_instance.k3s_node.id
}

output "connect_via_ssm" {
  description = "Open a shell on the node without SSH keys"
  value       = "aws ssm start-session --target ${aws_instance.k3s_node.id} --region ${var.aws_region}"
}

output "app_url" {
  description = "Public URL of the app once the Deployment/Service are applied"
  value       = "http://${aws_eip.k3s_node.public_ip}:${var.k3s_node_port}"
}

output "ecr_repository_url" {
  description = "Push Docker images here; referenced by the K8s Deployment manifest"
  value       = aws_ecr_repository.app.repository_url
}

output "aws_account_id" {
  description = "Account ID, useful for building the ECR image URI"
  value       = data.aws_caller_identity.current.account_id
}
