provider "aws" {
  region = "us-east-1"
}

# Fetch the default VPC in your region
data "aws_vpc" "default" {
  default = true
}

# Fetch subnets in specific Availability Zones
data "aws_subnet" "subnet_1" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1a"]
  }
}

data "aws_subnet" "subnet_2" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1b"]
  }
}

# Define Security Group for Strapi ECS service
resource "aws_security_group" "gbk_strapi_sg" {
  name        = "gbkdhd-strapi_sg"
  description = "Allow inbound traffic for Strapi ECS service"
  vpc_id      = data.aws_vpc.default.id

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

# ECS Task Definition
resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = "arn:aws:iam::118273046134:role/ecsTaskExecutionRole1"
  task_role_arn            = "arn:aws:iam::118273046134:role/ecsTaskExecutionRole1"

  cpu    = "256"
  memory = "512"

  container_definitions = jsonencode([
    {
      name  = "strapi-container",
      image = "your-docker-image",  # Replace with actual image (e.g., gudurubharatkumar/strapi-app:latest)
      cpu   = 256,
      memory = 512,
      essential = true,
      portMappings = [
        {
          containerPort = 80,
          hostPort      = 80,
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# Application Load Balancer (ALB)
resource "aws_lb" "strapi_alb" {
  name               = "gbkh-strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.gbk_strapi_sg.id]
  subnets            = [data.aws_subnet.subnet_1.id, data.aws_subnet.subnet_2.id]
  enable_deletion_protection = false
}

# Load Balancer Target Group
resource "aws_lb_target_group" "strapi_tg" {
  name        = "gbkhtg-strapi-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id  # Fixed: previously using `var.vpc_id`

  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# ECS Service for Strapi
resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [data.aws_subnet.subnet_1.id, data.aws_subnet.subnet_2.id]
    security_groups = [aws_security_group.gbk_strapi_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.strapi_tg.arn
    container_name   = "strapi-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.strapi_listener]
}

# Load Balancer Listener (required)
resource "aws_lb_listener" "strapi_listener" {
  load_balancer_arn = aws_lb.strapi_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strapi_tg.arn
  }
}

# Output the Load Balancer DNS name
output "strapi_alb_url" {
  value = aws_lb.strapi_alb.dns_name
}
