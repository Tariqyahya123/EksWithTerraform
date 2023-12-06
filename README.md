# EksWithTerraform


# Deployment Guide for EKS with Configurations

Follow these steps to deploy EKS with pre-configured settings.

## Step 0: Configure your AWS credentials.




## Step 1: Clone the Git Repository

```bash
git clone https://github.com/tariqyahya123/EksWithTerraform.git
```

## Step 2: Set the keypair to be used by bastion host.

Replace "PLACEHOLDER" in line 22 in EksWithTerraform/bastionhost.tf with the name of your key pair.

Use this sed command to help you if you wish.

```bash
cd EksWithTerraform
sed -i 's/key_name = "PLACEHOLDER"/key_name = "ENTER THE NAME OF YOUR KEY PAIR HERE"/g' bastionhost.tf
```


## Step 3: Apply the terraform code.
```bash
terraform apply
```


## Step 3: Note the auto-scaler-role-arn ,eks-ingress-role-arn and bastion host public ip which will be used to deploy required addons.

Here is an example of how the stdout output will look like after terraform has been applied.
```console

Apply complete! Resources: 36 added, 0 changed, 0 destroyed.

Outputs:

auto-scaler-role-arn = "```arn:aws:iam::411310121956:role/cluster-auto-scaler-role```"
eks-ingress-role-arn = "<mark>arn:aws:iam::411310121956:role/eks-ingress-role</mark>"
instance_public_ip = "<mark>161.131.158.179</mark>"
```


