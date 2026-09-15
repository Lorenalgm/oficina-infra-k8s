data "aws_iam_role" "lab" {
  name = var.iam_role_name
}

data "aws_caller_identity" "atual" {}

locals {
  # O módulo do EKS resolve o principal do criador do cluster chamando
  # iam:GetRole, que o Learner Lab nega explicitamente (ver ADR-004). Por isso
  # `enable_cluster_creator_admin_permissions` fica desligado e o access entry
  # é declarado à mão, com o ARN derivado da própria sessão:
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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = "${var.projeto}-eks"
  cluster_version = var.cluster_version

  vpc_id = data.terraform_remote_state.db.outputs.vpc_id
  # Nodes nas subnets públicas: sem NAT Gateway, é como eles alcançam a API do
  # EKS e o registro de imagens.
  subnet_ids = data.terraform_remote_state.db.outputs.public_subnet_ids

  cluster_endpoint_public_access = true

  # Dá ao usuário que roda o apply acesso admin ao cluster via access entry.
  # Declarado explicitamente porque a resolução automática do módulo depende de
  # iam:GetRole (ver o local `admin_do_cluster` acima).
  enable_cluster_creator_admin_permissions = false

  access_entries = {
    criador = {
      principal_arn = local.admin_do_cluster

      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  # --- Restrições do AWS Academy Learner Lab ---------------------------------
  # Sem criação de IAM role e sem chave KMS própria; os logs do control plane
  # ficam desligados para não gastar orçamento com CloudWatch.
  create_iam_role = false
  iam_role_arn    = data.aws_iam_role.lab.arn

  create_kms_key              = false
  cluster_encryption_config   = {}
  create_cloudwatch_log_group = false
  cluster_enabled_log_types   = []
  # ---------------------------------------------------------------------------

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  eks_managed_node_groups = {
    padrao = {
      instance_types = [var.node_instance_type]
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_min
      max_size     = var.node_max
      desired_size = var.node_min

      create_iam_role = false
      iam_role_arn    = data.aws_iam_role.lab.arn
    }
  }
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
  source_security_group_id = module.eks.node_security_group_id
}
