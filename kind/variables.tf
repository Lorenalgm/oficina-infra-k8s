variable "cluster_name" {
  description = "Nome do cluster kind."
  type        = string
  default     = "oficina"
}

variable "namespace" {
  description = "Namespace Kubernetes da aplicação."
  type        = string
  default     = "oficina"
}

variable "k8s_manifests_path" {
  description = <<-DOC
    Caminho para os manifestos Kubernetes, que continuam no repositório da
    aplicação. O default assume oficina-api e oficina-infra-k8s clonados lado a
    lado; ajuste se a sua árvore for outra.
  DOC
  type        = string
  default     = "../../oficina-api/k8s"
}

# --- Variáveis sensíveis (fornecidas via terraform.tfvars git-ignored ou TF_VAR_* no CI) ---

variable "app_key" {
  description = "APP_KEY do Laravel (formato base64:...)."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Senha do banco Postgres."
  type        = string
  sensitive   = true
}

variable "resend_api_key" {
  description = "Token do serviço externo Resend."
  type        = string
  sensitive   = true
  default     = ""
}

variable "jwt_secret" {
  description = <<-DOC
    Segredo HS256 que a oficina-api usa para revalidar o JWT emitido pela
    Lambda. Precisa ser idêntico ao dos dois lados; na AWS vem do Secrets
    Manager, aqui é informado à mão para o cluster local funcionar sozinho.
  DOC
  type        = string
  sensitive   = true
  default     = "segredo-local-de-desenvolvimento"
}

variable "new_relic_license_key" {
  description = "License key de ingestão do New Relic. Vazio desliga o agente no kind."
  type        = string
  sensitive   = true
  default     = ""
}
