variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform remote state"
  type        = string
}

variable "aurora_mode" {
  description = "Switch between Aurora Serverless v2 configuration and provisioned instances"
  type        = string
  default     = "serverless"

  validation {
    condition     = contains(["serverless", "provisioned"], var.aurora_mode)
    error_message = "aurora_mode must be either 'serverless' or 'provisioned'"
  }
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Master username for database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for database"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "Instance class for provisioned Aurora instances"
  type        = string
  default     = "db.serverless"
}

variable "instance_count" {
  description = "Number of Aurora instances"
  type        = number
  default     = 1
}

variable "serverless_min_capacity" {
  description = "Minimum ACU for Aurora Serverless v2"
  type        = number
  default     = 0.5
}

variable "serverless_max_capacity" {
  description = "Maximum ACU for Aurora Serverless v2"
  type        = number
  default     = 1
}

variable "enable_proxy" {
  description = "Enable RDS Proxy"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "external_rds_ips" {
  description = "List of external IP addresses or CIDR blocks allowed to access RDS"
  type        = list(string)
  default     = []
}

variable "enable_redis" {
  description = "Enable ElastiCache Redis"
  type        = bool
  default     = true
}

variable "redis_engine" {
  description = "ElastiCache engine (redis or valkey)"
  type        = string
  default     = "valkey"
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_engine_version" {
  description = "ElastiCache Redis engine version"
  type        = string
  default     = "7.1"
}

variable "redis_parameter_group_name" {
  description = "ElastiCache Redis parameter group name"
  type        = string
  default     = "default.redis7"
}
