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
sed -i 's/key_name = "PLACEHOLDER"/key_name = "ENTER THE NAME OF YOUR KEY PAIR HERE"/g' yourfile.tf
```


## Step 2: Set the keypair to be used by bastion host.

