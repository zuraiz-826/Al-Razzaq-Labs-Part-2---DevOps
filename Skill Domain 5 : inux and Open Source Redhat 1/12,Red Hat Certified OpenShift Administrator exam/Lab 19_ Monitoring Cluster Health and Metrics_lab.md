Lab 19: Monitoring Cluster Health and Metrics
Objectives
By the end of this lab, you will be able to:

Install and configure Prometheus for comprehensive cluster monitoring
Set up Grafana dashboards to visualize cluster health and performance metrics
Create and configure Prometheus alerts for resource utilization thresholds
Understand the monitoring stack architecture in OpenShift environments
Implement best practices for cluster observability and alerting
Prerequisites
Before starting this lab, you should have:

Basic understanding of Kubernetes and OpenShift concepts
Familiarity with YAML configuration files
Knowledge of Linux command-line operations
Understanding of containerized applications
Basic networking concepts
Previous experience with OpenShift CLI (oc command)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift cluster access. Simply click Start Lab to begin - no need to build your own virtual machine or install additional software.

Your lab environment includes:

OpenShift cluster with administrative access
Pre-installed OpenShift CLI (oc)
Network connectivity to deploy monitoring components
Sufficient resources for Prometheus and Grafana deployment
Task 1: Install and Configure Prometheus for Monitoring
Subtask 1.1: Verify Cluster Access and Create Monitoring Namespace
First, let's verify our cluster access and prepare the environment for monitoring components.

Login to your OpenShift cluster:
oc login --server=https://your-cluster-api:6443 --username=admin --password=your-password
Verify cluster status:
oc get nodes
oc cluster-info
Create a dedicated namespace for monitoring:
oc new-project monitoring-lab
oc project monitoring-lab
Verify the namespace creation:
oc get projects | grep monitoring-lab
Subtask 1.2: Deploy Prometheus Operator
The Prometheus Operator simplifies the deployment and management of Prometheus instances.

Create the Prometheus Operator deployment:
cat << 'EOF' > prometheus-operator.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus-operator
  namespace: monitoring-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus-operator
  template:
    metadata:
      labels:
        app: prometheus-operator
    spec:
      serviceAccountName: prometheus-operator
      containers:
      - name: prometheus-operator
        image: quay.io/prometheus-operator/prometheus-operator:v0.68.0
        args:
        - --kubelet-service=kube-system/kubelet
        - --logtostderr=true
        - --config-reloader-image=quay.io/prometheus-operator/prometheus-config-reloader:v0.68.0
        - --prometheus-config-reloader=quay.io/prometheus-operator/prometheus-config-reloader:v0.68.0
        ports:
        - containerPort: 8080
          name: http
        resources:
          limits:
            cpu: 200m
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
EOF
Create the ServiceAccount and RBAC permissions:
cat << 'EOF' > prometheus-rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus-operator
  namespace: monitoring-lab
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus-operator
rules:
- apiGroups: [""]
  resources: ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["monitoring.coreos.com"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus-operator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus-operator
subjects:
- kind: ServiceAccount
  name: prometheus-operator
  namespace: monitoring-lab
EOF
Apply the RBAC configuration:
oc apply -f prometheus-rbac.yaml
Deploy the Prometheus Operator:
oc apply -f prometheus-operator.yaml
Verify the operator deployment:
oc get pods -l app=prometheus-operator
oc logs deployment/prometheus-operator
Subtask 1.3: Deploy Prometheus Instance
Now we'll create a Prometheus instance using the operator.

Create Prometheus configuration:
cat << 'EOF' > prometheus-instance.yaml
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: prometheus-main
  namespace: monitoring-lab
spec:
  serviceAccountName: prometheus
  serviceMonitorSelector:
    matchLabels:
      team: monitoring
  ruleSelector:
    matchLabels:
      team: monitoring
  resources:
    requests:
      memory: 400Mi
      cpu: 100m
    limits:
      memory: 800Mi
      cpu: 200m
  retention: 7d
  storage:
    volumeClaimTemplate:
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 10Gi
  alerting:
    alertmanagers:
    - namespace: monitoring-lab
      name: alertmanager-main
      port: web
EOF
Create ServiceAccount for Prometheus:
cat << 'EOF' > prometheus-sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring-lab
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources: ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring-lab
EOF
Apply the ServiceAccount configuration:
oc apply -f prometheus-sa.yaml
Deploy the Prometheus instance:
oc apply -f prometheus-instance.yaml
Create a Service to expose Prometheus:
cat << 'EOF' > prometheus-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
  namespace: monitoring-lab
spec:
  selector:
    app.kubernetes.io/name: prometheus
  ports:
  - name: web
    port: 9090
    targetPort: 9090
  type: ClusterIP
EOF
Apply the service configuration:
oc apply -f prometheus-service.yaml
Verify Prometheus deployment:
oc get prometheus
oc get pods -l app.kubernetes.io/name=prometheus
oc get svc prometheus-service
Subtask 1.4: Configure ServiceMonitor for Cluster Metrics
ServiceMonitors tell Prometheus what to scrape for metrics.

Create a ServiceMonitor for kubelet metrics:
cat << 'EOF' > kubelet-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kubelet
  namespace: monitoring-lab
  labels:
    team: monitoring
spec:
  selector:
    matchLabels:
      app: kubelet
  endpoints:
  - port: https-metrics
    scheme: https
    tlsConfig:
      insecureSkipVerify: true
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    interval: 30s
    path: /metrics
---
apiVersion: v1
kind: Service
metadata:
  name: kubelet
  namespace: kube-system
  labels:
    app: kubelet
spec:
  type: ClusterIP
  clusterIP: None
  ports:
  - name: https-metrics
    port: 10250
    targetPort: 10250
  selector:
    app: kubelet
EOF
Apply the ServiceMonitor:
oc apply -f kubelet-servicemonitor.yaml
Create ServiceMonitor for API server metrics:
cat << 'EOF' > apiserver-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: apiserver
  namespace: monitoring-lab
  labels:
    team: monitoring
spec:
  selector:
    matchLabels:
      component: apiserver
      provider: kubernetes
  endpoints:
  - port: https
    scheme: https
    tlsConfig:
      serverName: kubernetes
      insecureSkipVerify: true
    bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    interval: 30s
EOF
Apply the API server ServiceMonitor:
oc apply -f apiserver-servicemonitor.yaml
Task 2: Set up Grafana Dashboards to Visualize Cluster Health
Subtask 2.1: Deploy Grafana
Create Grafana deployment configuration:
cat << 'EOF' > grafana-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:10.1.0
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin123"
        - name: GF_INSTALL_PLUGINS
          value: "grafana-kubernetes-app"
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
        - name: grafana-config
          mountPath: /etc/grafana/provisioning/datasources
        resources:
          requests:
            memory: 200Mi
            cpu: 100m
          limits:
            memory: 400Mi
            cpu: 200m
      volumes:
      - name: grafana-storage
        emptyDir: {}
      - name: grafana-config
        configMap:
          name: grafana-datasources
EOF
Create Grafana datasource configuration:
cat << 'EOF' > grafana-datasources.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: monitoring-lab
data:
  prometheus.yaml: |
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      access: proxy
      url: http://prometheus-service:9090
      isDefault: true
      editable: true
EOF
Apply the datasource configuration:
oc apply -f grafana-datasources.yaml
Deploy Grafana:
oc apply -f grafana-deployment.yaml
Create Grafana service:
cat << 'EOF' > grafana-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
  namespace: monitoring-lab
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
EOF
Apply the Grafana service:
oc apply -f grafana-service.yaml
Verify Grafana deployment:
oc get pods -l app=grafana
oc get svc grafana-service
Subtask 2.2: Create Routes for External Access
Create route for Prometheus:
oc expose service prometheus-service --name=prometheus-route
Create route for Grafana:
oc expose service grafana-service --name=grafana-route
Get the routes:
oc get routes
Test access to Prometheus:
PROMETHEUS_URL=$(oc get route prometheus-route -o jsonpath='{.spec.host}')
echo "Prometheus URL: http://$PROMETHEUS_URL"
curl -s http://$PROMETHEUS_URL/api/v1/query?query=up | head -20
Test access to Grafana:
GRAFANA_URL=$(oc get route grafana-route -o jsonpath='{.spec.host}')
echo "Grafana URL: http://$GRAFANA_URL"
echo "Username: admin"
echo "Password: admin123"
Subtask 2.3: Import Kubernetes Cluster Monitoring Dashboard
Create a comprehensive cluster monitoring dashboard:
cat << 'EOF' > cluster-dashboard.json
{
  "dashboard": {
    "id": null,
    "title": "Kubernetes Cluster Monitoring",
    "tags": ["kubernetes", "cluster"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Cluster CPU Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Cluster Memory Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "100 * (1 - ((avg_over_time(node_memory_MemFree_bytes[10m]) + avg_over_time(node_memory_Cached_bytes[10m]) + avg_over_time(node_memory_Buffers_bytes[10m])) / avg_over_time(node_memory_MemTotal_bytes[10m])))",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "id": 3,
        "title": "Pod Count by Namespace",
        "type": "bargauge",
        "targets": [
          {
            "expr": "count by (namespace) (kube_pod_info)",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
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
Create a ConfigMap with the dashboard:
oc create configmap cluster-dashboard --from-file=cluster-dashboard.json -n monitoring-lab
Access Grafana and import the dashboard manually:
Open your browser and navigate to the Grafana URL
Login with username: admin and password: admin123
Go to Dashboards > Import
Copy the content from the cluster-dashboard.json file and paste it
Click Load and then Import
Subtask 2.4: Create Node Exporter for Detailed Metrics
Deploy Node Exporter as a DaemonSet:
cat << 'EOF' > node-exporter.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring-lab
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      hostNetwork: true
      hostPID: true
      containers:
      - name: node-exporter
        image: prom/node-exporter:v1.6.1
        args:
        - --path.procfs=/host/proc
        - --path.sysfs=/host/sys
        - --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)
        ports:
        - containerPort: 9100
          hostPort: 9100
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
        resources:
          requests:
            memory: 50Mi
            cpu: 50m
          limits:
            memory: 100Mi
            cpu: 100m
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
      tolerations:
      - operator: Exists
---
apiVersion: v1
kind: Service
metadata:
  name: node-exporter
  namespace: monitoring-lab
  labels:
    app: node-exporter
spec:
  ports:
  - port: 9100
    targetPort: 9100
    name: metrics
  selector:
    app: node-exporter
EOF
Apply the Node Exporter configuration:
oc apply -f node-exporter.yaml
Create ServiceMonitor for Node Exporter:
cat << 'EOF' > node-exporter-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: node-exporter
  namespace: monitoring-lab
  labels:
    team: monitoring
spec:
  selector:
    matchLabels:
      app: node-exporter
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
EOF
Apply the ServiceMonitor:
oc apply -f node-exporter-servicemonitor.yaml
Verify Node Exporter deployment:
oc get daemonset node-exporter
oc get pods -l app=node-exporter
Task 3: Integrate Prometheus Alerts for Resource Utilization Thresholds
Subtask 3.1: Deploy Alertmanager
Create Alertmanager configuration:
cat << 'EOF' > alertmanager-config.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-main
  namespace: monitoring-lab
stringData:
  alertmanager.yml: |
    global:
      smtp_smarthost: 'localhost:587'
      smtp_from: 'alertmanager@example.com'
    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'web.hook'
    receivers:
    - name: 'web.hook'
      webhook_configs:
      - url: 'http://127.0.0.1:5001/'
        send_resolved: true
    inhibit_rules:
    - source_match:
        severity: 'critical'
      target_match:
        severity: 'warning'
      equal: ['alertname', 'dev', 'instance']
EOF
Apply the Alertmanager configuration:
oc apply -f alertmanager-config.yaml
Create Alertmanager instance:
cat << 'EOF' > alertmanager-instance.yaml
apiVersion: monitoring.coreos.com/v1
kind: Alertmanager
metadata:
  name: alertmanager-main
  namespace: monitoring-lab
spec:
  replicas: 1
  serviceAccountName: alertmanager
  configSecret: alertmanager-main
  resources:
    requests:
      memory: 100Mi
      cpu: 50m
    limits:
      memory: 200Mi
      cpu: 100m
EOF
Create ServiceAccount for Alertmanager:
cat << 'EOF' > alertmanager-sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: alertmanager
  namespace: monitoring-lab
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: alertmanager
rules:
- apiGroups: [""]
  resources: ["nodes", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: alertmanager
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: alertmanager
subjects:
- kind: ServiceAccount
  name: alertmanager
  namespace: monitoring-lab
EOF
Apply the ServiceAccount and deploy Alertmanager:
oc apply -f alertmanager-sa.yaml
oc apply -f alertmanager-instance.yaml
Create Alertmanager service:
cat << 'EOF' > alertmanager-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: alertmanager-service
  namespace: monitoring-lab
spec:
  selector:
    app.kubernetes.io/name: alertmanager
  ports:
  - port: 9093
    targetPort: 9093
    name: web
EOF
Apply the service and create route:
oc apply -f alertmanager-service.yaml
oc expose service alertmanager-service --name=alertmanager-route
Subtask 3.2: Create Prometheus Alert Rules
Create comprehensive alert rules:
cat << 'EOF' > prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: cluster-alerts
  namespace: monitoring-lab
  labels:
    team: monitoring
spec:
  groups:
  - name: cluster.rules
    rules:
    - alert: HighCPUUsage
      expr: 100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage detected"
        description: "CPU usage is above 80% for more than 5 minutes"
    
    - alert: HighMemoryUsage
      expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage detected"
        description: "Memory usage is above 85% for more than 5 minutes"
    
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Pod is crash looping"
        description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is crash looping"
    
    - alert: NodeNotReady
      expr: kube_node_status_condition{condition="Ready",status="true"} == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Node is not ready"
        description: "Node {{ $labels.node }} has been not ready for more than 5 minutes"
    
    - alert: DiskSpaceUsage
      expr: (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100 > 90
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High disk usage detected"
        description: "Disk usage on {{ $labels.device }} is above 90%"
    
    - alert: PodMemoryUsage
      expr: (container_memory_working_set_bytes / container_spec_memory_limit_bytes) * 100 > 90
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod memory usage is high"
        description: "Pod {{ $labels.pod }} memory usage is above 90% of limit"
EOF
Apply the alert rules:
oc apply -f prometheus-rules.yaml
Verify the rules are loaded:
oc get prometheusrules
Subtask 3.3: Test Alert Functionality
Create a test pod that will trigger alerts:
cat << 'EOF' > stress-test-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: stress-test
  namespace: monitoring-lab
spec:
  containers:
  - name: stress
    image: polinux/stress
    command: ["stress"]
    args: ["--cpu", "2", "--timeout", "300s"]
    resources:
      requests:
        memory: "100Mi"
        cpu: "100m"
      limits:
        memory: "200Mi"
        cpu: "200m"
EOF
Deploy the stress test pod:
oc apply -f stress-test-pod.yaml
Monitor the pod and check for alerts:
oc get pods stress-test
oc logs stress-test
Check Prometheus for active alerts:
PROMETHEUS_URL=$(oc get route prometheus-route -o jsonpath='{.spec.host}')
curl -s "http://$PROMETHEUS_URL/api/v1/alerts" | python3 -m json.tool
Access Alertmanager to view alerts:
ALERTMANAGER_URL=$(oc get route alertmanager-route -o jsonpath='{.spec.host}')
echo "Alertmanager URL: http://$ALERTMANAGER_URL"
Subtask 3.4: Configure Alert Notification Channels
Update Alertmanager configuration with Slack webhook (example):
cat << 'EOF' > alertmanager-config-updated.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-main
  namespace: monitoring-lab
stringData:
  alertmanager.yml: |
    global:
      slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'default'
      routes:
      - match:
          severity: critical
        receiver: 'critical-alerts'
      - match:
          severity: warning
        receiver: 'warning-alerts'
    receivers:
    - name: 'default'
      slack_configs:
      - channel: '#monitoring'
        title: 'Cluster Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
    - name: 'critical-alerts'
      slack_configs:
      - channel: '#critical-alerts'
        title: 'CRITICAL: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
        color: 'danger'
    - name: 'warning-alerts'
      slack_configs:
      - channel: '#warnings'
        title: 'WARNING: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
        color: 'warning'
EOF
Apply the updated configuration:
oc apply -f alertmanager-config-updated.yaml
Restart Alertmanager to pick up new configuration:
oc delete pod -l app.kubernetes.io/name=alertmanager
Verify Alertmanager is running with new config:
oc get pods -l app.kubernetes.io/name=alertmanager
Verification and Testing
Verify Complete Monitoring Stack
Check all monitoring components:
echo "=== Monitoring Stack Status ==="
echo "Prometheus Operator:"
oc get pods -l app=prometheus-operator
echo ""
echo "Prometheus Instance:"
oc get pods -l app.kubernetes.io/name=prometheus
echo ""
echo "Grafana:"
oc get pods -l app=grafana
echo ""
echo "Alertmanager:"
oc get pods -l app.kubernetes.io/name=alertmanager
echo ""
echo "Node Exporter:"
oc get pods -l app=node-exporter
Test metric collection:
PROMETHEUS_URL=$(oc get route prometheus-route -o jsonpath='{.spec.host}')
echo "Testing Prometheus metrics collection..."
curl -s "http://$PROMETHEUS_URL/api/v1/query?query=up" | python3 -m json.tool | head -20
Verify ServiceMonitors are working:
oc get servicemonitors
curl -s "http://$PROMETHEUS_URL/api/v1/targets" | python3 -m json.tool | grep -A5 -B5 "health"
Check alert rules:
curl -s "http://$PROMETHEUS_URL/api/v1/rules" | python3 -m json.tool | grep -A3 -B3 "alertname"
Access URLs Summary
Get all access URLs:
echo "=== Monitoring Stack Access URLs ==="
echo "Prometheus: http://$(oc get route prometheus-route -o jsonpath='{.spec.host}')"
echo "Grafana: http://$(oc get route grafana-route -o jsonpath='{.spec.host}') (admin/admin123)"
echo "Alertmanager: http://$(oc get route alertmanager-route -o jsonpath='{.spec.host}')"
Troubleshooting Common Issues
Issue 1: Prometheus Not Scraping Targets
Problem: Targets showing as down in Prometheus

Solution:

# Check ServiceMonitor labels
oc get servicemonitors -o yaml | grep -A10 -B10 labels

# Verify Prometheus selector matches ServiceMonitor labels
oc
