variable "network_name" {
  description = "Nombre de la red Docker"
  type        = string
  default     = "red-evaluacion"
}

variable "network_subnet" {
  description = "Segmento de red"
  type        = string
  default     = "10.20.0.0/24"
}

variable "web_container_name" {
  description = "Nombre del contenedor web"
  type        = string
  default     = "servidor-web"
}

variable "app_container_name" {
  description = "Nombre del contenedor de aplicaciones"
  type        = string
  default     = "servidor-app"
}

variable "web_port" {
  description = "Puerto publicado del servidor web"
  type        = number
  default     = 8080
}

variable "app_port" {
  description = "Puerto publicado del servidor de aplicaciones"
  type        = number
  default     = 8081
}

variable "web_ip" {
  description = "Dirección IP fija del servidor web"
  type        = string
  default     = "10.20.0.10"
}

variable "app_ip" {
  description = "Dirección IP fija del servidor de aplicaciones"
  type        = string
  default     = "10.20.0.20"
}
