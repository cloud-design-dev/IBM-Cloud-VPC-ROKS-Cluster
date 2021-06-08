resource "ibm_resource_group" "group" {
  count = var.resource_group != "" ? 0 : 1
  name  = "${var.name}-group"
  tags  = concat(var.tags, ["project:${var.name}", "region:${var.region}"])
}

locals {
  resource_group = var.resource_group != "" ? data.ibm_resource_group.group.0.id : ibm_resource_group.group.0.id
  worker_flavor  = var.worker_flavor != "" ? var.worker_flavor : "bx2.4x16"
}

module "vpc" {
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Module.git"
  name           = "${var.name}-vpc"
  resource_group = local.resource_group
  tags           = concat(var.tags, ["project:${var.name}", "region:${var.region}", "owner:${var.owner}", "vpc:${var.name}-vpc"])
}

module "public_gateway" {
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Public-Gateway-Module.git"
  name           = "${var.name}-${data.ibm_is_zones.mzr.zones[0]}-pubgw"
  zone           = data.ibm_is_zones.mzr.zones[0]
  vpc            = module.vpc.id
  resource_group = local.resource_group
  tags           = concat(var.tags, ["project:${var.name}", "region:${var.region}", "owner:${var.owner}", "vpc:${var.name}-vpc", "zone:${data.ibm_is_zones.mzr.zones[0]}"])
}

module "subnet" {
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Subnet-Module.git"
  name           = "${var.name}-${data.ibm_is_zones.mzr.zones[0]}-subnet"
  resource_group = local.resource_group
  address_count  = "32"
  vpc            = module.vpc.id
  zone           = data.ibm_is_zones.mzr.zones[0]
  public_gateway = module.public_gateway.id
  tags           = concat(var.tags, ["project:${var.name}", "region:${var.region}", "owner:${var.owner}", "vpc:${var.name}-vpc", "zone:${data.ibm_is_zones.mzr.zones[0]}"])
}

resource "ibm_resource_instance" "cos_instance" {
  depends_on = [module.subnet]
  name       = "${var.name}-cos-instance"
  service    = "cloud-object-storage"
  plan       = "standard"
  location   = "global"
  tags       = concat(var.tags, ["project:${var.name}", "owner:${var.owner}", "vpc:${var.name}-vpc"])
}

resource "ibm_container_vpc_cluster" "roks" {
  name                            = "${var.name}-roks-cluster"
  vpc_id                          = module.vpc.id
  kube_version                    = var.roks_version
  flavor                          = local.worker_flavor
  worker_count                    = "3"
  cos_instance_crn                = ibm_resource_instance.cos_instance.id
  disable_public_service_endpoint = true
  resource_group_id               = local.resource_group
  wait_till                       = "OneWorkerNodeReady"
  zones {
    subnet_id = module.subnet.id
    name      = data.ibm_is_zones.mzr.zones[0]
  }
  tags = concat(var.tags, ["project:${var.name}", "region:${var.region}", "vpc:${var.name}-vpc", "owner:${var.owner}"])

  timeouts {
    create = "60m"
    update = "60m"
  }
}

module "logging" {
  count          = var.enable_logging == true ? 0 : 1
  source         = "./logging"
  name           = var.name
  region         = var.region
  resource_group = local.resource_group
  cluster_id     = ibm_container_vpc_cluster.roks.id
  tags           = concat(var.tags, ["project:${var.name}", "region:${var.region}", "owner:${var.owner}"])
}

module "monitoring" {
  count          = var.enable_monitoring == true ? 0 : 1
  source         = "./monitoring"
  name           = var.name
  region         = var.region
  resource_group = local.resource_group
  cluster_id     = ibm_container_vpc_cluster.roks.id
  tags           = concat(var.tags, ["project:${var.name}", "region:${var.region}", "owner:${var.owner}"])
}
