variable "bucket_name" {
  description = "Nombre global único del bucket S3 que guarda las imágenes originales y las recortadas"
  type        = string
}

variable "force_destroy" {
  description = "Si es true, terraform destroy puede borrar el bucket aunque tenga objetos y versiones"
  type        = bool
}