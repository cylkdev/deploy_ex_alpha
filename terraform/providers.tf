terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7"
    }
  }

  required_version = "~> 1.9.6"
}

provider "aws" {
  region  = "us-west-1"
}
