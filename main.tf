terraform {
  backend "s3" {
    bucket         = "aaltopiiri-terraform-bucket"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    profile        = "terraform"
    dynamodb_table = "aws-locks"
    encrypt        = true
  }
}

provider "aws" {
  shared_credentials_file = var.shared_credentials_file
  profile                 = var.profile
  region                  = var.region
}

resource "aws_route53_zone" "default" {
  name     = var.domain_name
  provider = aws
  #force_destroy = true
}

resource "aws_route53_delegation_set" "default" {
  reference_name = "Terraform DNS"
}


data "aws_route53_zone" "default" {
  zone_id = aws_route53_zone.default.zone_id
  #private_zone = false
}

  resource "aws_route53_record" "A-record" {
  zone_id = data.aws_route53_zone.default.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = "300"
  records = ["10.10.10.10"]

}


  module "acm_request_certificate" {
  source                            = "git::https://github.com/cloudposse/terraform-aws-acm-request-certificate.git?ref=tags/0.7.0"
  domain_name                       = "${data.aws_route53_zone.default.name}"
  process_domain_validation_options = true
  ttl                               = "300"
  subject_alternative_names         = ["*.${data.aws_route53_zone.default.name}"]
}  



 