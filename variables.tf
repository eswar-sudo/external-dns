variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

# ---------------- Variables ----------------
variable "oidc_provider_url" {
  description = "EKS OIDC provider URL (without https://). Example: oidc.eks.us-east-1.amazonaws.com/id/XXXXXX"
  type        = string
}

variable "namespace" {
  description = "Namespace where external-dns will run"
  type        = string
  default     = "kube-system"
}

variable "external_dns_irsa_role_name" {
  description = "Name for the IAM role for ExternalDNS"
  type        = string
  default     = "external-dns-irsa-role"
}

variable "external_dns_chart_version" {
  description = "ExternalDNS Helm chart version"
  type        = string
  default     = "1.14.4"
}
