provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "strapi_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Create Security Group for EC2 instance with updated name
resource "aws_security_group" "strapi_sg" {
  name        = "strapi.app.gbkgg"  # Changed to strapi.app.gbkg
  description = "Security group for Strapi EC2 instance"
  vpc_id      = aws_vpc.strapi_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Port 1337 open for Strapi application access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 instance
resource "aws_instance" "strapi_instance" {
  ami                           = "ami-0e449927258d45bc4"  # Replace with your AMI ID
  instance_type                 = "t2.medium"
  subnet_id                    = aws_subnet.strapi_subnet.id
  vpc_security_group_ids       = [aws_security_group.strapi_sg.id]  # Use vpc_security_group_ids instead of security_group_ids
  associate_public_ip_address  = true
  key_name                     = "bharath"
  tags = {
    Name = "StrapiInstance_GBGB"
  }
}


# Create a subnet for the EC2 instance
resource "aws_subnet" "strapi_subnet" {
  vpc_id                  = aws_vpc.strapi_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# ECR repository for storing the Strapi Docker image
resource "aws_ecr_repository" "strapi_repo" {
  name = "strapi-repo"
}

# Get the Docker image tag from GitHub actions output (e.g., GitHub SHA)
variable "image_tag" {
  description = "The tag of the Docker image to be deployed"
  type        = string
}

# Use the image tag in user data to pull the Docker image
data "template_file" "user_data" {
template = file("user_data.sh")

  vars = {
    image_tag = var.image_tag
  }
}

output "ec2_public_ip" {
  value = aws_instance.strapi_instance.public_ip
}
