output "namespace_name" {
  description = "The provisioned staging namespace name"
  value       = kubernetes_namespace.kijani_staging.metadata[0].name
}

output "resource_quota_name" {
  description = "The resource quota applied to the staging namespace"
  value       = kubernetes_resource_quota.staging_quota.metadata[0].name
}