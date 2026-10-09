output "api_url" {
  description = "URL base de la API"
  value       = module.api.api_url
}

output "bucket_name" {
  description = "Nombre del bucket de imágenes"
  value       = local.bucket_name
}

output "queue_url" {
  description = "URL de la cola principal"
  value       = module.messaging.queue_url
}

output "dlq_arn" {
  description = "ARN de la cola de errores"
  value       = module.messaging.dlq_arn
}

output "sns_topic_arn" {
  description = "ARN del tema SNS de alertas"
  value       = module.messaging.sns_topic_arn
}

output "vpc_id" {
  description = "Id de la VPC"
  value       = module.network.vpc_id
}

output "upload_lambda_name" {
  description = "Nombre de la Lambda de subida"
  value       = module.compute.upload_lambda_name
}

output "crop_lambda_name" {
  description = "Nombre de la Lambda de recorte"
  value       = module.compute.crop_lambda_name
}