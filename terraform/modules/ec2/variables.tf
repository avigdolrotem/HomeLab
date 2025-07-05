variable "name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "The subnet ID for the EC2 instance"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to associate"
  type        = list(string)
}

variable "key_name" {
  description = "The SSH key pair name for the instance"
  type        = string
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script (cloud-init) to run on launch"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "iam_instance_profile" {
  description = "The IAM instance profile to attach to the EC2 instance"
  type        = string
  default     = null
}
