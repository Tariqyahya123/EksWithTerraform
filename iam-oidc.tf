data "tls_certificate" "eks-cert" {
  url = aws_eks_cluster.eks-cluster.identity[0].oidc[0].issuer
}


resource "aws_iam_openid_connect_provider" "eks-oidc" {
  url = aws_eks_cluster.eks-cluster.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [data.tls_certificate.eks-cert.certificates[0].sha1_fingerprint]
}