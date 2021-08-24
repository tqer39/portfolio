variable "cidr_block" {}
variable "name" {}
variable "tags" {}

resource "aws_vpc" "portfolio" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  tags                 = var.tags
}