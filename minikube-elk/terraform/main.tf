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
    Name             = "ELK"
    Github_Owner     = "YagoJanos"
    Project          = "TemaFinalDevops"
  } 
}

variable "SECURITY_GROUP" {
  type    = string
  default = "sg-01141db0a06fa5ca7"
}

provider "aws" {
  profile = "342678933335_JTsAccess"
  region  = "us-east-1"
}

resource "aws_instance" "elk" {
  ami             = "ami-0d00dd069dbb28f77"
  instance_type   = "t2.medium"
  key_name        = "YagoJanosJT"
  security_groups = [var.SECURITY_GROUP]
  subnet_id       = "subnet-00d24f1d63bbf3894"
  private_ip      = "172.31.16.8"
 
  root_block_device {
    volume_type = "gp2"
    volume_size = 12
    delete_on_termination = true
  }
  
  tags = var.THEME_TAGS
}

output "elk_instance_ip" {
  value = aws_instance.elk.private_ip
}
