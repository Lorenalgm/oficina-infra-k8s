# Namespace da aplicação.
resource "kubernetes_namespace_v1" "oficina" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/part-of" = "oficina-mecanica"
    }
  }

  depends_on = [kind_cluster.this]
}
