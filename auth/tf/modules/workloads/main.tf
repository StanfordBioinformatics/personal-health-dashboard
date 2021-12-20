data "google_client_config" "default" {}

data "google_container_cluster" "mycluster" {
  name     = var.cluster_name
  location = var.region
}

provider "kubernetes" {
  version = "2.7.1"

  host                   = "https://${var.host}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = var.cluster_ca_certificate
}

locals {
  name       = "phd-auth"
  image      = "gcr.io/${var.cluster_project}/sftp-go:latest"
  nfs_name   = "fail2ban"
  sink_name  = "sink"
  sink_image = "gcr.io/${var.cluster_project}/sink:latest"
}

resource "kubernetes_deployment" "auth" {
  metadata {
    name = local.name

    labels = {
      app = local.name
    }
  }

  spec {
    selector {
      match_labels = {
        app = local.name
      }
    }

    template {
      metadata {
        labels = {
          app = local.name
        }
      }

      spec {
        automount_service_account_token = false
        enable_service_links            = false

        container {
          name  = local.sink_name
          image = local.sink_image

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }

          env {
            name = "SECRETS_DIR"
            value_from {
              config_map_key_ref {
                key  = "SECRETS_DIR"
                name = "phd-auth-config"
              }
            }
          }

          env {
            name = "LOGS_DIR"
            value_from {
              config_map_key_ref {
                key  = "LOGS_DIR"
                name = "phd-auth-config"
              }
            }
          }

          env {
            name = "SFTPGO_LOG_FILE_PATH"
            value_from {
              config_map_key_ref {
                key  = "SFTPGO_LOG_FILE_PATH"
                name = "phd-auth-config"
              }
            }
          }

          volume_mount {
            mount_path = "/logs"
            name       = "logs"
            read_only  = false
          }

          volume_mount {
            mount_path = "/logs/fail2ban"
            name       = "fail2ban"
            read_only  = false
          }
        }

        container {
          name  = local.name
          image = local.image

          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }

          env {
            name = "KEYS_DIR"
            value_from {
              config_map_key_ref {
                key  = "KEYS_DIR"
                name = "phd-auth-config"
              }
            }
          }

          env {
            name = "SECRETS_DIR"
            value_from {
              config_map_key_ref {
                key  = "SECRETS_DIR"
                name = "phd-auth-config"
              }
            }
          }

          env {
            name = "LOGS_DIR"
            value_from {
              config_map_key_ref {
                key  = "LOGS_DIR"
                name = "phd-auth-config"
              }
            }
          }

          env {
            name = "GCS_PAYLOAD_BUCKET"
            value_from {
              config_map_key_ref {
                key  = "GCS_PAYLOAD_BUCKET"
                name = "phd-auth-config"
              }
            }
          }

          env {
            name = "GCS_KEYS_BUCKET"
            value_from {
              config_map_key_ref {
                key  = "GCS_KEYS_BUCKET"
                name = "phd-auth-config"
              }
            }
          }

          env {
            name = "GCS_PAYLOAD_CREDS_FILE"
            value_from {
              config_map_key_ref {
                key  = "GCS_PAYLOAD_CREDS_FILE"
                name = "phd-auth-config"
              }
            }
          }

          env {
            name = "GCS_KEYS_CREDS_FILE"
            value_from {
              config_map_key_ref {
                key  = "GCS_KEYS_CREDS_FILE"
                name = "phd-auth-config"
              }
            }
          }

          env {
            name = "BIGQUERY_CREDS_FILE"
            value_from {
              config_map_key_ref {
                key  = "BIGQUERY_CREDS_FILE"
                name = "phd-auth-config"
              }
            }
          }

          env {
            name = "CONSOLIDATED_FAILED_AUTH_LOGFILE"
            value_from {
              config_map_key_ref {
                key  = "CONSOLIDATED_FAILED_AUTH_LOGFILE"
                name = "phd-auth-config"
              }
            }
          }

          env {
            name = "SFTP_PERMISSIONS"
            value_from {
              config_map_key_ref {
                key  = "SFTP_PERMISSIONS"
                name = "phd-auth-config"
              }
            }
          }

          env {
            name = "SFTPGO_LOG_FILE_PATH"
            value_from {
              config_map_key_ref {
                key  = "SFTPGO_LOG_FILE_PATH"
                name = "phd-auth-config"
              }
            }
          }

          security_context {
            allow_privilege_escalation = false
            privileged                 = false
            run_as_user                = "0"
            run_as_group               = "0"

            capabilities {
              add = [
                "NET_ADMIN",
                "NET_RAW"
              ]
            }
          }

          volume_mount {
            mount_path = "/secrets"
            name       = "sftp"
            read_only  = true
          }

          volume_mount {
            mount_path = "/logs"
            name       = "logs"
            read_only  = false
          }

          volume_mount {
            mount_path = "/logs/fail2ban"
            name       = "fail2ban"
            read_only  = false
          }
        }

        volume {
          name = "sftp"

          secret {
            secret_name = "k8s-auth-prod-sftp-secrets"
          }
        }

        volume {
          name = "logs"

          empty_dir {}
        }

        volume {
          name = "fail2ban"

          persistent_volume_claim {
            claim_name = local.nfs_name
            read_only  = false
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_persistent_volume_claim.nfs,
  ]
}

resource "kubernetes_service" "phd" {
  metadata {
    name = local.name
  }
  spec {
    selector = {
      app = local.name
    }

    port {
      name        = var.port_name
      node_port   = var.port_num
      port        = 2222
      target_port = 22
    }

    type = "NodePort"
  }
}


resource "kubernetes_config_map" "phd" {
  metadata {
    name = "phd-auth-config"
  }

  data = {
    BIGQUERY_CREDS_FILE              = "/secrets/fail2ban_bq_service_account.json"
    GCS_KEYS_BUCKET                  = var.gcs_keys_bucket
    GCS_KEYS_CREDS_FILE              = "/secrets/cloud_service_account_keys.json"
    GCS_PAYLOAD_BUCKET               = replace(var.gcs_keys_bucket, "-keys", "")
    GCS_PAYLOAD_CREDS_FILE           = "/secrets/cloud_service_account_payload.json"
    KEYS_DIR                         = "/mnt/keys"
    LOGS_DIR                         = "/logs"
    PAYLOAD_BASE_DIR                 = "/opt"
    SECRETS_DIR                      = "/secrets"
    CONSOLIDATED_FAILED_AUTH_LOGFILE = "/logs/fail2ban/failed_auth.log"
    SFTP_PERMISSIONS                 = join(",", var.sftp_permissions)
    SFTPGO_LOG_FILE_PATH             = "/logs/sftpgo.log"
  }
}
