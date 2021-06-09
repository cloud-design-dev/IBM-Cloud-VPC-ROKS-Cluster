variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API key to use for deploying all resources."
}

variable "region" {
  type        = string
  description = "The region where the VPC resources will be deployed."
  default     = ""
}

variable "ssh_key" {
  type        = string
  description = "(Optional) The name of an existing SSH Key that will be added to the w instances in the region. If none provided a key will be created and added to the instance"
  default     = ""
}

variable "resource_group" {
  type        = string
  description = "(Optional) The name of an existing Resource group to use for resources. If none provided a new one will be created and used for all resources."
  default     = ""
}

variable "name" {
  type        = string
  description = "Name that will be prepended to resources."
}

variable "tags" {
  type        = list(string)
  description = "A set of default tags to add to all resources."
  default     = []
}

variable "roks_version" {
  type        = string
  description = "Version of OpenShift to use for VPC cluster. To see available options run the command `ibmcloud oc versions`."
  default     = "4.6.28_openshift"
}

variable "owner" {
  type        = string
  description = "Identifier for the user that created the VPC and cluster. Example would be `ryantiffany`. This will then get added as the tag `owner:ryantiffany`."
}

variable "worker_flavor" {
  type        = string
  description = "(Optional) The instance size to use for worker nodes. If none provided it will default to `bx2.4x16` which is the minimum instance size for ROKS."
}

variable "enable_logging" {
  type        = bool
  description = "(Optional) Wether or not to create a LogDNA instance for cluster logs."
}

variable "enable_monitoring" {
  type        = bool
  description = "(Optional) Wether or not to create a Sysdig instance for cluster metrics."
  default     = false
}

variable "private_endpoint_only"
type = bool
description = "Wether or not to disable the public endpoint"
default = false
}
