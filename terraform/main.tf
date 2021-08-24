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

module "vpc_portfolio" {
  source          = "terraform-aws-modules/vpc/aws"
  version         = "3.3.0"
  cidr            = var.address_space
  name            = var.prefix
  enable_ipv6     = false
  azs             = ["${var.region}a", "${var.region}c"]
  private_subnets = [cidrsubnet(var.address_space, 8, 1), cidrsubnet(var.address_space, 8, 2)]
  # public_subnets  = [cidrsubnet(var.address_space, 8, 255), cidrsubnet(var.address_space, 8, 256)]

  # public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = merge(local.common_tags, {
    Name = "${var.prefix}"
  })
}

# resource "aws_subnet" "portfolio_autoscaling_private_1" {
#   vpc_id                  = module.vpc_portfolio.id
#   cidr_block              = cidrsubnet(module.vpc_portfolio.cidr_block, 8, 0)
#   availability_zone       = var.availability_zones[0]
#   map_public_ip_on_launch = true

#   tags = merge(local.common_tags,
#     {
#       Name = "${var.prefix}_autoscaling_private_1"
#       Type = "private"
#     }
#   )
# }

# resource "aws_subnet" "portfolio_autoscaling_private_2" {
#   vpc_id                  = module.vpc_portfolio.id
#   cidr_block              = cidrsubnet(module.vpc_portfolio.cidr_block, 8, 1)
#   availability_zone       = var.availability_zones[1]
#   map_public_ip_on_launch = true

#   tags = merge(local.common_tags,
#     {
#       Name = "${var.prefix}_autoscaling_private_2"
#       Type = "private"
#     }
#   )
# }
