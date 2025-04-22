provider "aws" {
  region = "us-east-1"
}

# Reference the newly created VPC
data "aws_vpc" "gbk_vpc" {
  id = "vpc-0d255f5b20be72ef6"
}

# Fetch subnets in different Availability Zones (assuming subnets exist in the new VPC)
data "aws_subnet" "subnet_1" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.gbk_vpc.id]
  }

  filter {
    name   = "availabilityZone"
    values = ["us-east-1a"]
  }
}

data "aws_subnet" "subnet_2" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.gbk_vpc.id]
  }

  filter {
    name   = "availabilityZone"
    values = ["us-east-1b"]
  }
}

resource "aws_security_group" "gbk_strapi_sg" {
  name        = "gbkdhd-strapi_sg"
  description = "Allow inbound traffic for Strapi ECS service"
  vpc_id      = data.aws_vpc.gbk_vpc.id

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

resource "aws_ecs_cluster" "strapi_cluster" {
  name = "strapi-cluster"
}

resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = "arn:aws:iam::118273046134:role/ecsTaskExecutionRole1"
  task_role_arn            = "arn:aws:iam::118273046134:role/ecsTaskExecutionRole1"
  cpu                      = "256"
  memory                   = "512"

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

resource "aws_lb" "strapi_alb" {
  name               = "gbkh-strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.gbk_strapi_sg.id]
  subnets            = [data.aws_subnet.subnet_1.id, data.aws_subnet.subnet_2.id]
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "strapi_tg" {
  name        = "gbkhtg-strapi-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.gbk_vpc.id
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
}

output "strapi_alb_url" {
  value = aws_lb.strapi_alb.dns_name
}
