data "aws_iam_role" "lab" {
  name = var.iam_role_name
}

data "aws_caller_identity" "atual" {}

locals {
  cluster_name = "${var.projeto}-eks"

  # Quem roda o apply precisa virar admin do cluster. Derivamos o ARN da role a
  # partir do ARN da sessão, sem chamar iam:GetRole — ação negada pelo Learner
  # Lab (ver ADR-004):
  #   arn:aws:sts::<conta>:assumed-role/<role>/<sessao>
  #   -> arn:aws:iam::<conta>:role/<role>
  sessao = try(
    regex("^arn:aws:sts::(?P<conta>[0-9]+):assumed-role/(?P<role>[^/]+)/", data.aws_caller_identity.atual.arn),
    null
  )

  admin_do_cluster = coalesce(
    var.cluster_admin_role_arn != "" ? var.cluster_admin_role_arn : null,
    local.sessao != null ? "arn:aws:iam::${local.sessao.conta}:role/${local.sessao.role}" : null,
    data.aws_caller_identity.atual.arn,
  )
}

# O cluster é declarado com os recursos nativos do provider, e não com
# terraform-aws-modules/eks: em todas as versões v20 e v21 o módulo resolve o
# principal do criador via `aws_iam_session_context`, que chama iam:GetRole e
# falha no Learner Lab antes de criar qualquer recurso (ver ADR-004).
resource "aws_eks_cluster" "este" {
  name     = local.cluster_name
  version  = var.cluster_version
  role_arn = data.aws_iam_role.lab.arn

  vpc_config {
    # Nodes nas subnets públicas: sem NAT Gateway, é como eles alcançam a API do
    # EKS e o registro de imagens.
    subnet_ids              = data.terraform_remote_state.db.outputs.public_subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  access_config {
    authentication_mode = "API"
    # O access entry do criador é declarado abaixo, explicitamente.
    bootstrap_cluster_creator_admin_permissions = false
  }

  # Sem chave KMS própria e sem logs do control plane: o Learner Lab não permite
  # criar a role de criptografia, e o CloudWatch consumiria orçamento à toa.
  enabled_cluster_log_types = []

  tags = { Name = local.cluster_name }
}

resource "aws_eks_access_entry" "criador" {
  cluster_name  = aws_eks_cluster.este.name
  principal_arn = local.admin_do_cluster
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "criador_admin" {
  cluster_name  = aws_eks_cluster.este.name
  principal_arn = aws_eks_access_entry.criador.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_node_group" "padrao" {
  cluster_name    = aws_eks_cluster.este.name
  node_group_name = "padrao"
  subnet_ids      = data.terraform_remote_state.db.outputs.public_subnet_ids

  # Mesma restrição de IAM: reaproveitamos a LabRole em vez de criar uma role
  # de mínimo privilégio para os nodes.
  node_role_arn = data.aws_iam_role.lab.arn

  instance_types = [var.node_instance_type]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    min_size     = var.node_min
    max_size     = var.node_max
    desired_size = var.node_min
  }

  update_config {
    max_unavailable = 1
  }

  # O desired_size passa a ser gerido pelo HPA/cluster; não reverter no apply.
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [aws_eks_access_policy_association.criador_admin]
}

# vpc-cni e kube-proxy precisam existir antes dos nodes ficarem prontos; o
# coredns só agenda depois que há node disponível.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.este.name
  addon_name    = "vpc-cni"
  addon_version = null

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.este.name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.este.name
  addon_name   = "coredns"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.padrao]
}

# Libera o 5432 do RDS para os nodes. A regra vive aqui, e não no repositório do
# banco, porque é este state que conhece o security group do cluster — o
# contrário criaria dependência circular entre os dois states.
resource "aws_security_group_rule" "nodes_para_rds" {
  type                     = "ingress"
  description              = "PostgreSQL a partir dos nodes do EKS"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.db.outputs.db_sg_id
  source_security_group_id = aws_eks_cluster.este.vpc_config[0].cluster_security_group_id
}
