Lab 18: Configuring Storage Classes and PVCs
Objectives
By the end of this lab, you will be able to:

Understand the concepts of Storage Classes and Persistent Volume Claims (PVCs) in OpenShift
Create custom storage classes tailored for specific storage requirements
Configure and deploy PVCs that bind to StatefulSets for persistent storage
Modify storage configurations to optimize performance for different workload types
Troubleshoot common storage-related issues in OpenShift environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Kubernetes/OpenShift concepts
Familiarity with YAML configuration files
Knowledge of command-line interface operations
Understanding of containerized applications and their storage needs
Completed previous labs on OpenShift fundamentals
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

OpenShift cluster with administrative access
Pre-installed oc command-line tool
Sample applications for testing storage configurations
Task 1: Create Custom Storage Classes in OpenShift
Subtask 1.1: Understanding Storage Classes
Storage Classes in OpenShift define different types of storage that can be dynamically provisioned. They act as templates that describe the storage characteristics and provisioning parameters.

First, let's examine the existing storage classes in your cluster:

oc get storageclass
View detailed information about a specific storage class:

oc describe storageclass <storage-class-name>
Subtask 1.2: Create a High-Performance Storage Class
Create a custom storage class optimized for high-performance workloads:

# Create file: high-performance-storage.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: high-performance-ssd
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: kubernetes.io/no-provisioner
parameters:
  type: ssd
  iopsPerGB: "50"
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Retain
Apply the storage class configuration:

oc apply -f high-performance-storage.yaml
Verify the storage class was created:

oc get storageclass high-performance-ssd -o yaml
Subtask 1.3: Create a Cost-Optimized Storage Class
Create another storage class for cost-sensitive workloads:

# Create file: cost-optimized-storage.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: cost-optimized-hdd
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: kubernetes.io/no-provisioner
parameters:
  type: hdd
  iopsPerGB: "10"
  encrypted: "false"
volumeBindingMode: Immediate
allowVolumeExpansion: true
reclaimPolicy: Delete
Apply the configuration:

oc apply -f cost-optimized-storage.yaml
Subtask 1.4: Create a Backup Storage Class
Create a storage class specifically for backup purposes:

# Create file: backup-storage.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: backup-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: kubernetes.io/no-provisioner
parameters:
  type: cold-storage
  replication: "3"
  compression: "enabled"
volumeBindingMode: Immediate
allowVolumeExpansion: false
reclaimPolicy: Retain
Apply the backup storage class:

oc apply -f backup-storage.yaml
Verify all custom storage classes are created:

oc get storageclass | grep -E "(high-performance|cost-optimized|backup)"
Task 2: Create PVCs and Bind Them to StatefulSets
Subtask 2.1: Create PVCs for Different Storage Classes
Create a PVC using the high-performance storage class:

# Create file: high-performance-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-storage-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: high-performance-ssd
  resources:
    requests:
      storage: 50Gi
Create a PVC using the cost-optimized storage class:

# Create file: cost-optimized-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: log-storage-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: cost-optimized-hdd
  resources:
    requests:
      storage: 100Gi
Apply both PVC configurations:

oc apply -f high-performance-pvc.yaml
oc apply -f cost-optimized-pvc.yaml
Check the status of your PVCs:

oc get pvc
Subtask 2.2: Create a StatefulSet with Database Storage
Create a StatefulSet that uses the high-performance PVC for a database workload:

# Create file: database-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql-db
  namespace: default
spec:
  serviceName: postgresql-service
  replicas: 3
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
      - name: postgresql
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: "appdb"
        - name: POSTGRES_USER
          value: "dbuser"
        - name: POSTGRES_PASSWORD
          value: "securepassword"
        ports:
        - containerPort: 5432
          name: postgresql
        volumeMounts:
        - name: postgresql-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
  volumeClaimTemplates:
  - metadata:
      name: postgresql-storage
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: high-performance-ssd
      resources:
        requests:
          storage: 20Gi
Create the corresponding service:

# Create file: postgresql-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgresql-service
  namespace: default
spec:
  selector:
    app: postgresql
  ports:
  - port: 5432
    targetPort: 5432
  clusterIP: None
Apply the StatefulSet and service:

oc apply -f database-statefulset.yaml
oc apply -f postgresql-service.yaml
Subtask 2.3: Create a StatefulSet for Log Processing
Create a StatefulSet that uses cost-optimized storage for log processing:

# Create file: log-processor-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: log-processor
  namespace: default
spec:
  serviceName: log-processor-service
  replicas: 2
  selector:
    matchLabels:
      app: log-processor
  template:
    metadata:
      labels:
        app: log-processor
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.14
        ports:
        - containerPort: 24224
          name: fluentd
        volumeMounts:
        - name: log-storage
          mountPath: /var/log/fluentd
        - name: config-volume
          mountPath: /fluentd/etc
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
      volumes:
      - name: config-volume
        configMap:
          name: fluentd-config
  volumeClaimTemplates:
  - metadata:
      name: log-storage
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: cost-optimized-hdd
      resources:
        requests:
          storage: 50Gi
Create a basic Fluentd configuration:

# Create file: fluentd-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: default
data:
  fluent.conf: |
    <source>
      @type forward
      port 24224
      bind 0.0.0.0
    </source>
    
    <match **>
      @type file
      path /var/log/fluentd/access
      append true
      time_slice_format %Y%m%d
      time_slice_wait 10m
      time_format %Y%m%dT%H%M%S%z
    </match>
Apply the configurations:

oc apply -f fluentd-config.yaml
oc apply -f log-processor-statefulset.yaml
Subtask 2.4: Verify StatefulSet and PVC Binding
Check the status of your StatefulSets:

oc get statefulset
Verify that PVCs are bound to the StatefulSets:

oc get pvc
Check the pods created by the StatefulSets:

oc get pods -l app=postgresql
oc get pods -l app=log-processor
Describe a pod to see the volume mounts:

oc describe pod postgresql-db-0
Task 3: Modify Storage Configurations for Optimal Performance
Subtask 3.1: Update Storage Class Parameters
Modify the high-performance storage class to increase IOPS:

# Create file: updated-high-performance-storage.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: high-performance-ssd-v2
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: kubernetes.io/no-provisioner
parameters:
  type: ssd
  iopsPerGB: "100"
  encrypted: "true"
  fsType: "ext4"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Retain
Apply the updated storage class:

oc apply -f updated-high-performance-storage.yaml
Subtask 3.2: Expand Existing PVC Storage
Expand the database storage PVC to accommodate growing data:

oc patch pvc database-storage-pvc -p '{"spec":{"resources":{"requests":{"storage":"75Gi"}}}}'
Monitor the expansion process:

oc get pvc database-storage-pvc -w
Subtask 3.3: Create Performance-Optimized PVC
Create a new PVC with specific performance requirements:

# Create file: performance-optimized-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: high-iops-pvc
  namespace: default
  annotations:
    volume.beta.kubernetes.io/storage-provisioner: kubernetes.io/no-provisioner
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: high-performance-ssd-v2
  resources:
    requests:
      storage: 100Gi
Apply the performance-optimized PVC:

oc apply -f performance-optimized-pvc.yaml
Subtask 3.4: Configure Storage Monitoring
Create a monitoring configuration to track storage performance:

# Create file: storage-monitor.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: storage-monitor-config
  namespace: default
data:
  monitor.sh: |
    #!/bin/bash
    while true; do
      echo "=== Storage Usage Report $(date) ==="
      df -h | grep -E "(postgresql|fluentd)"
      echo "=== PVC Status ==="
      oc get pvc
      echo "=== Storage Classes ==="
      oc get storageclass
      sleep 300
    done
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: storage-monitor
  namespace: default
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: monitor
            image: registry.redhat.io/ubi8/ubi:latest
            command:
            - /bin/bash
            - -c
            - |
              oc get pvc > /tmp/pvc-status.log
              oc get storageclass > /tmp/sc-status.log
              echo "Storage monitoring completed at $(date)"
          restartPolicy: OnFailure
Apply the monitoring configuration:

oc apply -f storage-monitor.yaml
Subtask 3.5: Implement Storage Backup Strategy
Create a backup job for critical storage:

# Create file: storage-backup-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: database-backup
  namespace: default
spec:
  template:
    spec:
      containers:
      - name: backup
        image: postgres:13
        command:
        - /bin/bash
        - -c
        - |
          pg_dump -h postgresql-service -U dbuser -d appdb > /backup/database-backup-$(date +%Y%m%d-%H%M%S).sql
          echo "Backup completed successfully"
        env:
        - name: PGPASSWORD
          value: "securepassword"
        volumeMounts:
        - name: backup-volume
          mountPath: /backup
      volumes:
      - name: backup-volume
        persistentVolumeClaim:
          claimName: backup-pvc
      restartPolicy: Never
  backoffLimit: 3
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: backup-storage
  resources:
    requests:
      storage: 200Gi
Apply the backup configuration:

oc apply -f storage-backup-job.yaml
Verification and Testing
Verify Storage Configuration
Check all storage classes:

oc get storageclass
Verify all PVCs are bound:

oc get pvc -o wide
Check StatefulSet status:

oc get statefulset -o wide
Test Storage Performance
Create a test pod to verify storage performance:

# Create file: storage-test-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: storage-test
  namespace: default
spec:
  containers:
  - name: test-container
    image: registry.redhat.io/ubi8/ubi:latest
    command:
    - /bin/bash
    - -c
    - |
      echo "Testing storage performance..."
      dd if=/dev/zero of=/test-data/testfile bs=1M count=1000
      sync
      echo "Write test completed"
      dd if=/test-data/testfile of=/dev/null bs=1M
      echo "Read test completed"
      sleep 3600
    volumeMounts:
    - name: test-storage
      mountPath: /test-data
  volumes:
  - name: test-storage
    persistentVolumeClaim:
      claimName: high-iops-pvc
  restartPolicy: Never
Apply and monitor the test:

oc apply -f storage-test-pod.yaml
oc logs storage-test -f
Troubleshooting Common Issues
Issue 1: PVC Stuck in Pending State
Check the storage class and provisioner:

oc describe pvc <pvc-name>
oc get events --field-selector involvedObject.name=<pvc-name>
Issue 2: StatefulSet Pods Not Starting
Verify PVC availability and node resources:

oc describe statefulset <statefulset-name>
oc get nodes -o wide
Issue 3: Storage Performance Issues
Monitor storage metrics and check configuration:

oc top pods
oc describe storageclass <storage-class-name>
Cleanup
Remove all created resources:

# Delete StatefulSets
oc delete statefulset postgresql-db log-processor

# Delete PVCs
oc delete pvc database-storage-pvc log-storage-pvc high-iops-pvc backup-pvc

# Delete Storage Classes
oc delete storageclass high-performance-ssd cost-optimized-hdd backup-storage high-performance-ssd-v2

# Delete other resources
oc delete job database-backup
oc delete cronjob storage-monitor
oc delete pod storage-test
oc delete configmap fluentd-config storage-monitor-config
oc delete service postgresql-service
Conclusion
In this lab, you have successfully:

Created custom storage classes tailored for different performance and cost requirements, understanding how storage classes act as templates for dynamic provisioning
Configured and deployed PVCs that bind to StatefulSets, ensuring persistent storage for database and log processing workloads
Modified storage configurations to optimize performance through parameter tuning and storage expansion
Implemented monitoring and backup strategies for storage management in production environments
Why This Matters: Proper storage configuration is critical for application performance, data persistence, and cost optimization in containerized environments. Understanding how to create and manage storage classes and PVCs enables you to:

Design storage solutions that match application requirements
Optimize costs by using appropriate storage types for different workloads
Ensure data persistence and availability for stateful applications
Implement proper backup and monitoring strategies for production systems
These skills are essential for the Red Hat Certified OpenShift Administrator exam and real-world OpenShift deployments where storage management directly impacts application performance and reliability.
