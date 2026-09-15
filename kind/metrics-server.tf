# metrics-server — pré-requisito do HPA (fornece métricas de CPU/memória).
# O kind não o traz de fábrica. O arg --kubelet-insecure-tls é necessário
# porque os certificados de kubelet do kind não são assinados por uma CA reconhecida.
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  depends_on = [kind_cluster.this]
}
