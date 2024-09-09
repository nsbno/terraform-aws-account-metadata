variable "override_route53_zone" {
  description = "Override Route 53 Zone in the case of account alias not following the standard pattern"

  type    = string
  default = null
}
