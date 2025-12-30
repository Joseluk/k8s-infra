variable "redis_password" {
  description = "Redis password"
  type        = string
  sensitive   = true
  default     = "cloudprep-redis-2024"
}
