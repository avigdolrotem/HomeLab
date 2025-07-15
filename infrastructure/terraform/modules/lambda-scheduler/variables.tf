variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID to schedule"
  type        = string
}

variable "start_schedule" {
  description = "CloudWatch cron expression for start schedule"
  type        = string
  default     = "cron(0 6 * * ? *)"
}

variable "stop_schedule" {
  description = "CloudWatch cron expression for stop schedule"
  type        = string
  default     = "cron(0 18 * * ? *)"
}
