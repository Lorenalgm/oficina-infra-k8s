# nri-bundle entrega, sem tocar na aplicação:
#   - newrelic-infrastructure + kube-state-metrics: CPU e memória por pod
#     (K8sContainerSample / K8sPodSample), base dos painéis de recurso;
#   - newrelic-logging: coleta o stdout dos pods. Como a oficina-api escreve
#     JSON, cada campo do log vira atributo consultável por NRQL — é daí que
#     saem latência, volume de OS e falhas de processamento;
#   - nri-kube-events: eventos do cluster, incluindo reinício de pod.
resource "helm_release" "newrelic" {
  name             = "newrelic-bundle"
  repository       = "https://helm-charts.newrelic.com"
  chart            = "nri-bundle"
  namespace        = "newrelic"
  version          = "5.0.100"
  create_namespace = true

  set_sensitive {
    name  = "global.licenseKey"
    value = var.new_relic_license_key
  }

  set {
    name  = "global.cluster"
    value = var.new_relic_cluster_name
  }

  set {
    name  = "global.lowDataMode"
    value = "true"
  }

  set {
    name  = "newrelic-infrastructure.privileged"
    value = "true"
  }

  set {
    name  = "kube-state-metrics.enabled"
    value = "true"
  }

  set {
    name  = "newrelic-logging.enabled"
    value = "true"
  }

  set {
    name  = "nri-kube-events.enabled"
    value = "true"
  }

  depends_on = [module.eks]
}
