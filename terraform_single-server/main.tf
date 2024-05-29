provider "aws" {
  region  = "us-east-1"
}

data "aws_security_group" "existing_sg" {
  name = "Luxembourg"
}

resource "aws_instance" "example" {
  ami           = "ami-0bb84b8ffd87024d8"
  instance_type = "t2.micro"
  key_name      = "tutorial"
  # Associate the existing security group with the instance
  vpc_security_group_ids = [data.aws_security_group.existing_sg.id]

  tags = {
    Name = "terraform-example"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello, world!" > /var/www/html/index.html
              EOF
}

output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}
