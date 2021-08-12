terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
  }

  backend "remote" {
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

resource "aws_vpc" "portfolio" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = merge(local.common_tags,
    {
      Name = "${var.prefix}"
    }
  )
}

resource "aws_subnet" "portfolio_autoscaling_private_1" {
  vpc_id                  = aws_vpc.portfolio.id
  cidr_block              = cidrsubnet(aws_vpc.portfolio.cidr_block, 8, 0)
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags,
    {
      Name = "${var.prefix}_autoscaling_private_1"
      Type = "private"
    }
  )
}
