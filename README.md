# EksWithTerraform


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

## Step 9: Deploy the aws-load-balancer-controller helm chart.

Execute this helm command, enter the value of the eks-ingress-role noted from step 5 in place of "ROLE_ARN_HERE"

```bash
cd EksWithTerraform

helm upgrade -i aws-load-balancer-controller ./K8s-deployment-files/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eks-cluster \
  --set serviceAccount.annotations.eks\\.amazonaws\\.com\\/role-arn=$ROLE_ARN_HERE \
  --set serviceAccount.name=aws-load-balancer-controller 
```

&ensp;

## Step 10: Deploy the eks-auto-scaler helm chart.

Execute the following helm command, replace the value of auto-scaler-role-arn from step 5 in place of "ROLE_ARN_HERE"

```bash
helm upgrade -i eks-auto-scaler ./K8s-deployment-files/eks-auto-scaler \
  -n kube-system \
  --set autoScalerRoleArn=$ROLE_ARN_HERE
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
    echo $result
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

