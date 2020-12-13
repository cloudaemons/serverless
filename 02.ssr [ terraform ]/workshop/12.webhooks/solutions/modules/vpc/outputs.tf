output "sg_id" {
  description = "Security groups"
  value       = aws_security_group.sg.id
}

output "vpc_id" {
  description = "VPC id"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr" {
  description = "VPC cidr block"
  value       = var.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value = [
    aws_subnet.subnet_private_one.id,
    aws_subnet.subnet_private_two.id
  ]
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value = [
    aws_subnet.subnet_public_one.id,
    aws_subnet.subnet_public_two.id
  ]
}

output "nat_ips" {
  description = "NAT IPs"
  value = [
    "${aws_eip.nat_one.public_ip}/32",
    "${aws_eip.nat_two.public_ip}/32",
  ]
}

