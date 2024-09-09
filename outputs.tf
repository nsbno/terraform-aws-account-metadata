output "account" {
  value = {
    account_id = data.aws_caller_identity.this.account_id

    account_name = local.account_name
    environment  = local.environment
  }
}

/*
 * == Domain Name
 */

output "dns" {
  value = var.dns == false ? null : {
    domain_name    = local.account_domain
    hosted_zone_id = data.aws_route53_zone.this[0].zone_id
  }
}

/*
 * == Network Information
 */

output "network" {
  value = {
    vpc_id             = data.aws_vpc.shared.id
    private_subnet_ids = data.aws_subnets.private.ids
    public_subnet_ids  = data.aws_subnets.public.ids
  }
}

/*
 * == Load Balancer
 */

output "load_balancer" {
  value = var.load_balancer == false ? null : {
    arn        = local.lb_arn
    arn_suffix = data.aws_lb.all[local.lb_arn].arn_suffix

    dns_name = data.aws_lb.all[local.lb_arn].dns_name
    zone_id  = data.aws_lb.all[local.lb_arn].zone_id

    https_listener_arn = data.aws_lb_listener.https[0].arn

    security_group_id = tolist(data.aws_lb.all[local.lb_arn].security_groups)[0]
  }
}
