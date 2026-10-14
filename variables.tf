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

variable "load_balancer_excluded_name_prefixes" {
  description = "Ignore all Load Balancers in the shared VPC with a name matching these prefixes. By default, excludes ALBs created by ECS Express Mode."
  type        = set(string)
  default     = ["ecs-express-gateway-alb"]
}

variable "team_name" {
  description = "Get the name of the team"
  type        = bool
  default     = false
}
