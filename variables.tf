variable "region" {
  description = "The AWS region where resources will be created."
  type = string
}

variable "availability_zones" {
  type = list(string)
  description = "A list of availability zones for resource distribution."
}

variable "public_subnet_cidr_blocks" {
  type = list(string)
  description = "The CIDR blocks for the public subnets."
}


variable "private_subnet_cidr_blocks" {
  type = list(string)
  description = "The CIDR blocks for the private subnets."
}

variable "vpc_cidr_block" {
  type = string
  description = "The CIDR block for the VPC."
}



variable "eks-cluster-name" {
  type = string
  description = "This is the name of the eks cluster"
}

variable "bastion_ami_name" {
  type = string
  description = "This is the AMI name for the bastion host."
}


variable "bastion_instance_type" {
  type = string
  description = "This is the instance type for the bastion host."
}