resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.eks-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.eks-vpc-nat-gateway.id
  }



  tags = {
    Name = "private-rt"
  }
}



resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.eks-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-igw.id
  }



  tags = {
    Name = "public-rt"
  }
}


resource "aws_route_table_association" "private-subnet-A-association" {
  subnet_id      = aws_subnet.private-subnet-A.id
  route_table_id = aws_route_table.private-rt.id
}


resource "aws_route_table_association" "private-subnet-B-association" {
  subnet_id      = aws_subnet.private-subnet-B.id
  route_table_id = aws_route_table.private-rt.id
}


resource "aws_route_table_association" "private-subnet-C-association" {
  subnet_id      = aws_subnet.private-subnet-C.id
  route_table_id = aws_route_table.private-rt.id
}


resource "aws_route_table_association" "public-subnet-A-association" {
  subnet_id      = aws_subnet.public-subnet-A.id
  route_table_id = aws_route_table.public-rt.id
}


resource "aws_route_table_association" "public-subnet-B-association" {
  subnet_id      = aws_subnet.public-subnet-B.id
  route_table_id = aws_route_table.public-rt.id
}


resource "aws_route_table_association" "public-subnet-C-association" {
  subnet_id      = aws_subnet.public-subnet-C.id
  route_table_id = aws_route_table.public-rt.id
}