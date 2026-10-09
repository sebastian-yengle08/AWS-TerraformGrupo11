locals {
  name_prefix = "image-processor-${var.environment}"
  bucket_name = "${local.name_prefix}-images-${var.bucket_suffix}"
}

module "network" {
  source            = "../../modules/network"
  name_prefix       = local.name_prefix
  vpc_cidr          = var.vpc_cidr
  bucket_name       = local.bucket_name
  nat_gateway_count = var.nat_gateway_count
}

module "storage" {
  source        = "../../modules/storage"
  bucket_name   = local.bucket_name
  force_destroy = var.force_destroy
}

module "messaging" {
  source      = "../../modules/messaging"
  name_prefix = local.name_prefix
  bucket_id   = module.storage.bucket_id
  bucket_arn  = module.storage.bucket_arn
  alarm_email = var.alarm_email
}

module "compute" {
  source             = "../../modules/compute"
  name_prefix        = local.name_prefix
  bucket_name        = local.bucket_name
  bucket_arn         = module.storage.bucket_arn
  queue_arn          = module.messaging.queue_arn
  private_subnet_ids = module.network.private_subnet_ids
  sg_upload_id       = module.network.sg_upload_id
  sg_crop_id         = module.network.sg_crop_id
  log_retention_days = var.log_retention_days
}

module "api" {
  source                   = "../../modules/api"
  name_prefix              = local.name_prefix
  upload_lambda_name       = module.compute.upload_lambda_name
  upload_lambda_invoke_arn = module.compute.upload_lambda_invoke_arn
  log_retention_days       = var.log_retention_days
  throttle_rate_limit      = var.throttle_rate_limit
}