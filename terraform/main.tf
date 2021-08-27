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

resource "aws_iam_user" "terraform" {
  name          = "terraform"
  path          = "/"
  force_destroy = true
}

resource "aws_iam_access_key" "deploy" {
  user    = aws_iam_user.deploy.name
  pgp_key = var.pgp_key
}

resource "aws_iam_access_key" "terraform" {
  user    = aws_iam_user.terraform.name
  pgp_key = var.pgp_key
}

resource "aws_iam_group" "deploy" {
  name = "deploy"
  path = "/"
}

resource "aws_iam_group" "terraform" {
  name = "terraform"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "deploy" {
  group      = aws_iam_group.deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_group_policy_attachment" "terraform" {
  group      = aws_iam_group.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_membership" "deploy" {
  name = "deploy"
  users = [
    aws_iam_user.deploy.name,
  ]
  group = aws_iam_group.deploy.name
}

resource "aws_iam_group_membership" "terraform" {
  name = "terraform"
  users = [
    aws_iam_user.terraform.name,
  ]
  group = aws_iam_group.terraform.name
}

resource "aws_s3_bucket" "spa" {
  bucket        = "spa-373303485727"
  acl           = "private" # see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket#static-website-hosting
  force_destroy = true

  lifecycle_rule {
    enabled = false
    expiration {
      expired_object_delete_marker = false
    }
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
  versioning {
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name = "spa-373303485727"
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
        Sid    = "spa"
        Effect = "Allow"
        Principal = {
          "AWS" = ["${aws_cloudfront_origin_access_identity.portfolio.iam_arn}"]
        }
        Action = ["s3:GetObject"]
        Resource = [
          "${aws_s3_bucket.spa.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_acm_certificate" "portfolio" {
  provider                  = aws.virginia
  domain_name               = var.domains["portfolio"]
  subject_alternative_names = []
  validation_method         = "DNS"

  tags = merge(local.common_tags, {
    Name = "${var.prefix}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "portfolio" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.portfolio.arn
  validation_record_fqdns = [for record in aws_route53_record.portfolio : record.fqdn]

  depends_on = [
    aws_route53_record.portfolio
  ]
}

resource "aws_route53_zone" "portfolio" {
  name          = var.domains["root"]
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = "${var.prefix}"
  })
}

resource "aws_route53_record" "portfolio" {
  for_each = {
    for dvo in aws_acm_certificate.portfolio.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = aws_route53_zone.portfolio.id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.portfolio.id
}

resource "aws_route53_record" "portfolio_A" {
  zone_id = aws_route53_zone.portfolio.id
  name    = var.domains["portfolio"]
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.portfolio.domain_name
    zone_id                = aws_cloudfront_distribution.portfolio.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_s3_bucket" "cloudfront_log" {
  bucket        = "cloudfront-log-373303485727"
  acl           = "private"
  force_destroy = true

  lifecycle_rule {
    id      = "廃棄"
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days                         = 90
      expired_object_delete_marker = true
    }
  }

  versioning {
    enabled = true
  }

  tags = merge({
    Name = "cloudfront_log"
  })
}

resource "aws_cloudfront_origin_access_identity" "portfolio" {
  comment = "This is the cloudfront origin access identity for the portfolio."
}

resource "aws_cloudfront_distribution" "portfolio" {
  origin {
    domain_name = aws_s3_bucket.spa.bucket_regional_domain_name
    origin_id   = var.prefix

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.portfolio.cloudfront_access_identity_path
    }
  }

  enabled          = true
  http_version     = "http2"
  is_ipv6_enabled  = false
  price_class      = "PriceClass_All"
  retain_on_delete = false

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.portfolio.arn
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

  // CNAME
  aliases = [
    aws_acm_certificate.portfolio.domain_name
  ]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = var.prefix

    forwarded_values {
      query_string = false
      headers      = []

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  logging_config {
    include_cookies = false
    bucket          = "${aws_s3_bucket.cloudfront_log.bucket}.s3.amazonaws.com"
    prefix          = "log"
  }

  restrictions {
    // GEO ロケーションでアクセス制御
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"]
    }
  }
}

resource "aws_iam_user" "function" {
  name          = "function"
  path          = "/"
  force_destroy = true
}

resource "aws_iam_group" "function" {
  name = "function"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "function_AWSLambdaBasicExecutionRole" {
  group      = aws_iam_group.function.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_group_policy_attachment" "function_AWSXRayDaemonWriteAccess" {
  group      = aws_iam_group.function.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_group_membership" "function" {
  name = "function"
  users = [
    aws_iam_user.function.name,
  ]
  group = aws_iam_group.function.name
}

# resource "aws_api_gateway_rest_api" "portfolio" {
#   name        = "portfolio"
#   description = "example serverless api"
#   policy = jsonencode(statement {
#     effect = "Allow"
#     principals = {
#       type = "*"
#       identifiers = [
#       "*"]
#     }
#     actions = [
#       "execute-api:Invoke"
#     ]
#     resources = [
#       "arn:aws:execute-api:ap-northeast-1:*:*/*/*"
#     ]
#   })
# }
