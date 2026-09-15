output "cluster_name" {
  description = "Nome do cluster EKS."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint da API do Kubernetes."
  value       = module.eks.cluster_endpoint
}

output "node_security_group_id" {
  description = "Security group dos nodes."
  value       = module.eks.node_security_group_id
}

output "namespace" {
  description = "Namespace da aplicação."
  value       = kubernetes_namespace_v1.oficina.metadata[0].name
}

output "kubeconfig_comando" {
  description = "Comando que registra o cluster no kubeconfig local."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "backend_base_url_comando" {
  description = <<-DOC
    Como descobrir a URL do NLB para alimentar a variável backend_base_url do
    repositório oficina-auth-lambda.
  DOC
  value       = "kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}
