resource "ibm_resource_instance" "logdna" {
  name              = "${var.name}-logdna"
  resource_group_id = var.resource_group
  service           = "logdna"
  plan              = "7-day"
  location          = var.region
  tags              = var.tags
}

resource "ibm_resource_key" "logdna_resourceKey" {
  name                 = "${var.name}-logdna-key"
  resource_instance_id = ibm_resource_instance.logdna.id
  role                 = "Manager"
}

resource "ibm_ob_logging" "roks" {
  depends_on  = [ibm_resource_key.logdna_resourceKey]
  cluster     = var.cluster_id
  instance_id = ibm_resource_instance.logdna.guid
}
