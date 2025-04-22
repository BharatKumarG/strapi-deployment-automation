# infra-setup.tf

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "strapi_tf_state" {
  bucket = "strapi-ecs"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Recommended for state locking
resource "aws_dynamodb_table" "strapi_lock" {
  name           = "strapi-ecs-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
