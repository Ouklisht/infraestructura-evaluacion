#!/bin/bash
# Despliegue automático: init, fmt, validate, plan y apply
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/terraform"

echo "==> terraform init";     terraform init
echo "==> terraform fmt";      terraform fmt
echo "==> terraform validate"; terraform validate
echo "==> terraform plan";     terraform plan -out=tfplan
echo "==> terraform apply";    terraform apply -auto-approve tfplan
rm -f tfplan
terraform output
