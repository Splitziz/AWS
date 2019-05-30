provider "aws" {
  region  = "eu-west-2"
  version = "~> 2.11.0"
}

resource "aws_instance" "bastion" {
  ami             = "${data.aws_ami.packerami.id}"
  instance_type   = "t2.micro"
  key_name        = "${aws_key_pair.packer.key_name}"
  security_groups = ["${aws_security_group.allow_all_bastion.id}"]
  subnet_id       = "${aws_subnet.bastionsubnet.id}"

  tags = {
    Name = "bastionInstance"
  }
}

resource "aws_eip" "ip-bastion-env" {
  instance = "${aws_instance.bastion.id}"
  vpc      = true
}

resource "aws_vpc" "main" {
  cidr_block = "172.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "vpcBastion"
  }
}

resource "aws_internet_gateway" "bastion-ext-gateway" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "bastion-ext-gateway"
  }
}

resource "aws_route_table" "bastion-route-table" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.bastion-ext-gateway.id}"
  }

  tags {
    Name = "bastion-route-table"
  }
}

resource "aws_subnet" "bastionsubnet" {
  availability_zone = "eu-west-2a"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "172.20.3.0/24"

  tags = {
    Name = "bastionsubnet"
  }
}

resource "aws_security_group" "allow_all_bastion" {
   name        = "allow_all_bastion"
   description = "Allow TLS inbound traffic"
   vpc_id      = "${aws_vpc.main.id}"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags = {
    Name = "bastion-security-group"
  }
}

data "aws_ami" "packerami" {
  most_recent = true
  owners      = ["self"]
  name_regex  = "packer"
}

resource "aws_key_pair" "packer" {
  key_name   = "packer-key"
  public_key = "${file("~/.ssh/packer")}"
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.bastionsubnet.id}"
  route_table_id = "${aws_route_table.bastion-route-table.id}"
}
