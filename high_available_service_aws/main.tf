provider "aws" {
  region = var.aws_region
}


data "aws_availability_zones" "available" {}
data "aws_ami" "latest_amazon_linux" {
  owners      = ["137112412989"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
}

resource "aws_default_vpc" "default" {} # This is required since AWS provider v3.29+ to get default VPC id

//Security Group
resource "aws_security_group" "web_service" {
  name   = "SG for web service"
  vpc_id = aws_default_vpc.default.id
  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.default_tags, {
    Name = "Security Group of web service"
  })
}

//Launch configuration for Auto Scaling Group
resource "aws_launch_configuration" "web_service" {
  name_prefix     = "LC-WebService-"
  image_id        = data.aws_ami.latest_amazon_linux.id
  instance_type   = var.default_instance_type
  security_groups = [aws_security_group.web_service.id]
  user_data       = file("user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

//Auto Scaling Group
resource "aws_autoscaling_group" "web_service" {
  name                 = "ASG-WebService"
  launch_configuration = aws_launch_configuration.web_service.name
  min_size             = 3
  max_size             = 3
  min_elb_capacity     = 3
  health_check_type    = "ELB"
  vpc_zone_identifier  = [aws_default_subnet.default_subnet1.id, aws_default_subnet.default_subnet2.id]
  load_balancers       = [aws_elb.web_service.name]

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_launch_configuration.web_service
  ]
}

//Elastic Load Balancer
resource "aws_elb" "web_service" {
  name               = "ELB-WebService"
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  security_groups    = [aws_security_group.web_service.id]
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }
}

resource "aws_default_subnet" "default_subnet1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_default_subnet" "default_subnet2" {
  availability_zone = data.aws_availability_zones.available.names[1]
}
