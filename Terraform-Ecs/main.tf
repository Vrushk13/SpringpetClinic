provider "aws" {
  region = "eu-north-1"  
}

# -------------------
# VPC
# -------------------

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "route" {
  route_table_id         = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.rt.id
}

# -------------------
# Security Group
# -------------------

resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8085
    to_port     = 8085
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# ✅ ADD THIS (IMPORTANT)
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

# -------------------
# Load Balancer
# -------------------

resource "aws_lb" "petclinic_lb" {
  name               = "petclinic-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
}

resource "aws_lb_target_group" "petclinic_tg" {
  name     = "petclinic-tg"
  port     = 8085
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"
}

resource "aws_lb_listener" "petclinic_listener" {
  load_balancer_arn = aws_lb.petclinic_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.petclinic_tg.arn
  }
}
# NEW: HTTPS listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.petclinic_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn = "arn:aws:acm:eu-north-1:512190912096:certificate/c9735ab9-3dd3-4b1c-80af-e5f835fe8c87"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.petclinic_tg.arn
  }
}
# -------------------
# ECS Cluster
# -------------------

resource "aws_ecs_cluster" "cluster" {
  name = "petclinic-cluster"
}

# -------------------
# Task Definition
# -------------------

resource "aws_ecs_task_definition" "task" {
  family                   = "petclinic-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::512190912096:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name      = "petclinic"
      image     = "512190912096.dkr.ecr.eu-north-1.amazonaws.com/petclinic-repo"
      essential = true
      portMappings = [
        {
          containerPort = 8085
          hostPort      = 8085
        }
      ]
    }
  ])
}

# -------------------
# ECS Service
# -------------------

resource "aws_ecs_service" "service" {
  name            = "petclinic-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public1.id, aws_subnet.public2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.petclinic_tg.arn
    container_name   = "petclinic"
    container_port   = 8085
  }

  depends_on = [aws_lb_listener.petclinic_listener]
}
