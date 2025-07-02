variable "name" {
  type        = string
  description = "Name of the Helm release"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace to install the release"
  default     = "default"
}

variable "chart_path" {
  type        = string
  description = "Path to the Helm chart directory"
}

variable "s3www_image" {
  type        = string
  description = "Docker image for s3www application"
  default     = "y4m4/s3www:latest"
}

variable "bucket_name" {
  type        = string
  description = "Bucket name used by both s3www and MinIO"
  default     = "s3www-content"
}

variable "minio_image" {
  type        = string
  description = "Docker image for MinIO"
  default     = "quay.io/minio/minio:latest"
}

variable "minio_access_key" {
  type        = string
  description = "MinIO access key (can be set via TF_VAR_minio_access_key environment variable)"
  sensitive   = true
  default     = "minioadmin"
}

variable "minio_secret_key" {
  type        = string
  description = "MinIO secret key (can be set via TF_VAR_minio_secret_key environment variable)"
  sensitive   = true
  default     = "minioadmin123"
}

variable "storage_size" {
  type        = string
  description = "Storage size for MinIO PVC"
  default     = "1Gi"
}