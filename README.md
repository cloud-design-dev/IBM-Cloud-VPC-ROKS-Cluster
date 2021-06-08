# IBM Cloud VPC ROKS Cluster
This repository will deploy the following:

 - An IBM Cloud [VPC](https://www.ibm.com/cloud/learn/vpc) 
 - A single zone [Public Gateways](https://cloud.ibm.com/docs/vpc?topic=vpc-about-networking-for-vpc#public-gateway-for-external-connectivity) for outbound connectivity.
 - A single zone [Subnet](https://cloud.ibm.com/docs/vpc?topic=vpc-about-networking-for-vpc#subnets-in-the-vpc) for the OpenShift worker nodes.
 - A single zone [Red Hat OpenShift (ROKS)](https://www.ibm.com/cloud/openshift) cluster. 
 - (Optional) A [LogDNA](https://cloud.ibm.com/docs/openshift?topic=openshift-health#openshift_logging) logging instance for the cluster.
 - (Optional) A [Sysdig](https://cloud.ibm.com/docs/openshift?topic=openshift-health-monitor) monitoring instance for the cluster. 

## Deploy Resources

### Option 1: Using local Terraform
1. Copy `terraform.tfvars.example` to `terraform.tfvars`:

   ```sh
   cp terraform.tfvars.example terraform.tfvars
   ```

1. Edit `terraform.tfvars` to match your environment. See [inputs](#inputs) for available options.
1. Plan deployment:

   ```sh
   terraform init
   terraform plan -out default.tfplan
   ```

1. Apply deployment:

   ```sh
   terraform apply default.tfplan
   ```
   
### Option 2: Using IBM Cloud Schematics
[Schematics](https://cloud.ibm.com/docs/schematics?topic=schematics-about-schematics) workspaces deliver Terraform-as-a-Service capabilities to you so that you can automate the provisioning and management of your IBM Cloud resources, and rapidly build, duplicate, and scale complex, multi-tier cloud environments. 

[![Deploy using Schematics](https://cloud.ibm.com/devops/setup/deploy/button_x2.png)](https://cloud.ibm.com/schematics/workspaces/create?repository=https://github.com/cloud-design-dev/IBM-Cloud-VPC-ROKS-Cluster.git&terraform_version=terraform_v0.14)

Since the `terraform.tfvars` file is not tracked by Github, you will need to make sure you update the variables in the created Schematics Workspace. The process is outlined in this [IBM Cloud Doc](https://cloud.ibm.com/docs/schematics?topic=schematics-workspace-setup#import-template).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ibmcloud\_api\_key | IBM Cloud API key to use for deploying resources. | `string` | n/a | yes |
| name | Name that will be prepended to all resources. | `string` | n/a | yes |
| region | Name of the IBM Cloud region where resources will be deployed. Run `ibmcloud is regions` to see available options. | `string` | n/a | yes |
| owner | Identifier for the user that created the VPC and cluster. | `string` | n/a | yes |
| ssh\_key | Name of an existing ssh key that will be added to the vpn instance. | `string` | n/a | yes |
| resource_group | The name of an existing Resource group to use. If none provided, a new one named `var.name-resource-group` will be created. | `string` | n/a | no | 
| enable\_logging | Wether or not to deploy an IBM Cloud Logging instance with the cluster. | `bool` | `false` | no |
| enable\_monitoring | Wether or not to deploy an IBM Cloud Monitoring instance with the cluster. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc | All exported attributes from the VPC | 
| subnets | All exported attributes from the VPC Subnets |
| cluster_details |  All exported attributes from the OpenShift cluster |
