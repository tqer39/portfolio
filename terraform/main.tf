terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "tqer39"

    workspaces {
      name = "portfolio"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "virginia"
  region = var.region_virginia
}

locals {
  common_tags = {
    IaC           = var.IaC
    Environment   = var.Environment,
    Project       = "Portfolio",
    CostCenter    = var.CostCenter,
    Organizations = "tqer39"
    Workspace     = "portfolio"
  }
}

resource "aws_iam_user" "deploy" {
  name          = "deploy"
  path          = "/"
  force_destroy = true
}

resource "aws_iam_access_key" "deploy" {
  user    = aws_iam_user.deploy.name
  pgp_key = var.pgp_key
}

resource "aws_iam_group" "deploy" {
  name = "deploy"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "deploy" {
  group      = aws_iam_group.deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_group_membership" "deploy" {
  name = "deploy"
  users = [
    aws_iam_user.deploy.name,
  ]
  group = aws_iam_group.deploy.name
}

resource "aws_s3_bucket" "spa" {
  bucket        = "spa-373303485727"
  acl           = "public-read" # see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket#static-website-hosting
  force_destroy = true

  lifecycle_rule {
    enabled = false
  }

  website {
    index_document = "index.html"
    error_document = "error.html"

    routing_rules = <<EOF
[{
    "Condition": {
        "KeyPrefixEquals": "docs/"
    },
    "Redirect": {
        "ReplaceKeyPrefixWith": "documents/"
    }
}]
EOF
  }

  tags = merge(local.common_tags, {
    Name = "${var.prefix}"
  })
}

# see: https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/userguide/HostingWebsiteOnS3Setup.html#step3-add-bucket-policy-make-content-public
resource "aws_s3_bucket_policy" "spa" {
  bucket = aws_s3_bucket.spa.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "spa"
    Statement = [
      {
        Sid       = "spa"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.spa.id}/*"
        ]
      }
    ]
  })
}

resource "aws_acm_certificate" "portfolio" {
  provider                  = aws.virginia
  domain_name               = "${var.domains["portfolio"]}."
  subject_alternative_names = ["*.${var.domains["portfolio"]}"]
  validation_method         = "DNS"

  tags = merge(local.common_tags, {
    Name = "${var.prefix}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "portfolio_cname" {
  certificate_arn = aws_acm_certificate.portfolio.arn
  # validation_record_fqdns = [
  #   aws_route53_record.portfolio_cname.fqdn
  # ]
  validation_record_fqdns = [for record in aws_route53_record.portfolio_cname : record.fqdn]
}

resource "aws_route53_zone" "portfolio" {
  name          = var.domains["root"]
  force_destroy = true
}

resource "aws_route53_record" "portfolio_cname" {
  for_each = {
    for dvo in aws_acm_certificate.portfolio.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.portfolio.id
}

resource "aws_s3_bucket" "cloudfront_log" {
  bucket        = "cloudfront-log-373303485727"
  acl           = "private"
  force_destroy = true

  tags = merge({
    Name = "cloudfront_log"
  })

  lifecycle_rule {
    enabled = true
    expiration {
      days = "30"
    }
  }
}

resource "aws_cloudfront_distribution" "portfolio" {
  origin {
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    domain_name = var.domains["portfolio"]
    origin_id   = "Custom-${var.domains["portfolio"]}"

    custom_header {
      name  = "x-pre-shared-key"
      value = ""
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.portfolio.arn
    minimum_protocol_version       = "TLSv1.2_2019"
    ssl_support_method             = "sni-only"
  }

  // CNAME
  aliases = [
    aws_acm_certificate.portfolio.domain_name
  ]

  enabled         = true
  is_ipv6_enabled = false
  http_version    = "http2"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    default_ttl            = 86400
    max_ttl                = 31536000
    min_ttl                = 0
    smooth_streaming       = false
    target_origin_id       = "Custom-${var.domains["portfolio"]}"

    forwarded_values {
      headers = [
        "*"
      ]
      cookies {
        forward = "all"
      }
      query_string = true
    }
  }

  logging_config {
    include_cookies = false
    bucket          = "${aws_s3_bucket.cloudfront_log.bucket}.s3.amazonaws.com"
    prefix          = "log"
  }

  price_class      = "PriceClass_All"
  retain_on_delete = false

  restrictions {
    // GEO ロケーションでアクセス制御
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"]
    }
  }
}
