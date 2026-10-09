resource "aws_cloudwatch_log_group" "upload" {
  name              = "/aws/lambda/${var.name_prefix}-upload"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "crop" {
  name              = "/aws/lambda/${var.name_prefix}-crop"
  retention_in_days = var.log_retention_days
}

data "archive_file" "upload" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/upload-lambda"
  output_path = "${path.root}/upload-lambda.zip"
}

data "archive_file" "crop" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/crop-lambda"
  output_path = "${path.root}/crop-lambda.zip"
}

resource "aws_lambda_function" "upload" {
  function_name    = "${var.name_prefix}-upload"
  role             = aws_iam_role.upload.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  architectures    = ["x86_64"]
  memory_size      = 256
  timeout          = 30
  filename         = data.archive_file.upload.output_path
  source_code_hash = data.archive_file.upload.output_base64sha256

  environment {
    variables = {
      S3_BUCKET     = var.bucket_name
      UPLOAD_PREFIX = "uploads/"
      MAX_UPLOAD_MB = tostring(var.max_upload_mb)
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_upload_id]
  }

  depends_on = [aws_cloudwatch_log_group.upload]
}

resource "aws_lambda_function" "crop" {
  function_name    = "${var.name_prefix}-crop"
  role             = aws_iam_role.crop.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  architectures    = ["x86_64"]
  memory_size      = 512
  timeout          = 60
  filename         = data.archive_file.crop.output_path
  source_code_hash = data.archive_file.crop.output_base64sha256

  environment {
    variables = {
      S3_BUCKET        = var.bucket_name
      PROCESSED_PREFIX = "processed/"
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_crop_id]
  }

  depends_on = [aws_cloudwatch_log_group.crop]
}

resource "aws_lambda_event_source_mapping" "crop" {
  event_source_arn        = var.queue_arn
  function_name           = aws_lambda_function.crop.arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"]
}