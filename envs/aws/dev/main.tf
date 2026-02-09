locals {
  project     = var.project
  env         = var.env
  name_prefix = "${var.project}-${var.env}"
  tags = {
    Project   = var.project
    Env       = var.env
    ManagedBy = "Terraform"
    Owner     = "Jacob"
  }
}

module "vpc" {
  source = "../../../modules/vpc"

  project = var.project
  env     = var.env

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

}

resource "aws_ecr_repository" "demo_api" {
  name = lower("${local.name_prefix}-demo-api")

  tags = local.tags
}

resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-ecs"

  tags = local.tags
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.name_prefix}-ecs-task-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "demo_api" {
  name = "/ecs/${local.name_prefix}-demo-api"

  tags = local.tags
}

resource "aws_ecs_task_definition" "demo_api" {
  family                   = "${local.name_prefix}-demo-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "demo-api"
      image     = "${aws_ecr_repository.demo_api.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "PORT"
          value = "8080"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.demo_api.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = local.tags
}

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "ALB security group"
  vpc_id      = module.vpc.vpc_id

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

  tags = local.tags
}

resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "ECS service security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_lb" "demo_api" {
  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]

  tags = local.tags
}

resource "aws_lb_target_group" "demo_api" {
  name        = "${local.name_prefix}-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = local.tags
}

resource "aws_lb_listener" "demo_api" {
  load_balancer_arn = aws_lb.demo_api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo_api.arn
  }
}

resource "aws_ecs_service" "demo_api" {
  name            = "${local.name_prefix}-demo-api"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.demo_api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.demo_api.arn
    container_name   = "demo-api"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.demo_api]

  tags = local.tags
}
