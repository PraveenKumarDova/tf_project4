terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }

  # backend "s3" {
  #   bucket = "awsinfra-bucket"
  #   key = "terraform.tfsate"
  #   region = "eu-west-2"
  #   dynamodb_table = "aws-table"

  # }
}

provider "aws" {
  # Configuration options
  region = "eu-west-2"
}

variable "instance_type" {

}

# data "aws_ami" "myami" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-ecs-kernel-5.10-hvm-2.0.20250801-x86_64-ebs"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["amazon"]
# }

# resource "aws_instance" "webserver" {
#   # count         = 2
#   ami           = data.aws_ami.myami.id
#   instance_type = var.instance_type

#   tags = {
#     # Name = "webserver-${count.index + 1}"
#     Name = "webserver"
#   }
# }

# output "public_ip" {
#   value = aws_instance.webserver.public_ip
# }

# output "instance_id" {
#   value = aws_instance.webserver.id
# }

# output "ami" {
#   value = aws_instance.webserver.ami
# }

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  # instance_tenancy = "default"

  tags = {
    Name = "myvpc"
  }
}

resource "aws_subnet" "pub_subnet" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "pub_subnet"
  }
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "myigw"
  }
}

resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }

  tags = {
    Name = "rt1"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.pub_subnet.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_security_group" "mywebsecurity" {
  name        = "ownsecurityrules"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    name = "own-sg"
  }

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
  ami                         = data.aws_ami.myami.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.pub_subnet.id
  vpc_security_group_ids      = [aws_security_group.mywebsecurity.id]
  key_name                    = "london1"
  user_data                   = file("server-script.sh")

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