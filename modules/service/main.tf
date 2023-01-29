resource "kubernetes_service" "service" {
  metadata {
    name      = var.service_name
    namespace = var.namespace
    annotations = {
      "cloud.google.com/neg" = "{\"ingress\": true}"
    }
  }
  spec {
    type = "ClusterIP"
    port {
      port        = var.port
      target_port = var.target_port
    }
    selector = {
      app : var.service_name
    }
  }
}

resource "kubernetes_deployment" "deployment" {
  metadata {
    name      = var.service_name
    namespace = var.namespace
    labels = {
      app = var.service_name
    }
  }
  spec {
    selector {
      match_labels = {
        app = var.service_name
      }
    }
    strategy {
      type = "Recreate"
    }
    template {
      metadata {
        name      = var.service_name
        namespace = var.namespace
        labels = {
          app = var.service_name
        }
      }
      spec {
        container {
          name  = var.service_name
          image = var.service_image
          env {
            name  = "DB_HOST"
            value = var.db_host
          }
          env {
            name  = "DB_USER"
            value = var.db_user
          }
          env {
            name  = "DB_NAME"
            value = var.db_name
          }
          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = "mysql"
                key  = "password"
              }
            }
          }
          port {
            container_port = var.port
            name           = var.service_name
          }
          volume_mount {
            mount_path = "/var/www/html"
            name       = "${var.service_name}-persistent-storage"
          }
          liveness_probe {
            initial_delay_seconds = 30
            period_seconds        = 30
            timeout_seconds       = 10
            http_get {
              port = var.port
              path = var.healthcheck_path
            }
          }
          readiness_probe {
            http_get {
              port = var.port
              path = var.healthcheck_path
            }
          }
          resources {
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "1000m"
              memory = "1Gi"
            }
          }
        }
        volume {
          name = "${var.service_name}-persistent-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.claim.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_pod" "pod" {
  metadata {
    name = var.service_name
    labels = {
      app = var.service_name
    }
  }

  spec {
    container {
      image = var.service_image
      name  = var.service_name
    }
  }
}

resource "kubernetes_persistent_volume_claim" "claim" {
  metadata {
    name      = var.service_name
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

