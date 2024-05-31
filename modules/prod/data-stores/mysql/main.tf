provider "aws" { 
    region = "us-east-1"
}
resource "aws_db_instance" "example" {
    identifier_prefix   = "up-and-running-prod"
    engine              = "mysql"
    allocated_storage   = 10
    instance_class      = "db.t3.micro"
    skip_final_snapshot = true
    db_name             = "example_database"
    # How should we set the username and password?
    username            = var.db_username
    password            = var.db_password

    tags = {
        Environment = "prod"
        Department  = "main"
    }
}
# !!!!!!!!!!!!!!!How to set the username and password?!!!!!!!!!!!!!!!!
# export TF_VAR_db_username="(YOUR_DB_USERNAME)"
# export TF_VAR_db_password="(YOUR_DB_PASSWORD)"

terraform {
    backend "s3" {
      bucket = "funny-terraform-bucket"
      key    = "prod/data-stores/mysql/terraform.tfstate"
      region = "us-east-1"
      # Replace this with your DynamoDB table name!
      dynamodb_table = "funny-terraform-bucket-locks"
      encrypt = true 
   }
}

