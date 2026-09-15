# Secret com as variáveis sensíveis da aplicação.
# Valores vêm de variáveis (terraform.tfvars git-ignored localmente,
# TF_VAR_* / GitHub Secrets no CI) — nunca versionados.
resource "kubernetes_secret_v1" "app" {
  metadata {
    name      = "oficina-api-secrets"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = "oficina-api"
    }
  }

  type = "Opaque"

  data = {
    APP_KEY        = var.app_key
    DB_PASSWORD    = var.db_password
    RESEND_API_KEY = var.resend_api_key
    JWT_SECRET     = var.jwt_secret
  }

  depends_on = [kubernetes_namespace_v1.oficina]
}
