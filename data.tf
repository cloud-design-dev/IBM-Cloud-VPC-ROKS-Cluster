
data "ibm_resource_group" "group" {
  count = var.resource_group != "" ? 1 : 0
  name  = var.resource_group
}

data "ibm_is_ssh_key" "regional_ssh_key" {
  name = var.ssh_key
}

#data "ibm_is_image" "default" {
#   name = var.os_image
# }

data "ibm_is_zones" "mzr" {
  region = var.region
}



