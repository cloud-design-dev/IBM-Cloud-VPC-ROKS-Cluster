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
  count          = length(data.ibm_is_zones.mzr.zones)
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Public-Gateway-Module.git"
  name           = "${var.name}-${data.ibm_is_zones.mzr.zones[count.index]}-pubgw"
  zone           = data.ibm_is_zones.mzr.zones[count.index]
  vpc            = module.vpc.id
  resource_group = local.resource_group
  tags           = concat(var.tags, ["project:${var.name}", "region:${var.region}", "owner:${var.owner}", "vpc:${var.name}-vpc", "zone:${data.ibm_is_zones.mzr.zones[count.index]}"])
}

module "subnet" {
  count          = length(data.ibm_is_zones.mzr.zones)
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Subnet-Module.git"
  name           = "${var.name}-${data.ibm_is_zones.mzr.zones[count.index]}-subnet"
  resource_group = local.resource_group
  address_count  = "32"
  vpc            = module.vpc.id
  zone           = data.ibm_is_zones.mzr.zones[count.index]
  public_gateway = module.public_gateway[count.index].id
  tags           = concat(var.tags, ["project:${var.name}", "region:${var.region}", "owner:${var.owner}", "vpc:${var.name}-vpc", "zone:${data.ibm_is_zones.mzr.zones[count.index]}"])
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
  name              = "${var.name}-roks-cluster"
  vpc_id            = module.vpc.id
  kube_version      = var.roks_version
  flavor            = local.worker_flavor
  worker_count      = "3"
  cos_instance_crn  = ibm_resource_instance.cos_instance.id
  resource_group_id = local.resource_group
  wait_till         = "OneWorkerNodeReady"
  zones {
    subnet_id = module.subnet[0].id
    name      = "${var.region}-1"
  }
  zones {
    subnet_id = module.subnet[1].id
    name      = "${var.region}-2"
  }
  zones {
    subnet_id = module.subnet[2].id
    name      = "${var.region}-3"
  }
  tags = concat(var.tags, ["project:${var.name}", "region:${var.region}", "vpc:${var.name}-vpc", "owner:${var.owner}"])

  timeouts {
    create = "60m"
    update = "60m"
  }
}

resource "ibm_resource_instance" "logdna" {
  name              = "${var.name}-logdna"
  resource_group_id = local.resource_group
  service           = "logdna"
  plan              = "7-day"
  location          = var.region
}

resource "ibm_resource_key" "logdna_resourceKey" {
  name                 = "${var.name}-logdna-key"
  resource_instance_id = ibm_resource_instance.logdna.id
  role                 = "Manager"
}

resource "ibm_ob_logging" "roks" {
  depends_on  = [ibm_resource_key.logdna_resourceKey]
  cluster     = ibm_container_vpc_cluster.roks.id
  instance_id = ibm_resource_instance.logdna.guid
}

resource "ibm_resource_instance" "sysdig" {
  name              = "${var.name}-sysdig"
  resource_group_id = local.resource_group
  service           = "sysdig-monitor"
  plan              = "graduated-tier"
  location          = "us-south"
}

resource "ibm_resource_key" "sysdig_resourceKey" {
  name                 = "${var.name}-key"
  resource_instance_id = ibm_resource_instance.sysdig.id
  role                 = "Manager"
}

resource "ibm_ob_monitoring" "test2" {
  depends_on  = [ibm_resource_key.sysdig_resourceKey]
  cluster     = ibm_container_vpc_cluster.roks.id
  instance_id = ibm_resource_instance.sysdig.guid
}