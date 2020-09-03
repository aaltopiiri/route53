variable "dns_record_set" {
  description = "dns records"
  type = map(object({
    alias = object({
      evaluate_target_health = bool
      target = string
      target_zone = string
    })
    record_type = string
    records = object({
      record_set = set(string)
      ttl = number
    })
  }))
}