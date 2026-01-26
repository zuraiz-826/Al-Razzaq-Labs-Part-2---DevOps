Lab 17: Optimizing ODF Storage Performance
Objectives
By the end of this lab, students will be able to:

• Configure OpenShift Data Foundation (ODF) settings for improved performance • Monitor and analyze ODF performance metrics using built-in tools • Fine-tune storage configurations for specific workloads • Implement best practices for ODF performance optimization • Troubleshoot common performance bottlenecks in ODF environments

Prerequisites
Before starting this lab, students should have:

• Basic understanding of OpenShift Container Platform concepts • Familiarity with Kubernetes storage concepts (PVs, PVCs, StorageClasses) • Knowledge of Linux command line operations • Understanding of storage performance concepts (IOPS, throughput, latency) • Completion of basic ODF installation and configuration labs

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift and ODF already installed. Simply click Start Lab to begin - no need to build your own VM or install software.

Your lab environment includes: • OpenShift Container Platform 4.13+ • OpenShift Data Foundation 4.13+ • Prometheus and Grafana for monitoring • Sample applications for testing

Task 1: Configure ODF Settings for Improved Performance
Subtask 1.1: Analyze Current ODF Configuration
First, let's examine the current ODF deployment and identify areas for optimization.

Connect to your OpenShift cluster:
oc login -u admin -p admin https://api.cluster.local:6443
Check ODF operator status:
oc get csv -n openshift-storage | grep odf
Examine current storage cluster configuration:
oc get storagecluster -n openshift-storage -o yaml
List available storage classes:
oc get storageclass
Check OSD (Object Storage Daemon) pods:
oc get pods -n openshift-storage | grep osd
Subtask 1.2: Configure Performance-Optimized Storage Classes
Create optimized storage classes for different workload types.

Create a high-performance storage class for databases:
cat << EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ocs-storagecluster-ceph-rbd-high-perf
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
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF
Create a storage class optimized for sequential workloads:
cat << EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ocs-storagecluster-ceph-rbd-sequential
provisioner: openshift-storage.rbd.csi.ceph.com
parameters:
  clusterID: openshift-storage
  pool: ocs-storagecluster-cephblockpool
  imageFeatures: layering,fast-diff
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: openshift-storage
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: openshift-storage
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
  csi.storage.k8s.io/node-stage-secret-namespace: openshift-storage
  csi.storage.k8s.io/fstype: xfs
  mapOptions: "rw,noatime"
  mountOptions: "rw,noatime,inode64,allocsize=16m"
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF
Subtask 1.3: Optimize Ceph Configuration
Configure Ceph settings for better performance.

Access the Ceph toolbox:
oc patch OCSInitialization ocsinit -n openshift-storage --type json --patch '[{ "op": "replace", "path": "/spec/enableCephTools", "value": true }]'
Wait for toolbox pod to be ready:
oc wait --for=condition=Ready pod -l app=rook-ceph-tools -n openshift-storage --timeout=300s
Configure Ceph performance settings:
TOOLBOX_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}')

oc exec -n openshift-storage $TOOLBOX_POD -- ceph config set osd osd_op_queue wpq
oc exec -n openshift-storage $TOOLBOX_POD -- ceph config set osd osd_op_queue_cut_off high
oc exec -n openshift-storage $TOOLBOX_POD -- ceph config set osd bluestore_cache_size 2147483648
oc exec -n openshift-storage $TOOLBOX_POD -- ceph config set osd bluestore_cache_meta_ratio 0.4
oc exec -n openshift-storage $TOOLBOX_POD -- ceph config set osd bluestore_cache_kv_ratio 0.4
Verify the configuration changes:
oc exec -n openshift-storage $TOOLBOX_POD -- ceph config dump | grep -E "(osd_op_queue|bluestore_cache)"
Task 2: Monitor Performance Metrics
Subtask 2.1: Access ODF Performance Dashboard
Get the Grafana route:
oc get route grafana -n openshift-monitoring
Access Grafana dashboard (use the route URL from above):

Navigate to the Grafana URL in your browser
Login with your OpenShift credentials
Look for ODF/Ceph dashboards
Create a custom monitoring script:

cat << 'EOF' > monitor_odf_performance.sh
#!/bin/bash

echo "=== ODF Performance Monitoring ==="
echo "Timestamp: $(date)"
echo

# Check cluster health
echo "--- Ceph Cluster Health ---"
TOOLBOX_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}')
oc exec -n openshift-storage $TOOLBOX_POD -- ceph health detail

echo
echo "--- Storage Utilization ---"
oc exec -n openshift-storage $TOOLBOX_POD -- ceph df

echo
echo "--- OSD Performance ---"
oc exec -n openshift-storage $TOOLBOX_POD -- ceph osd perf

echo
echo "--- Pool Statistics ---"
oc exec -n openshift-storage $TOOLBOX_POD -- ceph osd pool stats

echo
echo "--- PVC Usage ---"
oc get pvc --all-namespaces | grep -E "(Bound|Pending)"

EOF

chmod +x monitor_odf_performance.sh
Run the monitoring script:
./monitor_odf_performance.sh
Subtask 2.2: Set Up Performance Alerts
Create a PrometheusRule for ODF performance monitoring:
cat << EOF | oc apply -f -
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: odf-performance-alerts
  namespace: openshift-storage
spec:
  groups:
  - name: odf.performance.rules
    rules:
    - alert: CephOSDHighLatency
      expr: ceph_osd_apply_latency_ms > 100
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Ceph OSD high latency detected"
        description: "OSD {{ \$labels.ceph_daemon }} has high apply latency of {{ \$value }}ms"
    
    - alert: CephPoolHighUtilization
      expr: ceph_pool_percent_used > 80
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Ceph pool utilization is high"
        description: "Pool {{ \$labels.name }} utilization is {{ \$value }}%"
    
    - alert: CephOSDDown
      expr: ceph_osd_up == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Ceph OSD is down"
        description: "OSD {{ \$labels.ceph_daemon }} is down"
EOF
Subtask 2.3: Create Performance Testing Workload
Deploy a test application to generate I/O load:
cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: performance-test
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: performance-test-pvc
  namespace: performance-test
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: ocs-storagecluster-ceph-rbd-high-perf
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fio-test
  namespace: performance-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: fio-test
  template:
    metadata:
      labels:
        app: fio-test
    spec:
      containers:
      - name: fio
        image: quay.io/openshift/origin-tests:latest
        command: ["/bin/bash"]
        args: ["-c", "while true; do sleep 3600; done"]
        volumeMounts:
        - name: test-volume
          mountPath: /test-data
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
      volumes:
      - name: test-volume
        persistentVolumeClaim:
          claimName: performance-test-pvc
EOF
Wait for the deployment to be ready:
oc wait --for=condition=Available deployment/fio-test -n performance-test --timeout=300s
Run performance tests:
FIO_POD=$(oc get pods -n performance-test -l app=fio-test -o jsonpath='{.items[0].metadata.name}')

# Random read test
oc exec -n performance-test $FIO_POD -- fio --name=random-read --ioengine=libaio --rw=randread --bs=4k --numjobs=4 --size=1G --runtime=60 --directory=/test-data --group_reporting

# Sequential write test
oc exec -n performance-test $FIO_POD -- fio --name=sequential-write --ioengine=libaio --rw=write --bs=1M --numjobs=1 --size=2G --runtime=60 --directory=/test-data --group_reporting
Task 3: Fine-tune Storage Configurations for Specific Workloads
Subtask 3.1: Optimize for Database Workloads
Create a database-optimized storage class:
cat << EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ocs-database-optimized
provisioner: openshift-storage.rbd.csi.ceph.com
parameters:
  clusterID: openshift-storage
  pool: ocs-storagecluster-cephblockpool
  imageFeatures: layering,exclusive-lock,object-map,fast-diff
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: openshift-storage
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: openshift-storage
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
  csi.storage.k8s.io/node-stage-secret-namespace: openshift-storage
  csi.storage.k8s.io/fstype: ext4
  mapOptions: "rw,noatime"
  mountOptions: "rw,noatime,nobarrier"
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF
Deploy a test PostgreSQL database:
cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: database-test
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: database-test
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: ocs-database-optimized
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: database-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: testdb
        - name: POSTGRES_USER
          value: testuser
        - name: POSTGRES_PASSWORD
          value: testpass
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
EOF
Subtask 3.2: Configure for High-Throughput Workloads
Create a CephBlockPool optimized for throughput:
cat << EOF | oc apply -f -
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: high-throughput-pool
  namespace: openshift-storage
spec:
  failureDomain: host
  replicated:
    size: 3
    requireSafeReplicaSize: true
  parameters:
    pg_num: "128"
    pgp_num: "128"
    compression_mode: none
  mirroring:
    enabled: false
EOF
Create a storage class using the high-throughput pool:
cat << EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ocs-high-throughput
provisioner: openshift-storage.rbd.csi.ceph.com
parameters:
  clusterID: openshift-storage
  pool: high-throughput-pool
  imageFeatures: layering
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: openshift-storage
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: openshift-storage
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
  csi.storage.k8s.io/node-stage-secret-namespace: openshift-storage
  csi.storage.k8s.io/fstype: xfs
  mapOptions: "rw,noatime"
  mountOptions: "rw,noatime,largeio,inode64,swalloc"
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF
Subtask 3.3: Implement Node-Specific Optimizations
Label nodes for storage optimization:
# Get worker nodes
oc get nodes --show-labels | grep worker

# Label nodes with SSD storage
oc label node <worker-node-1> storage-type=ssd
oc label node <worker-node-2> storage-type=ssd

# Label nodes with NVMe storage (if available)
oc label node <worker-node-3> storage-type=nvme
Create a node-affinity optimized storage class:
cat << EOF | oc apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ocs-ssd-optimized
provisioner: openshift-storage.rbd.csi.ceph.com
parameters:
  clusterID: openshift-storage
  pool: ocs-storagecluster-cephblockpool
  imageFeatures: layering,exclusive-lock
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: openshift-storage
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: openshift-storage
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
  csi.storage.k8s.io/node-stage-secret-namespace: openshift-storage
  csi.storage.k8s.io/fstype: ext4
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowedTopologies:
- matchLabelExpressions:
  - key: storage-type
    values:
    - ssd
    - nvme
EOF
Subtask 3.4: Performance Validation and Benchmarking
Create a comprehensive benchmark script:
cat << 'EOF' > odf_benchmark.sh
#!/bin/bash

NAMESPACE="performance-benchmark"
STORAGE_CLASS="ocs-storagecluster-ceph-rbd-high-perf"

echo "=== ODF Performance Benchmark ==="
echo "Starting benchmark at: $(date)"

# Create namespace
oc create namespace $NAMESPACE 2>/dev/null || true

# Deploy benchmark pod
cat << YAML | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: benchmark-pvc
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: $STORAGE_CLASS
---
apiVersion: v1
kind: Pod
metadata:
  name: benchmark-pod
  namespace: $NAMESPACE
spec:
  containers:
  - name: benchmark
    image: quay.io/openshift/origin-tests:latest
    command: ["/bin/bash"]
    args: ["-c", "while true; do sleep 3600; done"]
    volumeMounts:
    - name: benchmark-volume
      mountPath: /benchmark
    resources:
      requests:
        memory: "2Gi"
        cpu: "1000m"
      limits:
        memory: "4Gi"
        cpu: "2000m"
  volumes:
  - name: benchmark-volume
    persistentVolumeClaim:
      claimName: benchmark-pvc
YAML

# Wait for pod to be ready
echo "Waiting for benchmark pod to be ready..."
oc wait --for=condition=Ready pod/benchmark-pod -n $NAMESPACE --timeout=300s

echo "Running performance tests..."

# Random read/write test
echo "--- Random Read/Write Test ---"
oc exec -n $NAMESPACE benchmark-pod -- fio \
  --name=random-rw \
  --ioengine=libaio \
  --rw=randrw \
  --rwmixread=70 \
  --bs=4k \
  --numjobs=4 \
  --size=5G \
  --runtime=120 \
  --directory=/benchmark \
  --group_reporting \
  --output-format=json > random_rw_results.json

# Sequential read test
echo "--- Sequential Read Test ---"
oc exec -n $NAMESPACE benchmark-pod -- fio \
  --name=sequential-read \
  --ioengine=libaio \
  --rw=read \
  --bs=1M \
  --numjobs=1 \
  --size=10G \
  --runtime=60 \
  --directory=/benchmark \
  --group_reporting \
  --output-format=json > sequential_read_results.json

# Sequential write test
echo "--- Sequential Write Test ---"
oc exec -n $NAMESPACE benchmark-pod -- fio \
  --name=sequential-write \
  --ioengine=libaio \
  --rw=write \
  --bs=1M \
  --numjobs=1 \
  --size=10G \
  --runtime=60 \
  --directory=/benchmark \
  --group_reporting \
  --output-format=json > sequential_write_results.json

echo "Benchmark completed at: $(date)"
echo "Results saved to: random_rw_results.json, sequential_read_results.json, sequential_write_results.json"

# Cleanup
echo "Cleaning up benchmark resources..."
oc delete namespace $NAMESPACE

EOF

chmod +x odf_benchmark.sh
Run the benchmark:
./odf_benchmark.sh
Analyze results:
# Extract key metrics from results
echo "=== Performance Summary ==="
echo "Random R/W IOPS:"
cat random_rw_results.json | jq '.jobs[0].read.iops, .jobs[0].write.iops'

echo "Sequential Read Throughput (MB/s):"
cat sequential_read_results.json | jq '.jobs[0].read.bw / 1024'

echo "Sequential Write Throughput (MB/s):"
cat sequential_write_results.json | jq '.jobs[0].write.bw / 1024'
Troubleshooting Common Performance Issues
Issue 1: High Latency
Symptoms: Applications experiencing slow response times

Diagnosis:

# Check OSD performance
TOOLBOX_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}')
oc exec -n openshift-storage $TOOLBOX_POD -- ceph osd perf

# Check for slow requests
oc exec -n openshift-storage $TOOLBOX_POD -- ceph health detail | grep slow
Solutions:

Increase OSD memory allocation
Check network connectivity between nodes
Verify disk performance on storage nodes
Issue 2: Low Throughput
Symptoms: Poor sequential read/write performance

Diagnosis:

# Check pool configuration
oc exec -n openshift-storage $TOOLBOX_POD -- ceph osd pool get ocs-storagecluster-cephblockpool all

# Check placement group distribution
oc exec -n openshift-storage $TOOLBOX_POD -- ceph pg dump | grep active+clean | wc -l
Solutions:

Increase placement group count
Optimize Ceph cache settings
Use appropriate block sizes for workload
Issue 3: Resource Contention
Symptoms: Inconsistent performance across applications

Diagnosis:

# Check resource usage
oc top nodes
oc top pods -n openshift-storage

# Check for resource limits
oc describe pods -n openshift-storage | grep -A 5 -B 5 "Limits\|Requests"
Solutions:

Implement QoS classes
Use node affinity rules
Scale storage cluster if needed
Conclusion
In this lab, you have successfully:

• Configured ODF settings for improved performance by creating optimized storage classes, tuning Ceph parameters, and implementing performance-focused configurations

• Monitored performance metrics using built-in tools, custom scripts, and Prometheus alerts to gain visibility into storage system behavior

• Fine-tuned storage configurations for specific workloads including database optimization, high-throughput scenarios, and node-specific configurations

• Implemented comprehensive benchmarking to validate performance improvements and establish baseline metrics

Why This Matters: Performance optimization is crucial for production OpenShift Data Foundation deployments. The skills learned in this lab enable you to:

Maximize storage performance for critical applications
Proactively identify and resolve performance bottlenecks
Implement workload-specific optimizations
Maintain consistent performance as your environment scales
These optimization techniques are essential for Red Hat Certified Specialist in OpenShift Data Foundation certification and real-world enterprise deployments where storage performance directly impacts application responsiveness and user experience.

Next Steps: Consider exploring advanced topics such as multi-zone deployments, disaster recovery configurations, and integration with external storage systems to further enhance your ODF expertise.
