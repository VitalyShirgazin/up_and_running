terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
  cluster_name           = "webservers-stage"
  db_remote_state_bucket = "funny-terraform-bucket"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
}

# Iif you needed to expose an extra port in just the staging environment (e.g., for testing), you can uncomment next block
#resource "aws_security_group_rule" "allow_testing_inbound" { 
#  type = "ingress"
# security_group_id =
#  module.webserver_cluster.alb_security_group_id
#  from_port   = 12345
#  to_port     = 12345
#  protocol    = "tcp"
#  cidr_blocks = ["0.0.0.0/0"]
#}
