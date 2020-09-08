output "public-zone-id" {
  value = aws_route53_zone.default.zone_id
}

output "name-servers" {
  value = aws_route53_zone.default.name_servers
}
