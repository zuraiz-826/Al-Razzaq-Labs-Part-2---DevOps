Lab 8: Monitoring ODF Storage with OpenShift Dashboard
Objectives
By the end of this lab, you will be able to:

Set up and navigate the OpenShift Data Foundation (ODF) Dashboard in the OpenShift Web Console
Monitor storage capacity, utilization, and performance metrics using built-in dashboards
Analyze IOPS (Input/Output Operations Per Second) and throughput metrics
Identify and troubleshoot storage issues using ODF logs and health indicators
Interpret storage performance data to optimize cluster storage resources
Use monitoring tools to proactively manage storage infrastructure
Prerequisites
Before starting this lab, you should have:

Basic understanding of OpenShift Container Platform concepts
Familiarity with Kubernetes storage concepts (PVs, PVCs, StorageClasses)
Knowledge of container storage fundamentals
Experience navigating web-based administrative interfaces
Understanding of basic storage performance metrics
Completion of previous ODF installation and configuration labs
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift and ODF already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

OpenShift Container Platform 4.12+ cluster
OpenShift Data Foundation 4.12+ installed and configured
Pre-configured storage classes and sample workloads
Administrative access to the OpenShift Web Console
Sample applications generating storage I/O for monitoring
Task 1: Set up ODF Dashboard in OpenShift Web Console
Subtask 1.1: Access the OpenShift Web Console
Open your web browser and navigate to the OpenShift Web Console URL provided in your lab environment.

Log in using the administrator credentials:

Username: admin
Password: [provided in lab environment]
Verify successful login by confirming you can see the OpenShift dashboard with cluster overview information.

Subtask 1.2: Navigate to ODF Monitoring Dashboard
Access the Administrator perspective by clicking on the perspective switcher in the top-left corner and selecting Administrator.

Navigate to Storage in the left navigation menu and click on Data Foundation.

Explore the ODF Overview page which provides:

Cluster storage capacity summary
Storage system health status
Recent alerts and events
Quick access to monitoring dashboards
Subtask 1.3: Configure Dashboard Views
Access the Monitoring section by clicking on Observe in the left navigation menu.

Select Dashboards from the Observe submenu.

Filter for ODF dashboards by typing "ODF" or "Ceph" in the search box.

Identify key dashboards available for monitoring:

ODF - Block and File Dashboard
ODF - Object Service Dashboard
Ceph - Cluster Dashboard
Ceph - OSD Dashboard
Ceph - Pools Dashboard
Subtask 1.4: Customize Dashboard Layout
Open the ODF - Block and File Dashboard by clicking on it from the dashboard list.

Explore dashboard customization options:

Time range selector (last 1h, 6h, 24h, etc.)
Refresh interval settings
Panel arrangement and sizing
Set appropriate time range for monitoring by selecting Last 1 hour from the time range dropdown.

Enable auto-refresh by setting the refresh interval to 30 seconds for real-time monitoring.

Task 2: Monitor Storage Capacity, IOPS, and Performance Metrics
Subtask 2.1: Monitor Storage Capacity Metrics
Access the Storage Capacity panel in the ODF dashboard to view:

Total cluster storage capacity
Used storage space
Available storage space
Storage utilization percentage
Analyze capacity trends by examining the capacity utilization graph over time.

Document current capacity metrics by recording:

Total Capacity: _____ GB/TB
Used Capacity: _____ GB/TB
Available Capacity: _____ GB/TB
Utilization Percentage: _____%
Set up capacity alerts by navigating to Observe > Alerting and reviewing existing storage capacity alert rules.

Subtask 2.2: Monitor IOPS Performance
Locate the IOPS metrics panel in the dashboard showing:

Read IOPS (Input/Output Operations Per Second)
Write IOPS
Total IOPS
IOPS trends over time
Generate storage I/O activity to observe metrics in action:

# Connect to a cluster node via terminal
oc debug node/[node-name]

# Create a test workload that generates I/O
oc create -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: storage-io-test
spec:
  containers:
  - name: io-generator
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do dd if=/dev/zero of=/data/testfile bs=1M count=100; rm /data/testfile; sleep 5; done"]
    volumeMounts:
    - name: test-storage
      mountPath: /data
  volumes:
  - name: test-storage
    persistentVolumeClaim:
      claimName: test-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Monitor IOPS changes in the dashboard as the test workload runs.

Record peak IOPS values:

Peak Read IOPS: _____
Peak Write IOPS: _____
Average Total IOPS: _____
Subtask 2.3: Analyze Performance Metrics
Examine throughput metrics in the dashboard:

Read throughput (MB/s or GB/s)
Write throughput (MB/s or GB/s)
Network I/O related to storage
Monitor latency metrics:

Average read latency
Average write latency
95th percentile latency values
Check cluster performance indicators:

CPU utilization on storage nodes
Memory usage on storage nodes
Network bandwidth utilization
Create a performance baseline by documenting current metrics:

Read Throughput: _____ MB/s
Write Throughput: _____ MB/s
Average Read Latency: _____ ms
Average Write Latency: _____ ms
Subtask 2.4: Monitor Storage Pool Health
Navigate to the Ceph - Pools Dashboard to monitor individual storage pools.

Review pool-specific metrics:

Pool utilization percentages
Pool IOPS distribution
Pool health status
Placement group (PG) status
Identify any performance bottlenecks by comparing metrics across different pools.

Check replication status and data distribution across the cluster.

Task 3: Troubleshoot Using ODF Logs and Health Metrics
Subtask 3.1: Access ODF System Logs
Navigate to Observe > Logs in the OpenShift Web Console.

Filter logs for ODF components using the following queries:

# Filter for ODF operator logs
{kubernetes_namespace_name="openshift-storage"} |= "ocs-operator"

# Filter for Ceph logs
{kubernetes_namespace_name="openshift-storage"} |= "rook-ceph"

# Filter for storage-related errors
{kubernetes_namespace_name="openshift-storage"} |= "error" or "Error" or "ERROR"
Set appropriate time range for log analysis (last 1 hour or as needed).

Export relevant log entries for further analysis if issues are found.

Subtask 3.2: Analyze Health Metrics and Alerts
Check cluster health status in the ODF dashboard:

Overall cluster health (HEALTH_OK, HEALTH_WARN, HEALTH_ERR)
Individual component health status
Active alerts and warnings
Review active alerts by navigating to Observe > Alerting:

# Use CLI to check alerts related to storage
oc get alerts -n openshift-storage

# Get detailed information about specific alerts
oc describe alert [alert-name] -n openshift-storage
Investigate warning conditions:

Storage capacity warnings (>75% utilization)
Performance degradation alerts
Hardware or node-related issues
Network connectivity problems
Subtask 3.3: Troubleshoot Common Issues
Diagnose high storage utilization:

# Check PVC usage across namespaces
oc get pvc --all-namespaces

# Identify large consumers
oc get pvc --all-namespaces --sort-by=.spec.resources.requests.storage

# Check for unused PVCs
oc get pvc --all-namespaces -o json | jq '.items[] | select(.status.phase=="Bound") | select(.spec.volumeName as $pv | [.metadata.ownerReferences[]?.kind] | index("Pod") | not) | {name: .metadata.name, namespace: .metadata.namespace, size: .spec.resources.requests.storage}'
Investigate performance issues:

# Check OSD (Object Storage Daemon) status
oc exec -n openshift-storage deployment/rook-ceph-tools -- ceph osd status

# Check cluster performance statistics
oc exec -n openshift-storage deployment/rook-ceph-tools -- ceph osd perf

# Monitor real-time cluster status
oc exec -n openshift-storage deployment/rook-ceph-tools -- ceph -w
Resolve connectivity issues:

# Check network connectivity between storage nodes
oc get nodes -l cluster.ocs.openshift.io/openshift-storage=

# Verify storage node readiness
oc get nodes -l cluster.ocs.openshift.io/openshift-storage= -o wide

# Check storage operator status
oc get csv -n openshift-storage
Subtask 3.4: Create Monitoring Alerts
Create custom alert rules for proactive monitoring:

# Create a custom alert for high storage utilization
oc create -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: odf-custom-alerts
  namespace: openshift-storage
spec:
  groups:
  - name: odf.custom.rules
    rules:
    - alert: ODFStorageUtilizationHigh
      expr: (ceph_cluster_total_used_bytes / ceph_cluster_total_bytes) * 100 > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "ODF storage utilization is high"
        description: "Storage utilization is above 80% for more than 5 minutes"
EOF
Configure notification channels for alerts (if webhook endpoints are available):

# Check existing alert manager configuration
oc get secret alertmanager-main -n openshift-monitoring -o yaml
Test alert functionality by temporarily creating conditions that trigger alerts.

Subtask 3.5: Performance Optimization
Identify optimization opportunities based on monitoring data:

Uneven data distribution across OSDs
Suboptimal placement group counts
Network bottlenecks
Resource constraints on storage nodes
Implement basic optimizations:

# Balance data across OSDs if needed
oc exec -n openshift-storage deployment/rook-ceph-tools -- ceph osd reweight-by-utilization

# Check and optimize placement group counts
oc exec -n openshift-storage deployment/rook-ceph-tools -- ceph osd pool ls detail
Monitor the impact of optimizations using the dashboard metrics.

Subtask 3.6: Generate Monitoring Report
Document current cluster status:

Cluster Health: _____
Active Alerts: _____
Storage Utilization: _____%
Average IOPS: _____
Average Latency: _____ ms
Create a summary of findings:

Performance bottlenecks identified
Capacity planning recommendations
Optimization actions taken
Monitoring improvements implemented
Export dashboard data for reporting:

# Export Prometheus metrics for external analysis
oc port-forward -n openshift-monitoring svc/prometheus-k8s 9090:9090
# Access http://localhost:9090 to query and export metrics
Troubleshooting Tips
Common Issues and Solutions
Dashboard Not Loading:

Verify ODF installation status: oc get csv -n openshift-storage
Check monitoring stack health: oc get pods -n openshift-monitoring
Ensure proper RBAC permissions for monitoring
Missing Metrics:

Confirm Prometheus is scraping ODF metrics: oc get servicemonitor -n openshift-storage
Check if storage workloads are generating I/O
Verify time range selection in dashboard
High Storage Utilization Alerts:

Identify and clean up unused PVCs
Expand storage cluster if needed
Implement data lifecycle policies
Performance Degradation:

Check network connectivity between storage nodes
Monitor CPU and memory usage on storage nodes
Verify disk health and performance
Conclusion
In this lab, you have successfully:

Set up comprehensive monitoring for OpenShift Data Foundation using the built-in dashboard capabilities
Learned to interpret key storage metrics including capacity utilization, IOPS, throughput, and latency measurements
Gained hands-on experience with troubleshooting storage issues using logs, health metrics, and performance indicators
Implemented proactive monitoring through custom alerts and performance optimization techniques
Why This Matters: Effective storage monitoring is crucial for maintaining application performance and preventing data loss in production environments. The skills you've developed enable you to:

Proactively identify storage bottlenecks before they impact applications
Optimize storage performance through data-driven decisions
Plan capacity expansion based on utilization trends
Troubleshoot issues quickly using comprehensive monitoring tools
Maintain high availability of storage services in OpenShift clusters
These monitoring capabilities are essential for Red Hat Certified Specialists in OpenShift Data Foundation and are directly applicable to real-world enterprise storage management scenarios. The dashboard and troubleshooting techniques you've mastered will help you maintain robust, high-performing storage infrastructure in production OpenShift environments.

Next Steps: Consider exploring advanced monitoring topics such as custom Grafana dashboards, integration with external monitoring systems, and automated remediation workflows based on monitoring data.
