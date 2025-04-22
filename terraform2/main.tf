# ECS Task Definition
resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "gbk-strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "gbk-strapi-container"
    image     = "118273046134.dkr.ecr.us-east-1.amazonaws.com/gbk-strapi-app:latest"
    essential = true
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }
    ]
  }])
}
