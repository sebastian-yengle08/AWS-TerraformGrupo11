data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "upload" {
  name               = "${var.name_prefix}-upload-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "upload_basic" {
  role       = aws_iam_role.upload.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "upload_vpc" {
  role       = aws_iam_role.upload.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "upload_s3" {
  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${var.bucket_arn}/uploads/*"
    ]
  }
}

resource "aws_iam_role_policy" "upload_s3" {
  name   = "${var.name_prefix}-upload-s3-policy"
  role   = aws_iam_role.upload.id
  policy = data.aws_iam_policy_document.upload_s3.json
}

resource "aws_iam_role" "crop" {
  name               = "${var.name_prefix}-crop-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "crop_basic" {
  role       = aws_iam_role.crop.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "crop_vpc" {
  role       = aws_iam_role.crop.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "crop_access" {
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${var.bucket_arn}/uploads/*"
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${var.bucket_arn}/processed/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [
      var.queue_arn
    ]
  }
}

resource "aws_iam_role_policy" "crop_access" {
  name   = "${var.name_prefix}-crop-policy"
  role   = aws_iam_role.crop.id
  policy = data.aws_iam_policy_document.crop_access.json
}