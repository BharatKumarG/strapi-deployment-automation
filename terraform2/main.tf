provider "aws" {
  region = "us-east-1"  # Change this to your region
}

# Fetch the default VPC in your region
data "aws_vpc" "default" {
  default = true
}

# Fetch subnets in different Availability Zones
data "aws_subnet" "subnet_1" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  
  filter {
    name   = "availabilityZone"
    values = ["us-east-1a"]  # Change to your desired availability zone
  }
}

data "aws_subnet" "subnet_2" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  
  filter {
    name   = "availabilityZone"
    values = ["us-east-1b"]  # Change to your second desired availability zone
  }
}

# Define a Security Group for Strapi ECS service
resource "aws_security_group" "gbk_strapi_sg" {
  name        = "gbkhd-strapi_sg"
  description = "Allow inbound traffic for Strapi ECS service"
  
  ingress {
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

# Create ECS Cluster
resource "aws_ecs_cluster" "strapi_cluster" {
  name = "strapi-cluster"
}

# ECS Task Definition (with CPU and memory)
resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = "arn:aws:iam::118273046134:role/ecsTaskExecutionRole1"
  task_role_arn            = "arn:aws:iam::118273046134:role/ecsTaskExecutionRole1"
  
  cpu                     = "256"   # CPU resource
  memory                  = "512"   # Memory resource
  
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

# Load Balancer (ALB) definition
resource "aws_lb" "strapi_alb" {
  name               = "gbkh-strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.gbk_strapi_sg.id]

  # Reference two subnets in different Availability Zones
  subnets = [
    data.aws_subnet.subnet_1.id,
    data.aws_subnet.subnet_2.id
  ]

  enable_deletion_protection = false
}

# Create Load Balancer Target Group
resource "aws_lb_target_group" "strapi_tg" {
  name     = "gbkhg-strapi-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

# ECS Service for Strapi
resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = [data.aws_subnet.subnet_1.id, data.aws_subnet.subnet_2.id]  # Using two subnets in different AZs
    security_groups = [aws_security_group.gbk_strapi_sg.id]  # Using the defined security group
    assign_public_ip = true
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.strapi_tg.arn  # Referencing the target group
    container_name   = "strapi-container"
    container_port   = 80
  }
}

# Output the Load Balancer URL
output "strapi_alb_url" {
  value = aws_lb.strapi_alb.dns_name
}
