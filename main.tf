data "aws_caller_identity" "this" {}

/*
 * == Domain Name
 */
data "aws_iam_account_alias" "this" {}

locals {
  # The account alias includes the name of the environment we are in as a suffix
  split_alias = split("-", data.aws_iam_account_alias.this.account_alias)

  environment_index = length(local.split_alias) - 1

  account_name = join("-", slice(local.split_alias, 0, length(local.split_alias) - 1))
  environment  = local.split_alias[local.environment_index]

  is_production = local.environment == "prod"

  account_base_domain = "${local.account_name}.vydev.io"
  account_domain      = local.is_production ? local.account_base_domain : "${local.environment}.${local.account_base_domain}"
}

data "aws_route53_zone" "this" {
  name = local.account_domain
}

/*
 *  == Network Information
 */

data "aws_vpc" "shared" {
  filter {
    name   = "tag:Name"
    values = ["shared"]
  }
}

data "aws_subnets" "private" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["Private"]
  }
}

data "aws_subnets" "public" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["Public"]
  }
}


/*
 * == Load Balancer
 */

data "aws_lbs" "all" {}

data "aws_lb" "all" {
  for_each = data.aws_lbs.all.arns

  arn = each.value
}

locals {
  # Get the ARN of the load balancer that is in the same VPC as the shared VPC
  lbs_in_shared_vpc = [
    for lb in data.aws_lb.all : lb.arn if lb.vpc_id == data.aws_vpc.shared.id
  ]
  # Then we just assume that there is only one load balancer in the shared VPC
  lb_arn = local.lbs_in_shared_vpc[0]
}

data "aws_lb_listener" "https" {
  load_balancer_arn = local.lb_arn
  port              = 443
}
