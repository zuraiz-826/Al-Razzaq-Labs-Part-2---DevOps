Lab 11: Configuring Replication and Fault Tolerance in ODF
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of OpenShift Data Foundation (ODF) replication mechanisms
Configure replication policies for critical applications in ODF
Implement and test failover scenarios across multiple nodes
Monitor fault tolerance configurations using built-in ODF tools
Troubleshoot common replication and fault tolerance issues
Validate data consistency and availability during node failures
Prerequisites
Before starting this lab, students should have:

Basic understanding of Kubernetes and OpenShift concepts
Familiarity with storage concepts (PVs, PVCs, StorageClasses)
Knowledge of YAML configuration files
Experience with command-line interface operations
Completed previous ODF labs or equivalent knowledge
Understanding of distributed storage systems concepts
Required Knowledge Areas
OpenShift cluster administration basics
Storage provisioning concepts
Network connectivity fundamentals
Linux command-line operations
Lab Environment Setup
Al Nafi Cloud Machines: This lab uses pre-configured Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your environment - no need to build your own VM or configure infrastructure.

Environment Specifications
Operating System: Red Hat Enterprise Linux 8/9 or CentOS Stream
OpenShift Version: 4.12 or later
ODF Version: 4.12 or later
Cluster Nodes: Minimum 3 worker nodes with ODF installed
Storage: Each node equipped with additional block storage devices
Task 1: Enable ODF Replication for Critical Applications
Subtask 1.1: Verify ODF Installation and Cluster Status
First, let's verify that ODF is properly installed and running in your cluster.

# Check if ODF operator is installed
oc get csv -n openshift-storage | grep odf

# Verify ODF storage cluster status
oc get storagecluster -n openshift-storage

# Check storage nodes
oc get nodes -l cluster.ocs.openshift.io/openshift-storage=
Expected output should show ODF components in Succeeded or Ready state.

Subtask 1.2: Examine Current Storage Classes
# List available storage classes
oc get storageclass

# Get detailed information about ODF storage classes
oc describe storageclass ocs-storagecluster-ceph-rbd
oc describe storageclass ocs-storagecluster-cephfs
Subtask 1.3: Create a Replicated Storage Class
Create a custom storage class with specific replication settings for critical applications.

# Create file: critical-app-storageclass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: critical-app-rbd
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: openshift-storage.rbd.csi.ceph.com
parameters:
  clusterID: openshift-storage
  pool: ocs-storagecluster-cephblockpool
  imageFeatures: layering
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: openshift-storage
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: openshift-storage
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
  csi.storage.k8s.io/node-stage-secret-namespace: openshift-storage
  csi.storage.k8s.io/fstype: ext4
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate
Apply the storage class:

# Create the storage class
oc apply -f critical-app-storageclass.yaml

# Verify creation
oc get storageclass critical-app-rbd
Subtask 1.4: Configure Ceph Pool Replication
Check and configure the replication factor for the Ceph block pool.

# Access the Ceph toolbox pod
oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}')

# Inside the toolbox, check current pool configuration
ceph osd pool ls detail

# Check replication size for the RBD pool
ceph osd pool get ocs-storagecluster-cephblockpool size

# Set replication size to 3 for fault tolerance
ceph osd pool set ocs-storagecluster-cephblockpool size 3

# Set minimum replication size
ceph osd pool set ocs-storagecluster-cephblockpool min_size 2

# Verify the changes
ceph osd pool get ocs-storagecluster-cephblockpool size
ceph osd pool get ocs-storagecluster-cephblockpool min_size

# Exit the toolbox
exit
Subtask 1.5: Deploy a Critical Application with Replicated Storage
Create a sample critical application that uses the replicated storage.

# Create file: critical-app-deployment.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: critical-apps
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: critical-data-pvc
  namespace: critical-apps
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: critical-app-rbd
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-database
  namespace: critical-apps
  labels:
    app: critical-database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: critical-database
  template:
    metadata:
      labels:
        app: critical-database
    spec:
      containers:
      - name: postgresql
        image: registry.redhat.io/rhel8/postgresql-13:latest
        env:
        - name: POSTGRESQL_USER
          value: "testuser"
        - name: POSTGRESQL_PASSWORD
          value: "testpass123"
        - name: POSTGRESQL_DATABASE
          value: "criticaldb"
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: data-volume
          mountPath: /var/lib/pgsql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: data-volume
        persistentVolumeClaim:
          claimName: critical-data-pvc
Deploy the application:

# Create the critical application
oc apply -f critical-app-deployment.yaml

# Verify deployment
oc get pods -n critical-apps
oc get pvc -n critical-apps

# Check which node the pod is running on
oc get pods -n critical-apps -o wide
Task 2: Test Replication and Failover Across Nodes
Subtask 2.1: Verify Data Replication Status
# Check the PV details to see which Ceph RBD image is being used
oc get pv $(oc get pvc critical-data-pvc -n critical-apps -o jsonpath='{.spec.volumeName}') -o yaml

# Access Ceph toolbox to check replication status
oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}')

# Inside toolbox, check RBD images and their replication
rbd ls ocs-storagecluster-cephblockpool
rbd info ocs-storagecluster-cephblockpool/$(rbd ls ocs-storagecluster-cephblockpool | head -1)

# Check OSD status and data distribution
ceph osd tree
ceph pg dump | grep active+clean

exit
Subtask 2.2: Create Test Data in the Application
# Connect to the database pod and create test data
oc exec -it -n critical-apps $(oc get pods -n critical-apps -l app=critical-database -o jsonpath='{.items[0].metadata.name}') -- bash

# Inside the pod, connect to PostgreSQL
psql -U testuser -d criticaldb

# Create test table and insert data
CREATE TABLE test_replication (
    id SERIAL PRIMARY KEY,
    data VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO test_replication (data) VALUES 
('Critical data entry 1'),
('Critical data entry 2'),
('Critical data entry 3'),
('Mission critical information'),
('Fault tolerance test data');

# Verify data
SELECT * FROM test_replication;

# Exit PostgreSQL and pod
\q
exit
Subtask 2.3: Simulate Node Failure
Identify the node running the critical application and simulate its failure.

# Get the node where the pod is running
NODE_NAME=$(oc get pods -n critical-apps -l app=critical-database -o jsonpath='{.items[0].spec.nodeName}')
echo "Pod is running on node: $NODE_NAME"

# Cordon the node to prevent new pods from being scheduled
oc adm cordon $NODE_NAME

# Drain the node to move existing pods
oc adm drain $NODE_NAME --ignore-daemonsets --delete-emptydir-data --force

# Verify the pod has been rescheduled to another node
oc get pods -n critical-apps -o wide

# Wait for the pod to be running on the new node
oc wait --for=condition=Ready pod -l app=critical-database -n critical-apps --timeout=300s
Subtask 2.4: Verify Data Integrity After Failover
# Connect to the rescheduled pod
oc exec -it -n critical-apps $(oc get pods -n critical-apps -l app=critical-database -o jsonpath='{.items[0].metadata.name}') -- bash

# Connect to PostgreSQL and verify data integrity
psql -U testuser -d criticaldb

# Check if all data is still present
SELECT * FROM test_replication ORDER BY id;

# Add new data to verify write operations work
INSERT INTO test_replication (data) VALUES ('Post-failover data entry');

# Verify the new entry
SELECT * FROM test_replication WHERE data LIKE '%Post-failover%';

\q
exit
Subtask 2.5: Test Storage-Level Failover
# Check current OSD status
oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}')

# Inside toolbox
ceph osd tree
ceph -s

# Identify an OSD to simulate failure (choose one that has data)
ceph osd out osd.0

# Monitor cluster rebalancing
watch ceph -s

# After rebalancing completes (press Ctrl+C to exit watch), verify data
exit

# Verify application still works
oc exec -it -n critical-apps $(oc get pods -n critical-apps -l app=critical-database -o jsonpath='{.items[0].metadata.name}') -- psql -U testuser -d criticaldb -c "SELECT COUNT(*) FROM test_replication;"
Task 3: Monitor Fault Tolerance Configurations
Subtask 3.1: Set Up Monitoring Dashboard Access
# Get the ODF monitoring route
oc get routes -n openshift-storage | grep dashboard

# If no route exists, create one for the Ceph dashboard
oc create route edge ceph-dashboard --service=rook-ceph-mgr-dashboard -n openshift-storage

# Get the dashboard URL
echo "Ceph Dashboard URL: https://$(oc get route ceph-dashboard -n openshift-storage -o jsonpath='{.spec.host}')"

# Get dashboard admin password
oc get secret rook-ceph-dashboard-password -n openshift-storage -o jsonpath='{.data.password}' | base64 -d && echo
Subtask 3.2: Monitor Cluster Health Using CLI Tools
# Create a monitoring script
cat > monitor-odf-health.sh << 'EOF'
#!/bin/bash

echo "=== ODF Cluster Health Monitor ==="
echo "Timestamp: $(date)"
echo

# Check storage cluster status
echo "1. Storage Cluster Status:"
oc get storagecluster -n openshift-storage -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,HEALTH:.status.cephStatus.health

echo
echo "2. Ceph Cluster Status:"
oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}') ceph -s

echo
echo "3. OSD Status:"
oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}') ceph osd stat

echo
echo "4. Pool Status:"
oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}') ceph df

echo
echo "5. PVC Status:"
oc get pvc -A | grep -E "(Bound|Pending|Lost)"

echo
echo "6. Storage Node Status:"
oc get nodes -l cluster.ocs.openshift.io/openshift-storage= -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[?(@.type==\"Ready\")].status,ROLES:.metadata.labels.node-role\.kubernetes\.io/worker

echo "=== End of Health Check ==="
EOF

chmod +x monitor-odf-health.sh

# Run the monitoring script
./monitor-odf-health.sh
Subtask 3.3: Set Up Continuous Monitoring
# Create a monitoring loop script
cat > continuous-monitor.sh << 'EOF'
#!/bin/bash

INTERVAL=30  # Check every 30 seconds
LOG_FILE="/tmp/odf-health-$(date +%Y%m%d-%H%M%S).log"

echo "Starting continuous ODF monitoring..."
echo "Log file: $LOG_FILE"
echo "Check interval: ${INTERVAL} seconds"
echo "Press Ctrl+C to stop"

while true; do
    echo "=== Health Check at $(date) ===" >> $LOG_FILE
    
    # Quick health check
    STORAGE_STATUS=$(oc get storagecluster -n openshift-storage -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    echo "Storage Cluster Phase: $STORAGE_STATUS" >> $LOG_FILE
    
    # Check critical application
    APP_STATUS=$(oc get pods -n critical-apps -l app=critical-database -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    echo "Critical App Status: $APP_STATUS" >> $LOG_FILE
    
    # Check Ceph health
    CEPH_HEALTH=$(oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}') ceph health 2>/dev/null)
    echo "Ceph Health: $CEPH_HEALTH" >> $LOG_FILE
    
    echo "---" >> $LOG_FILE
    
    # Display current status
    echo "[$(date)] Storage: $STORAGE_STATUS | App: $APP_STATUS | Ceph: $CEPH_HEALTH"
    
    sleep $INTERVAL
done
EOF

chmod +x continuous-monitor.sh

# Start monitoring in background (optional)
# ./continuous-monitor.sh &
# MONITOR_PID=$!
# echo "Monitoring started with PID: $MONITOR_PID"
Subtask 3.4: Create Alerting Rules
# Create file: odf-alerting-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: odf-fault-tolerance-alerts
  namespace: openshift-storage
  labels:
    prometheus: kube-prometheus
    role: alert-rules
spec:
  groups:
  - name: odf.fault-tolerance.rules
    rules:
    - alert: CephClusterErrorState
      expr: ceph_health_status == 2
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Ceph cluster is in error state"
        description: "Ceph cluster has been in error state for more than 5 minutes"
    
    - alert: CephOSDDown
      expr: ceph_osd_up == 0
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: "Ceph OSD is down"
        description: "OSD {{ $labels.ceph_daemon }} has been down for more than 2 minutes"
    
    - alert: CephPoolNearFull
      expr: ceph_pool_percent_used > 85
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Ceph pool is nearly full"
        description: "Pool {{ $labels.name }} is {{ $value }}% full"
Apply the alerting rules:

# Create the alerting rules
oc apply -f odf-alerting-rules.yaml

# Verify the rules are loaded
oc get prometheusrule -n openshift-storage odf-fault-tolerance-alerts
Subtask 3.5: Test Monitoring During Failure Scenarios
# Restore the previously failed OSD
oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}')

# Inside toolbox
ceph osd in osd.0
ceph -s

# Wait for recovery to complete
watch ceph -s

exit

# Uncordon the previously drained node
oc adm uncordon $NODE_NAME

# Verify cluster is back to healthy state
./monitor-odf-health.sh
Troubleshooting Common Issues
Issue 1: Pod Stuck in Pending State After Failover
# Check PVC status
oc describe pvc critical-data-pvc -n critical-apps

# Check storage class
oc describe storageclass critical-app-rbd

# Check node resources
oc describe node $(oc get nodes -l cluster.ocs.openshift.io/openshift-storage= -o jsonpath='{.items[0].metadata.name}')
Issue 2: Ceph Cluster in Warning State
# Check detailed Ceph status
oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}')

ceph health detail
ceph osd tree
ceph pg stat

# Common fix for placement group issues
ceph pg repair <pg_id>

exit
Issue 3: Data Not Accessible After Node Failure
# Check if PV is properly bound
oc get pv | grep critical-data-pvc

# Verify RBD image exists
oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}')

rbd ls ocs-storagecluster-cephblockpool
rbd info ocs-storagecluster-cephblockpool/<image-name>

exit
Validation and Testing
Final Validation Script
# Create comprehensive validation script
cat > validate-lab-completion.sh << 'EOF'
#!/bin/bash

echo "=== Lab 11 Validation Script ==="
echo

PASSED=0
TOTAL=0

# Test 1: Check if critical application is running
echo "Test 1: Critical Application Status"
TOTAL=$((TOTAL + 1))
if oc get pods -n critical-apps -l app=critical-database | grep -q Running; then
    echo "✓ PASSED: Critical application is running"
    PASSED=$((PASSED + 1))
else
    echo "✗ FAILED: Critical application is not running"
fi

# Test 2: Check data integrity
echo "Test 2: Data Integrity"
TOTAL=$((TOTAL + 1))
DATA_COUNT=$(oc exec -n critical-apps $(oc get pods -n critical-apps -l app=critical-database -o jsonpath='{.items[0].metadata.name}') -- psql -U testuser -d criticaldb -t -c "SELECT COUNT(*) FROM test_replication;" 2>/dev/null | tr -d ' ')
if [ "$DATA_COUNT" -ge "5" ]; then
    echo "✓ PASSED: Data integrity maintained ($DATA_COUNT records found)"
    PASSED=$((PASSED + 1))
else
    echo "✗ FAILED: Data integrity compromised (only $DATA_COUNT records found)"
fi

# Test 3: Check Ceph health
echo "Test 3: Ceph Cluster Health"
TOTAL=$((TOTAL + 1))
CEPH_HEALTH=$(oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}') ceph health 2>/dev/null | grep -o "HEALTH_OK\|HEALTH_WARN\|HEALTH_ERR")
if [ "$CEPH_HEALTH" = "HEALTH_OK" ] || [ "$CEPH_HEALTH" = "HEALTH_WARN" ]; then
    echo "✓ PASSED: Ceph cluster health is acceptable ($CEPH_HEALTH)"
    PASSED=$((PASSED + 1))
else
    echo "✗ FAILED: Ceph cluster health is critical ($CEPH_HEALTH)"
fi

# Test 4: Check replication configuration
echo "Test 4: Replication Configuration"
TOTAL=$((TOTAL + 1))
REPLICATION_SIZE=$(oc rsh -n openshift-storage $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}') ceph osd pool get ocs-storagecluster-cephblockpool size 2>/dev/null | awk '{print $2}')
if [ "$REPLICATION_SIZE" -ge "2" ]; then
    echo "✓ PASSED: Replication is properly configured (size: $REPLICATION_SIZE)"
    PASSED=$((PASSED + 1))
else
    echo "✗ FAILED: Replication not properly configured (size: $REPLICATION_SIZE)"
fi

# Test 5: Check monitoring setup
echo "Test 5: Monitoring Configuration"
TOTAL=$((TOTAL + 1))
if oc get prometheusrule -n openshift-storage odf-fault-tolerance-alerts >/dev/null 2>&1; then
    echo "✓ PASSED: Monitoring rules are configured"
    PASSED=$((PASSED + 1))
else
    echo "✗ FAILED: Monitoring rules are not configured"
fi

echo
echo "=== Validation Summary ==="
echo "Passed: $PASSED/$TOTAL tests"
if [ $PASSED -eq $TOTAL ]; then
    echo "🎉 Congratulations! All tests passed. Lab completed successfully."
    exit 0
else
    echo "⚠️  Some tests failed. Please review the failed components."
    exit 1
fi
EOF

chmod +x validate-lab-completion.sh

# Run validation
./validate-lab-completion.sh
Cleanup (Optional)
If you need to clean up the lab environment:

# Delete the critical application
oc delete namespace critical-apps

# Remove custom storage class
oc delete storageclass critical-app-rbd

# Remove alerting rules
oc delete prometheusrule odf-fault-tolerance-alerts -n openshift-storage

# Uncordon any cordoned nodes
oc get nodes | grep SchedulingDisabled | awk '{print $1}' | xargs -I {} oc adm uncordon {}

# Clean up monitoring scripts
rm -f monitor-odf-health.sh continuous-monitor.sh validate-lab-completion.sh
Conclusion
In this comprehensive lab, you have successfully:

Accomplished Key Learning Objectives:

Configured ODF Replication: Set up a custom storage class with proper replication settings for critical applications, ensuring data is replicated across multiple storage nodes for fault tolerance.

Implemented Fault Tolerance: Deployed a critical database application using replicated storage and verified that it can survive node failures without data loss.

Tested Failover Scenarios: Simulated both compute node failures and storage node failures, demonstrating how ODF automatically handles failover and maintains application availability.

Established Monitoring: Set up comprehensive monitoring using both CLI tools and Prometheus alerting rules to track cluster health, storage utilization, and fault tolerance status.

Validated Data Integrity: Confirmed that data remains consistent and accessible throughout various failure scenarios, proving the effectiveness of the replication configuration.

Why This Matters: This lab demonstrates critical enterprise storage capabilities that are essential for production environments. The skills you've learned enable you to:

Design resilient storage architectures that can withstand hardware failures
Implement proper monitoring and alerting for storage infrastructure
Ensure business continuity through automated failover mechanisms
Maintain data integrity and availability in distributed storage systems
Real-World Applications: These configurations are fundamental for:

Database Systems: Ensuring critical business data remains available during infrastructure failures
Application Persistence: Maintaining stateful application data across cluster maintenance and failures
Disaster Recovery: Providing the foundation for backup and recovery strategies
Compliance Requirements: Meeting data availability and integrity standards required by various regulations
Next Steps: Consider exploring advanced topics such as:

Cross-cluster replication for disaster recovery
Performance tuning for replicated storage
Integration with backup solutions
Advanced monitoring and capacity planning
The fault tolerance and replication skills demonstrated in this lab are essential for the Red Hat Certified Specialist in OpenShift Data Foundation exam and are directly applicable to real-world enterprise storage management scenarios.
