# Command to create the cluster

cat <<EOF | kind create cluster --name s3www-cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 8080
EOF

# To create the folder structure and helm charts
helm create helm/s3www 
mkdir terraform
mkdir -p helm/s3www


# Only s3www (no MinIO):
helm install s3www ./s3www --set minio.enabled=false

# Only MinIO (no s3www):
helm install s3www ./s3www --set s3www.enabled=false


==> Linting helm/s3www
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed


helm template s3www ./s3www
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /Users/devd/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /Users/devd/.kube/config
Error: YAML parse error on s3www/templates/upload-job.yaml: error converting YAML to JSON: yaml: line 20: found unexpected end of stream

Use --debug flag to render out invalid YAML




Error: YAML parse error on s3www/templates/upload-job.yaml: error converting YAML to JSON: yaml: line 20: found unexpected end of stream
helm.go:84: [debug] error converting YAML to JSON: yaml: line 20: found unexpected end of stream


# Source: s3www/templates/upload-job.yaml

apiVersion: batch/v1
kind: Job
metadata:
  name: upload-content
spec:
  template:
    spec:
      restartPolicy: OnFailure
      containers:
        - name: uploader
          image: minio/mc
          command:
            - /bin/sh
            - -c
            - |
              echo "Hello from Helm chart!
" > /tmp/content.txt
              mc alias set local http://minio:9000 minioadmin minioadmin
              mc mb --ignore-existing local/s3www-content
              mc cp /tmp/content.txt local/s3www-content/index.html




MinIO Console at http://localhost:9000,
it redirects to a random port like http://localhost:41401.

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl get storageclass
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

[TODO]
check tf module part

update readme
