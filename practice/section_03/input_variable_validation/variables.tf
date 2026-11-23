variable "db_password" {
  type        = string
  description = "Password for the database"
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 12
    error_message = "Password must be at least 12 characters long"
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"

  validation {
    condition     = contains(["t2.micro", "t2.medium", "t2.large"], var.instance_type)
    error_message = "Instance type must be: t2.micro, t2.medium or t2.large"
  }
}

variable "email_id" {
  type        = string
  description = "Email"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.email_id))
    error_message = "Invalid email address"
  }
}

variable "ami_id" {
  type        = string
  description = "AMI ID"

  validation {
    condition     = length(var.ami_id) > 4 && substr(var.ami_id, 0, 4) == "ami-"
    error_message = "The AMI ID must be longer than 4 characters and start with ami-"
  }
}
