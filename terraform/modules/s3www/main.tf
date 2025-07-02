resource "helm_release" "s3www" {
  name       = var.name
  chart      = var.chart_path
  namespace  = var.namespace
  create_namespace = true

  values = [templatefile("${path.root}/values.tpl.yaml", {
    s3www_image         = var.s3www_image,
    bucket_name         = var.bucket_name,
    minio_image         = var.minio_image,
    minio_access_key    = var.minio_access_key,
    minio_secret_key    = var.minio_secret_key,
    storage_size        = var.storage_size
  })]

  depends_on = [
    kubernetes_secret.minio_credentials
  ]
}

resource "kubernetes_secret" "minio_credentials" {
  metadata {
    name      = "minio-credentials"
    namespace = var.namespace
  }

  data = {
    accesskey = var.minio_access_key
    secretkey = var.minio_secret_key
  }

  type = "Opaque"
}

