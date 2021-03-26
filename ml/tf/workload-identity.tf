module "workload-identity" {
  for_each   = var.workload_identity
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name       = each.key
  namespace  = each.value.namespace
  project_id = var.project_id
  roles      = each.value.roles
}