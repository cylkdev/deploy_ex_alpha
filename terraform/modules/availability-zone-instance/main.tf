data "aws_availability_zones" "available" {
  count = var.enable_availability_zones ? 1 : 0
  
  state                   = "available"
  all_availability_zones  = var.all_availability_zones
  exclude_names           = var.exclude_names
  exclude_zone_ids        = var.exclude_zone_ids

  filter {
    name   = "region-name"
    values = [var.region]
  }

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

resource "random_shuffle" "availability_zone_names" {
  input        = data.aws_availability_zones.available[0].names
  result_count = var.availability_zone_count
}