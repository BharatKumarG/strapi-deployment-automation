#!/bin/bash
# Update and install Docker
yum update -y
yum install -y docker
service docker start
usermod -a -G docker ec2-user

# Log in to AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com

# Pull the Strapi image using the image tag passed from GitHub Actions
docker pull <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com/strapi-repo:${image_tag}

# Run the Strapi container
docker run -d -p 1337:1337 <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com/strapi-repo:${image_tag}
