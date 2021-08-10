terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "CHANGE_ME!"

    workspaces {
      name = "tf-masterclass-demo"
    }
  }
}

provider "aws" {
  region = var.region
}
