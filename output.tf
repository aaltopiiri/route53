output "public-zone-id" {
  value = aws_route53_zone.primary.zone_id
}

output "name-servers" {
  value = aws_route53_zone.primary.name_servers
}

output "domain-name" {
  value = aws_route53_zone.primary.name
}