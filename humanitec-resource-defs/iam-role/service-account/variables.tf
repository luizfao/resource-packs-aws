variable "humanitec_organization" {
  type = string
}

variable "prefix" {
  type = string
}

variable "resource_packs_aws_rev" {
  type = string
}


variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "region" {
  type = string
}

variable "oidc_provider" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "policy_classes" {
  type = list(string)
}