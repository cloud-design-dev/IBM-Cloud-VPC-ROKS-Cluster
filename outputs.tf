output "vpc_details" {
  description = "All VPC attributes"
  value       = format("Name:%s ID:%s CRN:%s", "${var.name}-vpc", module.vpc.vpc.id, module.vpc.vpc.crn)
}

output "subnets" {
  value = module.subnet[*]
}

output "cluster_details" {
  value     = ibm_container_vpc_cluster.roks
  sensitive = true
}