variable "namespace_name" {
  description = "Name of the Kubernetes namespace to provision for staging"
  type        = string
  default     = "kijani-staging"
}