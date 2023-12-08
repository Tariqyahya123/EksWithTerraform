# EksWithTerraform

click here to go directly to the deployment guide.


# Brief of the project and the choices made.

&ensp;

## Networking

- The workers node group was deployed on 3 subnets each in a seperate Availbility Zone to ensure the highest level of availbility.

- (DOUBLE CHECK THIS, CHECK OUT THE SECURITY GROUP OF THE WORKER NODES.) All the work nodes are deployed on private subnets which ensures that these nodes are only accessable privately from inside the VPC, which allows for better security. 

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

  
## Resiliency and scalability:

- (MAKE SURE THAT NODES ARE DEPLOYED TO ALL 3 SUBNETS AND AREN'T GROUPED UP) 3 Nodes are deployed each to its own subnet which means that each node is deployed in a seperate Availbility Zones, which allows for resiliency incase one of the Availbility Zones goes down. In this case the workload deployed on node that went down is migrated to the two other nodes.

- Auto scaling of the worker nodegroup from 3 to a maximum of 5 is done by utilizing the [Cluster Autoscaler Add-on](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md). This allows for automatic scaling out and scaling in based on the requirements of the workload.


&ensp;


## Cost Optimization:

- By utiziling the AWS Load Balancer Add-on and ingress resources, it allows for the deployed ALB load balancer to be used by multiple deployment instead of the default EKS behaviour which is that each deployment would have a seperate load balancer. This reduces cost significantly.



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
&ensp;
&ensp;
&ensp;



# Contents of the Terraform files:


## provider.tf

## vpc.tf

- Contains VPC resource and it's configuration

## 




# Deployment Guide for EKS with Configurations

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



# Test the autoscaling feature of the cluster.
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

Keep in mind the the scale down process takes sometime.

To scale down the cluster, reduce the replicas of the wordpress deployment to 1 using this command:

```bash
kubectl scale deployment wordpress --replicas=1
```


&ensp;
&ensp;


# Resource clean-up guide:
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
terraform destory
```
