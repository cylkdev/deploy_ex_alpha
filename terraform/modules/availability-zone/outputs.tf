output "availability_zones_available" {
  value = data.aws_availability_zones.available[0]
}

output "availability_zone_names" {
  value = (
    var.randomize_availability_zones ?
    slice(data.aws_availability_zones.available[0].names, 0, var.availability_zone_count) :
    random_shuffle.availability_zone_names.result
  )
}

