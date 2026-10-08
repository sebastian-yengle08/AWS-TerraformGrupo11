
variable "name_prefix" {
  description = "Prefijo para nombrar los recursos del entorno"
  type        = string
}

variable "upload_lambda_name" {
  description = "Nombre de la funcion Lambda Upload"
  type        = string
}

variable "upload_lambda_invoke_arn" {
  description = "ARN de invocacion de Lambda Upload"
  type        = string
}

variable "log_retention_days" {
  description = "Dias de retencion de logs en CloudWatch"
  type        = number
}

variable "throttle_rate_limit" {
  description = "Limite de solicitudes por segundo"
  type        = number
}
