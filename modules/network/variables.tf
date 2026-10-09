variable "name_prefix" {
  description = "Prefijo de nombres"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "bucket_name" {
  description = "Nombre del bucket de imágenes"
  type        = string
}

variable "nat_gateway_count" {
  description = "Número de NAT Gateways"
  type        = number
  default     = 2

  validation {
    condition     = contains([1, 2], var.nat_gateway_count)
    error_message = "nat_gateway_count debe ser 1 o 2."
  }
}