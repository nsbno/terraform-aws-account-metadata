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

  cognito_user_pool_id_mapping = {
    "dev"   = "eu-west-1_0AvVv5Wyk"
    "test"  = "eu-west-1_Z53b9AbeT"
    "stage" = "eu-west-1_AUYQ679zW"
    "prod"  = "eu-west-1_e6o46c1oE"
  }
}

data "aws_route53_zone" "this" {
  count = var.dns ? 1 : 0

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
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["Private"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
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
  # The shared VPC can contain several load balancers. The ones we care about
  # are those that carry the https (443) and https_test (8443) listeners.
  lbs_in_shared_vpc = [
    for lb in data.aws_lb.all : lb.arn
    if lb.vpc_id == data.aws_vpc.shared.id
    && !anytrue([
      for prefix in var.load_balancer_excluded_name_prefixes : startswith(lb.name, prefix)
    ])
  ]

  lb_arn = var.load_balancer ? try(local.lbs_in_shared_vpc[0], null) : null
}

data "aws_lb_listener" "https" {
  count = var.load_balancer ? 1 : 0

  load_balancer_arn = local.lb_arn
  port              = 443

  lifecycle {
    precondition {
      condition     = length(local.lbs_in_shared_vpc) == 1
      error_message = "The shared-vpc contained more than one Load Balancer (after excluding prefixes: ${jsonencode(var.load_balancer_excluded_name_prefixes)}). Cannot determine which one to use. Found ${length(local.lbs_in_shared_vpc)}: ${jsonencode(local.lbs_in_shared_vpc)}"
    }
  }
}

data "aws_lb_listener" "https_test" {
  count = var.load_balancer ? 1 : 0

  load_balancer_arn = local.lb_arn
  port              = 8443
}

/*
 * = Team name
 */

data "aws_ssm_parameter" "team_name" {
  count = var.team_name ? 1 : 0

  name = "/__platform__/team_name_handle"
}
