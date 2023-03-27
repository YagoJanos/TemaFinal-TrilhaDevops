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

data "aws_elb" "elb-go" {
  name = "elb-go-yagoquaranta"
}

data "aws_ami" "go_custom_ami" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["calculator-packer-linux-aws"]
  }
}





resource "aws_launch_configuration" "lc-go" {
  key_name        = "YagoJanosJT"
  security_groups = [var.SECURITY_GROUP]

  name          = "lc-yagoquaranta-gocalc"
  instance_type = "t2.micro"
  image_id      = data.aws_ami.go_custom_ami.id
}

resource "aws_autoscaling_group" "asg-yagoquaranta" {
  max_size         = 1
  min_size         = 1
  desired_capacity = 1

  launch_configuration = aws_launch_configuration.lc-go.name
  load_balancers       = [data.aws_elb.elb-go.name]

  availability_zones = var.ZONES

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

