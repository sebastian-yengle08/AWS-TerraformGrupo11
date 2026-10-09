output "bucket_id" {
  description = "Id (nombre) del bucket S3 de imágenes"
  value       = aws_s3_bucket.images.id
}

output "bucket_arn" {
  description = "ARN del bucket S3 de imágenes"
  value       = aws_s3_bucket.images.arn
}