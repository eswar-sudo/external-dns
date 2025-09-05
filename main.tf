terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# ---------------- IRSA for ExternalDNS ----------------
# Get OIDC issuer URL from the EKS cluster
locals {
  oidc_provider_url = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

data "aws_iam_openid_connect_provider" "oidc" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_role" "external_dns_irsa" {
  name = var.external_dns_irsa_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_url}:sub" = "system:serviceaccount:${var.namespace}:external-dns"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "external_dns_policy" {
  name = "external-dns-policy"
  role = aws_iam_role.external_dns_irsa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets", "route53:ListHostedZones", "route53:ListResourceRecordSets"]
        Resource = "*"
      }
    ]
  })
}

# Service Account with IRSA annotation
resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns_irsa.arn
    }
  }
}

# ---------------- Helm Release ----------------
resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = var.namespace
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = var.external_dns_chart_version

  set = [
    {
      name  = "provider"
      value = "aws"
    },
    {
      name  = "policy"
      value = "upsert-only"
    },
    {
      name  = "registry"
      value = "txt"
    },
    {
      name  = "txtOwnerId"
      value = var.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account.external_dns.metadata[0].name
    }
  ]
  
}
