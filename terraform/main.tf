provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "strapi" {
  ami                    = "ami-0e449927258d45bc4" # Replace with a valid AMI ID for your region
  instance_type          = "t2.medium"
  key_name               = "bharath"               # Replace with your key pair name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 118273046134.dkr.ecr.us-east-1.amazonaws.com
              docker pull 118273046134.dkr.ecr.us-east-1.amazonaws.com/gbk-strapi-app:latest
              docker run -d -p 80:1337 118273046134.dkr.ecr.us-east-1.amazonaws.com/gbk-strapi-app:latest
              EOF

  tags = {
    Name = "Strapi-EC2-GBK"
  }
}

resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg-GBKGy"
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
  ingress {
  from_port   = 1337
  to_port     = 1337
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow Strapi"
}


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}
