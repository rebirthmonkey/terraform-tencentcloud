data "tencentcloud_instance_types" "default" {
  cpu_core_count   = var.cpu_core_count
  gpu_core_count   = var.gpu_core_count
  memory_size      = var.memory_size
  exclude_sold_out = true
}

data "tencentcloud_vpc_route_tables" "default" {
  vpc_id           = var.vpc_id
  association_main = true
}

locals {
  create_vpc         = var.create_vpc
  custom_route_table = var.create_route_table == false || local.create_vpc ? false : length(var.destination_cidrs) > 0
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : sort(distinct(data.tencentcloud_instance_types.default.instance_types.*.availability_zone))
  route_table_id = var.route_table_id != "" ? var.route_table_id : local.custom_route_table ? tencentcloud_route_table.route_table[0].id : local.create_vpc ? tencentcloud_vpc.vpc[0].default_route_table_id : try(
    data.tencentcloud_vpc_route_tables.default.instance_list[0].route_table_id,
    null
  )
}

resource "tencentcloud_vpc" "vpc" {
  count        = local.create_vpc ? 1 : 0
  name         = var.vpc_name
  cidr_block   = var.vpc_cidr
  is_multicast = var.vpc_is_multicast
  dns_servers  = length(var.vpc_dns_servers) > 0 ? var.vpc_dns_servers : null
  tags         = merge(var.tags, var.vpc_tags)
}

resource "tencentcloud_route_table" "route_table" {
  count  = local.custom_route_table ? 1 : 0
  name   = "${var.subnet_name}-route"
  vpc_id = var.vpc_id != "" ? var.vpc_id : tencentcloud_vpc.vpc[0].id
  tags = merge(
    var.tags,
    var.route_table_tags
  )
}

resource "tencentcloud_subnet" "subnet" {
  count             = length(var.subnet_cidrs)
  name              = length(var.subnet_cidrs) < 2 ? var.subnet_name : format("%s_%s", var.subnet_name, format(var.number_format, count.index + 1))
  vpc_id            = var.vpc_id != "" ? var.vpc_id : tencentcloud_vpc.vpc[0].id
  cidr_block        = var.subnet_cidrs[count.index]
  is_multicast      = var.subnet_is_multicast
  availability_zone = local.availability_zones[count.index % length(local.availability_zones)]
  route_table_id    = local.route_table_id
  tags              = merge(var.tags, var.subnet_tags)
}

resource "tencentcloud_route_table_entry" "route_entry" {
  count                  = length(var.destination_cidrs)
  route_table_id         = local.route_table_id
  destination_cidr_block = var.destination_cidrs[count.index]
  next_type              = var.next_type[count.index]
  next_hub               = var.next_type[count.index] == "NAT" && var.enable_nat_gateway && var.next_hub[count.index] == "0" ? tencentcloud_nat_gateway.nat[0].id : var.next_type[count.index] == "VPN" && var.enable_vpn_gateway && var.next_hub[count.index] == "0" ? tencentcloud_vpn_gateway.vpn[0].id : var.next_hub[count.index]
  lifecycle {
    ignore_changes = [
      disabled  // we do not control this toggle here because it will auto managed by other products such as CFW
    ]
  }
}
