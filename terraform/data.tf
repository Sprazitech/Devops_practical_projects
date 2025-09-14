data "aws_secretsmanager_secret" "infra_config" {
  name = "ecommerce-infra-config"
}

data "aws_secretsmanager_secret_version" "infra_config_version" {
  secret_id = data.aws_secretsmanager_secret.infra_config.id
}

locals {
  config = jsondecode(data.aws_secretsmanager_secret_version.infra_config.secret_string)
}
