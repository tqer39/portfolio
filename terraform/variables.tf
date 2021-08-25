##############################################################################
# Variables File
#
# Here is where we store the default values for all the variables used in our
# Terraform code. If you create a variable with no default, the user will be
# prompted to enter it (or define it via config file or command line flags.)

variable "Environment" {
  type    = string
  default = "dev"
}

variable "Project" {
  type    = string
  default = "project"
}

variable "IaC" {
  type    = string
  default = "Terraform"
}

variable "CostCenter" {
  type    = string
  default = "dev"
}

variable "TFC_WORKSPACE_NAME" {
  type    = string
  default = "ws"
}

variable "prefix" {
  description = "This prefix will be included in the name of most resources."
  default     = "portfolio"
}

variable "region" {
  description = "The region where the resources are created."
  default     = "ap-northeast-1"
  type        = string
}

variable "region_virginia" {
  description = "The region where the resources are created."
  default     = "us-east-1"
  type        = string
}

variable "address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones"
  default = [
    "ap-northeast-1a",
    "ap-northeast-1c",
    "ap-northeast-1d",
  ]
}

variable "pgp_key" {
  type        = string
  description = "gpg key"
  default     = "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"
}