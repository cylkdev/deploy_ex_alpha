provider "aws" {
  region  = "us-west-1"

  default_tags {
    tags = {
      Region = "us-west-1"
      Repository = "https://github.com/RequisDev/requis_backend_umbrella/"
    }
  }
}

provider "corefunc" {
  # Configuration options
}