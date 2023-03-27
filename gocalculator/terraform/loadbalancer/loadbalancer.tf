terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.52.0"
    }
  }
}

variable "THEME_TAGS" {
  type    = object({})
  default = {
    Name         = "Calculator"
    Github_Owner = "YagoJanos"
    Project      = "TemaFinalDevops"
  }
}

variable "ZONES" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "SECURITY_GROUP" {
  type    = string
  default = "sg-01141db0a06fa5ca7"
}

provider "aws" {
  profile = "342678933335_JTsAccess"
  region  = "us-east-1"
}

resource "aws_elb" "elb-go" {
  security_groups = [var.SECURITY_GROUP]

  name               = "elb-go-yagoquaranta"
  availability_zones = var.ZONES

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 8080
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2

    interval = 30
    timeout  = 3

    target = "HTTP:8080/health"
  }

  tags = var.THEME_TAGS
}

