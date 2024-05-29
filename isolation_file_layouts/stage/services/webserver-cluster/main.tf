provider "aws" {
  region = "us-east-1"
}

resource "aws_launch_template" "example" {
  name_prefix   = "example-"
  image_id      = "ami-0bb84b8ffd87024d8"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

#  User data before moving into user-data.sh 
#  user_data = base64encode(<<-EOF
#    #!/bin/bash
#    yum update -y
#    yum install -y httpd
#    systemctl start httpd
#    systemctl enable httpd
#    echo "Hello, world!" > /var/www/html/index.html
#    echo "${data.terraform_remote_state.db.outputs.address}" >> /var/www/html/index.html
#    echo "${data.terraform_remote_state.db.outputs.port}" >> /var/www/html/index.html
#    EOF
#  )
# Render the User Data script as a template
  user_data = base64encode(templatefile("user-data.sh", {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  })
)

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "example" {
  desired_capacity     = 2
  min_size             = 2
  max_size             = 10
  vpc_zone_identifier  = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance" {
  name = var.instance_security_group_name

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_lb" "example" {
  name               = var.alb_name
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "asg" {
  name     = var.alb_name
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_security_group" "alb" {
  name = var.alb_security_group_name

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "terraform_remote_state" "db" {
    backend = "s3"
    config = {
      bucket = "funny-terraform-bucket"
      key    = "stage/data-stores/mysql/terraform.tfstate"
      region = "us-east-1"
  } 
}
