variable "region" {
  description = "The AWS region where resources will be deployed"
  type        = string
  default     = "eu-central-1"
}

variable "profile" {
  description = "The name of the AWS CLI profile to use for authentication and credentials"
  type        = string
}
