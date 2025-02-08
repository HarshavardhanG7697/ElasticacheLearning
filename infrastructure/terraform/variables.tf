variable "stack_name" {
  type = string
  description = "Name of the stack"
}

variable "EC2AMI" {
  type = string
  description = "AMI to use for EC2 instances"
  default = "Latest Amazon Linux"
  validation {
    condition = contains(["Latest Amazon Linux", "Latest Ubuntu"], var.EC2AMI)
    error_message = "EC2AMI must be either 'Latest Amazon Linux' or 'Latest Ubuntu'."
  }
}

variable "deployment_region" {
  type = string
  description = "The region in which the resources are deployed"
  default = "ap-south-1"
}