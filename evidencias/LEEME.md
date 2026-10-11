# Evidencias

Guardar aquí las capturas con estos nombres:

| Archivo | Qué debe verse |
|---|---|
| 00_validate_con_error.png | (Opcional) `terraform validate` sobre el proyecto original del docente, fallando por los `value` vacíos de outputs.tf |
| 01_terraform_init.png | `terraform init` ("Terraform has been successfully initialized!") |
| 02_terraform_validate.png | `terraform validate` ("Success! The configuration is valid.") |
| 03_terraform_plan.png | `terraform plan` ("Plan: 5 to add, 0 to change, 0 to destroy.") |
| 04_terraform_apply.png | `terraform apply` ("Apply complete! Resources: 5 added") |
| 05_docker_ps.png | `docker ps` con servidor-web y servidor-app |
| 06_docker_network_ls.png | `docker network ls` con red-evaluacion |
| 07_verify.png | `./scripts/verify.sh` terminando en "todo correcto" |
| 08_curl.png | `curl` al web (8080) y a la app (8081) |
| 09_terraform_output.png | `terraform output` con los 5 outputs |
| 10_error_intencional.png | (Opcional) fallo de verificación con `external = 8082` antes de corregir |
| 11_modificacion_plan.png | `terraform plan` tras el cambio solicitado (ej. puerto 8090) |
| 12_modificacion_apply.png | `terraform apply` del cambio y verificación posterior |
| 13_terraform_destroy.png | `terraform destroy` ("Destroy complete! Resources: 5 destroyed") |
| 14_reconstruccion.png | `terraform apply` otra vez + `./scripts/verify.sh` exitoso |
