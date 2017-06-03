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

variable "min_size" {
  default = 1
}

resource "aws_security_group" "main-sg" {
  name = "bhegazy-instance-sg"

  ingress {
    from_port = "${var.nginx_port}"
    to_port = "${var.nginx_port}"
    protocol = "tcp"
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

resource "aws_launch_configuration" "bhegazy" {
  image_id = "ami-772aa961"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.main-sg.id}"]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bhegazy" {
  launch_configuration = "${aws_launch_configuration.bhegazy.id}"
  availability_zones = ["${data.aws_availability_zones.az.names}"]

  load_balancers = ["${aws_elb.bhegazy.name}"]

  min_size = "${var.min_size}"
  max_size = 10
  health_check_type = "ELB"
  
  tag {
    key = "Name"
    value = "bhegazy-asg"
    propagate_at_launch = true
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

