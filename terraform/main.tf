provider "aws" {
	region = "us-east-1"
}

data "aws_availability_zones" "az" {}

variable "nginx_port" {
  description = "The port the server will use for HTTP requests"
  default = 8080
}

variable "instance_type" {
  default = "t2.micro"
}

variable "size" {
  default = 1
}

resource "aws_key_pair" "bhegazy" {
  key_name   = "bhegazy-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDXFxpJFAXb8e3U7QnfPc7GdbXX9LzWDhrTo4Vh9O4z2yJyDKgmS3Ffj1yyHZ8Fw8frI5D9emdN7ZEgANUNx6aDJCTFNZb0AqF/3QwkezApzLixYfwh4wv7oDqcmSXho9JFB7GhYH3B8CjEEf+GW1qoXoStfSYDyozlhcJy1jekWmQF3tY4VSiMNV+yiSIu6iBHGYjVgLidQpDxmZOnkikc85lkQ1RcZ9NLoCdvSUSAL4dLsgvDlxwStPARWP/QW1W5+i7h9Y+saN5L35vbkAadwrENx+KTp2pfgnoAZMO/I8iESu7a/4zL/EpATvFDBcH+CZLEPHvyzQizQwfrT74vaYXGNq+r5eoFYQdpHaHtKbb5stFWAjVwfcTndNnCLlGdIefbrTcusrcSAD6t3e+iO9G4pebAQtkSNesKhs8cZaOGaXb2UxkAUV/YwOG9a8RHTs2Nz4oaPRFxQAinip5/N/FH+PVwoglZmPaGVhGgI7t0Mumvr7JJ2bHzGCD8stiMvpbIfMnVomoYeTEWnyDQNNu7r9mwy6Sy7R/j02w18QOZ71r/rR9cDxwrOFoHjmZJ7gvd06hBRhH/JarbCQpPanGcjP4NeI46PIA0ujvv4yCriL/ffYL/AZzLs8vqzoQdlwk7I9T9NrwL2M5LQiBnUBFOvEYzvAjcqiLqEdOqTw=="
}

resource "aws_security_group" "main-sg" {
  name = "bhegazy-instance-sg"

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
  name = "bhegazy-elb-sg"
  
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
  count = "${var.size}"
  ami = "ami-772aa961"
  instance_type = "${var.instance_type}"
  vpc_security_group_ids = ["${aws_security_group.main-sg.id}"]
  key_name = "${aws_key_pair.bhegazy.key_name}"
  tags {
    Name = "bhegazy"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "bhegazy" {
  name = "bhegazy"
  availability_zones = ["${data.aws_availability_zones.az.names}"]
  security_groups = ["${aws_security_group.elb-sg.id}"]

  health_check {
    target = "HTTP:${var.nginx_port}/"
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


