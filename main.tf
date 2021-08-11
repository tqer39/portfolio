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
      Name = "${var.prefix}-vpc"
    }
  )
}
