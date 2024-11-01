locals {
  user_data_first = <<-EOT
    #!/bin/bash
    yum group install -y "Development Tools"
    yum install -y cmake ninja-build

    curl https://sh.rustup.rs -sSf > RUSTUP.sh
    sh RUSTUP.sh -y
    rm RUSTUP.sh
    echo "Installing for ec2-user.."
    cp -r ~/.{cargo,rustup,bash_profile,profile} /home/ec2-user
    wget https://raw.githubusercontent.com/efagerho/terraform-ec2-benchmark/refs/heads/main/packets.sh
    cp packets.sh /home/ec2-user
    chown -R ec2-user:ec2-user /home/ec2-user

    export PB_REL="https://github.com/protocolbuffers/protobuf/releases"
    curl -LO $PB_REL/download/v25.1/protoc-25.1-linux-aarch_64.zip
    unzip protoc-25.1-linux-aarch_64.zip -d /usr/local
  EOT

  user_data_second = <<-EOT
    #!/bin/bash
    yum group install -y "Development Tools"
    yum install -y cmake ninja-build

    curl https://sh.rustup.rs -sSf > RUSTUP.sh
    sh RUSTUP.sh -y
    rm RUSTUP.sh
    echo "Installing for ec2-user.."
    cp -r ~/.{cargo,rustup,bash_profile,profile} /home/ec2-user
    wget https://raw.githubusercontent.com/efagerho/terraform-ec2-benchmark/refs/heads/main/packets.sh
    cp packets.sh /home/ec2-user
    chown -R ec2-user:ec2-user /home/ec2-user

    export PB_REL="https://github.com/protocolbuffers/protobuf/releases"
    curl -LO $PB_REL/download/v25.1/protoc-25.1-linux-aarch_64.zip
    unzip protoc-25.1-linux-aarch_64.zip -d /usr/local
  EOT

  user_data_third = <<-EOT
    #!/bin/bash
    yum group install -y "Development Tools"
    yum install -y cmake ninja-build

    curl https://sh.rustup.rs -sSf > RUSTUP.sh
    sh RUSTUP.sh -y
    rm RUSTUP.sh
    echo "Installing for ec2-user.."
    cp -r ~/.{cargo,rustup,bash_profile,profile} /home/ec2-user
    wget https://raw.githubusercontent.com/efagerho/terraform-ec2-benchmark/refs/heads/main/packets.sh
    cp packets.sh /home/ec2-user
    chown -R ec2-user:ec2-user /home/ec2-user

    export PB_REL="https://github.com/protocolbuffers/protobuf/releases"
    curl -LO $PB_REL/download/v25.1/protoc-25.1-linux-aarch_64.zip
    unzip protoc-25.1-linux-aarch_64.zip -d /usr/local
  EOT
}

#
# VPC
#

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "ec2-benchmark"
  }
}

resource "aws_subnet" "first" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "ec2-benchmark-first"
  }
}

resource "aws_subnet" "second" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "ec2-benchmark-second"
  }
}

resource "aws_subnet" "third" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "ec2-benchmark-third"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ec2-benchmark-igw"
  }
}

resource "aws_route_table" "igw" {
 vpc_id = aws_vpc.main.id
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.main.id
 }

 tags = {
   Name = "ec2-benchmark-igw"
 }
}

resource "aws_route_table_association" "first" {
 subnet_id      = aws_subnet.first.id
 route_table_id = aws_route_table.igw.id
}

resource "aws_route_table_association" "second" {
 subnet_id      = aws_subnet.second.id
 route_table_id = aws_route_table.igw.id
}

resource "aws_route_table_association" "third" {
 subnet_id      = aws_subnet.third.id
 route_table_id = aws_route_table.igw.id
}

#
# SSH key
#

resource "aws_key_pair" "instance" {
  key_name   = "ec2-benchmark"
  public_key = var.public_key
}

#
# Security Group
#

resource "aws_security_group" "instance" {
  name        = "ec2-benchmark"
  vpc_id      = aws_vpc.main.id

  tags = {
    Terraform = "true"
    Name = "ec2-benchmark"
  }
}

# Allow everything, since otherwise you hit SG conntrack limits when benchmarking
resource "aws_vpc_security_group_ingress_rule" "all_in" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#
# EC2 instances
#

module "first" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  count = var.num_first_instances
  name = "ec2-benchmark-first-${count.index}"

  private_ip             = cidrhost("10.0.1.0/24", 10 + count.index)
  associate_public_ip_address = true
  ami                    = var.first_ami_id
  instance_type          = var.first_instance_type
  key_name               = "ec2-benchmark"
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.instance.id]
  subnet_id              = aws_subnet.first.id

  user_data_base64            = base64encode(local.user_data_first)
  user_data_replace_on_change = true

  root_block_device = [{
    volume_size = 30
    volume_type = "gp3"
    encrypted   = false
  }]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "second" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  count = var.num_second_instances
  name = "ec2-benchmark-second-${count.index}"

  private_ip             = cidrhost("10.0.2.0/24", 10 + count.index)
  associate_public_ip_address = true
  ami                    = var.second_ami_id
  instance_type          = var.second_instance_type
  key_name               = "ec2-benchmark"
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.instance.id]
  subnet_id              = aws_subnet.second.id

  user_data_base64            = base64encode(local.user_data_second)
  user_data_replace_on_change = true

  root_block_device = [{
    volume_size = 30
    volume_type = "gp3"
    encrypted   = false
  }]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "third" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  count = var.num_third_instances
  name = "ec2-benchmark-third-${count.index}"

  private_ip             = cidrhost("10.0.3.0/24", 10 + count.index)
  associate_public_ip_address = true
  ami                    = var.third_ami_id
  instance_type          = var.third_instance_type
  key_name               = "ec2-benchmark"
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.instance.id]
  subnet_id              = aws_subnet.third.id

  user_data_base64            = base64encode(local.user_data_third)
  user_data_replace_on_change = true

  root_block_device = [{
    volume_size = 30
    volume_type = "gp3"
    encrypted   = false
  }]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
