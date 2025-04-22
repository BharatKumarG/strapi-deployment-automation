terraform {
  backend "s3" {
    bucket         = "strapi-ecs"
    key            = "terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "strapi-ecs-locks"   # optional but useful
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}
