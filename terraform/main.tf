provider "aws" {
    region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "pythonwebapptfstate"
    key            = "myapp/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-lock-table"
  }
}