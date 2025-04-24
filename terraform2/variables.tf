variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "image_uri" {
  description = "The URI of the Docker image in ECR"
  type        = string
  default     = "118273046134.dkr.ecr.us-east-1.amazonaws.com/gbk-strapi-app:latest"
}

variable "existing_vpc_id" {
  description = "ID of the existing VPC"
  default     = "vpc-0d255f5b20be72ef6"
}

variable "image_uri" {
  type        = string
  description = "URI of the Docker image in ECR"
}

variable "region" {
  type        = string
  description = "AWS region for deployment"
}

variable "app_keys" {
  type        = string
  description = "Application keys for Strapi"
  sensitive   = true
}

variable "api_token_salt" {
  type        = string
  description = "API token salt for Strapi"
  sensitive   = true
}

variable "admin_jwt_secret" {
  type        = string
  description = "Admin JWT secret for Strapi"
  sensitive   = true
}

variable "transfer_token_salt" {
  type        = string
  description = "Transfer token salt for Strapi"
  sensitive   = true
}

variable "jwt_secret" {
  type        = string
  description = "JWT secret for Strapi"
  sensitive   = true
}
