variable "kubeconfig" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

# Variables for MinIO credentials (can be set via environment variables)
variable "minio_access_key" {
  type        = string
  description = "MinIO access key (can be set also via TF_VAR_minio_access_key environment variable)"
  sensitive   = true
  default     = "minioadmin"
}

variable "minio_secret_key" {
  type        = string
  description = "MinIO secret key (can be set also via TF_VAR_minio_secret_key environment variable)"
  sensitive   = true
  default     = "minioadmin123"
}