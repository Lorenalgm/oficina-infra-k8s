# metrics-server: pré-requisito do HPA, que entrega o requisito de escalabilidade.
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.2"

  depends_on = [aws_eks_node_group.padrao]
}

# ingress-nginx expõe a API por um Network Load Balancer; é a URL que o
# API Gateway usa como backend_base_url durante a gravação.
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  version          = "4.11.3"
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  # NLB em vez do Classic Load Balancer: mais barato e com provisionamento
  # bem mais rápido, o que importa numa janela de gravação curta.
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  depends_on = [aws_eks_node_group.padrao]
}
