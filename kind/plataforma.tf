# Plataforma da Fase 4 — RabbitMQ (broker da Saga) e MongoDB (banco do
# Execução Service), compartilhados pelos três microsserviços.
#
# Mesma abordagem do Postgres: os manifestos em ../plataforma são a fonte
# única, usados também no caminho "kubectl puro" e no EKS.

resource "kubernetes_secret_v1" "plataforma" {
  metadata {
    name      = "plataforma-secrets"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/part-of" = "oficina-mecanica"
    }
  }

  type = "Opaque"

  data = {
    RABBITMQ_ADMIN_USER        = "admin"
    RABBITMQ_ADMIN_PASSWORD    = var.plataforma_senhas.rabbitmq_admin
    RABBITMQ_OS_PASSWORD       = var.plataforma_senhas.rabbitmq_os
    RABBITMQ_BILLING_PASSWORD  = var.plataforma_senhas.rabbitmq_billing
    RABBITMQ_EXECUCAO_PASSWORD = var.plataforma_senhas.rabbitmq_execucao
    MONGO_ROOT_PASSWORD        = var.plataforma_senhas.mongo_root
    MONGO_EXECUCAO_PASSWORD    = var.plataforma_senhas.mongo_execucao
  }

  depends_on = [kubernetes_namespace_v1.oficina]
}

resource "null_resource" "plataforma" {
  triggers = {
    manifestos = sha1(join("", [
      for arquivo in sort(fileset("${path.module}/../plataforma", "*.yaml")) :
      filesha1("${path.module}/../plataforma/${arquivo}")
    ]))
    senhas = sha1(jsonencode(var.plataforma_senhas))
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      K="kubectl --kubeconfig ${kind_cluster.this.kubeconfig_path} -n ${var.namespace}"
      # O Job é imutável: recria para reaplicar a topologia a cada mudança.
      $K delete job rabbitmq-topologia --ignore-not-found
      $K apply -k "${path.module}/../plataforma"
      $K rollout status statefulset/rabbitmq --timeout=240s
      $K rollout status statefulset/mongodb --timeout=240s
      $K wait --for=condition=complete job/rabbitmq-topologia --timeout=180s
    EOT
  }

  depends_on = [kubernetes_secret_v1.plataforma]
}
