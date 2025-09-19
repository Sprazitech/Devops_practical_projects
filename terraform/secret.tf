# resource "aws_secretsmanager_secret" "infra_config" {
#   name = "ecommerce-infra-config"
# }

# resource "aws_secretsmanager_secret_version" "infra_config_version" {
#   secret_id = aws_secretsmanager_secret.infra_config.id

#   secret_string = jsonencode({
#     region      = "us-east-1"
#     project     = "ecommerce"
#     ami_id      = "ami-0c55b159cbfafe1f0"
#     key_name    = "my-keypair"
#     db_password = "StrongPassword123!"
#   })
# }
