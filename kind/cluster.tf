# Provisiona o cluster Kubernetes local usando kind (Kubernetes-in-Docker).
# Requer Docker em execução na máquina.
resource "kind_cluster" "this" {
  name           = var.cluster_name
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      # Mapeia portas do host para o nó, úteis caso use um Ingress Controller.
      extra_port_mappings {
        container_port = 30080
        host_port      = 8080
      }
    }

    node {
      role = "worker"
    }
  }
}
