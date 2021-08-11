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
}

variable "address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = "10.0.0.0/16"
}