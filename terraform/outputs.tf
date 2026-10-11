output "network_name" {
  description = "Nombre de la red creada"
  value       = docker_network.infra_network.name
}

output "web_container" {
  description = "Nombre del servidor web"
  value       = docker_container.web.name
}

output "app_container" {
  description = "Nombre del servidor de aplicaciones"
  value       = docker_container.app.name
}

output "web_url" {
  description = "URL del servidor web"
  value       = "http://localhost:${var.web_port}"
}

output "app_url" {
  description = "URL del servidor de aplicaciones"
  value       = "http://localhost:${var.app_port}"
}
