variable "project_name" {
  description = "Nombre base del proyecto para nombrar los recursos"
  type        = string
  default     = "asistencia"
}

variable "environment" {
  description = "Ambiente de despliegue (dev, qa, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Region de Azure donde se desplegaran los recursos"
  type        = string
  default     = "swedencentral"
}

variable "vm_size" {
  description = "Tamano de la maquina virtual. Standard_B2as_v2 (2 vCPU / 2 GB RAM) disponible sin restricciones para Azure Free Trial"
  type        = string
  default     = "Standard_B2as_v2"
}

variable "admin_username" {
  description = "Usuario administrador de la VM (para SSH)"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Contrasena del administrador de la VM (para SSH). Minimo 12 caracteres con mayusculas, numeros y simbolos."
  type        = string
  sensitive   = true
}

variable "node_version" {
  description = "Version de Node.js a instalar en la VM (LTS recomendado para compilar Vite)"
  type        = string
  default     = "20"
}

variable "vite_api_url" {
  description = "URL base del backend API con la que se compilara el frontend Vite (ej: http://51.12.93.59:3000/api/v1/)"
  type        = string
  default     = "http://localhost:3000/api/v1/"
}

variable "repo_url" {
  description = "URL del repositorio Git del frontend (para clonar en la VM si aplica)"
  type        = string
  default     = ""
}

variable "extra_tags" {
  description = "Etiquetas adicionales opcionales para los recursos"
  type        = map(string)
  default     = {}
}
