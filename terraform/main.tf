terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.0"
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

resource "kubernetes_namespace" "kijani_staging" {
  metadata {
    name = var.namespace_name
    labels = {
      environment = "staging"
      managed-by  = "terraform"
      project     = "kijanikiosk"
    }
  }
}

resource "kubernetes_resource_quota" "staging_quota" {
  metadata {
    name      = "staging-quota"
    namespace = kubernetes_namespace.kijani_staging.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = "500m"
      "requests.memory" = "512Mi"
      "limits.cpu"      = "2000m"
      "limits.memory"   = "1Gi"
      "pods"            = "10"
    }
  }
}
