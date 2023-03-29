terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.52.0"
    }
  }
}

provider "aws" {
  profile    = ""
  region     = "us-east-1"
}





variable "ZONES"{
  default = ["us-east-1a","us-east-1b"]
}

variable "SECURITY_GROUP" {
  type    = string
  default = "sg-0b153b6c2b776d15b"
}

data "aws_lb_target_group" "redis" {
  name = "redis-tg"
}

data "aws_ami" "redis_custom_ami" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["redis-linux-aws"]
  }
}





resource "aws_launch_configuration" "lc-go" {
  key_name        = "YagoJanosJT"
  security_groups = [var.SECURITY_GROUP]  

  name          = "lc-yagoquaranta"
  instance_type = "t2.micro"
  image_id      = data.aws_ami.redis_custom_ami.id
}

resource "aws_autoscaling_group" "asg-redis" {
  max_size         = 1
  min_size         = 1
  desired_capacity = 1
  
  launch_configuration = aws_launch_configuration.lc-go.name
  target_group_arns    = [data.aws_lb_target_group.redis.arn]

  availability_zones = var.ZONES

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "Redis"
  }

  tag {
    key                 = "GithubOwner"
    propagate_at_launch = true
    value               = "YagoJanos"
  }

  tag {
    key                 = "Project"
    propagate_at_launch = true
    value               = "TemaFinalDevops"
  }
}

