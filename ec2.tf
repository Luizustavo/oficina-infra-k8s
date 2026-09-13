# Latest Amazon Linux 2023 AMI, resolved automatically (no hardcoded AMI ID to go stale).
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_iam_role" "k3s_node" {
  name = "${var.project_name}-k3s-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "k3s_ecr_readonly" {
  role       = aws_iam_role.k3s_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Lets us connect via `aws ssm start-session` instead of managing SSH key pairs
# and opening port 22 to the internet.
resource "aws_iam_role_policy_attachment" "k3s_ssm" {
  role       = aws_iam_role.k3s_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "k3s_node" {
  name = "${var.project_name}-k3s-node-profile"
  role = aws_iam_role.k3s_node.name
}

resource "aws_security_group" "k3s_node" {
  name        = "${var.project_name}-k3s-node-sg"
  description = "Single-node k3s cluster - Kubernetes API and app NodePort access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Kubernetes API server (kubectl)"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App NodePort"
    from_port   = var.k3s_node_port
    to_port     = var.k3s_node_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-k3s-node-sg"
  }
}

# Allocated independently of the instance so its address is known before the
# instance's user_data is rendered — avoids the EIP/instance ordering cycle.
resource "aws_eip" "k3s_node" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-k3s-eip"
  }
}

resource "aws_instance" "k3s_node" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.k3s_instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.k3s_node.id]
  iam_instance_profile        = aws_iam_instance_profile.k3s_node.name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  # The EIP's address (stable across reboots) is baked into k3s' TLS
  # certificate SAN list — see k3s-user-data.sh.tpl.
  user_data = templatefile("${path.module}/k3s-user-data.sh.tpl", {
    aws_region     = var.aws_region
    aws_account_id = data.aws_caller_identity.current.account_id
    public_ip      = aws_eip.k3s_node.public_ip
  })

  tags = {
    Name = "${var.project_name}-k3s-node"
  }
}

resource "aws_eip_association" "k3s_node" {
  instance_id   = aws_instance.k3s_node.id
  allocation_id = aws_eip.k3s_node.id
}
