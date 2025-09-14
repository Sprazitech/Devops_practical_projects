# Statefile creation
terraform {
  backend "s3" {
    encrypt = true
    bucket  = "devops-practical-projects-statefile"
    key     = "3tier/terraform.tfstate"
    region  = "us-east-1"
    # dynamodb_table = "testworklock"
  }
}
