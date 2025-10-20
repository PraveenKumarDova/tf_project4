terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "eu-west-2"
}

variable "instance_type" {

}

data "aws_ami" "myami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-kernel-5.10-hvm-2.0.20250801-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "webserver" {
  # count         = 2
  ami           = data.aws_ami.myami.id
  instance_type = var.instance_type

  tags = {
    # Name = "webserver-${count.index + 1}"
    Name = "webserver"
  }
}

output "public_ip" {
  value = aws_instance.webserver.public_ip
}

output "instance_id" {
  value = aws_instance.webserver.id
}

output "ami" {
  value = aws_instance.webserver.ami
}