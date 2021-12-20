resource "kubernetes_horizontal_pod_autoscaler" "auth" {
  metadata {
    name = local.name

    labels = {
      app = local.name
    }
  }

  spec {
    max_replicas = 50
    min_replicas = 10

    scale_target_ref {
      kind        = "Deployment"
      name        = local.name
      api_version = "apps/v1"
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = "65"
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = "65"
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].behavior
    ]
  }
}
