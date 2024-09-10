variable "dns" {
  description = "Get DNS data"
  type        = bool
  default     = true
}

variable "load_balancer" {
  description = "Get load balancer data"
  type        = bool
  default     = true
}

variable "team_name" {
  description = "Get the name of the team"
  type        = string
  default     = false
}
