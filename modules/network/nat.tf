resource "aws_eip" "nat" {
  count  = var.nat_gateway_count
  domain = "vpc"

  tags = { Name = "${var.name_prefix}-eip-nat-${local.az_suffix[count.index]}" }
}

resource "aws_nat_gateway" "this" {
  count         = var.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = { Name = "${var.name_prefix}-nat-${local.az_suffix[count.index]}" }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[min(count.index, var.nat_gateway_count - 1)].id
  }

  tags = { Name = "${var.name_prefix}-rt-private-${local.az_suffix[count.index]}" }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}