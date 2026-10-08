variable "name_prefix" {
  description = "Prefijo compartido para nombres de recursos (ej. image-processor-dev)."
  type        = string
}

variable "bucket_name" {
  description = "Nombre del bucket S3 que reciben las Lambdas como variable de entorno S3_BUCKET."
  type        = string
}

variable "bucket_arn" {
  description = "ARN del bucket S3, usado para construir las policies IAM de las Lambdas."
  type        = string
}

variable "queue_arn" {
  description = "ARN de la cola SQS principal, consumida por crop-lambda vía Event Source Mapping."
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las dos subredes privadas donde corren las Lambdas."
  type        = list(string)
}

variable "sg_upload_id" {
  description = "Security group ID para upload-lambda."
  type        = string
}

variable "sg_crop_id" {
  description = "Security group ID para crop-lambda."
  type        = string
}

variable "log_retention_days" {
  description = "Dias de retencion de los CloudWatch log groups de ambas Lambdas."
  type        = number
}

variable "max_upload_mb" {
  description = "Tamano maximo permitido para la imagen de subida en MB. Se pasa a upload-lambda como MAX_UPLOAD_MB."
  type        = number
  default     = 4
}