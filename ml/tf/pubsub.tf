module "preprocessing" {
  source  = "terraform-google-modules/pubsub/google"
  version = "~> 1.5"

  topic      = "preprocessing"
  project_id = var.project_id
  topic_labels = {
    app = "trainference"
  }

  pull_subscriptions = [
    {
      name                       = "preprocessing"
      ack_deadline_seconds       = 600
      message_retention_duration = "86400s"

      maximum_backoff = "600s"
      minimum_backoff = "10s"
    }
  ]
}

module "trainference" {
  source  = "terraform-google-modules/pubsub/google"
  version = "~> 1.5"

  topic      = "trainference"
  project_id = var.project_id
  topic_labels = {
    app = "trainference"
  }

  pull_subscriptions = [
    {
      name                       = "trainference"
      ack_deadline_seconds       = 600
      message_retention_duration = "86400s"

      maximum_backoff = "600s"
      minimum_backoff = "10s"
    }
  ]
}

module "inference" {
  source  = "terraform-google-modules/pubsub/google"
  version = "~> 1.5"

  topic      = "inference"
  project_id = var.project_id
  topic_labels = {
    app = "trainference"
  }

  pull_subscriptions = [
    {
      name                       = "inference"
      ack_deadline_seconds       = 600
      message_retention_duration = "86400s"

      maximum_backoff = "600s"
      minimum_backoff = "10s"
    }
  ]
}

module "encrypted_payload" {
  source  = "terraform-google-modules/pubsub/google"
  version = "~> 1.5"

  topic      = "decrypt"
  project_id = var.project_id
  topic_labels = {
    app = "decrypt"
  }

  pull_subscriptions = [
    {
      name                       = "decrypt"
      ack_deadline_seconds       = 600
      message_retention_duration = "86400s"

      maximum_backoff = "600s"
      minimum_backoff = "10s"
    }
  ]
}