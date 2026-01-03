terraform {
  backend "s3" {
    bucket         = "playground-terraform-state-us-east-1"
    key            = "country-events-api/terraform.tfstate"
    region         = "us-east-1"
    # dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
