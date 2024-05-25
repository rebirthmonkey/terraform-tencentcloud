output "vpc_id" {
  description = "The id of vpc."
  value       = var.vpc_id != "" ? var.vpc_id : concat(tencentcloud_vpc.vpc.*.id, [""])[0]
}

output "subnet_id" {
  description = "The id of subnet."
  value       = tencentcloud_subnet.subnet.*.id
}

output "az_to_subnets" {
  value = {
    for k, subnet in tencentcloud_subnet.subnet: subnet.availability_zone => subnet.id...
  }
}

output "route_table_id" {
  description = "The id of route table."
  value       = local.route_table_id
}

output "route_entry_id" {
  description = "The id of route table entry."
  value       = tencentcloud_route_table_entry.route_entry.*.id
}

