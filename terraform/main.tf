provider "aws" {
  region = "us-east-1" # Choose your desired AWS region
}

# EC2 instance definition
resource "aws_instance" "strapi_ec2" {
  ami           = "ami-xxxxxxxxxx"  # Replace with the correct AMI ID for your EC2 instance
  instance_type = "t2.micro"

  tags = {
    Name = "StrapiEC2"
  }

  # User data script to install Docker and run Strapi container
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker
              service docker start
              docker pull ${var.ecr_registry}/${var.ecr_repository}:${var.image_tag}
              docker run -d -p 80:80 ${var.ecr_registry}/${var.ecr_repository}:${var.image_tag}
              EOF

  # IAM role for EC2 to access ECR
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
}

# IAM Role for EC2 to access ECR
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the ECR policy to the EC2 role
resource "aws_iam_role_policy_attachment" "ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ec2_role.name
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}
