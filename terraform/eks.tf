data "aws_iam_role" "lab" {
  name = var.iam_role_name
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
  enable_cluster_creator_admin_permissions = true

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
