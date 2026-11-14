#!/bin/bash
set -euo pipefail

if ! command -v aws >/dev/null 2>&1; then
  dnf install -y awscli
fi

# k3s' self-signed cert only covers its own view of "who am I" (private IP,
# cluster IPs, localhost) by default. Without this, kubectl from outside the
# VPC fails TLS verification against the public (Elastic) IP.
mkdir -p /etc/rancher/k3s
printf "tls-san:\n  - %s\n" "${public_ip}" > /etc/rancher/k3s/config.yaml

# Traefik (o ingress que já vem no k3s) assume a porta de entrada do cluster.
# Tudo o que é colocado nesta pasta o k3s aplica sozinho ao subir, então o
# cluster já nasce com o Traefik em NodePort ${k3s_node_port} — a mesma porta
# que o security group libera e que o API Gateway (oficina-lambda-auth) usa.
# Ele roteia por caminho: /api/billing, /api/execution e o resto de /api.
# Ver ADR-015 no repositório oficina-backend.
mkdir -p /var/lib/rancher/k3s/server/manifests
cat > /var/lib/rancher/k3s/server/manifests/traefik-config.yaml <<'YAML'
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    service:
      type: NodePort
    ports:
      web:
        nodePort: ${k3s_node_port}
YAML

curl -sfL https://get.k3s.io | sh -

# ECR tokens expire every 12h, so a timer keeps containerd's registry auth fresh.
cat > /usr/local/bin/refresh-ecr-auth.sh <<'SCRIPT'
#!/bin/bash
set -euo pipefail
REGION="${aws_region}"
ACCOUNT_ID="${aws_account_id}"
PASSWORD=$(aws ecr get-login-password --region "$REGION")
cat > /etc/rancher/k3s/registries.yaml <<YAML
configs:
  "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com":
    auth:
      username: AWS
      password: "$PASSWORD"
YAML
systemctl restart k3s
SCRIPT
chmod +x /usr/local/bin/refresh-ecr-auth.sh
/usr/local/bin/refresh-ecr-auth.sh

cat > /etc/systemd/system/refresh-ecr-auth.service <<'UNIT'
[Unit]
Description=Refresh ECR auth for k3s

[Service]
Type=oneshot
ExecStart=/usr/local/bin/refresh-ecr-auth.sh
UNIT

cat > /etc/systemd/system/refresh-ecr-auth.timer <<'UNIT'
[Unit]
Description=Refresh ECR auth for k3s every 6 hours

[Timer]
OnBootSec=5min
OnUnitActiveSec=6h

[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl enable --now refresh-ecr-auth.timer
