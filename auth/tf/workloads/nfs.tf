
resource "google_filestore_instance" "filestore" {
  name = var.cluster_name
  tier = "STANDARD"
  zone = element(var.zones, 0)

  file_shares {
    capacity_gb = 1024
    name        = "vol1"
  }

  networks {
    network = var.network
    modes   = ["MODE_IPV4"]
  }
}

resource "kubernetes_storage_class" "nfs" {
  metadata {
    name = local.nfs_name
  }
  reclaim_policy      = "Retain"
  storage_provisioner = "nfs"
}

resource "kubernetes_persistent_volume" "nfs" {
  metadata {
    name = local.nfs_name
  }
  spec {
    capacity = {
      storage = "100Gi"
    }
    storage_class_name = kubernetes_storage_class.nfs.metadata[0].name
    access_modes       = ["ReadWriteMany"]
    persistent_volume_source {
      nfs {
        server = google_filestore_instance.filestore.networks[0].ip_addresses[0]
        path   = "/${google_filestore_instance.filestore.file_shares[0].name}"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "nfs" {
  metadata {
    name      = local.nfs_name
    namespace = "default"
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.nfs.metadata[0].name
    volume_name        = kubernetes_persistent_volume.nfs.metadata[0].name
    resources {
      requests = {
        storage = "100Gi"
      }
    }
  }
}