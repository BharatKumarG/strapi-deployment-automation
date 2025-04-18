variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"  # Adjust to your desired region
}

variable "ecr_registry" {
  description = "The ECR registry URL"
  type        = string
}

variable "ecr_repository" {
  description = "The ECR repository name"
  type        = string
}

variable "image_tag" {
  description = "The tag of the Docker image"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t2.medium"
}

variable "ami_name_filter" {
  description = "The filter for the AMI name"
  type        = string
  default     = "amzn2-ami-hvm-*-x86_64-gp2"
}
