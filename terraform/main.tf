terraform {
  required_version = ">= 1.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}



module "s3www" {
  source = "./modules/s3www"
  
  name                = "s3www"
  namespace          = "default"
  chart_path         = "../helm/s3www"
  s3www_image        = "y4m4/s3www:latest"
  bucket_name        = "s3www-content"  # Single bucket name for both s3www & MinIO
  minio_image        = "quay.io/minio/minio:latest"
  # Credentials can be overridden via environment variables:
  # export TF_VAR_minio_access_key="your-custom-access-key"
  # export TF_VAR_minio_secret_key="your-custom-secret-key"
  minio_access_key   = var.minio_access_key
  minio_secret_key   = var.minio_secret_key
  storage_size       = "1Gi"
}
