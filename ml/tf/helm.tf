resource "helm_release" "argo_events" {
  name      = "argo-events"
  namespace = "argo-events"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-events"
  version    = "1.0.0"
  wait       = true
  timeout    = 60

  set {
    name  = "serviceAccount"
    value = "argo-events-sa"
  }

  set {
    name  = "additionalSaNamespaces"
    value = "{ml,decrypt}"
  }

  depends_on = [
    kubernetes_namespace.ns,
    kubernetes_pod_security_policy.policy,
    kubernetes_cluster_role.role,
    kubernetes_role_binding.role_binding
  ]
}