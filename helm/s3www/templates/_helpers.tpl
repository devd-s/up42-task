{{/*
Expand the name of the chart.
*/}}
{{- define "s3www.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a fully qualified name.
*/}}
{{- define "s3www.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version for labels.
*/}}
{{- define "s3www.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels for all resources.
*/}}
{{- define "s3www.labels" -}}
helm.sh/chart: {{ include "s3www.chart" . }}
{{ include "s3www.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end }}

{{/*
Labels for selector matching (s3www).
*/}}
{{- define "s3www.selectorLabels" -}}
app.kubernetes.io/name: {{ include "s3www.name" . }}
app.kubernetes.io/instance: {{ include "s3www.fullname" . }}
{{- end }}

{{/*
Service account name logic.
*/}}
{{- define "s3www.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "s3www.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
MinIO specific selector labels.
*/}}
{{- define "s3www.minioSelectorLabels" -}}
app.kubernetes.io/name: minio
app.kubernetes.io/instance: {{ include "s3www.fullname" . }}
{{- end }}

{{/*
MinIO specific full name.
*/}}
{{- define "s3www.minioFullname" -}}
{{- printf "%s-%s" (include "s3www.fullname" .) "minio" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
MinIO specific labels.
*/}}
{{- define "s3www.minioLabels" -}}
helm.sh/chart: {{ include "s3www.chart" . }}
{{ include "s3www.minioSelectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/name: minio
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end }}
