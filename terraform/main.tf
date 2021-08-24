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
