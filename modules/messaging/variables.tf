variable "name_prefix" {
  type        = string
  description = "Prefijo de nombres del entorno"
}

variable "bucket_id" {
  type        = string
  description = "Nombre (id) del bucket de imágenes sobre el que se crea la notificación"
}

variable "bucket_arn" {
  type        = string
  description = "ARN del bucket de imágenes, usado para autorizar a S3 a escribir en la cola"
}

variable "alarm_email" {
  type        = string
  description = "Correo que recibe las alertas cuando hay mensajes en la DLQ"
}