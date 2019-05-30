provider "aws" {
  region  = "eu-west-2"
  version = "~> 2.11.0"
}

variable "pgname" {
  default = "mydb"
}

variable "pguser" {
  default = "suley"
}

variable "pgpass" {
  default = "popopopo"
}

data "aws_instance" "bastion" {
  instance_tags {
    Name = "bastionInstance"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "9.6.3"
  instance_class         = "db.t2.micro"
  name                   = "${var.pgname}"
  username               = "${var.pguser}"
  password               = "${var.pgpass}"
  #parameter_group_name   = "default.postgres9.6"
  db_subnet_group_name   = "${aws_db_subnet_group.main.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_tls.id}"]
  skip_final_snapshot    = true
  tags = {
   Name = "mydb"
 }
}

resource "aws_instance" "mess-bToEC2" {
  ami                    = "${data.aws_ami.packer.id}"
  instance_type          = "t2.micro"
  key_name               = "packer-key"
  subnet_id              = "${aws_subnet.main.id}"
  vpc_security_group_ids = ["${aws_security_group.security_allow_all.id}"]

  tags = {
    Name = "mess-bToEC2"
  }

  connection {
    // bastion
    bastion_host        = "${data.aws_instance.bastion.public_dns}"
    bastion_host_key    = "packer-key"
    bastion_private_key = "${file("~/.ssh/packer")}"
    bastion_user        = "ubuntu"

    // ursho
    type        = "ssh"
    user        = "ubuntu"
    host        = "${aws_instance.mess-bToEC2.private_ip}"
    private_key = "${file("~/.ssh/packer")}"
    timeout     = "30s"
  }

  provisioner "file" {
    source      = "./dbconf.json"
    destination = "/home/ubuntu/config/config.json"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl start ursho.service",
      "sudo systemctl enable ursho.service",
    ]
  }
}

data "aws_vpc" "main" {
  tags {
    Name = "vpcBastion"
  }
}

data "aws_ami" "packer" {
  most_recent = true
  owners      = ["self"]
  name_regex  = "packer"
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = "${data.aws_vpc.main.id}"
}



resource "aws_subnet" "main" {
  availability_zone = "eu-west-2a"
  vpc_id            = "${data.aws_vpc.main.id}"
  cidr_block        = "172.20.1.0/24"

  tags = {
    Name = "mainsubnet"
  }
}

resource "aws_subnet" "second" {
  availability_zone = "eu-west-2b"
  vpc_id            = "${data.aws_vpc.main.id}"
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
   vpc_id      = "${data.aws_vpc.main.id}"

  ingress {
    cidr_blocks = ["172.2.0.0/16"]
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

resource "aws_security_group" "security_allow_all" {
  name   = "security_allow_all"
  vpc_id = "${data.aws_vpc.main.id}"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["${data.aws_vpc.main.cidr_block}"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "init" {
  template = "${file("${path.module}/dbconf.json")}"

  vars = {
    hostDB = "${aws_db_instance.default.endpoint}"
    pguser = "${var.pguser}"
    pgpass = "${var.pgpass}"
    pgname = "${var.pgname}"
  }
}

data "aws_internet_gateway" "mess-ext-gateway" {
  filter {
    name   = "tag:Name"
    values = ["bastion-ext-gateway"]
  }
}

resource "aws_eip" "ip-test-env" {
  instance = "${aws_instance.mess-bToEC2.id}"
  vpc      = true
}

resource "aws_route_table" "route-table" {
  vpc_id = "${data.aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.aws_internet_gateway.mess-ext-gateway.id}"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.main.id}"
  route_table_id = "${aws_route_table.route-table.id}"
}
