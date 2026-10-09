output "upload_lambda_name" {
  description = "Nombre de la funcion upload-lambda, consumido por el modulo api para aws_lambda_permission."
  value       = aws_lambda_function.upload.function_name
}

output "upload_lambda_invoke_arn" {
  description = "Invoke ARN de upload-lambda, consumido por el modulo api en aws_apigatewayv2_integration."
  value       = aws_lambda_function.upload.invoke_arn
}

output "crop_lambda_name" {
  description = "Nombre de la funcion crop-lambda, para referencia desde el entorno."
  value       = aws_lambda_function.crop.function_name
}