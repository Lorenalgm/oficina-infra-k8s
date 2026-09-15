output "cluster_name" {
  description = "Nome do cluster kind provisionado."
  value       = kind_cluster.this.name
}

output "kubeconfig_path" {
  description = "Caminho do kubeconfig do cluster kind."
  value       = kind_cluster.this.kubeconfig_path
}

output "namespace" {
  description = "Namespace da aplicação."
  value       = var.namespace
}

output "proximos_passos" {
  description = "O que rodar depois do apply."
  value       = <<-EOT
    Infra pronta. Para implantar a aplicação:
      kubectl apply -k ${var.k8s_manifests_path}/
      kubectl -n ${var.namespace} rollout status deployment/oficina-api
      kubectl -n ${var.namespace} port-forward svc/oficina-api 8080:80
  EOT
}
