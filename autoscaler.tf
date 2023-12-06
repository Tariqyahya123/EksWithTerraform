data "aws_iam_policy_document" "cluster_auto_scaler_trust_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks-oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks-oidc.arn]
      type        = "Federated"
    }
  }
}




resource "aws_iam_policy" "cluster-auto-scaler-policy" {
  name = "cluster-auto-scaler-policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeScalingActivities",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": ["*"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
            ],
            "Resource": ["*"]
        }
    ]
})
}


resource "aws_iam_role" "cluster-auto-scaler-role" {
  assume_role_policy = data.aws_iam_policy_document.cluster_auto_scaler_trust_policy.json
  name               = "cluster-auto-scaler-role"
}


resource "aws_iam_role_policy_attachment" "cluster-auto-scaler-attack" {
  role       = aws_iam_role.cluster-auto-scaler-role.name
  policy_arn = aws_iam_policy.cluster-auto-scaler-policy.arn
}

output "auto-scaler-role-arn" {
  value = aws_iam_role.cluster-auto-scaler-role.arn
}
