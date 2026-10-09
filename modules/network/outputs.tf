output "vpc_id" {
  value = aws_vpc.this.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "sg_upload_id" {
  value = aws_security_group.upload.id
}

output "sg_crop_id" {
  value = aws_security_group.crop.id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.this[*].id
}