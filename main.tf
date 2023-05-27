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

# Custom VPC
resource "aws_vpc" "quick_start_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Private subnets
resource "aws_subnet" "private_network_1" {
  vpc_id            = aws_vpc.quick_start_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private_subnet_1"
  }
}

resource "aws_subnet" "private_network_2" {
  # Add name(private network 2)
  vpc_id            = aws_vpc.quick_start_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private_subnet_2"
  }
}

# Public subnets
resource "aws_subnet" "public_network_1" {
  # Add name (public network 1)
  vpc_id            = aws_vpc.quick_start_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public_subnet_1"
  }
}

resource "aws_subnet" "public_network_2" {
  #Add name (public network 2)
  vpc_id            = aws_vpc.quick_start_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "public_subnet_2"
  }
}

# Internet GW
resource "aws_internet_gateway" "quick_start_gw" {
  vpc_id = aws_vpc.quick_start_vpc.id
}

# Application load balancer
resource "aws_lb" "quick_start_lb" {
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_network_1.id, aws_subnet.public_network_2.id]
  security_groups    = [aws_security_group.allow_http.id]
  # Listener ports and instance missing

}

# SG to allow inbound HTTP
resource "aws_security_group" "allow_http" {
  name        = "allow HTTP"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.quick_start_vpc.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 0
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # improve
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Route table for public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.quick_start_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.quick_start_gw.id
  }
}

# Route table associations for public subnets
resource "aws_route_table_association" "public_route_table_association_1" {
  subnet_id      = aws_subnet.public_network_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_association_2" {
  subnet_id      = aws_subnet.public_network_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# Elastic IP used by NAT gateway
resource "aws_eip" "nat_gateway_eip_1" {
  vpc        = true
  depends_on = [aws_internet_gateway.quick_start_gw]
}

resource "aws_eip" "nat_gateway_eip_2" {
  vpc        = true
  depends_on = [aws_internet_gateway.quick_start_gw]
}

# NAT Gateways for private subnets
resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_eip_1.id
  subnet_id     = aws_subnet.public_network_1.id
  depends_on    = [aws_internet_gateway.quick_start_gw]
}

resource "aws_nat_gateway" "nat_gateway_2" {
  allocation_id = aws_eip.nat_gateway_eip_2.id
  subnet_id     = aws_subnet.public_network_2.id
  depends_on    = [aws_internet_gateway.quick_start_gw]
}

# Private route table for private subnet 1
resource "aws_route_table" "private_route_table_1" {
  vpc_id = aws_vpc.quick_start_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_1.id
  }
}

# Private route table for private subnet 2
resource "aws_route_table" "private_route_table_2" {
  vpc_id = aws_vpc.quick_start_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_2.id
  }
}

# Route table associations for pricate subnets
resource "aws_route_table_association" "private_route_table_association_1" {
  subnet_id      = aws_subnet.private_network_1.id
  route_table_id = aws_route_table.private_route_table_1.id
}

resource "aws_route_table_association" "private_route_table_association_2" {
  subnet_id      = aws_subnet.private_network_2.id
  route_table_id = aws_route_table.private_route_table_2.id
}

# Security Group responsible for allowing ssh traffic to bastion host

resource "aws_security_group" "SG_allow_ssh" {

  name        = "Allow SSH Bastion"
  description = "Allow ssh traffic"
  vpc_id      = aws_vpc.quick_start_vpc.id

  ingress {
    description = "SSH connection"
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # improve
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


data "aws_ami" "amazon" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
}

# Bastion host Instance located in public network
resource "aws_instance" "bastion_host" {
  ami             = data.aws_ami.amazon.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_network_1.id
  security_groups = [aws_security_group.SG_allow_ssh.id]

  tags = {
    Name = "Bastion-host"
  }
}

# Webserver
resource "aws_instance" "web_server" {
  ami             = data.aws_ami.amazon.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_network_1.id
  security_groups = [aws_security_group.SG_allow_ssh.id]
  user_data       = file("userdata.sh")
  tags = {
    Name = "Web Server"
  }
}


# Target group


resource "aws_lb_target_group" "tg_webserver" {
  name     = "tg-webserver"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.quick_start_vpc.id
  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group_attachment" "tg_webserver_attachment" {
  target_group_arn = aws_lb_target_group.tg_webserver.arn
  target_id        = aws_instance.web_server.id
  port             = 80
}
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.quick_start_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_webserver.arn
  }
}


