terraform {
  required_version = "~> 1.9.6"

  backend "s3" {
    bucket = "requis-backend-terraform-state"
    key    = "state"
    region = "us-west-1"
    dynamodb_table = "requis-backend-terraform-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7"
    }
  }
}

provider "aws" {
  region  = "us-west-1"

  default_tags {
    tags = {
      Terraform  = "true"
      Repository = "https://github.com/RequisDev/requis_backend_umbrella/"
    }
  }
}