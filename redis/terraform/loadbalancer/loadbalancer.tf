terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.52.0"
    }
  }
}

provider "aws" {
  profile = "342678933335_JTsAccess"
  region  = "us-east-1"
}

data "aws_vpc" "main" {
  default = true
}

variable "THEME_TAGS" {
  type    = object({})
  default = {
    Name             = "Redis"
    Github_Owner     = "YagoJanos"
    Project          = "TemaFinalDevops"
  }
}

resource "aws_lb" "redis" {
  name               = "redis"
  internal           = true
  load_balancer_type = "network"
  subnets            = [ "subnet-00d24f1d63bbf3894", "subnet-07b99545f36de4ca7"]

  tags = var.THEME_TAGS
}

resource "aws_lb_listener" "redis" {
  load_balancer_arn = aws_lb.redis.arn
  port              = 6379
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.redis.arn
  }

  tags = var.THEME_TAGS
}

resource "aws_lb_target_group" "redis" {
  name       = "redis-tg"
  port              = 6379
  protocol          = "TCP"
  target_type       = "instance"
  vpc_id            = data.aws_vpc.main.id
  health_check {
    enabled            = true
    interval           = 10
    timeout            = 5
    protocol           = "TCP"
    healthy_threshold  = 3
    unhealthy_threshold= 3
  }

  tags = var.THEME_TAGS
}

