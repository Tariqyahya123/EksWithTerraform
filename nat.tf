resource "aws_eip" "nat" {
  domain   = "vpc"


    tags = {

        Name = "nat-eip"

    }


}


resource "aws_nat_gateway" "eks-vpc-nat-gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-subnet-A.id

  tags = {
    Name = "eks-nat"
  }


  depends_on = [aws_internet_gateway.eks-igw]
}