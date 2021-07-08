provider "aws" {
  version = "3.48.0"
  region  = "eu-west-2"
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "my_cluster"
}

resource "aws_ecr_repository" "my_service" {
  name = "my-service"
}

resource "aws_security_group" "lb" {
  name   = "my-service-lb"
  vpc_id = "vpc-12345"

  egress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.task.id]
  }
}

resource "aws_lb" "my_service" {
  name               = "my-service"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = ["private-subnet-1"]
}

resource "aws_lb_target_group" "http" {
  name        = "my-service-http"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-12345"
  target_type = "ip"

  health_check {
    protocol            = "http"
    healthy_threshold   = 1
    unhealthy_threshold = 1
    interval            = 10
    timeout             = 5
    path                = "/"
    matcher             = "200-599"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = "arn:aws:elasticloadbalancing:eu-west-2:399338986753:loadbalancer/app/r2d2-data-ecs-perm-alb/31d9bd9c51d8af30"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

resource "aws_security_group" "task" {
  name   = "my-service-task"
  vpc_id = "vpc-12345"

  egress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "lb_to_task" {
  type                     = "egress"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lb.id
  source_security_group_id = aws_security_group.task.id
  from_port                = 80
  to_port                  = 80
}

resource "aws_security_group_rule" "task_from_lb" {
  type                     = "ingress"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.task.id
  source_security_group_id = aws_security_group.lb.id
  from_port                = 80
  to_port                  = 80
}

resource "aws_ecs_service" "this" {
  name            = "my-service"
  cluster         = "my_cluster"
  task_definition = aws_ecs_task_definition.this.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = ["private-subnet-1"]
    security_groups  = [aws_security_group.task.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.http.arn
    container_name   = "application"
    container_port   = 80
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "my-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = "arn:aws:iam::123456789:role/ecsTaskExecutionRole"
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name      = "application"
      image     =  "123456789.dkr.ecr.eu-west-2.amazonaws.com/my-service:latest"
      essential = true
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = 80
        }
      ],
      environment = [
        { name = "DB_URL", value = aws_db_instance.my_service_mysql.address },
        { name = "DB_ADMIN", value = "admin" },
        { name = "DB_PASSWORD", value = "password1" },
      ]
    },
  ])
}

resource "aws_security_group" "db" {
  name   = "my-service-task"
  vpc_id = "vpc-12345"
}

resource "aws_security_group_rule" "task_from_lb" {
  type              = "ingress"
  protocol          = "tcp"
  security_group_id = aws_security_group.task.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 5432
  to_port           = 5432
}

resource "aws_db_instance" "my_service_mysql" {
  allocated_storage      = 10
  engine                 = "postgresql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  name                   = "my_service_db"
  username               = "admin"
  password               = "password1"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.db.id]
}
