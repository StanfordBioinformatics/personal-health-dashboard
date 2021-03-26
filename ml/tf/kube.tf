resource "kubernetes_namespace" "ns" {
  for_each = var.namespaces

  metadata {
    labels = each.value

    name = each.key
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels
    ]
  }
}

resource "kubernetes_pod_security_policy" "policy" {
  metadata {
    name = "argo"
  }

  spec {
    privileged                 = false
    allow_privilege_escalation = false

    volumes = [
      "configMap",
      "emptyDir",
      "projected",
      "secret",
      "downwardAPI",
      "persistentVolumeClaim",
    ]

    run_as_user {
      rule = "RunAsAny"
    }

    se_linux {
      rule = "RunAsAny"
    }

    supplemental_groups {
      rule = "MustRunAs"
      range {
        min = 1
        max = 65535
      }
    }

    fs_group {
      rule = "MustRunAs"
      range {
        min = 1
        max = 65535
      }
    }

    read_only_root_filesystem = false
  }
}

resource "kubernetes_cluster_role" "role" {
  metadata {
    name = "psp:argo"
  }

  rule {
    api_groups     = ["policy"]
    resources      = ["podsecuritypolicies"]
    verbs          = ["use"]
    resource_names = ["argo"]
  }
}

resource "kubernetes_role_binding" "role_binding" {
  for_each = var.namespaces

  metadata {
    name      = "psp:argo"
    namespace = each.key
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "psp:argo"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "argo-events-sa"
    namespace = each.key
  }

  depends_on = [
    kubernetes_namespace.ns,
  ]
}

resource "kubernetes_cluster_role" "job" {
  metadata {
    name = "argo:jobs"
  }

  rule {
    api_groups = ["", "batch", "extensions"]
    resources  = ["jobs", "pods"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_cluster_role_binding" "role_binding_job" {
  metadata {
    name = "argo:jobs"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "argo:jobs"
  }

  dynamic "subject" {
    for_each = var.namespaces

    content {
      kind      = "ServiceAccount"
      name      = "argo-events-sa"
      namespace = subject.key
    }
  }

  depends_on = [
    kubernetes_namespace.ns,
  ]
}