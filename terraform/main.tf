provider "aws" {
  region = var.aws_region
}

# Fetch the latest Amazon Linux 2 AMI dynamically based on the region
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }
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

# Attach policy to allow EC2 access to ECR
resource "aws_iam_role_policy_attachment" "ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ec2_role.name
}

# EC2 Instance
resource "aws_instance" "strapi_ec2" {
  ami           = data.aws_ami.latest_amazon_linux.id  # Dynamically fetched AMI ID
  instance_type = var.instance_type

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

# IAM Instance Profile to attach the IAM role to the EC2 instance
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}
