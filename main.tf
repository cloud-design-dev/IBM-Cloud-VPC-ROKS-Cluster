locals {
  worker_flavor = var.worker_flavor != "" ? var.worker_flavor : "bx2.4x16"
}

module "vpc" {
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Module.git"
  name           = "${var.name}-vpc"
  resource_group = data.ibm_resource_group.group.id
  tags           = concat(var.tags, ["project:${var.name}", "region:${var.region}"])
}

module "public_gateway" {
  count          = length(data.ibm_is_zones.mzr.zones)
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Public-Gateway-Module.git"
  name           = "${var.name}-${data.ibm_is_zones.mzr.zones[count.index]}-pubgw"
  zone           = data.ibm_is_zones.mzr.zones[count.index]
  vpc            = module.vpc.id
  resource_group = data.ibm_resource_group.group.id
  tags           = concat(var.tags, ["project:${var.name}", "region:${var.region}", "zone:${data.ibm_is_zones.mzr.zones[count.index]}"])
}

module "subnet" {
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Subnet-Module.git"
  name           = "${var.name}-${data.ibm_is_zones.mzr.zones[count.index]}-subnet"
  resource_group = data.ibm_resource_group.group.id
  address_count  = "32"
  vpc            = module.vpc.id
  zone           = data.ibm_is_zones.mzr.zones[count.index]
  public_gateway = data.ibm_resource_group.group.id
  tags           = concat(var.tags, ["project:${var.name}", "region:${var.region}", "zone:${data.ibm_is_zones.mzr.zones[count.index]}"])
}

resource "ibm_resource_instance" "cos_instance" {
  depends_on        = [module.subnet]
  name              = "${var.name}-cos-instance"
  resource_group_id = data.ibm_resource_group.group.id
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  tags              = concat(var.tags, ["project:${var.name}"])
}

resource "ibm_container_vpc_cluster" "roks" {
  name                            = "${var.name}-roks-cluster"
  vpc_id                          = module.vpc.id
  kube_version                    = var.roks_version
  flavor                          = local.worker_flavor
  worker_count                    = "3"
  cos_instance_crn                = ibm_resource_instance.cos_instance.id
  disable_public_service_endpoint = var.private_endpoint_only
  resource_group                  = data.ibm_resource_group.group.id
  wait_till                       = "OneWorkerNodeReady"
  zones {
    subnet_id = module.subnet[0].id
    name      = data.ibm_is_zones.mzr.zones[0]
  }
  zones {
    subnet_id = module.subnet[1].id
    name      = data.ibm_is_zones.mzr.zones[1]
  }

  zones {
    subnet_id = module.subnet[2].id
    name      = data.ibm_is_zones.mzr.zones[2]
  }
  tags = concat(var.tags, ["project:${var.name}", "region:${var.region}"])

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
  resource_group = data.ibm_resource_group.group.id
  cluster_id     = ibm_container_vpc_cluster.roks.id
  tags           = concat(var.tags, ["project:${var.name}", "region:${var.region}", "owner:${var.owner}"])
}

module "monitoring" {
  count          = var.enable_monitoring == true ? 0 : 1
  source         = "./monitoring"
  name           = var.name
  region         = var.region
  resource_group = data.ibm_resource_group.group.id
  cluster_id     = ibm_container_vpc_cluster.roks.id
  tags           = concat(var.tags, ["project:${var.name}", "region:${var.region}", "owner:${var.owner}"])
}


# module "security" {
#   source = "./security"
#   name = var.name

# }

# module "openvpn" {
#   source            = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Instance-Module.git"
#   vpc_id            = module.vpc.id
#   subnet_id         = module.subnet.id
#   ssh_keys          = [data.ibm_is_ssh_key.regional_ssh_key.id]
#   resource_group    = local.resource_group
#   name              = "${var.name}-vpn"
#   zone              = data.ibm_is_zones.mzr.zones[0]
#   security_groups   = ibm_is_security_group.wireguard.id
#   tags              = concat(var.tags, ["project:${var.name}", "region:${var.region}", "owner:${var.owner}"])
#   user_data         = file("${path.module}/install.yml")
# }

# resource "ibm_is_floating_ip" "wg_vpn" {
#   name   = "${var.name}-public-ip"
#   target = module.instance.primary_network_interface_id
# }

