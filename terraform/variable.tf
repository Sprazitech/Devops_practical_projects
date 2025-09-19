# =================================================================
# VARIABLES
# =================================================================

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name prefix for tagging/naming"
  type        = string
  default     = "ecommerce"
}

# variable "ami_id" {
#   description = "AMI ID for EC2 instances"
#   type        = string
#   default     = "ami-0c55b159cbfafe1f0"
# }

variable "instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key name for EC2 instances"
  type        = string
  default     = "my-keypair"
}

variable "db_username" {
  description = "Master username for RDS Postgres"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Master password for RDS Postgres"
  type        = string
  sensitive   = true
  default     = "StrongPassword123!"
}

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage (in GB)"
  type        = number
  default     = 20
}
