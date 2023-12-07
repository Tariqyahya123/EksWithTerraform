output "eks-ingress-role-arn" {
  description = "This is the IAM Role to be used for the ingress controlle add-on"
  value = aws_iam_role.ingress-eks-role.arn
}



output "auto-scaler-role-arn" {
  description = "This is the IAM Role to be used for Cluster Autoscaler add-on"
  value = aws_iam_role.cluster-auto-scaler-role.arn
}


output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.bastion-host.public_ip
}