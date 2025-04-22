provider "aws" {
  region = "us-east-1"  # Update this with your desired AWS region
}

# VPC Setup
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Internet Gateway Setup
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Public Subnet Setup
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Update with your AZ
  map_public_ip_on_launch = true
}

# Route Table Setup
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
}

# Route Table Association
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group Setup (using provided name)
resource "aws_security_group" "gbk_strapi_sg" {
  name        = "gbk-strapi-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id

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

# ALB Target Group
resource "aws_lb_target_group" "strapi_tg" {
  name     = "strapi-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# ALB Setup
resource "aws_lb" "strapi_alb" {
  name               = "strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.gbk_strapi_sg.id]
  subnets            = [aws_subnet.public_subnet.id]

  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true
}

# ECS Cluster
resource "aws_ecs_cluster" "strapi_cluster" {
  name = "strapi-cluster"
}

# ECS Task Definition (with provided IAM role ARN)
resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-task"
  task_role_arn            = "arn:aws:iam::118273046134:role/ecsTaskExecutionRole1"  # Provided IAM role ARN
  execution_role_arn       = "arn:aws:iam::118273046134:role/ecsTaskExecutionRole1"  # Provided IAM role ARN
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "strapi-container"
      image     = "your-docker-image"  # Replace with your actual Docker image
      essential = true
      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# ECS Service (add if you want to deploy a service on ECS)
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
}

# Outputs
output "strapi_alb_url" {
  value = aws_lb.strapi_alb.dns_name
}
