# O mesmo nri-bundle do EKS, rodando no kind. Permite montar e validar os
# dashboards e alertas antes de o cluster na AWS existir: os logs JSON da
# aplicação chegam ao New Relic exatamente com o mesmo formato.
# Deixe new_relic_license_key vazio para não instalar o agente.
resource "helm_release" "newrelic" {
  count = var.new_relic_license_key == "" ? 0 : 1

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
    value = "oficina-kind"
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

  depends_on = [kind_cluster.this]
}
