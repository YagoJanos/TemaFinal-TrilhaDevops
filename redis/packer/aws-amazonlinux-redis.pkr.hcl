packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "amazonlinux" {
  ami_name      = "redis-linux-aws"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami    = "ami-0b5eea76982371e91"

  profile = ""
  ssh_username         = "ec2-user"
  ssh_keypair_name     = "YagoJanosJT"
  ssh_private_key_file = "/home/yago-janos/YagoJanosJT.pem"


  tags = {
    GithubOwner      = "YagoJanos"
    Project          = "Tema Final Devops"
  }
}

build {
  name    = "redis"
  sources = ["source.amazon-ebs.amazonlinux"]
  
  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y amazon-linux-extras",
      "sudo amazon-linux-extras enable ansible2",
      "sudo yum install -y ansible"
    ]

  }

  provisioner "file" {
    source = "../files"
    destination = "/home/ec2-user/files"
  }


  provisioner "ansible-local" {
    playbook_file   = "../ansible/main_with_roles.yml"
    role_paths      = ["../ansible/roles/redis_config", "../ansible/roles/logrotate_config", "../ansible/roles/healthcheck_config"]
  }

}
