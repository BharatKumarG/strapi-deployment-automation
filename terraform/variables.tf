variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "ecr_registry" {
  description = "AWS ECR registry URL"
  type        = string
}

variable "ecr_image" {
  description = "ECR image URI"
  type        = string
}
