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
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
}


resource "aws_subnet" "private_network" {
  count             = 2
  vpc_id            = aws_vpc.quick_start_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "private_subnet_${count.index}"
  }
}
resource "aws_subnet" "public_network" {
  count             = 2
  vpc_id            = aws_vpc.quick_start_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index + 2)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "public_subnet_${count.index}"
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
  subnets         = aws_subnet.public_network.*.id
  security_groups = [aws_security_group.allow_http.id]
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

resource "aws_route_table_association" "public_rta" {
  count          = 2
  subnet_id      = aws_subnet.public_network[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "eip" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.quick_start_gw]
  tags = {
    Name = "eip_${count.index}"
  }
}


resource "aws_nat_gateway" "nat_gateway" {
  count         = 2
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.public_network[count.index].id
  depends_on    = [aws_internet_gateway.quick_start_gw]
  tags = {
    Name = "Nat Gateway ${count.index}"
  }
}

resource "aws_route_table" "private_route_table" {
  count  = 2
  vpc_id = aws_vpc.quick_start_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }
}

resource "aws_route_table_association" "private_route_table_association" {
  count          = 2
  subnet_id      = aws_subnet.private_network[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
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

# Specify the type of instance that will be created
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
  ami                         = data.aws_ami.amazon.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_network[0].id
  security_groups             = [aws_security_group.SG_allow_ssh.id]
  associate_public_ip_address = true

  tags = {
    Name = "Bastion-host"
  }
}

# Key pair for private instance(web server)
resource "tls_private_key" "instance_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.instance_key.public_key_openssh
}

resource "local_file" "local_key_pair" {
  filename        = "${var.key_pair_name}.pem"
  file_permission = "0400"
  content         = tls_private_key.instance_key.private_key_pem
}

# Webserver
resource "aws_instance" "web_server" {
  ami             = data.aws_ami.amazon.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_network[0].id
  security_groups = [aws_security_group.SG_allow_ssh.id, aws_security_group.allow_http.id]

  key_name  = aws_key_pair.generated_key.key_name
  user_data = file("userdata.sh")

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

# Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.quick_start_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_webserver.arn
  }
}

