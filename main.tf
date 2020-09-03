#variable "shared_credentials_file" {}


terraform {
  backend "s3" {
    bucket         = "aaltopiiri-terraform-bucket"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "aws-locks"
    encrypt        = true
  }
}

provider "aws" {
  #  shared_credentials_file = var.shared_credentials_file
  profile = var.profile
  region  = var.region
}
resource "aws_route53_zone" "zone" {
  name     = var.domain_name
  provider = aws
  #force_destroy = true
}

resource "aws_route53_delegation_set" "zone" {
  reference_name = "TerraformDNS"
}


data "aws_route53_zone" "zone" {
  zone_id = aws_route53_zone.zone.zone_id
  #private_zone = false
}


resource "aws_route53_record" "www-record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "www.${data.aws_route53_zone.zone.name}"
  type    = "A"
  ttl     = "300"
  records = ["10.32.15.27"]
}

resource "aws_route53_record" "mail1-record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${data.aws_route53_zone.zone.name}"
  type    = "MX"
  ttl     = "300"
  records = [
    "1 aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 aspmx2.googlemail.com.",
    "10 aspmx3.googlemail.com."
  ]
}
