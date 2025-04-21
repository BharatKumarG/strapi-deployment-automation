provider "aws" {
  region = "us-east-1"  # Changed region to us-east-1
}

# Create VPC
resource "aws_vpc" "strapi_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Create Security Group for EC2 instance with updated name
resource "aws_security_group" "strapi_sg" {
  name        = "strapi.app.gbkg"  # Changed to strapi.app.gbkg
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
  ami           = "ami-0c55b159cbfafe1f0"  # Choose an Amazon Linux AMI
  instance_type = "t2.micro"
  key_name      = "bharath"  # Changed to key name 'bharath'
  security_groups = [aws_security_group.strapi_sg.name]
  subnet_id     = aws_subnet.strapi_subnet.id

  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "Strapi EC2 Instance"
  }
}

# Create a subnet for the EC2 instance
resource "aws_subnet" "strapi_subnet" {
  vpc_id                  = aws_vpc.strapi_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Changed to us-east-1
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
  template = file("terraform/user_data.sh")

  vars = {
    image_tag = var.image_tag
  }
}

output "ec2_public_ip" {
  value = aws_instance.strapi_instance.public_ip
}
