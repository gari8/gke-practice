resource "kubernetes_service_account" "cloud_sql_access" {
  secret {
    name = kubernetes_secret.cloud_sql_proxy_key.metadata.0.name
  }
  metadata {
    name      = "cloud-sql-access"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = "cloud-sql-access@${var.project}.iam.gserviceaccount.com"
    }
  }
}

resource "google_service_account_iam_binding" "cloud_sql_access_iam" {
  members            = ["serviceAccount:${var.project}.svc.id.goog[app/cloud-sql-access]"]
  role               = "roles/iam.workloadIdentityUser"
  service_account_id = google_service_account.custom.id
}

resource "google_service_account_key" "cloud_proxy_key" {
  service_account_id = google_service_account.custom.name
}

resource "kubernetes_secret" "cloud_sql_proxy_key" {
  metadata {
    name      = "cloud-sql-proxy-key"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }
  data = {
    "credentials.json" = base64decode(google_service_account_key.cloud_proxy_key.private_key)
  }
}

resource "kubernetes_service" "cloud_sql_proxy" {
  metadata {
    name      = "cloud-sql-proxy"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels = {
      app = "cloud-sql-proxy"
    }
  }
  spec {
    selector = {
      app = "cloud-sql-proxy"
    }
    port {
      name        = "cloud-sql-proxy"
      protocol    = "TCP"
      port        = 3306
      target_port = 3306
    }
  }
}

resource "kubernetes_config_map" "cloud_sql_instance" {
  metadata {
    name      = "cloud-sql-instance"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }
  data = {
    CLOUD_SQL_PROJECT_ID      = var.project
    CLOUD_SQL_INSTANCE_REGION = var.region
    CLOUD_SQL_INSTANCE_NAME   = var.cloud_sql_instance_name
  }
}

resource "kubernetes_deployment" "cloud_sql_proxy" {
  metadata {
    name      = "cloud-sql-proxy"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels = {
      app = "cloud-sql-proxy"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "cloud-sql-proxy"
      }
    }
    strategy {}
    replicas = 3
    template {
      metadata {
        labels = {
          app = "cloud-sql-proxy"
        }
      }
      spec {
        service_account_name = kubernetes_service_account.cloud_sql_access.metadata[0].name
        container {
          name  = "cloud-sql-proxy"
          image = "gcr.io/cloudsql-docker/gce-proxy:1.23.0"
          port {
            name           = "cloud-sql-proxy"
            container_port = 3306
            protocol       = "TCP"
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.cloud_sql_instance.metadata[0].name
            }
          }
          command = [
            "/cloud_sql_proxy",
            "-instances=${var.project}:${var.region}:${var.cloud_sql_instance_name}=tcp:0.0.0.0:3306",
            "-ip_address_types=PRIVATE"
          ]
          security_context {
            run_as_non_root = true
          }
          resources {
            limits = {
              cpu    = "100m"
              memory = "2Gi"
            }
            requests = {
              cpu    = "100m"
              memory = "2Gi"
            }
          }
        }
      }
    }
  }
}