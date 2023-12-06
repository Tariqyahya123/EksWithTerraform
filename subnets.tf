resource "aws_subnet" "private-subnet-A" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = var.private_subnet_cidr_blocks[0]
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "private-subnet-A",
    "kubernetes.io/role/internal-elb" = 1

  }
}

resource "aws_subnet" "private-subnet-B" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = var.private_subnet_cidr_blocks[1]
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "private-subnet-B",
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_subnet" "private-subnet-C" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = var.private_subnet_cidr_blocks[2]
  availability_zone = var.availability_zones[2]

  tags = {
    Name = "private-subnet-C",
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_subnet" "public-subnet-A" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = var.public_subnet_cidr_blocks[0]
  availability_zone = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-A",
    "kubernetes.io/role/elb" = 1
    
  }
}

resource "aws_subnet" "public-subnet-B" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = var.public_subnet_cidr_blocks[1]
  availability_zone = var.availability_zones[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-B",
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_subnet" "public-subnet-C" {
    vpc_id     = aws_vpc.eks-vpc.id
    cidr_block = var.public_subnet_cidr_blocks[2]
    availability_zone = var.availability_zones[2]
    map_public_ip_on_launch = true

  
    tags = {
      Name = "public-subnet-C",
      "kubernetes.io/role/elb" = 1
    }
  }