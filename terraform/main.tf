terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
}

# ---------------------------------------------------------------
# Red Docker (10.20.0.0/24)
# ---------------------------------------------------------------
resource "docker_network" "infra_network" {

  name = var.network_name

  ipam_config {
    subnet = var.network_subnet
  }
}

# ---------------------------------------------------------------
# Servidor web (10.20.0.10, puerto 8080)
# ---------------------------------------------------------------
resource "docker_image" "web_image" {
  name         = "nginx:alpine"
  keep_locally = true
}

resource "docker_container" "web" {

  name  = var.web_container_name
  image = docker_image.web_image.image_id

  ports {
    internal = 80
    external = var.web_port
  }

  networks_advanced {
    name         = docker_network.infra_network.name
    aliases      = ["web"]
    ipv4_address = var.web_ip # COMPLETADO: dirección IP fija
  }
}

# ---------------------------------------------------------------
# Servidor de aplicaciones (10.20.0.20, puerto 8081)
# ---------------------------------------------------------------
resource "docker_image" "app_image" {
  name         = "nginx:alpine"
  keep_locally = true
}

resource "docker_container" "app" {

  name  = var.app_container_name
  image = docker_image.app_image.image_id

  ports {
    internal = 80

    # CORREGIDO: el error intencional era "external = 8082".
    # El puerto debe salir de la variable app_port (8081).
    external = var.app_port
  }

  networks_advanced {
    name         = docker_network.infra_network.name
    aliases      = ["app"]
    ipv4_address = var.app_ip # COMPLETADO: dirección IP fija
  }
}
