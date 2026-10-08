resource "aws_security_group" "upload" {
  name        = "${var.name_prefix}-sg-upload-lambda"
  description = "upload-lambda: sin inbound; outbound 443 hacia los endpoints"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.name_prefix}-sg-upload-lambda" }
}

resource "aws_security_group" "crop" {
  name        = "${var.name_prefix}-sg-crop-lambda"
  description = "crop-lambda: sin inbound; outbound 443 hacia los endpoints"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.name_prefix}-sg-crop-lambda" }
}

resource "aws_security_group" "vpce_sqs" {
  name        = "${var.name_prefix}-sg-vpce-sqs"
  description = "Endpoint de SQS: acepta 443 solo desde las Lambdas"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.name_prefix}-sg-vpce-sqs" }
}

locals {
  lambda_sgs = {
    upload = aws_security_group.upload.id
    crop   = aws_security_group.crop.id
  }
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_s3" {
  for_each          = local.lambda_sgs
  security_group_id = each.value
  prefix_list_id    = aws_vpc_endpoint.s3.prefix_list_id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS hacia el S3 Gateway Endpoint"
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_sqs" {
  for_each                     = local.lambda_sgs
  security_group_id            = each.value
  referenced_security_group_id = aws_security_group.vpce_sqs.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "HTTPS hacia el SQS Interface Endpoint"
}

resource "aws_vpc_security_group_ingress_rule" "sqs_from_lambda" {
  for_each                     = local.lambda_sgs
  security_group_id            = aws_security_group.vpce_sqs.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "HTTPS desde las Lambdas"
}