#!/bin/bash
# Destruye la infraestructura
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/terraform"
terraform destroy -auto-approve
