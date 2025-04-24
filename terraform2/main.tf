provider "aws" {
  region = "us-east-1"
}

# Create a custom VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Route Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Subnets in different AZs
resource "aws_subnet" "subnet-1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet-2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

# Associate Subnets with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.rt.id
}

# Security Group for ECS
resource "aws_security_group" "gbk_strapi_sg" {
  name        = "gbkdhd-strapi_sg"
  description = "Allow inbound traffic for Strapi ECS service"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 1337  # Strapi default port
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

# ECS Cluster
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
  cpu                      = "1024"  # Updated to 1 vCPU
  memory                   = "2048"  # Updated to 2GB

  container_definitions = jsonencode([{
    name         = "strapi-container",
    image        = "118273046134.dkr.ecr.us-east-1.amazonaws.com/gbk-strapi-app:latest",
    cpu          = 1024,
    memory       = 2048,
    essential    = true,
 portMappings = [{
    containerPort = 1337
    hostPort      = 1337
  }]

  environment = [
    {
      name  = "APP_KEYS"
      value = "Jg4YbhVcsYoRouStfw0z2A==,CBUkQ7RFmML9J0rEHKlj5A==,4T8r0nRvF4vjRFVpXulISw=="
    },  # ← comma here :contentReference[oaicite:4]{index=4}
    {
      name  = "API_TOKEN_SALT"
      value = "BSNERswHRhVxowfHjthtog=="
    },  # ← comma here
    {
      name  = "ADMIN_JWT_SECRET"
      value = "xeMpWFLgUfL5Far9L177LA=="
    },  # ← comma here
    {
      name  = "TRANSFER_TOKEN_SALT"
      value = "U7Dlnvp/F2LHezYIKCzHgQ=="
    },  # ← comma here
    {
      name  = "JWT_SECRET"
      value = "SCSW/V83HscaFgxCGMPT3Q=="
    },  # ← comma here
    {
      name  = "DATABASE_CLIENT"
      value = "sqlite"
    },  # ← comma here
    {
      name  = "DATABASE_FILENAME"
      value = ".tmp/data.db"
    }   # No comma on the last item
  ]    # End of environment list :contentReference[oaicite:5]{index=5}

  logConfiguration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = "/ecs/strapi"
      awslogs-region        = "us-east-1"
      awslogs-stream-prefix = "ecs"
    }
  }
}])
}

# Random ID for Load Balancer Name
resource "random_id" "lb_id" {
  byte_length = 4
}

# Application Load Balancer
resource "aws_lb" "strapi_alb" {
  name                        = "gbkh-strapi-alb-${random_id.lb_id.hex}"
  internal                    = false
  load_balancer_type          = "application"
  security_groups             = [aws_security_group.gbk_strapi_sg.id]
  subnets                     = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
  enable_deletion_protection  = false
}

# Target Group
resource "aws_lb_target_group" "strapi_tg" {
  name        = "gbkhtg-strapi-tg"
  port        = 1337  # Match Strapi port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/_health"  # Health check endpoint
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# ECS Service
resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  enable_execute_command = true  # Enable ECS Exec

  network_configuration {
    subnets          = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
    security_groups  = [aws_security_group.gbk_strapi_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.strapi_tg.arn
    container_name   = "strapi-container"
    container_port   = 1337  # Correct port
  }

  depends_on = [aws_lb_listener.strapi_listener]
}

# Listener for ALB
resource "aws_lb_listener" "strapi_listener" {
  load_balancer_arn = aws_lb.strapi_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strapi_tg.arn
  }
}

# Output
output "strapi_alb_url" {
  value = aws_lb.strapi_alb.dns_name
}
