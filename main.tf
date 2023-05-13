terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

provider "aws" {
  region                   = "us-east-1"
  profile                  = "terraform"
  shared_credentials_files = ["C:\\Users\\AlmeidaAlmeida\\.aws\\credentials"]
  shared_config_files      = ["C:\\Users\\AlmeidaAlmeida\\.aws\\config"]
}

resource "aws_vpc" "quick_start_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "private_network_1" {
  vpc_id = aws_vpc.quick_start_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a" 
}

resource "aws_subnet" "private_network_2" {
  vpc_id = aws_vpc.quick_start_vpc.id 
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b" 
}

resource "aws_subnet" "public_network_1" {
  vpc_id = aws_vpc.quick_start_vpc.id 
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a" 
}

resource "aws_subnet" "public_network_2" {
  vpc_id = aws_vpc.quick_start_vpc.id 
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1b" 
}

resource "aws_internet_gateway" "quick_start_gw" {
  vpc_id = aws_vpc.quick_start_vpc.id
}

resource "aws_lb" "quick_start_lb" {
  internal = false
  load_balancer_type = "application"
  subnets = [aws_subnet.public_network_1.id, aws_subnet.public_network_2.id]
}

resource "aws_security_group" "allow_http" {
  name = "allow HTTP"
  description = "Allow HTTP traffic"
  vpc_id = aws_vpc.quick_start_vpc.id

  ingress {
    description = "HTTP from Internet"
    from_port = 80 # double check
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/32"]
  }
  # improve
  egress {
    from_port = 0
    to_port =  0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
   }
}

