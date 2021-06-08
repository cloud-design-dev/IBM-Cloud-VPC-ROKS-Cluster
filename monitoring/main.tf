resource "ibm_resource_instance" "monitoring" {
  name              = "${var.name}-sysdig"
  resource_group_id = var.resource_group
  service           = "sysdig-monitor"
  plan              = "graduated-tier"
  location          = var.region
  tags              = var.tags
}

resource "ibm_resource_key" "sysdig_resourceKey" {
  name                 = "${var.name}-key"
  resource_instance_id = ibm_resource_instance.monitoring.id
  role                 = "Manager"
}

resource "ibm_ob_monitoring" "test2" {
  depends_on  = [ibm_resource_key.sysdig_resourceKey]
  cluster     = var.cluster_id
  instance_id = ibm_resource_instance.monitoring.guid
}