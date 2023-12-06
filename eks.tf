resource "aws_iam_role" "eks-role" {
  name = "eks-role"

  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
})

  tags = {
    Name = "eks-role"
  }
}


resource "aws_iam_role_policy_attachment" "eks-policy-to-eks-role" {
  policy_arn       = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks-role.id
}


resource "aws_security_group" "allow_bastion_host_traffic_to_eks_api_server" {
  name        = "allow_bastion_to_eks"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.eks-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups  = [aws_security_group.allow_ssh_bastion.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}




resource "aws_eks_cluster" "eks-cluster" {
  name     = var.eks-cluster-name
  role_arn = aws_iam_role.eks-role.arn

  vpc_config {
    subnet_ids = [
        aws_subnet.private-subnet-A.id,
        aws_subnet.private-subnet-B.id,
        aws_subnet.private-subnet-C.id
        
        ]


        endpoint_public_access = false

        endpoint_private_access = true

        security_group_ids = [aws_security_group.allow_bastion_host_traffic_to_eks_api_server.id]
  }



  depends_on = [
    aws_iam_role_policy_attachment.eks-policy-to-eks-role,

  ]
}



