
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

output "dns" {
  value = aws_lb.alb.dns_name
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "rahul"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "rahul"
  }
}

resource "aws_subnet" "main1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "rahul1"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rahul"
  }
}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block        = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "rahul"
  }
}

#resource "aws_route_table_association" "a" {
#  subnet_id      = aws_subnet.main.id
#  route_table_id = aws_route_table.rtb.id
#}
#
#resource "aws_route_table_association" "b" {
#  subnet_id      = aws_subnet.main1.id
#  route_table_id = aws_route_table.rtb.id
#}

resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_security_group" "python_flask_sg" {
  name        = "python_flask_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "web Port"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

##ECS Deployment 
resource "aws_ecs_cluster" "python_flask" {
  name = "python_flask_cluster"
}

resource "aws_lb_target_group" "tg" {
  name        = "python-flask-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb" "alb" {
  name               = "python-flask"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.python_flask_sg.id]
  subnets            = [aws_subnet.main.id,aws_subnet.main1.id]

  enable_deletion_protection = false


  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_ecs_service" "python_flask_service" {
  name            = "python_flask"
  cluster         = aws_ecs_cluster.python_flask.id
  task_definition = aws_ecs_task_definition.python_flask_task.arn
  launch_type     = "FARGATE"
  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "python-flask"
    container_port   = 80
  }
  network_configuration {
    subnets          = [aws_subnet.main.id]
    assign_public_ip = true
    security_groups = [aws_security_group.python_flask_sg.id]
  }
  desired_count = 1
}

resource "aws_ecs_task_definition" "python_flask_task" {
  family                   = "python_flask_task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = "arn:aws:iam::456123789456:role/ecsTaskExecutionRole"		#make change here
  container_definitions    = <<EOF
[
  {
    "name": "python-flask",
    "image": "456123789456.dkr.ecr.ap-south-1.amazonaws.com/python-flask:latest",		#make change here
    "memory": 512,
    "cpu": 256,
    "essential": true,
    "entryPoint": [],
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/python_flask_task",
        "awslogs-region": "ap-south-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]


EOF
}
