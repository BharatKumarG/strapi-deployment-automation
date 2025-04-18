# main.tf
resource "aws_instance" "strapi" {
  ami                    = "ami-084568db4383264d4" # Use correct AMI ID for your region
  instance_type          = "t2.medium"
  key_name               = "bharath"
  associate_public_ip_address = true

  # Attach security group (optional)
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]

  tags = {
    Name = "Strapi-EC2"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update packages
              yum update -y

              # Install Docker
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user

              # Install AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install

              # Login to ECR
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.ecr_registry}

              # Pull and run the Docker image from ECR
              docker pull ${var.ecr_image}
              docker run -d -p 80:1337 ${var.ecr_image}
              EOF
}
