packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "amazonlinux" {
  ami_name      = "calculator-packer-linux-aws"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami    = "ami-0b5eea76982371e91"
  
  profile = ""
  ssh_username         = "ec2-user"
  ssh_keypair_name     = "YagoJanosJT"
  ssh_private_key_file = "/home/yago-janos/YagoJanosJT.pem"

  tags = {
    Github_Owner     = "YagoQuaranta"
    Project          = "TemaFinalDevops"
  }
}

build {
  name    = "calculator"
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
    source = "../calculator"
    destination = "/home/ec2-user/calculator"
  }  

  provisioner "ansible-local" {
    playbook_file   = "../ansible/main_with_roles.yml"
    role_paths      = ["../ansible/roles/calculator_config", "../ansible/roles/filebeat_config", "../ansible/roles/metricbeat_config"]
  }
}
