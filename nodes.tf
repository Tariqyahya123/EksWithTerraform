resource "aws_iam_role" "eks-workers-role" {
  name = "eks-workers-role"

  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
})

  tags = {
    Name = "eks-workers-role"
  }
}


resource "aws_iam_role_policy_attachment" "eks-workers-node-policy-to-eks-workers-role" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.eks-workers-role.id
}



resource "aws_iam_role_policy_attachment" "eks-workers-CNI-policy-to-eks-workers-role" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.eks-workers-role.id
}

resource "aws_eks_node_group" "eks-worker-nodes" {
  cluster_name    = aws_eks_cluster.eks-cluster.name
  node_group_name = "worker-nodes"
  node_role_arn   = aws_iam_role.eks-workers-role.arn
  subnet_ids      = [aws_subnet.private-subnet-A.id, aws_subnet.private-subnet-B.id, aws_subnet.private-subnet-C.id]

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 3
  }

  update_config {
    max_unavailable = 1
  }


  capacity_type = "ON_DEMAND"
  instance_types = ["t3.small"]

  depends_on = [
    aws_iam_role_policy_attachment.eks-workers-node-policy-to-eks-workers-role,
    aws_iam_role_policy_attachment.eks-workers-CNI-policy-to-eks-workers-role,
    aws_iam_role_policy_attachment.eks-workers-ECR-policy-to-eks-workers-role,
  ]
}




resource "aws_iam_role_policy_attachment" "eks-workers-ECR-policy-to-eks-workers-role" {
  role       = aws_iam_role.eks-workers-role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" 
}

