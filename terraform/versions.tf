terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
  }

  backend "s3" {
    key = "infra-k8s/terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Projeto   = var.projeto
      Repo      = "oficina-infra-k8s"
      ManagedBy = "terraform"
    }
  }
}

# A rede vem do repositório do banco: um único dono da VPC evita divergência.
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.tfstate_bucket
    key    = "infra-db/terraform.tfstate"
    region = var.aws_region
  }
}

# Token de curta duração do EKS: dispensa guardar kubeconfig no state.
data "aws_eks_cluster_auth" "este" {
  name = aws_eks_cluster.este.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.este.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.este.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.este.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.este.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.este.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.este.token
  }
}
