
# Local values
locals {
  environments = ["blue"]

  common_tags = {
    Project     = var.project_name
    Environment = "ecs-django"
    ManagedBy   = "terraform"
  }

}

