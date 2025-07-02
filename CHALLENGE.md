# Technical Challenge Analysis

Document mentions about challenges faced, solutions implemented/tried & gained information during development.

## Overview

To create production ready IaC solution which deploys static website service (s3www) using MinIO object storage via Terraform and Helm on K8s.

## Architecture Decisions

### 1. Technology Stack Choice

Tools used : Terraform + Helm + Kubernetes

### 2. Modular Terraform Design

Decision: Using module for terraform and single helm chart to deploy both s3www and minio and job

## Technical Challenges


### Challenge : Helm Chart Service Discovery Issues

**Problem**: 
```
Error: Service s3www-minio has no endpoints
Upload job failing with "connection refused" to MinIO


Root Cause: Multiple service discovery issues:
1. Service selector mismatch: `app: minio` vs `app.kubernetes.io/name: minio`
2. Hardcoded service names in templates instead of using helper functions
3. Missing named ports for health check probes

**Solutions Implemented**:
1. **Fixed Service Selectors**:
   ```yaml
   # Before (broken)
   selector:
     app: {{ .Values.minio.name }}
   
   # After (working)
   selector:
     {{- include "s3www.minioSelectorLabels" . | nindent 4 }}
   ```

2. Dynamic Service Names:
   ```yaml
   # Before (hardcoded)
   - "-endpoint=http://minio:{{ .Values.minio.port }}"
   
   # After (dynamic)
   - "-endpoint=http://{{ include "s3www.minioFullname" . }}:{{ .Values.minio.port }}"
   ```

Lessons Learned:
- Use Helm helper functions for consistent naming
- Test service connectivity thoroughly throughout development
- Implement proper health checks with named ports
- Use `kubectl get endpoints` to debug service discovery issues

### Challenge : Helm Hook Lifecycle Management

**Problem**: 
```
Upload jobs persisting after terraform destroy
Multiple jobs created on subsequent deployments
Hook deletion policies not working as expected
```

RCA:
1. Helm Hook Scope**: Hook deletion policies only apply to hooks from the same Helm release
2. Terraform Lifecycle: `terraform destroy` removes the Helm release, orphaning the hooks
3. Fresh Install Detection: Each `terraform apply` after `destroy` is a new release (revision 1)

**Solutions tried**:

Attempt 1: Modify deletion policy
```yaml
# Tried but failed
"helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
```
Attempt 2: Cleanup job approach
```yaml
# Considered but abandoned
pre-install hook to delete old jobs
```

Attempt 3: Idempotent upload job
```bash
# Check if content already exists
if mc stat local/bucket/index.html >/dev/null 2>&1; then
    echo "Files already exist. Skipping upload."
else
    echo "Uploading content..."
    # Upload logic
fi
```
Benefits: Jobs run safely, no duplicate uploads, self-healing
Issue: Jobs still accumulate over time

Final Solution: TTL-based automatic cleanup (https://kubernetes.io/docs/concepts/workloads/controllers/ttlafterfinished/)
```yaml
spec:
  ttlSecondsAfterFinished: 600  # Delete after 10 minutes
```

**Why This Works**:
- Kubernetes Native: Using built-in TTL controller
- No RBAC Required: No additional permissions required
- Configurable: Easy to adjust cleanup timing
- Resource Efficient: Automatic cleanup without overhead
- Predictable: Clear lifecycle mgmt


### Challenge : Persistent Data Lifecycle

**Problem**:
```
MinIO data lost between terraform destroy/apply cycles
Upload job "unnecessarily" running on each deployment which is why I added PVC
```

**Analysis**:
This revealed a fundamental architectural question: **Should data persist across infrastructure deployments?**







