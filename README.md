# S3WWW Deployment with Terraform and Helm

A production-ready IaC solution for deploying a static website service which is backed by MinIO object storage on K8s via Terraform & Helm.

For the sake of simplicity using deployment with volume mounts to keep the persistent state of upload file

## Architecture Overview


<img width="660" alt="Screenshot 2025-07-02 at 10 23 16 AM" src="https://github.com/user-attachments/assets/bdfe31e7-8999-4cf8-bf5e-e3fe80ccb702" />


## Components

- s3www: Static file server which serves contents from S3-compatible storage
- MinIO: S3-compatible object storage as backend
- Upload Job: Helm hook that initializes content in the bucket
- Terraform: Infrastructure orchestration & using TF for Helm deployment
- Kubernetes: Container orchestration which is created via Kind

## Prerequisites

- Kubernetes cluster (1.24+)
- Terraform (1.0+)
- Helm (3.0+)
- kubectl command installed to access/interact with cluster

### Quick Setup with Kind

```yaml
# Create local Kubernetes cluster
cat <<EOF | kind create cluster --name s3www-cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
```

# Set up storage class (for Kind) 
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

### Why Local Provisioner for Kind?

Kind Limitations:
- Kind clusters runs inside Docker containers
- No built-in dynamic storage provisioning
- PersistentVolumeClaims will remain in "Pending" state without a storage provisioner

Local Path Provisioner Benefits:

1. Dynamic Provisioning: Automatically creates PVs when PVCs are requested
2. Host Path Storage: Uses Docker container's filesystem (which are mapping to host directories)
3. Data persistence: Survives pod restarts but not cluster recreation

Alternatives:
- **hostPath volumes**: Manual, no dynamic provisioning
- **EmptyDir**: Data lost on pod restart
- **NFS**: Can be used in prod setup
- **Cloud storage**: Can be used in prod setup

## Local Storage Limitations
Multi-Node Constraints

Local Path Provisioner limitations in multi-node clusters:

Access Mode Support:
- **ReadWriteOnce (RWO)**: Supported - volume mounted by single node
- **ReadWriteMany (RWX)**: NOT supported - returns error
- **ReadWriteOncePod**: Supported - volume mounted by single pod

Error with ReadWriteMany:
- ProvisioningFailed: NodePath only supports ReadWriteOnce and ReadWriteOncePod access modes


## Quick Start

1. Cloning and navigating to the repository

   git clone https://github.com/devd-s/up42-task && cd up42-task/terraform

2. Deploying with Terraform
 
   terraform init  # To initialize the terraform module and pull the module
   terraform plan  # To plan
   terraform apply # To apply the changes

### Environment Variables

You can customize MinIO credentials using environment variables:


# Set custom MinIO credentials as TF VAR
export TF_VAR_minio_access_key="your-custom-access-key"
export TF_VAR_minio_secret_key="your-custom-secret-key"

OR

echo 'export TF_VAR_minio_access_key="custom-admin"' >> .env
echo 'export TF_VAR_minio_secret_key="custom-password123"' >> .env
source .env
terraform apply


Default Values (if environment variables not set):
- `minio_access_key`: "minioadmin"
- `minio_secret_key`: "minioadmin123"


3. Verifying deployment of components on K8s

   kubectl get pods -n default
   kubectl get pvc -n default
   kubectl get services -n default


4. To Access application by port forwarding

   kubectl port-forward service/s3www 8080:80
   # To access visit http://localhost:8080


## Configuration

### Terraform Variables

Configuration for `terraform/main.tf`:

```hcl
module "s3www" {
  source = "./modules/s3www"
  
  name                = "s3www"
  namespace          = "default"
  chart_path         = "../helm/s3www"
  s3www_image        = "y4m4/s3www:latest"
  bucket_name        = "s3www-content"     # Single bucket name for both s3www and MinIO
  minio_image        = "quay.io/minio/minio:latest"
  minio_access_key   = "minioadmin"        # This needs to be changed for production
  minio_secret_key   = "minioadmin123"     # This needs to be changed for production
  storage_size       = "1Gi"               # Change based on the requirement on Prod
}
```


### Helm Values

Key config options in `helm/s3www/values.yaml`:

```yaml
global:
  bucketName: s3www-content  # Single bucket name for both components

s3www:
  enabled: true
  image: y4m4/s3www:latest
  port: 8080
  replicas: 2

minio:
  enabled: true
  image: quay.io/minio/minio:latest
  replicas: 3
  port: 9000
  consolePort: 9090
  persistence:
    enabled: true
    size: 1Gi
    storageClass: standard

# Job Management
uploadJob:
  ttlSecondsAfterFinished: 600  # Auto-cleanup after 10 minutes

# Horizontal Pod Autoscaling
autoscaling:
  s3www:
    enabled: false  # Enable CPU/Memory based scaling
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
  minio:
    enabled: false
    minReplicas: 1
    maxReplicas: 5
    targetCPUUtilizationPercentage: 75

# Prometheus Monitoring
prometheus:
  metricsPort: 9091
  serviceMonitor:
    enabled: false  # Enable when s3www implements metrics
```


### Current Implementation

- IaC: Complete Terraform mgmt
- Helm Chart: Templated K8s manifests
- High Availability: Multiple replicas for both services
- Persistent Storage: For MinIO data persistence
- Secret Management: K8s secrets for credentials
- Health Checks: For Service health monitoring
- Automated Setup: Upload job initializes content with TTL-based cleanup
- Idempotent Deployment: Safe to run multiple times
- Job Management: Automatic cleanup via Kubernetes TTL controller
- Horizontal Pod Autoscaling: CPU/Memory based scaling for both s3www and MinIO
- Prometheus Ready: ServiceMonitor and metrics port configuration


## Operations

### To Deploy via TF


# Initialize deployment
terraform init
terraform apply

# Update deployment
terraform plan
terraform apply

# TO Scale replicas (edit values and apply)
# To Clean deployment
terraform destroy

### Deployment Commands via helm

# To render helm charts
Go to helm folder 
helm template s3www 

# To install via helm command
helm install RELEASE_NAME CHARTS_LOCATION --> helm install s3www ./s3www

# To uninstall
helm uninstall RELEASE_NAME --> helm install s3www 

# To apply changes
helm upgrade s3www ./helm/s3www

# To apply with custom values (You can also set other values using set command)
helm upgrade s3www ./helm/s3www --set uploadJob.ttlSecondsAfterFinished=1800

helm upgrade s3www ./helm/s3www --set autoscaling.s3www.enabled=true # By default keeping disabled

### For Troubleshooting


# To Check pod status
kubectl get pods -n default

# To View pod logs
kubectl logs -f deployment/s3www -n default
kubectl logs -f deployment/s3www-minio -n default

# To Check upload job (note: jobs auto-cleanup after TTL)
kubectl get jobs -n default -l job-type=upload
kubectl logs job/upload-content-<id> -n default

# To Check HPA status (if enabled)
kubectl get hpa -n default

# To Check services and endpoints
kubectl get svc,endpoints -n default

# To Debug networking
kubectl exec -it deployment/s3www -n default -- curl http://s3www-minio:9000


### Monitoring


# To Check resource usage
kubectl top pods -n default

# To View events
kubectl get events -n default --sort-by='.lastTimestamp'

# To do port forwarding for local access
kubectl port-forward service/s3www 8080:80
kubectl port-forward service/s3www-minio 9000:9000  # MinIO API
kubectl port-forward service/s3www-minio 9090:9090  # MinIO Console


### Prometheus Monitoring

By default it is set to false

Prepare for future metrics collection:

# Enable ServiceMonitor for Prometheus Operator
helm upgrade s3www ./helm/s3www --set prometheus.serviceMonitor.enabled=true

# Verify metrics endpoint (when implemented)
kubectl port-forward service/s3www 9091:9091
curl http://localhost:9091/metrics


### Configuration Examples

```yaml
# Production-ready configurations which can be implemented based on needs
autoscaling:
  s3www:
    enabled: true
    minReplicas: 3
    maxReplicas: 20
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80
  minio:
    enabled: true
    minReplicas: 2
    maxReplicas: 8
    targetCPUUtilizationPercentage: 75

uploadJob:
  ttlSecondsAfterFinished: 3600  # Keep for 1 hour for debugging

prometheus:
  serviceMonitor:
    enabled: true
    interval: 30s
    path: /metrics


## Multi-Node Storage Strategies for distributed storage which can be enabled on prod env


# Spread s3www pods across nodes
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values: [s3www]
        topologyKey: kubernetes.io/hostname
```

#### 2. Multiple PVCs (Distributed Storage)
```yaml
# Create separate PVCs for each node
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: storage-node-1
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: storage-node-2
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
```

## Production Enhancements

For production deployment, consider implementing these improvements:

### 🔐 Security

- External Secret Mgmt: Integration with HashiCorp Vault, AWS Secrets Manager or Azure Key Vault can be done
- Pod Security Standards: Enable Pod Security Policies/Standards
- Network Policies: Kubernetes NetworkPolicies for traffic isolation can be implemented
- TLS/SSL: cert-manager for automatic certificate mgmt can be added
- RBAC: Fine-grained can be given using role-based access control
- Image Security: private registries and image scanning can be used 
- Non-root Containers: containers as non-root users



#### MinIO in Distributed Mode can installed as sts

# StatefulSet with multiple PVCs
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: minio-distributed
spec:
  serviceName: minio-hl
  replicas: 4
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ReadWriteOnce]
      resources:
        requests:
          storage: 1Gi
```

### For terrafrom state management a remote backend bucket can be added to keep the state
´´´
terraform {

  backend "s3" {

    bucket          = “MY_BUCKET”

    key               = “PATH/TO/KEY”

    region           = “MY_REGION”

    access_key  = “AWS_ACCESS_KEY” # Can be passed from aws account profile

    secret_key	 = “AWS_SECRET_KEY” # Can be passed from aws account profile

  }

}
´´´
