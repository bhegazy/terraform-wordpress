provider "aws" {
	region = "us-east-1"
}

data "aws_availability_zones" "az" {}

variable "nginx_port" {
  description = "The port the server will use for HTTP requests"
  default = 80
}

variable "instance_type" {
  default = "t2.micro"
}

variable "num_servers" {
  default = 1
}

variable "environment" {
  default = "dev"
}

variable "app_name" {
  default = "hello"
}

variable "ssh_key" {
  default = "test"
}

resource "aws_key_pair" "bhegazy" {
  key_name   = "${var.app_name}-${var.environment}"
  public_key = "${var.ssh_key}"
}

resource "aws_security_group" "main-sg" {
  name = "${var.app_name}-${var.environment}-instance-sg"

  ingress {
    from_port = "${var.nginx_port}"
    to_port = "${var.nginx_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elb-sg" {
  name = "${var.app_name}-${var.environment}-elb-sg"
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bhegazy" {
  count = "${var.num_servers}"
  ami = "ami-772aa961"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = ["${aws_security_group.main-sg.id}"]
  key_name = "${aws_key_pair.bhegazy.key_name}"
  tags {
    Name = "${var.app_name}-${var.environment}"
    Environment = "${var.environment}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "bhegazy" {
  name = "${var.app_name}-${var.environment}"
  availability_zones = ["${data.aws_availability_zones.az.names}"]
  security_groups = ["${aws_security_group.elb-sg.id}"]
  instances = ["${aws_instance.bhegazy.*.id}"]
  health_check {
    target = "TCP:${var.nginx_port}"
    healthy_threshold = 5
    unhealthy_threshold = 5
    timeout = 6
    interval = 30
  }

  listener {
    lb_protocol = "http"
    lb_port = 80
    instance_port = "${var.nginx_port}"
    instance_protocol = "http"
  }
}

output "public_ip" {
  value = "${aws_instance.bhegazy.*.public_ip}"
}

output "elb_dns_name" {
  value = "${aws_elb.bhegazy.dns_name}"
}

