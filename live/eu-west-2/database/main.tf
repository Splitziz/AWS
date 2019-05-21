provider "aws" {
  region  = "eu-west-2"
  version = "~> 2.11.0"
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = "${aws_db_subnet_group.main.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_tls.id}"]
  skip_final_snapshot  = true
  tags = {
   Name = "mydb"
 }
}

resource "aws_vpc" "main" {
  cidr_block = "172.20.0.0/16"
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

   tags = {
    Name = "allow_all"
  }
}
