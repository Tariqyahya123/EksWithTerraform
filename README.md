# EksWithTerraform


# Table of Contents

- [Introduction](#introduction)
- [Brief of the project and the choices made](#brief-of-the-project-and-the-choices-made)
- [Contents of the Terraform files](#contents-of-the-terraform-files)
- [Deployment Guide](#deployment-guide)
- [Test the autoscaling feature of the cluster](#test-the-autoscaling-feature-of-the-cluster)
- [Resource clean-up guide](#resource-clean-up-guide)


&ensp;

&ensp;


# Introduction

This project deploys an Amazon EKS (Elastic Kubernetes Service) cluster using Terraform. The configuration also includes the deployment of a bastion host, Cluster Autoscaler, and AWS Load Balancer Controller for efficient management.



&ensp;

&ensp;



# Brief of the project and the choices made


## Networking

- The workers node group was deployed on 3 subnets each in a seperate Availbility Zone to ensure the highest level of availbility.

- All the work nodes are deployed on private subnets which ensures that these nodes are only accessable privately from inside the VPC, which allows for better security. 

- The endpoint of the control plane can only be accessed private from inside the VPC cluster as well, furthermore the security group attached to the control plane only allows for communication from the bastion host, this also allows for better access control and security.

- There are also three public subnets, used for the bastion host and NAT Gateway. The bastion host is publicly accessable.

- DNS hostname and DNS resolution were enabled since in the VPC it is a requirement by EKS.

- The workloads ran on the cluster are accessable through a public Ingress ALB which has been deployed by the help of the [AWS Load Balancer Add-on](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html). The AWS Load Balancer Controller is a tool designed to manage AWS Elastic Load Balancers (ELBs) for Kubernetes clusters. It simplifies the process of integrating Kubernetes Ingress controllers - which use layer 7 loadbalancing - with the AWS layer 7 loadbalancing offering (ALB - Application load balancer)

- The use of AWS Load Balancer Add-on allows for easier routing through information present in the request itself.

&ensp;


## Security

- AWS recommended IAM Roles were used to adhere to the least privilege security principle.

- Public ip's were only allowed for bastion host and Ingress Load-balancer since public access is crucial for these components.

- OIDC provider is used to grant roles to service accounts belonging the AWS Load Balancer Add-on as well as the Cluster-Autoscaler-Add-on


&ensp;

&ensp;


  
## Resiliency and scalability:

- 3 Nodes are deployed each to its own subnet which means that each node is deployed in a seperate Availbility Zones, which allows for resiliency incase one of the Availbility Zones goes down. In this case the workload deployed on node that went down is migrated to the two other nodes.

- Auto scaling of the worker nodegroup from 3 to a maximum of 5 is done by utilizing the [Cluster Autoscaler Add-on](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md). This allows for automatic scaling out and scaling in based on the requirements of the workload.


&ensp;


## Cost Optimization:

- By utiziling the AWS Load Balancer Add-on and ingress resources, it allows for the deployed ALB load balancer to be used by multiple deployment instead of the default EKS behaviour which is that each deployment would have a seperate load balancer. This reduces cost significantly.

- Bastion host instance type is "t2.micro" which is free tier eligible and since bastion hosts don't require much resources, it is a perfect fit.



&ensp;


## Bastion Host:

- Bastion host is intialized using user-data that installs the following tools:

  - kubectl
  - awscli
  - helm


&ensp;

&ensp;

&ensp;

&ensp;



# Contents of the Terraform files


## provider.tf

- This Terraform configuration file specifies that it requires the AWS provider version 5.29.0 and sets the AWS region dynamically based on the variable (var.region).

## vpc.tf

- This Terraform configuration creates the VPC named "eks-vpc" with a specified CIDR block, default tenancy, DNS hostname support, and associated tags.

## subnets.tf


- This Terraform configuration creates the subnets in the VPC, defining private and public subnets across different availability zones. Each subnet is tagged with specific roles for internal and external load balancing.

- Private Subnets (A, B, C):

    - Associated with the VPC.
    - Configured with specified CIDR blocks and availability zones.
    - Tagged with the name and role for internal Elastic Load Balancers (ELB).


- Public Subnets (A, B, C):

    - Associated with the same VPC, CIDR blocks, and availability zones.
    - Configured to map public IPs on launch.
    - Tagged with the name and role for external Elastic Load Balancers (ELB).

## routes.tf

- This Terraform configuration defines route tables and associations for private and public subnets in the VPC.

- Private Route Table (private-rt):

    - Associated with the VPC.
    - Has a default route to a NAT gateway for internet access.
    - Tagged with the name "private-rt."

- Public Route Table (public-rt):

    - Associated with the same VPC.
    - Has a default route to an internet gateway for public access.
    - Tagged with the name "public-rt."
    
- Route Table Associations:

    - Associates each private and public subnet with its corresponding route table.
    - Ensures proper routing for the private and public subnets in different availability zones.


## nat.tf


- This Terraform configuration creates an Elastic IP (EIP) and the NAT Gateway.

- Elastic IP (EIP):

    - Associated with the "vpc" domain.
    - Tagged with the name "nat-eip."
  
- NAT Gateway:

    - Uses the EIP created above.
    - Associated with the public subnet "public-subnet-A."
    - Tagged with the name "eks-nat."
    - Depends on the existence of the Internet Gateway "eks-igw" (waits for it to be created before creating the NAT Gateway).


## igw.tf

- This Terraform configuration creates an Internet Gateway (IGW):

- Internet Gateway (IGW):
    - Associated with the VPC.
    - Tagged with the name "eks-internet-gateway."

## eks.tf 

- This Terraform configuration sets up the EKS (Elastic Kubernetes Service) cluster along with related resources:

- IAM Role:

   -  Named "eks-role."
    - Has a policy attachment for "Amazon EKS Cluster" Policy.
    - Tagged with the name "eks-role."

- Security Group:

    - Named "allow_bastion_host_traffic_to_eks_api_server."
    - Allows TLS inbound traffic from the bastion host.
    - Allows all outbound traffic.

  
- EKS Cluster:

    - Named based on the variable "eks-cluster-name."
    - Uses the IAM role "eks-role."
    - Deployed in the VPC, allowing only private access to the EKS API server.
    - Security group configured to allow traffic from the "allow_bastion_host_traffic_to_eks_api_server" security group.


## nodes.tf 

- This Terraform configuration sets up the EKS worker node group:

- IAM Role for Worker Nodes:

    - Named "eks-workers-role."
    - Allows EC2 service to assume the role.
    - Tagged with the name "eks-workers-role."


- IAM Role Policy Attachments:

    - Attached policies for "Amazon EKS Worker Node" Policy, "Amazon EKS CNI" Policy, and "Amazon ECR ReadOnly" Policy.


- EKS Node Group for Worker Nodes:

    - Associated with the EKS cluster "eks-cluster."
    - Named "worker-nodes."
    - Uses the IAM role "eks-workers-role."
    - Deployed in private subnets A, B, and C.
    - Configured with desired, max, and min sizes for scaling.
    - Uses "t3.small" instance types with "ON_DEMAND" capacity type.
    - Depends on the IAM role policy attachments.
 
  
This configuration deploys and manages worker nodes for an EKS cluster, ensuring they have the necessary IAM roles and policies attached.


## iam-oidc.tf


- This Terraform configuration Creates an OpenID Connect (OIDC) provider:

    - Uses the data "tls_certificate" block to retrieve the TLS certificate information from the OIDC issuer URL of the EKS cluster.
    - Uses resource "aws_iam_openid_connect_provider" block.
    - The provider's URL is set to the OIDC issuer URL of the EKS cluster.
    - Specifies a client ID list, with "sts.amazonaws.com" included.
    - Sets the thumbprint list using the SHA-1 fingerprint of the TLS certificate obtained from the OIDC issuer.


- In summary, this configuration establishes an OIDC provider in IAM, linking it to the EKS cluster's OIDC issuer URL and configuring necessary details for authentication and authorization.


## bastionhost.tf

- This is what bastionhost.tf does:

    - Uses the data "aws_ami" block to fetch the latest Ubuntu Amazon Machine Image (AMI) owned by "amazon" with a specified name.
    - Creates an EC2 instance as a bastion host using the resource "aws_instance" block.
    - Specifies the AMI using the data source result.
    - Sets the instance type, subnet, and associates a public IP address.
    - Defines a user data script to install kubectl, awscli, and Helm on the bastion host.
    - Associates the instance with a security group allowing SSH traffic.
    - Tags the instance with the name "bastion-host."
    - Creates a security group named "allow_ssh_bastion" using the resource "aws_security_group" block.
    - Allows inbound SSH traffic from anywhere and unrestricted outbound traffic.


## autoscaler.tf

- This Terraform configuration:

    - Defines the data "aws_iam_policy_document" block to create a trust policy for the IAM role assumed by the Cluster Auto Scaler Add-on.
    - Specifies conditions for assuming the role based on the OpenID Connect (OIDC) provider's URL and the service account within the Kubernetes cluster.
    - Creates the resource "aws_iam_policy" block to define the Cluster Auto Scaler's IAM policy, allowing specific actions on Auto Scaling Groups and EC2 instances.
    - Sets up the resource "aws_iam_role" block for the IAM role named "cluster-auto-scaler-role," using the trust policy from the data block.
    - Attaches the IAM policy to the IAM role using the resource "aws_iam_role_policy_attachment" block, linking the "cluster-auto-scaler-role" with the defined policy.


- This configuration establishes an IAM role and policy for the Cluster Auto Scaler, enabling it to perform designated actions on the Worker Nodes Auto Scaling Group and Nodes themself.

## ingress.tf


- This Terraform configuration:

    - Utilizes the data "aws_iam_policy_document" block to create a trust policy for the IAM role assumed by the AWS Load Balancer Controller Add-on.
    - Defines conditions for assuming the role based on the OpenID Connect (OIDC) provider's URL, ensuring it matches the service account within the Kubernetes cluster and the expected audience.
    - Creates the resource "aws_iam_policy" block, specifying the IAM policy named "eks-ingress-policy," granting permissions for various AWS services related to load balancing.
    - Establishes the resource "aws_iam_role" block for the IAM role named "eks-ingress-role," incorporating the trust policy from the data block.
    - Attaches the IAM policy to the IAM role through the resource "aws_iam_role_policy_attachment" block, linking the "eks-ingress-role" with the defined policy.


- This configuration sets up an IAM role and policy for the AWS Load Balancer Controller, allowing it to perform actions related to creating and managing Elastic Load Balancers (ELBs).


## variables.tf


- This terraform configuration contains definition of these Terraform variables:

    - region: Represents the AWS region where resources will be created. It is of type string.
    
    - availability_zones: A list of availability zones for resource distribution. It is of type list of strings.
    
    - public_subnet_cidr_blocks: Defines the CIDR blocks for the public subnets. It is of type list of strings.
    
    - private_subnet_cidr_blocks: Specifies the CIDR blocks for the private subnets. It is of type list of strings.
    
    - vpc_cidr_block: Represents the CIDR block for the Virtual Private Cloud (VPC). It is of type string.
    
    - eks-cluster-name: Denotes the name of the Amazon EKS (Elastic Kubernetes Service) cluster. It is of type string.
    
    - bastion_ami_name: Represents the name of the Amazon Machine Image (AMI) used for the bastion host. It is of type string.
    
    - bastion_instance_type: Specifies the instance type for the bastion host. It is of type string.

- These variables provide flexibility and customization options when deploying infrastructure using Terraform. Users can input values for these variables to tailor the configuration to their specific requirements, such as defining the AWS region, subnet CIDR blocks, EKS cluster name, and characteristics of the bastion host.


## terraform.tfvars


- This Terraform file contains the values for the variables defined in variables.tf, this is where the default values for the variables are set and they can be changed by editing this file.

- There are the default values for the variables: 

    - Sets the AWS region to "eu-west-3."
    - Specifies a list of availability zones, including "eu-west-3a," "eu-west-3b," and "eu-west-3c."
    - Defines the CIDR block for the Virtual Private Cloud (VPC) as "10.0.0.0/16."
    - Provides CIDR blocks for public subnets: "10.0.21.0/24," "10.0.22.0/24," and "10.0.23.0/24."
    - Specifies CIDR blocks for private subnets: "10.0.1.0/24," "10.0.2.0/24," and "10.0.3.0/24."
    - Sets the name of the EKS cluster to "eks-cluster."
    - Defines the AMI name for the bastion host using a wildcard pattern for Ubuntu 22.04 AMIs.
    - Specifies the instance type for the bastion host as "t2.micro."

    
- In summary, this configuration creates a VPC with public and private subnets distributed across different availability zones in the "eu-west-3" region. It also sets up an EKS cluster named "eks-cluster" and defines a bastion host with specific AMI and instance type settings.


## outputs.tf


- This Terraform output configuration:

    - Provides an output named "eks-ingress-role-arn" with the description "This is the IAM Role to be used for the ingress controller add-on." It returns the Amazon Resource Name (ARN) of the IAM role created for the ingress controller. The value is obtained from the aws_iam_role.ingress-eks-role.arn.
    
    - Includes an output named "auto-scaler-role-arn" with the description "This is the IAM Role to be used for Cluster Autoscaler add-on." It returns the ARN of the IAM role created for the Cluster Autoscaler. The value is fetched from aws_iam_role.cluster-auto-scaler-role.arn.
    
    - Defines an output named "instance_public_ip" providing the description "Public IP address of the EC2 instance." It retrieves the public IP address of the bastion host (EC2 instance) from aws_instance.bastion-host.public_ip.

- In summary, these outputs expose key information such as IAM role ARNs for the add-ons (AWS Load Balancer Controller and Cluster Autoscaler) and the public IP address of the EC2 instance (bastion host) for reference or further use.


&ensp;

&ensp;

&ensp;
&ensp;
&ensp;
&ensp;


# Deployment Guide

Follow these steps to deploy EKS with pre-configured settings.

&ensp;
&ensp;



## Prerequisites:

- Make sure you have Terraform installed.

- Have an AWS keypair already created, since an existing keypair will be needed in step 3.

- Requirments like helm, kubectl and aws cli which will be needed in the bastion host, will be auto installed on the bastion host using aws user-data.

&ensp;
&ensp;



## Step 0: Configure your AWS credentials.



&ensp;




## Step 1: Clone the Git Repository

```bash
git clone https://github.com/tariqyahya123/EksWithTerraform.git
```
&ensp;

## (OPTIONAL) Step 2: Change default region and Availability Zones.

EksWithTerraform/terraform.tfvars contains the variables used for the deployment.

Im using region eu-west-3 by default but you can change it to whichever region you like or use my default values.

If you happen to change the region make sure you change the Availbility zones as well.

&ensp;

## Step 3: Set the keypair to be used by bastion host.

Make sure you have an already existing keypair in your aws account, since this terraform code will not create a key pair. It will use an already existing keypair from your account.

Replace "PLACEHOLDER" in line 22 in EksWithTerraform/bastionhost.tf with the name of your key pair.

Use this sed command to help you if you wish.

```bash
cd EksWithTerraform
sed -i 's/key_name = "PLACEHOLDER"/key_name = "ENTER THE NAME OF YOUR KEY PAIR HERE"/g' bastionhost.tf
```
&ensp;

## Step 4: Apply the terraform code.
```bash
terraform init
terraform apply
```
&ensp;

## Step 5: Note the auto-scaler-role-arn, eks-ingress-role-arn and bastion host public ip which will be used to deploy required addons.

Here is an example of how the stdout output will look like after terraform has been applied.
```bash

Apply complete! Resources: 36 added, 0 changed, 0 destroyed.

Outputs:

auto-scaler-role-arn = "arn:aws:iam::YOUR-ACCOUNT-ID:role/cluster-auto-scaler-role"
eks-ingress-role-arn = "arn:aws:iam::YOUR-ACCOUNT-ID:role/eks-ingress-role"
instance_public_ip = "161.131.158.179"
```

In this example the data to note is: 

- arn:aws:iam::YOUR-ACCOUNT-ID:role/cluster-auto-scaler-role

- arn:aws:iam::YOUR-ACCOUNT-ID:role/eks-ingress-role

- 161.131.158.179

These are values required later.

&ensp;
&ensp;

Use this command to output the required data to a file called output.txt

```bash
terraform output | grep -E "auto-scaler-role-arn|eks-ingress-role-arn|instance_public_ip" | awk -F" = " '{gsub(/"/, "", $2); print $2}' > output.txt
```



&ensp;

## Step 6: Log in to the bastion host using the public ip noted in step 5.

&ensp;


- The username for the bastion host is: ubuntu


&ensp;
&ensp;
## Step 7: Configure your AWS credentials on the bastion host and pull the kube-config file.

Use this command to pull the kubeconfig file.


```bash
aws eks update-kubeconfig --region eu-west-3 --name eks-cluster
```

If you made changes to the region and cluster name variables in the EksWithTerraform/terraform.tfvars file, then adjust the above commands to your needs.

&ensp;

## Step 8: Pull this repository to the bastion host.

```bash
git clone https://github.com/tariqyahya123/EksWithTerraform.git
```

&ensp;



## Step 9: Deploy the eks-auto-scaler helm chart.

Execute the following helm command, replace the value of auto-scaler-role-arn from step 5 in place of "ROLE_ARN_HERE"

```bash
cd EksWithTerraform

helm upgrade -i eks-auto-scaler ./K8s-deployment-files/eks-auto-scaler \
  -n kube-system \
  --set autoScalerRoleArn=$ROLE_ARN_HERE
```

&ensp;

## Step 10: Deploy the aws-load-balancer-controller helm chart.

Execute this helm command, enter the value of the eks-ingress-role noted from step 5 in place of "ROLE_ARN_HERE"

```bash
helm upgrade -i aws-load-balancer-controller ./K8s-deployment-files/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eks-cluster \
  --set serviceAccount.annotations.eks\\.amazonaws\\.com\\/role-arn=$ROLE_ARN_HERE \
  --set serviceAccount.name=aws-load-balancer-controller 
```

&ensp;

## Step 11: Deploy the wordpress helm chart.

Execute the following helm command.

```bash
helm upgrade -i wordpress ./K8s-deployment-files/wordpress-deployment -n default
```


If you get the following error wait and retry the above command again in 10 seconds.
```console
Error: Internal error occurred: failed calling webhook "mservice.elbv2.k8s.aws": failed to call webhook: Post "https://aws-load-balancer-webhook-service.kube-system.svc:443/mutate-v1-service?timeout=10s": dial tcp 10.0.80.69:9443: connect: connection refused
```
&ensp;


## Step 12: Make sure your ingress load balancer has been provisioned successfuly.

This is a bash command that will repeatedly check the status of your ingress load balancer untill it is active and ready to recieve traffic.

```bash
while true; do
    status=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?starts_with(LoadBalancerName, 'k8s')].State.Code" --output text --region eu-west-3)  # Replace with your actual command
   if [ -z "$status" ]; then
        echo "No ingress loadbalancer found."
        break # Exit the loop if loadbalancer doesn't exist
    elif [ "$status" = "active" ]; then
        echo "Ingress loadbalancer is active!"
        break  # Exit the loop when the output is "active"
    fi
    echo "Still provisioning"
    sleep 1  # Add a delay to avoid constant checking
done
```
&ensp;

Expected output:
```console
Still provisioning
Still provisioning
Still provisioning
Still provisioning
Still provisioning
Still provisioning
Still provisioning
Still provisioning
Still provisioning
Ingress loadbalancer is active!
```


Make sure region value is adjusted to your requirement if the default region values in the EksWithTerraform/terraform.tfvars were changed.

&ensp;

## Step 13: Get the dns name of the ingress-loadbalancer and use it to access wordpress.


Execute the following kubectl command to get the dns name of the ingress loadbalancer.

Give it a few seconds after Step 11 was executed.

```bash
hostname=$(kubectl get ingress wordpress-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

if [ -n "$hostname" ]; then
    result="http://$hostname"
    echo -e "\n\n$result"
else
    echo "Hostname is empty"
fi
```

Example output:
```console
http://k8s-publicloadbalance-1b5f5a824e-999999999.eu-west-3.elb.amazonaws.com
```
&ensp;

&ensp;

&ensp;

&ensp;



# Test the autoscaling feature of the cluster
&ensp;
&ensp;
## Step 1: Scale out the wordpress deployment to 50 replicas.

```bash
kubectl scale deployment wordpress --replicas=50
```
&ensp;
Expected output:
```console
deployment.apps/wordpress scaled
```
&ensp;

## Step 2: Watch the nodes scale out from 3 nodes to 5 nodes.

```bash
kubectl get nodes --watch
```

&ensp;

## How the scale in process works:

The cluster automatically scales down when the number of replicas can be accomodated by 3 nodes.

Keep in mind the the scale down process takes some time.

To scale down the cluster, reduce the replicas of the wordpress deployment to 1 using this command:

```bash
kubectl scale deployment wordpress --replicas=1
```


&ensp;

&ensp;

&ensp;

&ensp;



# Resource clean-up guide
&ensp;


## Step 1: Uninstall all helm charts:

Execute this command from the bastion host.

```bash
helm uninstall wordpress

helm uninstall aws-load-balancer-controller -n kube-system

helm uninstall eks-auto-scaler -n kube-system
```

&ensp;


## Step 2: Terraform Destroy:

Execute this command from the machine where terraform apply was done earlier and make you are in the EksWithTerraform directory.


```bash
terraform destroy
```
