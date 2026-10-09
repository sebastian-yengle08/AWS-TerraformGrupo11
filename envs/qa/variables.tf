variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Profile de AWS que uso para las credenciales"
  type        = string
  default     = "customprofile"
}

variable "environment" {
  description = "Entorno: dev, qa o prod"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "El valor de environment debe ser dev, qa o prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
}

variable "bucket_suffix" {
  description = "Sufijo para que el nombre del bucket sea único"
  type        = string
}

variable "nat_gateway_count" {
  description = "Cantidad de NAT Gateways (1 o 2), cobran por hora"
  type        = number
  default     = 2
}

variable "log_retention_days" {
  description = "Días que se guardan los logs"
  type        = number
  default     = 14
}

variable "throttle_rate_limit" {
  description = "Máximo de peticiones por segundo en la API"
  type        = number
}

variable "force_destroy" {
  description = "Permite que destroy borre el bucket aunque tenga objetos"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Correo que recibe la alerta de la DLQ"
  type        = string
}