provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "strapi" {
  ami                    = "ami-0e449927258d45bc4" # AMI for us-east-1 (Amazon Linux 2)
  instance_type          = "t2.medium"
  key_name               = "bharath"
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.strapi_sg.id]

  tags = {
    Name = "Strapi-EC2"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user

              # Install AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install

              # Login to ECR and pull image
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.ecr_registry}
              docker pull ${var.ecr_image}
              docker run -d -p 80:1337 ${var.ecr_image}
              EOF
}

output "ec2_public_ip" {
  description = "Public IP of the deployed EC2 instance"
  value       = aws_instance.strapi.public_ip
}
