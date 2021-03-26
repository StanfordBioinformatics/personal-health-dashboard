project_id = "pdh-project"

region = "us-central1"

network = "default"

subnetwork = "default"

bastion_members = [ ]

cluster = {
  regional                   = false
  zone                       = "us-central1-c"
  region                     = "us-central1"
  ip_range_pods              = "gke-cov-cluster-pods"
  ip_range_services          = "gke-cov-cluster-services"
  enable_pod_security_policy = true
  grant_registry_access      = true
  default_max_pods_per_node  = 55
}

node_pools = [
  {
    name               = "standard-pool"
    machine_type       = "e2-standard-4"
    node_locations     = "us-central1-a,us-central1-c"
    min_count          = 1
    max_count          = 4
    disk_size_gb       = 40
    disk_type          = "pd-standard"
    image_type         = "COS"
    preemptible        = true
    initial_node_count = 1
    auto_repair        = true
    auto_upgrade       = true
    enable_secure_boot = true
  },
  {
    name               = "preprocessing-pool"
    machine_type       = "e2-standard-16"
    node_locations     = "us-central1-a,us-central1-c"
    min_count          = 0
    max_count          = 1024
    disk_size_gb       = 40
    disk_type          = "pd-standard"
    image_type         = "COS"
    preemptible        = true
    initial_node_count = 0
    auto_repair        = true
    auto_upgrade       = true
    enable_secure_boot = true
  },
  {
    name               = "trainference-pool-0"
    machine_type       = "n2-highmem-32"
    node_locations     = "us-central1-a,us-central1-c"
    min_count          = 0
    max_count          = 1024
    disk_size_gb       = 40
    disk_type          = "pd-standard"
    image_type         = "COS"
    preemptible        = true
    initial_node_count = 0
    auto_repair        = true
    auto_upgrade       = true
    enable_secure_boot = true
  },
  {
    name               = "trainference-pool-1"
    machine_type       = "n2-highmem-32"
    node_locations     = "us-central1-a,us-central1-b,us-central1-c"
    min_count          = 0
    max_count          = 1024
    disk_size_gb       = 40
    disk_type          = "pd-standard"
    image_type         = "COS"
    preemptible        = true
    initial_node_count = 0
    auto_repair        = true
    auto_upgrade       = true
    enable_secure_boot = true
  },
  {
    name               = "trainference-pool-2"
    machine_type       = "n2-highmem-32"
    node_locations     = "us-central1-a,us-central1-b,us-central1-c"
    min_count          = 0
    max_count          = 1024
    disk_size_gb       = 40
    disk_type          = "pd-standard"
    image_type         = "COS"
    preemptible        = true
    initial_node_count = 0
    auto_repair        = true
    auto_upgrade       = true
    enable_secure_boot = true
  },
  {
    name               = "trainference-pool-3"
    machine_type       = "n2-highmem-32"
    node_locations     = "us-central1-a,us-central1-b,us-central1-c"
    min_count          = 0
    max_count          = 1024
    disk_size_gb       = 40
    disk_type          = "pd-standard"
    image_type         = "COS"
    preemptible        = true
    initial_node_count = 0
    auto_repair        = true
    auto_upgrade       = true
    enable_secure_boot = true
  },
  {
    name               = "decrypt-pool"
    machine_type       = "e2-standard-16"
    node_locations     = "us-central1-a,us-central1-c"
    min_count          = 0
    max_count          = 1024
    disk_size_gb       = 40
    disk_type          = "pd-standard"
    image_type         = "COS"
    preemptible        = true
    initial_node_count = 0
    auto_repair        = true
    auto_upgrade       = true
    enable_secure_boot = true
  }
]

node_pools_labels = {
  default-pool = {
    workload = "default"
  }

  preprocessing-pool = {
    workload = "preprocessing"
  }

  trainference-pool-0 = {
    workload = "trainference"
  }

  trainference-pool-1 = {
    workload = "trainference"
  }

  trainference-pool-2 = {
    workload = "trainference"
  }

  trainference-pool-3 = {
    workload = "trainference"
  }

  decrypt-pool = {
    workload = "decrypt"
  }
}
