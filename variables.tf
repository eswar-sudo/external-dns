variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where ExternalDNS is deployed"
  type        = string
  default     = "kube-system"
}

variable "external_dns_chart_version" {
  description = "Helm chart version for ExternalDNS"
  type        = string
  default     = "1.15.0"
}

variable "external_dns_irsa_role_name" {
  description = "IAM Role name for ExternalDNS IRSA"
  type        = string
  default     = "external-dns-irsa"
}
