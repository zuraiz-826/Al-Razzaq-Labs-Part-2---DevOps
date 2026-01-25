Lab 20: Troubleshooting OpenShift Cluster Issues
Objectives
By the end of this lab, students will be able to:

• Use oc logs and oc describe commands to inspect cluster components and pod logs effectively • Identify and troubleshoot failing applications using built-in OpenShift monitoring tools • Implement Prometheus and Grafana for advanced application monitoring and troubleshooting • Resolve common OpenShift cluster issues including resource constraints, networking problems, and deployment failures • Apply systematic troubleshooting methodologies for OpenShift environments • Understand log analysis techniques for identifying root causes of application failures

Prerequisites
Before starting this lab, students should have:

• Basic understanding of OpenShift concepts including pods, services, and deployments • Familiarity with command-line interface operations • Knowledge of YAML configuration files • Understanding of containerized applications and Kubernetes fundamentals • Completion of previous OpenShift administration labs or equivalent experience

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift cluster access. Simply click Start Lab to begin - no need to build your own VM or install additional software.

Your lab environment includes: • OpenShift cluster with admin access • Pre-installed oc CLI tool • Sample applications for troubleshooting exercises • Prometheus and Grafana monitoring stack

Task 1: Using oc logs and oc describe for Cluster Inspection
Subtask 1.1: Verify Cluster Status and Access
First, let's ensure your OpenShift cluster is accessible and check its overall health.

Login to OpenShift cluster:
oc login --server=https://api.cluster.example.com:6443 --username=admin --password=admin123
Verify cluster nodes status:
oc get nodes
Check cluster operators status:
oc get clusteroperators
View cluster version information:
oc version
Subtask 1.2: Inspect Pod Logs Using oc logs
Now we'll examine pod logs to identify potential issues.

List all pods across namespaces:
oc get pods --all-namespaces
Create a test namespace and deployment:
oc new-project troubleshooting-lab
Deploy a sample application with intentional issues:
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: problematic-app
  namespace: troubleshooting-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: problematic-app
  template:
    metadata:
      labels:
        app: problematic-app
    spec:
      containers:
      - name: web-server
        image: nginx:1.20
        ports:
        - containerPort: 80
        env:
        - name: INVALID_CONFIG
          value: "this-will-cause-issues"
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
EOF
Check pod status:
oc get pods -n troubleshooting-lab
Examine pod logs for errors:
# Get pod name first
POD_NAME=$(oc get pods -n troubleshooting-lab -o jsonpath='{.items[0].metadata.name}')

# View current logs
oc logs $POD_NAME -n troubleshooting-lab

# View logs with timestamps
oc logs $POD_NAME -n troubleshooting-lab --timestamps=true

# Follow logs in real-time
oc logs $POD_NAME -n troubleshooting-lab --follow
View previous container logs if pod restarted:
oc logs $POD_NAME -n troubleshooting-lab --previous
Subtask 1.3: Using oc describe for Detailed Resource Information
The oc describe command provides comprehensive information about OpenShift resources.

Describe the problematic pod:
oc describe pod $POD_NAME -n troubleshooting-lab
Describe the deployment:
oc describe deployment problematic-app -n troubleshooting-lab
Describe the namespace:
oc describe namespace troubleshooting-lab
Check node resource utilization:
# Get node name
NODE_NAME=$(oc get nodes -o jsonpath='{.items[0].metadata.name}')

# Describe the node
oc describe node $NODE_NAME
Examine events for troubleshooting:
# View events in the namespace
oc get events -n troubleshooting-lab --sort-by='.lastTimestamp'

# View cluster-wide events
oc get events --all-namespaces --sort-by='.lastTimestamp'
Task 2: Troubleshooting a Failing Application Using Prometheus and Grafana
Subtask 2.1: Deploy Prometheus Monitoring Stack
Create monitoring namespace:
oc new-project monitoring-stack
Deploy Prometheus using OpenShift templates:
cat << EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring-stack
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
    - job_name: 'kubernetes-nodes'
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring-stack
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:v2.40.0
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config-volume
          mountPath: /etc/prometheus
        args:
        - '--config.file=/etc/prometheus/prometheus.yml'
        - '--storage.tsdb.path=/prometheus'
        - '--web.console.libraries=/etc/prometheus/console_libraries'
        - '--web.console.templates=/etc/prometheus/consoles'
      volumes:
      - name: config-volume
        configMap:
          name: prometheus-config
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
  namespace: monitoring-stack
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
  type: ClusterIP
EOF
Expose Prometheus service:
oc expose service prometheus-service -n monitoring-stack
Subtask 2.2: Deploy Grafana for Visualization
Deploy Grafana:
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring-stack
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
        image: grafana/grafana:9.3.0
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin123"
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
      volumes:
      - name: grafana-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-service
  namespace: monitoring-stack
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
EOF
Expose Grafana service:
oc expose service grafana-service -n monitoring-stack
Get Grafana route URL:
oc get route grafana-service -n monitoring-stack
Subtask 2.3: Create a Failing Application for Monitoring
Deploy an application with resource issues:
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-hungry-app
  namespace: troubleshooting-lab
  labels:
    app: resource-hungry-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: resource-hungry-app
  template:
    metadata:
      labels:
        app: resource-hungry-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
    spec:
      containers:
      - name: app
        image: nginx:1.20
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: resource-hungry-service
  namespace: troubleshooting-lab
spec:
  selector:
    app: resource-hungry-app
  ports:
  - port: 8080
    targetPort: 8080
EOF
Subtask 2.4: Monitor and Troubleshoot Using Prometheus Queries
Access Prometheus web interface:
# Get Prometheus route
oc get route prometheus-service -n monitoring-stack

# Port forward if route is not available
oc port-forward service/prometheus-service 9090:9090 -n monitoring-stack
Execute troubleshooting queries in Prometheus:
Check pod CPU usage:

rate(container_cpu_usage_seconds_total[5m])
Check memory usage:

container_memory_usage_bytes / container_spec_memory_limit_bytes
Check pod restart count:

kube_pod_container_status_restarts_total
Check failed pods:

kube_pod_status_phase{phase="Failed"}
Analyze the metrics and identify issues:
# Check current resource usage
oc top pods -n troubleshooting-lab

# Check node resource availability
oc top nodes
Task 3: Resolve Common OpenShift Cluster Issues
Subtask 3.1: Resolve Resource Constraint Issues
Identify resource constraints:
# Check pod status for resource-related issues
oc get pods -n troubleshooting-lab -o wide

# Describe pods to see resource-related events
oc describe pods -n troubleshooting-lab
Fix resource constraints by adjusting limits:
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-hungry-app
  namespace: troubleshooting-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: resource-hungry-app
  template:
    metadata:
      labels:
        app: resource-hungry-app
    spec:
      containers:
      - name: app
        image: nginx:1.20
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
EOF
Verify the fix:
oc get pods -n troubleshooting-lab
oc describe deployment resource-hungry-app -n troubleshooting-lab
Subtask 3.2: Troubleshoot Networking Issues
Create a service with networking problems:
cat << EOF | oc apply -f -
apiVersion: v1
kind: Service
metadata:
  name: broken-service
  namespace: troubleshooting-lab
spec:
  selector:
    app: nonexistent-app
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
EOF
Diagnose networking issues:
# Check service endpoints
oc get endpoints broken-service -n troubleshooting-lab

# Describe the service
oc describe service broken-service -n troubleshooting-lab

# Check if pods match the selector
oc get pods -n troubleshooting-lab --show-labels
Fix the networking issue:
# Update service selector to match existing pods
oc patch service broken-service -n troubleshooting-lab -p '{"spec":{"selector":{"app":"resource-hungry-app"}}}'

# Verify the fix
oc get endpoints broken-service -n troubleshooting-lab
Subtask 3.3: Resolve Image Pull Issues
Create a deployment with image pull problems:
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: image-pull-issue
  namespace: troubleshooting-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: image-pull-issue
  template:
    metadata:
      labels:
        app: image-pull-issue
    spec:
      containers:
      - name: app
        image: nonexistent-registry.com/fake-image:latest
        ports:
        - containerPort: 80
EOF
Diagnose image pull issues:
# Check pod status
oc get pods -n troubleshooting-lab

# Get detailed information about the failing pod
POD_NAME=$(oc get pods -n troubleshooting-lab -l app=image-pull-issue -o jsonpath='{.items[0].metadata.name}')
oc describe pod $POD_NAME -n troubleshooting-lab

# Check events
oc get events -n troubleshooting-lab --field-selector involvedObject.name=$POD_NAME
Fix the image pull issue:
# Update deployment with correct image
oc patch deployment image-pull-issue -n troubleshooting-lab -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","image":"nginx:1.20"}]}}}}'

# Verify the fix
oc get pods -n troubleshooting-lab -l app=image-pull-issue
Subtask 3.4: Troubleshoot Configuration Issues
Create a deployment with configuration problems:
cat << EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: troubleshooting-lab
data:
  config.properties: |
    database.url=jdbc:mysql://nonexistent-db:3306/app
    database.username=admin
    database.password=secret123
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-issue-app
  namespace: troubleshooting-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: config-issue-app
  template:
    metadata:
      labels:
        app: config-issue-app
    spec:
      containers:
      - name: app
        image: nginx:1.20
        ports:
        - containerPort: 80
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
        env:
        - name: CONFIG_FILE
          value: "/etc/config/config.properties"
      volumes:
      - name: config-volume
        configMap:
          name: nonexistent-configmap
EOF
Diagnose configuration issues:
# Check pod status
oc get pods -n troubleshooting-lab -l app=config-issue-app

# Describe the pod to see configuration errors
POD_NAME=$(oc get pods -n troubleshooting-lab -l app=config-issue-app -o jsonpath='{.items[0].metadata.name}')
oc describe pod $POD_NAME -n troubleshooting-lab
Fix configuration issues:
# Update deployment to use existing ConfigMap
oc patch deployment config-issue-app -n troubleshooting-lab -p '{"spec":{"template":{"spec":{"volumes":[{"name":"config-volume","configMap":{"name":"app-config"}}]}}}}'

# Verify the fix
oc get pods -n troubleshooting-lab -l app=config-issue-app
Subtask 3.5: Comprehensive Cluster Health Check
Create a comprehensive health check script:
cat << 'EOF' > cluster-health-check.sh
#!/bin/bash

echo "=== OpenShift Cluster Health Check ==="
echo

echo "1. Cluster Nodes Status:"
oc get nodes
echo

echo "2. Cluster Operators Status:"
oc get clusteroperators | grep -v "True.*False.*False"
echo

echo "3. Pods in Error State:"
oc get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded
echo

echo "4. Recent Events (Last 1 hour):"
oc get events --all-namespaces --sort-by='.lastTimestamp' | head -20
echo

echo "5. Node Resource Usage:"
oc top nodes
echo

echo "6. High Memory Usage Pods:"
oc top pods --all-namespaces --sort-by=memory | head -10
echo

echo "7. High CPU Usage Pods:"
oc top pods --all-namespaces --sort-by=cpu | head -10
echo

echo "=== Health Check Complete ==="
EOF

chmod +x cluster-health-check.sh
Run the health check:
./cluster-health-check.sh
Create automated monitoring alerts:
cat << EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: alerting-rules
  namespace: monitoring-stack
data:
  alerts.yml: |
    groups:
    - name: cluster-health
      rules:
      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Pod {{ \$labels.pod }} is using more than 80% of its memory limit"
      
      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Pod is crash looping"
          description: "Pod {{ \$labels.pod }} is restarting frequently"
EOF
Troubleshooting Tips and Common Issues
Common OpenShift Issues and Solutions
Issue 1: Pods Stuck in Pending State

Cause: Insufficient resources or scheduling constraints
Solution: Check node resources and adjust resource requests/limits
Issue 2: ImagePullBackOff Errors

Cause: Invalid image name, registry authentication issues, or network problems
Solution: Verify image name, check registry credentials, and test network connectivity
Issue 3: CrashLoopBackOff

Cause: Application configuration errors or resource constraints
Solution: Check application logs, verify configuration, and adjust resource limits
Issue 4: Service Not Accessible

Cause: Incorrect service selector or port configuration
Solution: Verify service selector matches pod labels and check port mappings
Best Practices for Troubleshooting
Always start with basic checks: node status, pod status, and recent events
Use systematic approach: logs → describe → events → metrics
Check resource utilization: CPU, memory, and storage usage
Verify network connectivity: services, routes, and DNS resolution
Monitor application metrics: use Prometheus and Grafana for insights
Conclusion
In this comprehensive lab, you have successfully learned to troubleshoot OpenShift cluster issues using various tools and techniques. You accomplished the following key objectives:

Technical Skills Gained: • Mastered the use of oc logs and oc describe commands for detailed cluster inspection and debugging • Implemented Prometheus and Grafana monitoring stack for advanced application troubleshooting • Resolved common OpenShift issues including resource constraints, networking problems, and configuration errors • Developed systematic troubleshooting methodologies for enterprise OpenShift environments

Practical Experience: • Diagnosed and fixed resource allocation problems that prevent pod scheduling • Resolved networking issues affecting service connectivity and application accessibility • Troubleshot image pull failures and configuration-related deployment problems • Created automated health checks and monitoring alerts for proactive issue detection

Why This Matters: These troubleshooting skills are essential for maintaining production OpenShift clusters in enterprise environments. The ability to quickly identify, diagnose, and resolve cluster issues minimizes downtime and ensures reliable application delivery. The monitoring and alerting capabilities you've implemented provide proactive insights that help prevent issues before they impact users.

The systematic approach you've learned - combining command-line tools, monitoring systems, and automated health checks - forms the foundation for effective OpenShift cluster administration and aligns with industry best practices for container platform management.
