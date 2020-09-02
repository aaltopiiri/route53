output "public-zone-id" {
  value = aws_route53_zone.zone.zone_id
}

output "name-servers" {
  value = aws_route53_zone.zone.name_servers
}