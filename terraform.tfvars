
region = "eu-west-3"

availability_zones = [
  "eu-west-3a",
  "eu-west-3b",
  "eu-west-3c"
]



vpc_cidr_block = "10.0.0.0/16"


public_subnet_cidr_blocks = [
  "10.0.21.0/24",
  "10.0.22.0/24",
  "10.0.23.0/24"
]

private_subnet_cidr_blocks = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]

eks-cluster-name = "eks-cluster"

bastion_ami_name = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-*"


bastion_instance_type = "t2.micro"
