variable "aws_region" {
  description = "Região da AWS. O AWS Academy Learner Lab só libera us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "projeto" {
  description = "Prefixo aplicado ao nome de todos os recursos."
  type        = string
  default     = "oficina"
}

variable "tfstate_bucket" {
  description = "Bucket S3 onde ficam os states dos repositórios de infraestrutura."
  type        = string
}

variable "cluster_version" {
  description = "Versão do Kubernetes no EKS."
  type        = string
  default     = "1.31"
}

variable "namespace" {
  description = "Namespace da aplicação."
  type        = string
  default     = "oficina"
}

variable "node_instance_type" {
  description = <<-DOC
    Tipo da instância dos nodes. t3.medium dá folga para ingress, metrics-server,
    agente do New Relic e as réplicas da API sob HPA. O Learner Lab encerra as
    instâncias EC2 ao fim de cada sessão — o managed node group as recria.
  DOC
  type        = string
  default     = "t3.medium"
}

variable "node_min" {
  description = "Mínimo de nodes no managed node group."
  type        = number
  default     = 2
}

variable "node_max" {
  description = "Máximo de nodes no managed node group."
  type        = number
  default     = 4
}

variable "iam_role_name" {
  description = <<-DOC
    Role usada pelo control plane e pelos nodes. O AWS Academy Learner Lab não
    permite criar IAM roles, então reaproveitamos a LabRole do ambiente, que já
    tem as políticas de EKS, ECR e CNI. Fora do Learner Lab, o módulo criaria
    duas roles distintas de mínimo privilégio (ver ADR-004).
  DOC
  type        = string
  default     = "LabRole"
}

variable "new_relic_license_key" {
  description = "License key de ingestão do New Relic."
  type        = string
  sensitive   = true
}

variable "new_relic_cluster_name" {
  description = "Nome com que o cluster aparece no New Relic."
  type        = string
  default     = "oficina-eks"
}
