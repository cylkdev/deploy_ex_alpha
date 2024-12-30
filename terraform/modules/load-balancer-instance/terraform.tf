terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7"
    }

    corefunc = {
      source = "northwood-labs/corefunc"
      version = "1.5.1"
    }
  }
}