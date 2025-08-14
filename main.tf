# Configuração do provider AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.8.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Provisionamento da instância
resource "aws_instance" "webserver" {
  ami                         = "ami-0de716d6197524dd9"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.subnet_pub.id
  vpc_security_group_ids      = [aws_security_group.acesso_webserver.id]
  associate_public_ip_address = true
  user_data                   = file("ec2-data.sh")

  tags = {
    Name = "ec2-terraform-github-actions"
  }
}

# Provisionamento da vpc
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# Provisionamento da subnet privada
resource "aws_subnet" "subnet_priv" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet_priv"
  }
}

# Provisionamento da subnet pública
resource "aws_subnet" "subnet_pub" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_pub"
  }
}

# Provisionamento do security group
resource "aws_security_group" "acesso_webserver" {
  name        = "acesso_ssh_http"
  description = "Acesso SSH e HTTP"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Provisionamento do internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main"
  }
}

# Provisionamento da tabela de roteamento pública
resource "aws_route_table" "rt-pub" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "rt-pub"
  }
}

# Associação da tabela de roteamento pública a subnet
resource "aws_route_table_association" "rt_public_ass" {
  subnet_id      = aws_subnet.subnet_pub.id
  route_table_id = aws_route_table.rt-pub.id
}

# Output do IP da instância
output "public_ip" {
  value       = aws_instance.webserver.public_ip
  description = "IP público do meu Webserver"
}
