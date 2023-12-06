terraform {
    required_providers {
        aws = {
        source = "hashicorp/aws"
        version = "5.29.0"
        }
    }
}
provider "aws" {
   # region = var.aws_region
   region = var.region
}
