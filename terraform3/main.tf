provider "aws" {
  region = "us-east-1"

  ignore_tags {
    keys = ["*"]
  }

  skip_credentials_validation = false
  skip_metadata_api_check     = false
  skip_requesting_account_id  = false
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "strapi_sg" {
  name        = "gbkgb-strapi-sg"
  description = "Allow HTTP and ECS traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
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
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "strapi" {
  name               = "gbkgb-strapi-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.strapi_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "blue" {
  name        = "gbkgb-strapi-tg-blue"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "green" {
  name        = "gbkgb-strapi-tg-green"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.strapi.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

resource "aws_ecs_cluster" "strapi" {
  name = "gbkgb-strapi-cluster"
}

resource "aws_cloudwatch_log_group" "strapi" {
  name = "/ecs/gbkgb-strapi"
}

resource "aws_ecs_task_definition" "strapi" {
  family                   = "gbkgb-strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = "arn:aws:iam::118273046134:role/ecsTaskExecutionRole1"

  container_definitions = jsonencode([{
    name      = "gbkgb-strapi"
    image     = "118273046134.dkr.ecr.us-east-1.amazonaws.com/gbk-strapi-app:latest"
    essential = true
    portMappings = [
      {
        containerPort = 1337
        hostPort      = 1337
      }
    ],
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-group         = aws_cloudwatch_log_group.strapi.name,
        awslogs-region        = "us-east-1",
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "strapi" {
  name            = "gbkgb-strapi-service"
  cluster         = aws_ecs_cluster.strapi.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    assign_public_ip = true
    security_groups  = [aws_security_group.strapi_sg.id]
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "gbkgb-strapi"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.front_end]
}

resource "aws_codedeploy_app" "strapi" {
  name             = "gbkgb-strapi-codedeploy-app"
  compute_platform = "ECS"
}

resource "aws_iam_role_policy_attachment" "codedeploy_service" {
  role       = "CodeDeployServiceRole"
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

resource "aws_codedeploy_deployment_group" "strapi" {
  app_name               = aws_codedeploy_app.strapi.name
  deployment_group_name  = "gbkgb-strapi-deployment-group"
  service_role_arn       = "arn:aws:iam::118273046134:role/CodeDeployServiceRole"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout    = "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = 0
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.strapi.name
    service_name = aws_ecs_service.strapi.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.front_end.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }

  depends_on = [aws_iam_role_policy_attachment.codedeploy_service]
}

output "strapi_lb_dns" {
  value = aws_lb.strapi.dns_name
}
