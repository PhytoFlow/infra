output "compute_sg_id" {
  value = aws_security_group.compute_security_group.id
}

output "compute_private_rt_id" {
  value = aws_route_table.compute_private.id
}

output "compute_vpc_cidr_block" {
  value = aws_vpc.compute_vpc.cidr_block
}

output "compute_vpc_id" {
  value = aws_vpc.compute_vpc.id
}
