output "api_url" {
  description = "URL base de API Gateway"
  value       = aws_apigatewayv2_stage.default.invoke_url
}
