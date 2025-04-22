variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "image_uri" {
  description = "The URI of the Docker image in ECR"
  type        = string
  default     = "118273046134.dkr.ecr.us-east-1.amazonaws.com/gbk-strapi-app:latest"
}

variable "vpc_id" {
  description = "The ID of the VPC where resources will be deployed"
  type        = string
}
