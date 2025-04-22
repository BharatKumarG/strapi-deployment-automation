provider "aws" {
  region = "us-east-1"  # Specify the AWS region
}

# Fetch the default VPC in your region
data "aws_vpc" "default" {
  default = true
}

# Create a public subnet in the default VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# Create an internet gateway for the default VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = data.aws_vpc.default.id
}

# Create a route table for public access in the default VPC
resource "aws_route_table" "public_rt" {
  vpc_id = data.aws_vpc.default.id
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security group for Strapi
resource "aws_security_group" "gbk_strapi_sg" {
  name        = "gbk-strapi-sg"
  description = "Allow inbound HTTP/HTTPS traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

# Create an Application Load Balancer (ALB)
resource "aws_lb" "strapi_alb" {
  name               = "strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.gbk_strapi_sg.id]
  subnets            = [aws_subnet.public_subnet.id]
  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true
}

# Create an Application Load Balancer Target Group
resource "aws_lb_target_group" "strapi_tg" {
  name     = "strapi-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

# Create ECS Cluster
resource "aws_ecs_cluster" "strapi_cluster" {
  name = "strapi-cluster"
}

# Create ECS Task Definition for Strapi
resource "aws_ecs_task_definition" "strapi_task" {
  family                = "strapi-task"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn    = "arn:aws:iam::118273046134:role/ecsTaskExecutionRole1"
  task_role_arn         = "arn:aws:iam::118273046134:role/ecsTaskExecutionRole1"
  
  container_definitions = <<DEFINITION
  [
    {
      "name": "strapi-container",
      "image": "your-docker-image",
      "cpu": 256,
      "memory": 512,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ]
    }
  ]
  DEFINITION
}

# Create ECS Service for Strapi
resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups = [aws_security_group.gbk_strapi_sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.strapi_tg.arn
    container_name   = "strapi-container"
    container_port   = 80
  }
}

# Output the Load Balancer URL
output "strapi_alb_url" {
  value = aws_lb.strapi_alb.dns_name
}
