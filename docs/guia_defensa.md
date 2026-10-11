# Guía de defensa (respuestas para la demostración)

> Documento de estudio personal. Léelo antes de la evaluación: el docente evalúa que **expliques** lo que haces.

## Etapa 1. Análisis

**¿Qué es Infraestructura como Código?**
Es gestionar y crear infraestructura (redes, servidores, contenedores) mediante archivos de código en lugar de configurarla a mano. El código se versiona, se revisa y se puede ejecutar cuantas veces se necesite para obtener el mismo resultado.

**¿Qué función cumple Terraform?**
Lee archivos declarativos (`.tf`) que describen el estado deseado, lo compara con la infraestructura real (guardada en el *state*) y ejecuta los cambios necesarios mediante *providers*. Aquí usa el provider `kreuzwerker/docker`.

**¿Diferencia entre `terraform plan` y `terraform apply`?**
`plan` solo calcula y muestra qué se creará, modificará o eliminará, sin cambiar nada. `apply` ejecuta esos cambios (y pide confirmación).

**¿Ventaja de utilizar variables?**
Evitan valores escritos directamente en el código: se cambian en un solo lugar (`terraform.tfvars`), se reutiliza el mismo código en distintos entornos, se reducen errores y el código es más legible. (En este proyecto, el error intencional `external = 8082` existía justamente por no usar la variable.)

## Etapa 2. Preparación

| Comando | Qué hace |
|---|---|
| `terraform init` | Inicializa el directorio: descarga el provider (docker), crea la carpeta `.terraform/` y el archivo de bloqueo `.terraform.lock.hcl`. |
| `terraform fmt` | Da formato estándar a los archivos `.tf` (indentación y alineación). No cambia el funcionamiento. |
| `terraform validate` | Revisa que la configuración sea sintácticamente válida y coherente (argumentos requeridos, referencias). No consulta Docker ni crea nada. |

## Etapa 3. Planificación

Con el proyecto completado, `terraform plan` debe mostrar **Plan: 5 to add, 0 to change, 0 to destroy**:

- **Creados (5):** `docker_network.infra_network`, `docker_image.web_image`, `docker_image.app_image`, `docker_container.web`, `docker_container.app`.
- **Modificados:** ninguno (primera ejecución). **Eliminados:** ninguno.
- **Dependencias:** los contenedores dependen de su imagen y de la red (por las referencias `docker_image.*.image_id` y `docker_network.*.name`). Terraform crea primero red e imágenes y después los contenedores.
- **Símbolos:** `+` crear, `~` modificar en sitio, `-` destruir, `-/+` reemplazar (destruir y crear).

**¿Qué pasa si ejecutas `terraform apply` sin revisar el plan?**
Terraform muestra el plan igualmente y pide `yes`, pero si lo confirmas sin leerlo puedes destruir o reemplazar recursos por error (por ejemplo, un cambio de puerto reemplaza el contenedor y se pierde su estado interno). Revisar el plan es la forma de evitar cambios no deseados.

## Etapa 4. Implementación

```bash
terraform apply        # escribir yes
docker ps              # 2 contenedores: servidor-web (0.0.0.0:8080->80) y servidor-app (0.0.0.0:8081->80)
docker network ls      # red-evaluacion
```

## Etapa 5. Verificación: qué verifica cada comando

| Comando | Qué comprueba |
|---|---|
| `terraform validate` | Que el código sigue siendo válido. |
| `docker ps` | Que los contenedores existen y están en ejecución (`Up`), y qué puertos publican. |
| `docker network ls` | Que la red fue creada. |
| `docker inspect <contenedor>` | Detalles reales: IP asignada, red, puertos, estado. Confirma que la IP fija coincide con el código. |
| `docker logs <contenedor>` | La salida del servicio: sirve para ver peticiones recibidas o errores. |
| `curl -I http://localhost:8080` | Que el servicio HTTP responde (cabecera `HTTP/1.1 200 OK`). |
| `curl -I http://localhost:8081` | Lo mismo para el servidor de aplicaciones. |
| `docker exec servidor-web ping 10.20.0.20` | Que los servidores se comunican dentro de la red. |
| `terraform output` | Los valores de salida definidos en `outputs.tf`. |

**¿Cómo sabes que la infraestructura realmente funciona?**
No basta con que `apply` termine sin error: se comprueba que los contenedores estén `Up`, que las IP sean las definidas, que `curl` obtenga HTTP 200 en ambos puertos y que haya conectividad entre servidores. `verify.sh` automatiza todo eso.

## Etapa 6. Modificación (ensayo)

El docente puede pedir, por ejemplo, **cambiar el puerto del web** o **el nombre del servicio web**.

**Ejemplo A: puerto del web 8080 → 8090**

1. En `terraform/terraform.tfvars`: `web_port = 8090`.
2. `terraform plan` → verás `docker_container.web must be replaced` con `-/+` y **Plan: 1 to add, 0 to change, 1 to destroy**. Se reemplaza porque un contenedor no puede cambiar sus puertos publicados en caliente.
3. `terraform apply` → `docker ps` muestra `0.0.0.0:8090->80/tcp`.
4. Verifica: `curl -I http://localhost:8090`. Ojo: `verify.sh` toma la URL desde `terraform output`, así que seguirá funcionando con el nuevo puerto.

**Ejemplo B: nombre del contenedor web**

1. `terraform.tfvars`: `web_container_name = "servidor-web-2"`.
2. `terraform plan` → también reemplazo (`-/+`) porque el nombre fuerza recreación.
3. `terraform apply`. Nota: `verify.sh` usa el nombre `servidor-web` fijo; si cambias el nombre, actualiza la variable `WEB` del script o explica que la prueba de nombre fallará por eso.

Al terminar, vuelve a dejar los valores originales y aplica si quieres conservar la configuración base.

## Etapa 7. Prueba de recuperación

```bash
terraform destroy      # yes -> Destroy complete! Resources: 5 destroyed
docker ps -a           # ya no existen servidor-web ni servidor-app
terraform apply        # yes -> Apply complete! Resources: 5 added
./scripts/verify.sh
```

Se demuestra que la infraestructura se reproduce desde la definición declarativa.

## Situación problema: el error deliberado

**Caso real de este proyecto:** `external = 8082` en el contenedor `app` (debía ser 8081 = `app_port`).

- `terraform validate` y `terraform plan` **no** lo detectan, porque 8082 es un valor válido.
- `verify.sh` falla en la prueba [5]: `curl http://localhost:8081` no conecta.
- `docker ps` muestra `0.0.0.0:8082->80/tcp`, no 8081.
- **Solución:** cambiar a `external = var.app_port`, ejecutar `terraform validate`, `terraform plan` (reemplazo del contenedor app), `terraform apply` y `./scripts/verify.sh`.

**Ejemplo del enunciado:** `container_port = 808` en lugar de `8080` (en este proyecto el equivalente es `internal`).

- `validate` y `plan` pasan; `apply` crea el contenedor.
- `docker ps` muestra `0.0.0.0:8080->808/tcp`: el host publica 8080 pero hacia un puerto donde nginx no escucha (nginx escucha en el 80).
- `curl http://localhost:8080` falla con `Empty reply from server` o `Connection reset by peer`.
- Corrección: `internal = 80`, `plan`, `apply`, `verify.sh`.

**Método para cualquier error:** leer el mensaje completo → identificar el archivo y la línea → comparar contra el README (IP, puertos) → `docker ps` / `docker logs` / `docker inspect` → corregir → `validate` → `plan` → `apply` → verificar de nuevo.

**Otros errores posibles y cómo reconocerlos**

| Síntoma | Causa probable | Solución |
|---|---|---|
| `address already in use` en `apply` | El puerto del host está ocupado | `ss -tlnp \| grep :8080`; detener el servicio o cambiar el puerto |
| `Pool overlaps with other one` | Otra red Docker usa 10.20.0.0/24 | `docker network ls` y `docker network rm` de la sobrante |
| `Invalid IP address` / `no configured subnet` | IP fuera de la subred 10.20.0.0/24 | Corregir `web_ip` / `app_ip` |
| `Missing required argument "value"` | Output sin completar | Completar `outputs.tf` |
| `permission denied` con Docker | Usuario sin grupo docker | `usermod -aG docker` y reiniciar sesión |

## Preguntas de desempeño

- **¿Relación entre DevOps y automatización?** DevOps busca unir desarrollo y operaciones para entregar más rápido y con calidad; la automatización es su herramienta principal: scripts, IaC y pruebas reemplazan tareas manuales repetitivas, reducen errores y hacen los procesos repetibles.
- **¿Qué tareas manuales se eliminan?** Crear la red a mano, levantar cada contenedor con sus opciones, asignar IP y puertos, repetir las pruebas una por una y documentar lo hecho.
- **¿Por qué Terraform es IaC?** Porque la infraestructura se define en código declarativo, versionable y reproducible, y Terraform la crea y la mantiene a partir de esa definición.
- **¿Ventaja de un script frente a comandos manuales?** Misma secuencia siempre, sin olvidar pasos ni equivocarse al teclear, más rápido, y sirve como documentación ejecutable. `verify.sh` además devuelve un código de salida que otros procesos (CI) pueden usar.
- **¿Qué pasa si otro administrador recibe solo tu repositorio?** Con Terraform y Docker instalados ejecuta `./scripts/deploy.sh` y obtiene la misma infraestructura; el README y la guía le explican el resto. No necesita conocer los pasos manuales.
- **¿Por qué guardar el proyecto en Git?** Historial de cambios (quién, qué y cuándo), posibilidad de revertir, colaboración, respaldo y base para CI/CD. Se ignoran `.terraform/` y `*.tfstate` porque son locales y pueden contener datos sensibles.

## Autoevaluación (lista de cotejo)

- [ ] Inicializa Terraform correctamente (`init`)
- [ ] Utiliza `terraform validate`
- [ ] Utiliza `terraform plan`
- [ ] Explica el propósito de cada comando
- [ ] Implementa la infraestructura (`apply`)
- [ ] Ejecuta scripts (`verify.sh`, `deploy.sh`)
- [ ] Verifica los servicios (`curl`, `docker ps`, `ping`)
- [ ] Identifica errores
- [ ] Corrige errores
- [ ] Modifica la infraestructura
- [ ] Reconstruye la infraestructura
- [ ] Explica las ventajas de IaC
- [ ] Explica la relación entre DevOps y automatización

## Nota sobre el Dockerfile

El proyecto incluye `docker/Dockerfile` (nginx con una página personalizada), pero `main.tf` usa la imagen `nginx:alpine` directamente, así que no se utiliza. Si el docente lo pidiera, se puede construir con Terraform agregando al recurso `docker_image` un bloque `build { context = "../docker" }` y un nombre de imagen propio.
