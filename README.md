# Evaluación - Infraestructura como Código

**Materia:** Automatización de Infraestructura Digital II
**Actividad:** Despliegue, verificación y recuperación de una infraestructura automatizada
**Alumno:** [COMPLETAR: nombre]  **Grupo:** [COMPLETAR]  **Fecha:** [COMPLETAR]
**Repositorio:** [COMPLETAR: URL de GitHub/GitLab]

## Objetivo

Completar y ejecutar la infraestructura definida mediante Terraform, verificar su funcionamiento, modificarla, detectar y corregir un error, y demostrar que puede destruirse y reconstruirse a partir del código.

## Requisitos

- Docker
- Terraform
- Git
- Bash

## Arquitectura

La infraestructura está compuesta por:

- Una red Docker.
- Un servidor web.
- Un servidor de aplicaciones.

```
        red-evaluacion
        10.20.0.0/24
             │
     ┌───────┴────────┐
┌────▼─────┐     ┌────▼─────┐
│ servidor │     │ servidor │
│   -web   │     │   -app   │
│10.20.0.10│     │10.20.0.20│
│ :8080    │     │ :8081    │
└──────────┘     └──────────┘
```

### Direccionamiento

| Recurso | Dirección |
|---|---|
| Red | 10.20.0.0/24 |
| Web | 10.20.0.10 |
| App | 10.20.0.20 |

### Puertos

| Servicio | Puerto (host) | Puerto (contenedor) |
|---|---:|---:|
| Web | 8080 | 80 |
| App | 8081 | 80 |

## Estructura del proyecto

```
infraestructura-evaluacion/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── scripts/
│   ├── verify.sh      (base del docente, completado)
│   ├── deploy.sh      (init, fmt, validate, plan, apply)
│   └── destroy.sh     (terraform destroy)
├── docker/
│   └── Dockerfile     (entregado por el docente)
├── docs/
│   └── guia_defensa.md
├── evidencias/
├── .gitignore
└── README.md
```

## Trabajo realizado sobre el proyecto base

| Archivo | Qué se completó o corrigió |
|---|---|
| `terraform/main.tf` | Se agregó IP fija a `servidor-web` (`var.web_ip`) y a `servidor-app` (`var.app_ip`). **Se corrigió el error intencional** `external = 8082`, que ignoraba la variable `app_port`; ahora usa `var.app_port` (8081). Se agregó `keep_locally = true` a las imágenes para que el `destroy` no falle al tener dos recursos con la misma imagen. |
| `terraform/variables.tf` | Nuevas variables `web_ip` y `app_ip`. |
| `terraform/terraform.tfvars` | Valores de `web_ip` y `app_ip`. |
| `terraform/outputs.tf` | Se completaron `web_url` y `app_url` con `"http://localhost:${var.web_port}"` y `"http://localhost:${var.app_port}"`. |
| `scripts/verify.sh` | Se completó la prueba [5] (servidor de aplicaciones). Se agregó el `cd` a `terraform/` para poder ejecutarlo desde la raíz, comprobación de código HTTP, IP fijas, subred y ping entre servidores. Devuelve código de salida distinto de 0 si algo falla. |
| `scripts/deploy.sh`, `scripts/destroy.sh` | Scripts adicionales para automatizar el despliegue y la destrucción. |

## Procedimiento

```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
docker ps
docker network ls
cd ..
./scripts/verify.sh
curl -I http://localhost:8080
curl -I http://localhost:8081
cd terraform && terraform output
```

## Resultados y evidencias

### terraform init
![terraform init](evidencias/01_terraform_init.png)

### terraform validate
![terraform validate](evidencias/02_terraform_validate.png)

### terraform plan
![terraform plan](evidencias/03_terraform_plan.png)

El plan indica 5 recursos a crear: 1 red, 2 imágenes y 2 contenedores. [COMPLETAR: confirma con tu captura]

### terraform apply
![terraform apply](evidencias/04_terraform_apply.png)

### docker ps
![docker ps](evidencias/05_docker_ps.png)

### docker network ls
![docker network ls](evidencias/06_docker_network_ls.png)

### Ejecución de verify.sh
![verify.sh](evidencias/07_verify.png)

### Pruebas con curl
![curl](evidencias/08_curl.png)

### terraform output
![terraform output](evidencias/09_terraform_output.png)

## Error intencional detectado y corregido

En `main.tf` el servidor de aplicaciones tenía `external = 8082`, mientras que la documentación y `terraform.tfvars` establecen el puerto 8081 (`app_port`).

- **Qué ocurría:** `terraform validate` y `terraform plan` no marcan error porque 8082 es un número válido. El contenedor se crea, pero la aplicación queda publicada en 8082 y no en 8081, por lo que la prueba [5] de `verify.sh` fallaba (`curl http://localhost:8081` no conecta). Además, la variable `app_port` no se utilizaba.
- **Corrección:** `external = var.app_port`.
- **Validación:** `terraform validate`, `terraform plan`, `terraform apply` y `./scripts/verify.sh` con todas las pruebas correctas.

[COMPLETAR: si capturaste el fallo antes de corregir, inserta aquí `evidencias/10_error_intencional.png`]

## Modificación de la infraestructura

[COMPLETAR: describe el cambio que solicitó el docente (por ejemplo, cambiar `web_port` de 8080 a 8090), el resultado de `terraform plan` (el contenedor se reemplaza: 1 to add, 1 to destroy), el `apply` y la verificación posterior.]

![plan de la modificación](evidencias/11_modificacion_plan.png)
![apply de la modificación](evidencias/12_modificacion_apply.png)

## Prueba de recuperación (destroy y reconstrucción)

```bash
./scripts/destroy.sh
docker ps -a
./scripts/deploy.sh
./scripts/verify.sh
```

![terraform destroy](evidencias/13_terraform_destroy.png)
![reconstrucción](evidencias/14_reconstruccion.png)

[COMPLETAR: tiempo aproximado y resultado de la verificación tras reconstruir.]

## Pregunta final

**Explique cómo la Infraestructura como Código permite reproducir la infraestructura implementada.**

Toda la infraestructura (red, subred, direcciones IP, puertos, imágenes y contenedores) está descrita de forma declarativa en archivos de texto: `main.tf` define los recursos, `variables.tf` y `terraform.tfvars` sus valores, y `outputs.tf` los datos de salida. Terraform compara esa definición con el estado real y crea exactamente lo que falta; por eso, después de ejecutar `terraform destroy`, un nuevo `terraform apply` vuelve a producir la misma red, las mismas IP y los mismos servicios sin repetir ningún paso manual. Como el código se guarda en Git, cualquier persona que reciba el repositorio, con Terraform y Docker instalados, puede ejecutar `./scripts/deploy.sh` y obtener un entorno idéntico, y `./scripts/verify.sh` comprueba que realmente funciona. Así se eliminan los errores humanos y las diferencias entre entornos, y queda documentado qué cambió y cuándo.

## Conclusiones

[COMPLETAR: 4 a 6 líneas con lo aprendido, el error encontrado y cómo se resolvió, y la relación entre DevOps y automatización.]
