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

resource "aws_s3_bucket" "spa" {
  bucket        = "spa-373303485727"
  acl           = "public-read" # see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket#static-website-hosting
  force_destroy = true

  lifecycle_rule {
    enabled = false
  }

  tags = merge(local.common_tags, {
    Name = "${var.prefix}"
  })
}

data "bucket_policy_document" "spa_policy" {
  statement {
    sid    = "spa"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.spa.id}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["582318560864"] // 東京リージョンはこの AWS Account ID を指定
    }
  }
}

resource "aws_s3_bucket_policy" "spa" {
  bucket = aws_s3_bucket.spa.id
  policy = data.bucket_policy_document.spa_policy.json
}
