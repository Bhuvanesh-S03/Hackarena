terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {}
}

provider "aws" { region = var.region }

data "aws_vpc" "default" { default = true }
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
data "aws_ecr_repository" "arena" { name = "arena" }

# ---------- Security groups ----------
resource "aws_security_group" "alb" {
  name   = "arena-alb"
  vpc_id = data.aws_vpc.default.id
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

resource "aws_security_group" "tasks" {
  name   = "arena-tasks"
  vpc_id = data.aws_vpc.default.id
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
}

# ---------- Shared: cluster, IAM, ALB ----------
resource "aws_ecs_cluster" "arena" { name = "arena" }

resource "aws_iam_role" "exec" {
  name = "arena-task-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "exec" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb" "arena" {
  name               = "arena-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.arena.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No such team"
      status_code  = "404"
    }
  }
}

# Wildcard DNS: *.arena.yourdomain.com -> ALB (optional)
resource "aws_route53_record" "wildcard" {
  count   = var.zone_id != "" && var.domain_name != "" ? 1 : 0
  zone_id = var.zone_id
  name    = "*.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.arena.dns_name
    zone_id                = aws_lb.arena.zone_id
    evaluate_target_health = false
  }
}

# ---------- One module instance per team ----------
module "team" {
  for_each = toset(var.team_names)
  source   = "./modules/team"

  name         = each.key
  priority     = 100 + tonumber(regex("[0-9]+", each.key))
  host         = var.domain_name != "" ? "${each.key}.${var.domain_name}" : "${each.key}.local"
  image        = "${data.aws_ecr_repository.arena.repository_url}:${each.key}-${var.image_tag}"
  region       = var.region
  cpu          = var.cpu
  memory       = var.memory
  cluster_arn  = aws_ecs_cluster.arena.arn
  vpc_id       = data.aws_vpc.default.id
  subnets      = data.aws_subnets.default.ids
  task_sg_id   = aws_security_group.tasks.id
  listener_arn = aws_lb_listener.http.arn
  exec_role_arn = aws_iam_role.exec.arn
}
