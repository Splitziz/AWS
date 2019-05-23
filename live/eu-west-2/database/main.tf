provider "aws" {
  region  = "eu-west-2"
  version = "~> 2.11.0"
}

resource "aws_instance" "imageec2" {
  ami             = "ami-04508d1a5695f5a35"
  instance_type   = "t2.micro"
  key_name        = "menage"
  security_groups = ["${aws_security_group.allow_tls.id}"]
  subnet_id = "${aws_subnet.main.id}"
}

resource "aws_eip" "ip-test-env" {
  instance = "${aws_instance.imageec2.id}"
  vpc      = true
}

resource "aws_db_instance" "default" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "9.6.3"
  instance_class         = "db.t2.micro"
  name                   = "mydb"
  username               = "suley"
  password               = "popopopo"
  #parameter_group_name   = "default.postgres9.6"
  db_subnet_group_name   = "${aws_db_subnet_group.main.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_tls.id}"]
  skip_final_snapshot    = true
  tags = {
   Name = "mydb"
 }
}

resource "aws_vpc" "main" {
  cidr_block = "172.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "route-table" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gateway.id}"
  }
}

resource "aws_subnet" "main" {
  availability_zone = "eu-west-2a"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "172.20.1.0/24"

  tags = {
    Name = "mainsubnet"
  }
}

resource "aws_subnet" "second" {
  availability_zone = "eu-west-2b"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "172.20.2.0/24"

  tags = {
    Name = "secondsubnet"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = ["${aws_subnet.main.id}", "${aws_subnet.second.id}"]

  tags = {
    Name = "db subnet group"
  }
}

resource "aws_security_group" "allow_tls" {
   name        = "allow_tls"
   description = "Allow TLS inbound traffic"
   vpc_id      = "${aws_vpc.main.id}"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [
      "172.20.0.0/16"
    ]
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags = {
    Name = "allow_all"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.main.id}"
  route_table_id = "${aws_route_table.route-table.id}"
}
