Lab 14: Auditing Storage Access and Usage
Objectives
By the end of this lab, students will be able to:

Configure comprehensive auditing for OpenShift Data Foundation (ODF) storage resources
Implement monitoring and reporting mechanisms for storage usage patterns
Set up automated alerts for unauthorized access attempts and security violations
Analyze audit logs to identify potential security threats and compliance issues
Create custom dashboards for storage access visualization
Understand best practices for storage security auditing in enterprise environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of OpenShift Container Platform concepts
Familiarity with Kubernetes storage concepts (PVs, PVCs, StorageClasses)
Knowledge of OpenShift Data Foundation fundamentals
Experience with command-line interface operations
Understanding of YAML configuration files
Basic knowledge of monitoring and logging concepts
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift and ODF already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

OpenShift Container Platform 4.13+
OpenShift Data Foundation 4.13+
Prometheus and Grafana for monitoring
ElasticSearch and Kibana for log analysis
Pre-configured storage classes and sample applications
Task 1: Set up Auditing for ODF Storage Access
Subtask 1.1: Enable OpenShift Audit Logging
First, we need to enable comprehensive audit logging for the OpenShift cluster to capture storage-related events.

Access your OpenShift cluster as cluster-admin:
oc login -u system:admin
Check current audit policy configuration:
oc get apiserver cluster -o yaml | grep -A 10 audit
Create a comprehensive audit policy for storage events:
cat > storage-audit-policy.yaml << 'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
# Log storage-related API calls at RequestResponse level
- level: RequestResponse
  namespaces: ["openshift-storage"]
  resources:
  - group: ""
    resources: ["persistentvolumes", "persistentvolumeclaims"]
  - group: "storage.k8s.io"
    resources: ["storageclasses", "volumeattachments"]
  - group: "ceph.rook.io"
    resources: ["*"]
  - group: "ocs.openshift.io"
    resources: ["*"]

# Log PVC operations across all namespaces
- level: Request
  resources:
  - group: ""
    resources: ["persistentvolumeclaims"]
  verbs: ["create", "delete", "update", "patch"]

# Log storage class usage
- level: Metadata
  resources:
  - group: "storage.k8s.io"
    resources: ["storageclasses"]
  verbs: ["get", "list"]

# Default rule for other operations
- level: Metadata
  omitStages:
  - RequestReceived
EOF
Apply the audit policy:
oc create configmap storage-audit-policy -n openshift-config --from-file=audit.yaml=storage-audit-policy.yaml
Update the API server configuration to use the new audit policy:
oc patch apiserver cluster --type merge -p '{"spec":{"audit":{"profile":"WriteRequestBodies","customRules":[{"profile":"WriteRequestBodies","priority":100}]}}}'
Subtask 1.2: Configure ODF-Specific Auditing
Create a dedicated namespace for audit monitoring:
oc create namespace odf-audit-monitoring
Deploy audit log collector for ODF events:
cat > odf-audit-collector.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: odf-audit-collector
  namespace: odf-audit-monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: odf-audit-collector
  template:
    metadata:
      labels:
        app: odf-audit-collector
    spec:
      serviceAccountName: odf-audit-collector
      containers:
      - name: collector
        image: quay.io/openshift/origin-logging-fluentd:latest
        env:
        - name: FLUENTD_CONF
          value: "fluent.conf"
        volumeMounts:
        - name: config
          mountPath: /fluentd/etc
        - name: audit-logs
          mountPath: /var/log/audit
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: fluentd-config
      - name: audit-logs
        hostPath:
          path: /var/log/audit
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: odf-audit-collector
  namespace: odf-audit-monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: odf-audit-collector
rules:
- apiGroups: [""]
  resources: ["nodes", "pods", "events"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: odf-audit-collector
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: odf-audit-collector
subjects:
- kind: ServiceAccount
  name: odf-audit-collector
  namespace: odf-audit-monitoring
EOF
Create Fluentd configuration for ODF audit parsing:
cat > fluentd-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: odf-audit-monitoring
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/audit/audit.log
      pos_file /var/log/fluentd-audit.log.pos
      tag kubernetes.audit
      format json
      time_key timestamp
      time_format %Y-%m-%dT%H:%M:%S.%NZ
    </source>
    
    <filter kubernetes.audit>
      @type grep
      <regexp>
        key objectRef.namespace
        pattern ^(openshift-storage|.*odf.*)$
      </regexp>
    </filter>
    
    <filter kubernetes.audit>
      @type record_transformer
      <record>
        cluster_name "#{ENV['CLUSTER_NAME'] || 'odf-cluster'}"
        audit_type storage
      </record>
    </filter>
    
    <match kubernetes.audit>
      @type elasticsearch
      host elasticsearch.openshift-logging.svc.cluster.local
      port 9200
      index_name odf-audit
      type_name _doc
    </match>
EOF
Apply the configurations:
oc apply -f fluentd-config.yaml
oc apply -f odf-audit-collector.yaml
Subtask 1.3: Set up Storage Access Monitoring
Create a ServiceMonitor for ODF metrics:
cat > odf-storage-monitor.yaml << 'EOF'
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: odf-storage-access-monitor
  namespace: openshift-storage
  labels:
    app: odf-storage-monitor
spec:
  selector:
    matchLabels:
      app: rook-ceph-mgr
  endpoints:
  - port: http-metrics
    interval: 30s
    path: /metrics
---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: odf-storage-access-rules
  namespace: openshift-storage
spec:
  groups:
  - name: odf.storage.access
    rules:
    - alert: UnauthorizedStorageAccess
      expr: increase(apiserver_audit_total{objectRef_namespace="openshift-storage",verb=~"create|delete|update"}[5m]) > 10
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: "High number of storage operations detected"
        description: "{{ $value }} storage operations in the last 5 minutes"
    
    - alert: SuspiciousStorageActivity
      expr: rate(apiserver_audit_total{objectRef_resource="persistentvolumeclaims",verb="delete"}[5m]) > 0.1
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Suspicious PVC deletion activity"
        description: "Multiple PVCs being deleted rapidly"
EOF
Apply the monitoring configuration:
oc apply -f odf-storage-monitor.yaml
Verify the monitoring setup:
oc get servicemonitor -n openshift-storage
oc get prometheusrule -n openshift-storage
Task 2: Monitor and Report on Storage Usage
Subtask 2.1: Create Storage Usage Monitoring Dashboard
Install Grafana operator if not already present:
cat > grafana-operator.yaml << 'EOF'
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: grafana-operator
  namespace: openshift-operators
spec:
  channel: v4
  name: grafana-operator
  source: community-operators
  sourceNamespace: openshift-marketplace
EOF
oc apply -f grafana-operator.yaml
Create Grafana instance for ODF monitoring:
cat > odf-grafana.yaml << 'EOF'
apiVersion: integreatly.org/v1alpha1
kind: Grafana
metadata:
  name: odf-grafana
  namespace: odf-audit-monitoring
spec:
  ingress:
    enabled: true
  config:
    auth:
      disable_signout_menu: true
    auth.anonymous:
      enabled: true
    log:
      level: warn
      mode: console
    security:
      admin_password: secret
      admin_user: root
  dashboardLabelSelector:
    - matchExpressions:
        - key: app
          operator: In
          values:
            - grafana
EOF
Create storage usage dashboard:
cat > storage-usage-dashboard.yaml << 'EOF'
apiVersion: integreatly.org/v1alpha1
kind: GrafanaDashboard
metadata:
  name: odf-storage-usage
  namespace: odf-audit-monitoring
  labels:
    app: grafana
spec:
  json: |
    {
      "dashboard": {
        "id": null,
        "title": "ODF Storage Usage and Access Audit",
        "tags": ["odf", "storage", "audit"],
        "style": "dark",
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Storage Usage by Namespace",
            "type": "graph",
            "targets": [
              {
                "expr": "sum by (namespace) (kubelet_volume_stats_used_bytes{persistentvolumeclaim=~\".*\"})",
                "legendFormat": "{{ namespace }}"
              }
            ],
            "yAxes": [
              {
                "label": "Bytes",
                "min": 0
              }
            ],
            "xAxis": {
              "show": true
            },
            "gridPos": {
              "h": 8,
              "w": 12,
              "x": 0,
              "y": 0
            }
          },
          {
            "id": 2,
            "title": "PVC Access Frequency",
            "type": "stat",
            "targets": [
              {
                "expr": "sum(rate(apiserver_audit_total{objectRef_resource=\"persistentvolumeclaims\"}[5m]))",
                "legendFormat": "PVC Operations/sec"
              }
            ],
            "gridPos": {
              "h": 8,
              "w": 12,
              "x": 12,
              "y": 0
            }
          },
          {
            "id": 3,
            "title": "Storage Class Usage Distribution",
            "type": "piechart",
            "targets": [
              {
                "expr": "count by (storageclass) (kube_persistentvolumeclaim_info)",
                "legendFormat": "{{ storageclass }}"
              }
            ],
            "gridPos": {
              "h": 8,
              "w": 24,
              "x": 0,
              "y": 8
            }
          }
        ],
        "time": {
          "from": "now-1h",
          "to": "now"
        },
        "refresh": "30s"
      }
    }
EOF
Apply the Grafana configurations:
oc apply -f odf-grafana.yaml
oc apply -f storage-usage-dashboard.yaml
Subtask 2.2: Create Automated Storage Reports
Create a CronJob for daily storage usage reports:
cat > storage-report-cronjob.yaml << 'EOF'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-storage-report
  namespace: odf-audit-monitoring
spec:
  schedule: "0 6 * * *"  # Daily at 6 AM
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: storage-reporter
          containers:
          - name: reporter
            image: quay.io/openshift/origin-cli:latest
            command:
            - /bin/bash
            - -c
            - |
              #!/bin/bash
              
              # Generate storage usage report
              echo "=== Daily Storage Usage Report ===" > /tmp/report.txt
              echo "Date: $(date)" >> /tmp/report.txt
              echo "" >> /tmp/report.txt
              
              # Get PVC usage by namespace
              echo "PVC Usage by Namespace:" >> /tmp/report.txt
              oc get pvc --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.spec.resources.requests.storage,STORAGECLASS:.spec.storageClassName --no-headers | sort | uniq -c >> /tmp/report.txt
              
              echo "" >> /tmp/report.txt
              echo "Storage Classes:" >> /tmp/report.txt
              oc get storageclass -o custom-columns=NAME:.metadata.name,PROVISIONER:.provisioner,RECLAIM:.reclaimPolicy --no-headers >> /tmp/report.txt
              
              echo "" >> /tmp/report.txt
              echo "Recent Storage Events:" >> /tmp/report.txt
              oc get events --all-namespaces --field-selector reason=ProvisioningSucceeded,reason=ProvisioningFailed --sort-by='.lastTimestamp' | tail -20 >> /tmp/report.txt
              
              # Send report (in real environment, you would email or store this)
              cat /tmp/report.txt
              
              # Store in ConfigMap for later retrieval
              oc create configmap daily-storage-report-$(date +%Y%m%d) --from-file=report.txt=/tmp/report.txt -n odf-audit-monitoring --dry-run=client -o yaml | oc apply -f -
          restartPolicy: OnFailure
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: storage-reporter
  namespace: odf-audit-monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: storage-reporter
rules:
- apiGroups: [""]
  resources: ["persistentvolumes", "persistentvolumeclaims", "events", "configmaps"]
  verbs: ["get", "list", "create", "update"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: storage-reporter
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: storage-reporter
subjects:
- kind: ServiceAccount
  name: storage-reporter
  namespace: odf-audit-monitoring
EOF
Apply the reporting configuration:
oc apply -f storage-report-cronjob.yaml
Test the report generation manually:
oc create job manual-storage-report --from=cronjob/daily-storage-report -n odf-audit-monitoring
Check the generated report:
oc logs job/manual-storage-report -n odf-audit-monitoring
Subtask 2.3: Set up Storage Metrics Collection
Create custom metrics for storage auditing:
cat > storage-metrics-exporter.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storage-metrics-exporter
  namespace: odf-audit-monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: storage-metrics-exporter
  template:
    metadata:
      labels:
        app: storage-metrics-exporter
    spec:
      serviceAccountName: storage-metrics-exporter
      containers:
      - name: exporter
        image: quay.io/prometheus/node-exporter:latest
        ports:
        - containerPort: 9100
          name: metrics
        command:
        - /bin/sh
        - -c
        - |
          #!/bin/sh
          
          # Create a simple metrics endpoint
          while true; do
            # Count PVCs by status
            BOUND_PVCS=$(oc get pvc --all-namespaces -o json | jq '.items | map(select(.status.phase == "Bound")) | length')
            PENDING_PVCS=$(oc get pvc --all-namespaces -o json | jq '.items | map(select(.status.phase == "Pending")) | length')
            
            # Count storage classes
            STORAGE_CLASSES=$(oc get storageclass -o json | jq '.items | length')
            
            # Generate metrics
            cat > /tmp/metrics.prom << EOF
          # HELP odf_pvc_bound_total Total number of bound PVCs
          # TYPE odf_pvc_bound_total gauge
          odf_pvc_bound_total $BOUND_PVCS
          
          # HELP odf_pvc_pending_total Total number of pending PVCs
          # TYPE odf_pvc_pending_total gauge
          odf_pvc_pending_total $PENDING_PVCS
          
          # HELP odf_storage_classes_total Total number of storage classes
          # TYPE odf_storage_classes_total gauge
          odf_storage_classes_total $STORAGE_CLASSES
          EOF
            
            sleep 30
          done
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: storage-metrics-exporter
  namespace: odf-audit-monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: storage-metrics-exporter
rules:
- apiGroups: [""]
  resources: ["persistentvolumes", "persistentvolumeclaims"]
  verbs: ["get", "list"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: storage-metrics-exporter
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: storage-metrics-exporter
subjects:
- kind: ServiceAccount
  name: storage-metrics-exporter
  namespace: odf-audit-monitoring
---
apiVersion: v1
kind: Service
metadata:
  name: storage-metrics-exporter
  namespace: odf-audit-monitoring
  labels:
    app: storage-metrics-exporter
spec:
  ports:
  - port: 9100
    name: metrics
  selector:
    app: storage-metrics-exporter
EOF
Deploy the metrics exporter:
oc apply -f storage-metrics-exporter.yaml
Task 3: Create Alerts for Unauthorized Access Attempts
Subtask 3.1: Configure Advanced Alert Rules
Create comprehensive alerting rules for storage security:
cat > storage-security-alerts.yaml << 'EOF'
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: odf-security-alerts
  namespace: openshift-storage
  labels:
    prometheus: kube-prometheus
    role: alert-rules
spec:
  groups:
  - name: odf.security.alerts
    rules:
    
    # Alert for unauthorized PVC deletions
    - alert: UnauthorizedPVCDeletion
      expr: increase(apiserver_audit_total{objectRef_resource="persistentvolumeclaims",verb="delete",user_username!~"system:.*"}[5m]) > 0
      for: 0m
      labels:
        severity: critical
        category: security
      annotations:
        summary: "Unauthorized PVC deletion detected"
        description: "User {{ $labels.user_username }} deleted PVC {{ $labels.objectRef_name }} in namespace {{ $labels.objectRef_namespace }}"
    
    # Alert for suspicious storage class modifications
    - alert: StorageClassModification
      expr: increase(apiserver_audit_total{objectRef_resource="storageclasses",verb=~"update|patch|delete"}[5m]) > 0
      for: 0m
      labels:
        severity: warning
        category: security
      annotations:
        summary: "Storage class modification detected"
        description: "Storage class {{ $labels.objectRef_name }} was modified by {{ $labels.user_username }}"
    
    # Alert for rapid PVC creation (potential abuse)
    - alert: RapidPVCCreation
      expr: rate(apiserver_audit_total{objectRef_resource="persistentvolumeclaims",verb="create"}[5m]) > 0.5
      for: 2m
      labels:
        severity: warning
        category: security
      annotations:
        summary: "Rapid PVC creation detected"
        description: "More than 0.5 PVCs per second being created - potential abuse"
    
    # Alert for access to sensitive storage namespaces
    - alert: SensitiveStorageAccess
      expr: increase(apiserver_audit_total{objectRef_namespace="openshift-storage",user_username!~"system:.*"}[5m]) > 5
      for: 1m
      labels:
        severity: warning
        category: security
      annotations:
        summary: "High access to sensitive storage namespace"
        description: "User {{ $labels.user_username }} has made {{ $value }} requests to openshift-storage namespace"
    
    # Alert for failed storage operations
    - alert: StorageOperationFailures
      expr: increase(apiserver_audit_total{objectRef_resource=~"persistentvolume.*",responseStatus_code=~"4..|5.."}[5m]) > 3
      for: 2m
      labels:
        severity: warning
        category: operations
      annotations:
        summary: "Multiple storage operation failures"
        description: "{{ $value }} storage operations failed in the last 5 minutes"
    
    # Alert for unusual storage access patterns
    - alert: UnusualStorageAccessPattern
      expr: |
        (
          rate(apiserver_audit_total{objectRef_resource="persistentvolumeclaims"}[5m]) 
          / 
          rate(apiserver_audit_total{objectRef_resource="persistentvolumeclaims"}[1h] offset 1h)
        ) > 3
      for: 5m
      labels:
        severity: info
        category: anomaly
      annotations:
        summary: "Unusual storage access pattern detected"
        description: "Storage access rate is 3x higher than usual"
EOF
Apply the security alert rules:
oc apply -f storage-security-alerts.yaml
Subtask 3.2: Set up Alert Manager Configuration
Create AlertManager configuration for storage alerts:
cat > alertmanager-storage-config.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-storage-config
  namespace: openshift-monitoring
type: Opaque
stringData:
  alertmanager.yml: |
    global:
      smtp_smarthost: 'localhost:587'
      smtp_from: 'alerts@company.com'
    
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'default'
      routes:
      - match:
          category: security
        receiver: 'security-team'
        group_wait: 0s
        repeat_interval: 5m
      - match:
          severity: critical
        receiver: 'critical-alerts'
        group_wait: 0s
    
    receivers:
    - name: 'default'
      webhook_configs:
      - url: 'http://webhook-logger.odf-audit-monitoring.svc.cluster.local:8080/webhook'
        send_resolved: true
    
    - name: 'security-team'
      webhook_configs:
      - url: 'http://webhook-logger.odf-audit-monitoring.svc.cluster.local:8080/security'
        send_resolved: true
        title: 'ODF Security Alert'
        text: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Severity: {{ .Labels.severity }}
          {{ end }}
    
    - name: 'critical-alerts'
      webhook_configs:
      - url: 'http://webhook-logger.odf-audit-monitoring.svc.cluster.local:8080/critical'
        send_resolved: true
EOF
Create a webhook receiver for testing alerts:
cat > webhook-logger.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webhook-logger
  namespace: odf-audit-monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webhook-logger
  template:
    metadata:
      labels:
        app: webhook-logger
    spec:
      containers:
      - name: webhook
        image: quay.io/openshift/origin-cli:latest
        command:
        - /bin/bash
        - -c
        - |
          #!/bin/bash
          
          # Simple webhook receiver
          while true; do
            echo "Webhook server listening on port 8080..."
            nc -l -p 8080 -e /bin/bash -c '
              read request
              echo "HTTP/1.1 200 OK"
              echo "Content-Type: text/plain"
              echo ""
              echo "Alert received at $(date)"
              echo "Request: $request"
              
              # Log the alert
              echo "$(date): Alert received - $request" >> /tmp/alerts.log
            '
          done
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: webhook-logger
  namespace: odf-audit-monitoring
spec:
  selector:
    app: webhook-logger
  ports:
  - port: 8080
    targetPort: 8080
EOF
Deploy the webhook logger:
oc apply -f webhook-logger.yaml
Subtask 3.3: Test Alert System
Create a test scenario to trigger alerts:
cat > test-alert-scenario.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-alert-pvc-1
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ocs-storagecluster-ceph-rbd
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-alert-pvc-2
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ocs-storagecluster-ceph-rbd
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-alert-pvc-3
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Create multiple PVCs rapidly to trigger alerts:
# Create PVCs
oc apply -f test-alert-scenario.yaml

# Wait a moment, then delete them rapidly
sleep 10
oc delete pvc test-alert-pvc-1 test-alert-pvc-2 test-alert-pvc-3
Check if alerts are firing:
# Check Prometheus alerts
oc get prometheus -n openshift-monitoring -o jsonpath='{.items[0].status.conditions[?(@.type=="Available")].status}'

# Check AlertManager
oc port-forward -n openshift-monitoring svc/alertmanager-main 9093:9093 &
curl -s http://localhost:9093/api/v1/alerts | jq '.data[] | select(.labels.category == "security")'
Verify webhook logs:
oc logs deployment/webhook-logger -n odf-audit-monitoring
Subtask 3.4: Create Custom Alert Dashboard
Create a Grafana dashboard for alert visualization:
cat > alert-dashboard.yaml << 'EOF'
apiVersion: integreatly.org/v1alpha1
kind: GrafanaDashboard
metadata:
  name: odf-security-alerts
  namespace: odf-audit-monitoring
  labels:
    app: grafana
spec:
  json: |
    {
      "dashboard": {
        "id": null,
        "title": "ODF Security Alerts Dashboard",
        "tags": ["odf", "security", "alerts"],
        "style": "dark",
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Active Security Alerts",
            "type": "stat",
            "targets": [
              {
                "expr": "ALERTS{category=\"security\",alertstate=\"firing\"}",
                "legendFormat": "{{ alertname }}"
              }
            ],
            "fieldConfig": {
              "defaults": {
                "color": {
                  "mode": "thresholds"
                },
                "thresholds": {
                  "steps": [
                    {"color": "green", "value": null},
                    {"color": "yellow", "value": 1},
                    {"color": "red", "value": 3}
                  ]
                }
              }
            },
            "gridPos": {
              "h": 8,
              "w": 12,
              "x": 0,
              "y": 0
            }
          },
          {
            "id": 2,
            "title": "Alert Frequency",
            "type": "graph",
            "
