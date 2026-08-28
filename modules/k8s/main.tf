resource "kubernetes_namespace" "app" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_config_map" "app" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  data = {
    APP_ENV   = "production"
    APP_TITLE = var.app_name
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        app = var.app_name
      }
    }
    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }
      spec {
        container {
          name  = "web"
          image = var.image
          port {
            container_port = 80
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.app.metadata[0].name
            }
          }
          resources {
            requests = {
              cpu    = "50m"
              memory = "32Mi"
            }
            limits = {
              cpu    = "150m"
              memory = "64Mi"
            }
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 3
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    selector = {
      app = var.app_name
    }
    type = "NodePort"
    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_ingress_v1" "app" {
  metadata {
    name      = "${var.app_name}-ingress"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    rule {
      host = "app.local"
      http {
        path {
          path_type = "Prefix"
          path      = "/"
          backend {
            service {
              name = kubernetes_service.app.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "app" {
  metadata {
    name      = "${var.app_name}-hpa"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }
    min_replicas = var.replicas
    max_replicas = 6
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 50
        }
      }
    }
  }
}

resource "kubernetes_manifest" "kyverno_policy" {
  depends_on = [kubernetes_namespace.app]
  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "disallow-latest-tag"
    }
    spec = {
      rules = [
        {
          name = "require-image-tag"
          match = {
            any = [
              {
                resources = {
                  kinds = ["Pod"]
                }
              }
            ]
          }
          validate = {
            failureAction = "Enforce"
            message       = "Un tag d'image explicite est requis (pas de latest)."
            pattern = {
              spec = {
                containers = [
                  {
                    image = "!*:latest"
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
}
