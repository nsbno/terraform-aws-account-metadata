module "account_metadata" {
  source = "../../"

  # Here we define that we do not want it to lookup and return
  # the name of the team and the info about the loadbalancer.
  #
  # This can be useful if you don't have an ALB or are missing
  # the team name setup.
  load_balancer = false
  team_name     = false
}
