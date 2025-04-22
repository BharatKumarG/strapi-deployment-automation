provider "aws" {
  region = "us-east-1"  # Specify the AWS region
}

# Fetch the default VPC in your region
data "aws_vpc" "default" {
  default = true
}

# Create a public subnet in the default VPC with a new CIDR block
resource "aws_subnet" "public_subnet" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "10.0.2.0/24"  # Changed the CIDR block
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# Do not create an internet gateway if it already exists in the default VPC
# Referencing the existing internet gateway
data "aws_internet_gateway" "existing_igw" {
  filter {
    name = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
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

# Create an ECS Cluster
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
  
  # Add CPU and Memory definitions
  cpu                    = "256"   # Added CPU definition
  memory                 = "512"   # Added Memory definition
  
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
