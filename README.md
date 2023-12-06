# EksWithTerraform


# Deployment Guide for EKS with Configurations

Follow these steps to deploy EKS with pre-configured settings.

## Step 1: Clone the Git Repository

```bash
git clone https://github.com/tariqyahya123/EksWithTerraform.git




markdown
Copy code
# Deployment Guide for EKS with Configurations

Follow these steps to deploy EKS with pre-configured settings.

## Step 1: Clone the Git Repository

```bash
git clone https://github.com/yourusername/eks-deployment.git
cd eks-deployment
Step 2: Configure Bastion Host
Enter the name of the key pair in the bastionhost file.

bash
Copy code
echo "your-key-pair-name" > bastionhost
Step 3: Terraform Apply
Navigate to the EksWithTerraform directory and execute the following command to apply Terraform configurations.

bash
Copy code
cd EksWithTerraform
terraform apply
Note: Capture the output of the terraform apply command, which contains the ARNs of the required IAM roles for the autoscaler and aws-load-balancer-controller addons.

Step 4: Install aws-load-balancer-controller Helm Chart
bash
Copy code
helm upgrade -i aws-load-balancer-controller ./K8s-deployment-file/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-cluster \
  --set serviceAccount.annotations.eks\\.amazonaws\\.com\\/role-arn=<ARN-of-eks-ingress-role> \
  --set serviceAccount.name=aws-load-balancer-controller
Replace <ARN-of-eks-ingress-role> with the ARN obtained from the Terraform output.

Step 5: Install eks-auto-scaler Helm Chart
bash
Copy code
helm upgrade -i eks-auto-scaler ./K8s-deployment-file/eks-auto-scaler \
  -n kube-system \
  --set autoScalerRoleArn=<ARN-of-cluster-auto-scaler-role>
Replace <ARN-of-cluster-auto-scaler-role> with the ARN obtained from the Terraform output.

Step 6: Install WordPress Helm Chart
bash
Copy code
helm upgrade -i wordpress ./K8s-deployment-file/wordpress-deployment -n default
Your EKS cluster with configured addons and applications is now deployed successfully. Access the WordPress application to start using your EKS environment.

csharp
Copy code

Feel free to copy and paste this directly into your README.md file on GitHub.
