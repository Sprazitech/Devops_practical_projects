# # Look up the secret
# data "aws_secretsmanager_secret" "infra_config" {
#   name = "ecommerce-secrets"
# }

# # Get the latest version of the secret
# data "aws_secretsmanager_secret_version" "infra_config" {
#   secret_id = data.aws_secretsmanager_secret.infra_config.id
# }

# # Parse secret JSON into locals
# locals {
#   config = jsondecode(data.aws_secretsmanager_secret_version.infra_config.secret_string)
# }
