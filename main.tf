/* terraform {
  backend "s3" {
    bucket         = "aaltopiiri-terraform-bucket"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    profile        = "terraform"
    dynamodb_table = "aws-locks"
    encrypt        = true
  }
} */

resource "aws_route53_health_check" "health_check_us" {
  fqdn              = "example.com"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "tf-us-health-check"
  }
}

resource "aws_route53_health_check" "health_check_eu" {
  fqdn              = "example.com"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "tf-eu-health-check"
  }
}

resource "aws_route53_health_check" "health_check_ap" {
  fqdn              = "example.com"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "tf-ap-health-check"
  }
}

provider "aws" {
  shared_credentials_file = var.shared_credentials_file
  profile                 = var.profile
  region                  = var.region
}


resource "aws_route53_delegation_set" "main" {
  reference_name = "TerraformDNS"
}

resource "aws_route53_zone" "primary" {
  name              = var.domain_name
  delegation_set_id = aws_route53_delegation_set.main.id
}

/*
module "acm_request_certificate" {
  source                            = "git::https://github.com/cloudposse/terraform-aws-acm-request-certificate.git?ref=tags/0.7.0"
  domain_name                       = "${var.domain_name}"
  process_domain_validation_options = true
  ttl                               = "300"
  subject_alternative_names         = ["*.${var.domain_name}"]
}
*/

//Region us-east-1 (North Virginia)  
//Latency Policy

resource "aws_route53_record" "a-latency-us-east-1" {
  zone_id        = aws_route53_zone.primary.zone_id
  name           = "${var.domain_name}"
  type           = "A"
  set_identifier = "cdp-tds-us-east-1-a"
  latency_routing_policy {
    region = "us-east-1"
  }
  alias {
    name                   = "cdp-tds-alb-4d-930437359.us-east-1.elb.amazonaws.com."
    zone_id                = "${var.elb_us_zone_id}"
    evaluate_target_health = false
  }
}


/*   module "acm_request_certificate" {
  source                            = "git::https://github.com/cloudposse/terraform-aws-acm-request-certificate.git?ref=tags/0.7.0"
  domain_name                       = "${data.aws_route53_zone.default.name}"
  process_domain_validation_options = true
  ttl                               = "300"
  subject_alternative_names         = ["*.${data.aws_route53_zone.default.name}"]
}   */

resource "aws_route53_record" "aaaa-latency-us-east-1" {
  zone_id        = aws_route53_zone.primary.zone_id
  name           = "${var.domain_name}"
  type           = "AAAA"
  set_identifier = "cdp-tds-us-east-1-aaaa"
  latency_routing_policy {
    region = "us-east-1"
  }
  alias {
    name                   = "cdp-tds-alb-4d-930437359.us-east-1.elb.amazonaws.com."
    zone_id                = "${var.elb_us_zone_id}"
    evaluate_target_health = false
  }
}

//Region eu-west-1 (Dublin) 
//Failover Policy

resource "aws_route53_record" "a-failover-primary-eu-west-1" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "eu-west-1.${var.domain_name}"
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "eu-west-1-primary-a"
  alias {
    name                   = "cdp-tds-eu-west-alb-4d-429299911.eu-west-1.elb.amazonaws.com."
    zone_id                = "${var.elb_eu_zone_id}"
    evaluate_target_health = true
  }

}

resource "aws_route53_record" "a-failover-secondary-eu-west-1" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "eu-west-1.${var.domain_name}"
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "eu-west-1-secondary-a"
  alias {
    name                   = "cdp-tds-alb-4d-930437359.us-east-1.elb.amazonaws.com."
    zone_id                = "${var.elb_us_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "aaaa-failover-primary-eu-west-1" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "eu-west-1.${var.domain_name}"
  type    = "AAAA"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "eu-west-1-primary-aaaa"
  alias {
    name                   = "cdp-tds-eu-west-alb-4d-429299911.eu-west-1.elb.amazonaws.com."
    zone_id                = "${var.elb_eu_zone_id}"
    evaluate_target_health = true
  }

}

resource "aws_route53_record" "aaaa-failover-secondary-eu-west-1" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "eu-west-1.${var.domain_name}"
  type    = "AAAA"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "eu-west-1-secondary-aaaa"
  alias {
    name                   = "cdp-tds-alb-4d-930437359.us-east-1.elb.amazonaws.com."
    zone_id                = "${var.elb_us_zone_id}"
    evaluate_target_health = true
  }
}

//Latency Policy eu-west-1

resource "aws_route53_record" "a-latency-eu-west-1" {
  zone_id        = aws_route53_zone.primary.zone_id
  name           = "${var.domain_name}"
  type           = "A"
  set_identifier = "cdp-tds-eu-west-1-a"
  latency_routing_policy {
    region = "eu-west-1"
  }
  alias {
    name                   = "eu-west-1.${var.domain_name}."
    zone_id                = aws_route53_zone.primary.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "aaaa-latency-eu-west-1" {
  zone_id        = aws_route53_zone.primary.zone_id
  name           = "${var.domain_name}"
  type           = "AAAA"
  set_identifier = "cdp-tds-eu-west-1-aaaa"
  latency_routing_policy {
    region = "eu-west-1"
  }
  alias {
    name                   = "eu-west-1.${var.domain_name}."
    zone_id                = aws_route53_zone.primary.zone_id
    evaluate_target_health = false
  }
}

//Region ap-south-1 (Mumbai) 

resource "aws_route53_record" "a-failover-primary-ap-south-1" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "ap-south-1.${var.domain_name}"
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "ap-south-1-primary-a"
  alias {
    name                   = "cdp-tds-ap-south-alb-4d-1293711515.ap-south-1.elb.amazonaws.com."
    zone_id                = "${var.elb_ap_zone_id}"
    evaluate_target_health = true
  }

}

resource "aws_route53_record" "a-failover-secondary-ap-south-1" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "ap-south-1.${var.domain_name}"
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "ap-south-1-secondary-a"
  alias {
    name                   = "cdp-tds-alb-4d-930437359.us-east-1.elb.amazonaws.com."
    zone_id                = "${var.elb_us_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "aaaa-failover-primary-ap-south-1" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "ap-south-1.${var.domain_name}"
  type    = "AAAA"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "ap-south-1-primary-aaaa"
  alias {
    name                   = "cdp-tds-ap-south-alb-4d-1293711515.ap-south-1.elb.amazonaws.com."
    zone_id                = "${var.elb_ap_zone_id}"
    evaluate_target_health = true
  }

}

resource "aws_route53_record" "aaaa-failover-secondary-ap-south-1" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "ap-south-1.${var.domain_name}"
  type    = "AAAA"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "ap-south-1-secondary-aaaa"
  alias {
    name                   = "cdp-tds-alb-4d-930437359.us-east-1.elb.amazonaws.com."
    zone_id                = "${var.elb_us_zone_id}"
    evaluate_target_health = true
  }
}

//Latency Policy ap-south-1

resource "aws_route53_record" "a-latency-ap-south-1" {
  zone_id        = aws_route53_zone.primary.zone_id
  name           = "${var.domain_name}"
  type           = "A"
  set_identifier = "cdp-tds-ap-south-1-a"
  latency_routing_policy {
    region = "ap-south-1"
  }
  alias {
    name                   = "ap-south-1.${var.domain_name}."
    zone_id                = aws_route53_zone.primary.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "aaaa-latency-ap-south-1" {
  zone_id        = aws_route53_zone.primary.zone_id
  name           = "${var.domain_name}"
  type           = "AAAA"
  set_identifier = "cdp-tds-ap-south-1-aaaa"
  latency_routing_policy {
    region = "ap-south-1"
  }
  alias {
    name                   = "ap-south-1.${var.domain_name}."
    zone_id                = aws_route53_zone.primary.zone_id
    evaluate_target_health = false
  }
}

/*
resource "aws_route53_record" "AAAA-record-ap-south-1" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${data.aws_route53_zone.selected.name}"
  type    = "AAAA"
  //ttl     = "300"
  set_identifier = "ap-south-1.${data.aws_route53_zone.selected.name}"
  latency_routing_policy {
  region = "ap-south-1"
  }
  alias {
    name                   = "ap-south-1.${data.aws_route53_zone.selected.name}."
    zone_id                = data.aws_route53_zone.selected.zone_id
    evaluate_target_health = false
  }
}

 
resource "aws_route53_record" "mx-record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${data.aws_route53_zone.selected.name}"
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



resource "aws_route53_zone" "zone" {
  name     = var.domain_name
  provider = aws
  //force_destroy = true
}


resource "aws_route53_delegation_set" "zone-delegation" {
  reference_name = "DNSTerraform"
}



data "aws_route53_zone" "default" {
  //zone_id = aws_route53_zone.default.zone_id
  name = aws_route53_zone.default.name
  //private_zone = false
}


*/
