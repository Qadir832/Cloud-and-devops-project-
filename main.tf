terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# Public subnet
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group for Bilal's server
resource "aws_security_group" "bilalserver_sg" {
  name        = "bilalserver-sg"
  description = "HTTP access and SSH administration"
  vpc_id      = data.aws_vpc.default.id

  # HTTP access for the dashboard
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH administration - restrict to your own public IP in production
  ingress {
    description = "SSH administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound access for Docker images and updates
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "bilalserver-sg"
    Project = "Bilal-Cloud-DevOps"
  }
}

# EC2 server
resource "aws_instance" "bilalserver" {
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.bilalserver_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y docker
    systemctl enable --now docker
    docker run -d \
      --name bilal-dashboard \
      --restart unless-stopped \
      -p 80:80 \
      nginx:alpine
  EOF

  user_data_replace_on_change = true

  tags = {
    Name    = "bilalserver"
    Project = "Bilal-Cloud-DevOps"
  }
}

# Display server details
output "server_name" {
  value = aws_instance.bilalserver.tags["Name"]
}

output "server_public_ip" {
  value = aws_instance.bilalserver.public_ip
}

output "dashboard_url" {
  value = "http://${aws_instance.bilalserver.public_ip}"
}