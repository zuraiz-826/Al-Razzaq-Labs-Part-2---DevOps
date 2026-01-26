Lab 18: Configuring Ceph for Containerized Environments
Objectives
By the end of this lab, students will be able to:

Configure Ceph as a persistent volume backend for Kubernetes clusters
Integrate Ceph storage with OpenShift for container workloads
Deploy and manage stateful applications using Ceph persistent storage
Understand the architecture and benefits of Ceph in containerized environments
Troubleshoot common Ceph storage issues in container platforms
Prerequisites
Before starting this lab, students should have:

Basic understanding of Kubernetes concepts (pods, services, persistent volumes)
Familiarity with container orchestration platforms
Knowledge of Linux command line operations
Understanding of storage concepts (block storage, file systems)
Experience with YAML configuration files
Basic networking knowledge
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines or install software - everything is ready to use!

Your lab environment includes:

3 Linux nodes (Ubuntu 20.04 LTS) pre-configured for Ceph
Kubernetes cluster (v1.28) already installed
OpenShift cluster environment
All necessary tools and dependencies pre-installed
Task 1: Set up Ceph as a Persistent Volume for Kubernetes
Subtask 1.1: Verify Lab Environment and Ceph Cluster Status
First, let's verify that our Ceph cluster is running and healthy.

Connect to the master node and check cluster status:
# Switch to the ceph user
sudo su - ceph

# Check Ceph cluster health
ceph health

# View cluster status
ceph status

# List available pools
ceph osd pool ls
Verify Kubernetes cluster is running:
# Switch back to regular user
exit

# Check Kubernetes nodes
kubectl get nodes

# Verify all nodes are ready
kubectl get nodes -o wide
Subtask 1.2: Install Ceph CSI Driver for Kubernetes
The Container Storage Interface (CSI) driver allows Kubernetes to communicate with Ceph storage.

Clone the Ceph CSI repository:
# Create working directory
mkdir -p ~/ceph-k8s-lab
cd ~/ceph-k8s-lab

# Clone the official Ceph CSI driver
git clone https://github.com/ceph/ceph-csi.git
cd ceph-csi

# Switch to stable release
git checkout v3.9.0
Deploy Ceph CSI components:
# Navigate to deployment directory
cd deploy/rbd/kubernetes

# Create namespace for Ceph CSI
kubectl create namespace ceph-csi-rbd

# Deploy CSI driver components
kubectl apply -f csi-provisioner-rbac.yaml
kubectl apply -f csi-nodeplugin-rbac.yaml
kubectl apply -f csi-rbdplugin-provisioner.yaml
kubectl apply -f csi-rbdplugin.yaml
Verify CSI driver deployment:
# Check CSI pods status
kubectl get pods -n ceph-csi-rbd

# Wait for all pods to be running (this may take 2-3 minutes)
kubectl wait --for=condition=ready pod -l app=csi-rbdplugin -n ceph-csi-rbd --timeout=300s
Subtask 1.3: Create Ceph Storage Pool and User
Create a dedicated pool for Kubernetes:
# Switch to ceph user
sudo su - ceph

# Create a new pool for Kubernetes persistent volumes
ceph osd pool create kubernetes 64 64

# Initialize the pool for RBD
rbd pool init kubernetes

# Verify pool creation
ceph osd pool ls | grep kubernetes
Create Ceph user for Kubernetes access:
# Create a new user with appropriate permissions
ceph auth get-or-create client.kubernetes \
  mon 'profile rbd' \
  osd 'profile rbd pool=kubernetes' \
  mgr 'profile rbd pool=kubernetes'

# Get the user key (save this for later use)
ceph auth get-key client.kubernetes
Get cluster information needed for configuration:
# Get cluster FSID
ceph fsid

# Get monitor addresses
ceph mon dump

# Exit ceph user
exit
Subtask 1.4: Configure Kubernetes Storage Classes and Secrets
Create Ceph cluster secret:
Create a file called ceph-secret.yaml:

cat > ceph-secret.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: csi-rbd-secret
  namespace: default
stringData:
  userID: kubernetes
  userKey: REPLACE_WITH_ACTUAL_KEY
type: kubernetes.io/rbd
EOF
Update the secret with actual values:
# Get the actual key from Ceph
CEPH_KEY=$(sudo ceph auth get-key client.kubernetes)

# Replace the placeholder with actual key
sed -i "s/REPLACE_WITH_ACTUAL_KEY/$CEPH_KEY/" ceph-secret.yaml

# Apply the secret
kubectl apply -f ceph-secret.yaml
Create ConfigMap for Ceph cluster information:
# Get cluster FSID and monitor IPs
CLUSTER_ID=$(sudo ceph fsid)
MON_IPS=$(sudo ceph mon dump | grep -oP 'mon\.\d+.*?(\d+\.\d+\.\d+\.\d+:\d+)' | grep -oP '\d+\.\d+\.\d+\.\d+:\d+' | head -3 | tr '\n' ',' | sed 's/,$//')

cat > ceph-configmap.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ceph-csi-config
  namespace: ceph-csi-rbd
data:
  config.json: |
    [
      {
        "clusterID": "$CLUSTER_ID",
        "monitors": ["$MON_IPS"]
      }
    ]
EOF

# Apply the ConfigMap
kubectl apply -f ceph-configmap.yaml
Create Storage Class for Ceph RBD:
cat > ceph-storageclass.yaml << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ceph-rbd
provisioner: rbd.csi.ceph.com
parameters:
  clusterID: $CLUSTER_ID
  pool: kubernetes
  imageFeatures: layering
  csi.storage.k8s.io/provisioner-secret-name: csi-rbd-secret
  csi.storage.k8s.io/provisioner-secret-namespace: default
  csi.storage.k8s.io/controller-expand-secret-name: csi-rbd-secret
  csi.storage.k8s.io/controller-expand-secret-namespace: default
  csi.storage.k8s.io/node-stage-secret-name: csi-rbd-secret
  csi.storage.k8s.io/node-stage-secret-namespace: default
reclaimPolicy: Delete
allowVolumeExpansion: true
mountOptions:
  - discard
EOF

# Apply the Storage Class
kubectl apply -f ceph-storageclass.yaml
Subtask 1.5: Test Persistent Volume Creation
Create a test Persistent Volume Claim:
cat > test-pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ceph-rbd-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ceph-rbd
EOF

# Apply the PVC
kubectl apply -f test-pvc.yaml
Verify PVC creation and binding:
# Check PVC status
kubectl get pvc ceph-rbd-pvc

# Wait for PVC to be bound
kubectl wait --for=condition=bound pvc/ceph-rbd-pvc --timeout=60s

# Check if PV was automatically created
kubectl get pv
Create a test pod to use the PVC:
cat > test-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: ceph-rbd-test-pod
spec:
  containers:
  - name: test-container
    image: nginx:latest
    volumeMounts:
    - name: ceph-storage
      mountPath: /data
  volumes:
  - name: ceph-storage
    persistentVolumeClaim:
      claimName: ceph-rbd-pvc
EOF

# Deploy the test pod
kubectl apply -f test-pod.yaml

# Wait for pod to be running
kubectl wait --for=condition=ready pod/ceph-rbd-test-pod --timeout=120s
Test storage functionality:
# Write data to the mounted volume
kubectl exec ceph-rbd-test-pod -- sh -c "echo 'Hello from Ceph storage!' > /data/test.txt"

# Verify data was written
kubectl exec ceph-rbd-test-pod -- cat /data/test.txt

# Check storage usage
kubectl exec ceph-rbd-test-pod -- df -h /data
Task 2: Integrate Ceph with OpenShift for Container Storage
Subtask 2.1: Prepare OpenShift Environment
Switch to OpenShift context (if not already active):
# Check current context
oc config current-context

# If needed, login to OpenShift cluster
oc login -u admin -p admin https://api.openshift.local:6443

# Verify cluster access
oc get nodes
Create project for Ceph integration:
# Create new project
oc new-project ceph-storage

# Switch to the project
oc project ceph-storage
Subtask 2.2: Deploy Ceph CSI Driver for OpenShift
Install Ceph CSI Operator:
# Create operator subscription
cat > ceph-csi-operator.yaml << 'EOF'
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ceph-csi-operator
  namespace: openshift-storage
spec:
  channel: stable
  name: ceph-csi-operator
  source: community-operators
  sourceNamespace: openshift-marketplace
EOF

# Create openshift-storage namespace if it doesn't exist
oc create namespace openshift-storage --dry-run=client -o yaml | oc apply -f -

# Apply the subscription
oc apply -f ceph-csi-operator.yaml
Wait for operator installation:
# Check operator installation status
oc get csv -n openshift-storage

# Wait for operator to be ready
oc wait --for=condition=ready pod -l name=ceph-csi-operator -n openshift-storage --timeout=300s
Subtask 2.3: Configure Ceph Storage for OpenShift
Create Ceph cluster secret for OpenShift:
# Get Ceph credentials
CEPH_KEY=$(sudo ceph auth get-key client.kubernetes)
CLUSTER_ID=$(sudo ceph fsid)

# Create secret in OpenShift
oc create secret generic ceph-secret \
  --from-literal=userID=kubernetes \
  --from-literal=userKey=$CEPH_KEY \
  -n ceph-storage
Create ConfigMap for Ceph cluster:
# Get monitor addresses
MON_ADDRESSES=$(sudo ceph mon dump | grep -oP 'mon\.\d+.*?(\d+\.\d+\.\d+\.\d+:\d+)' | grep -oP '\d+\.\d+\.\d+\.\d+:\d+' | head -3)

cat > openshift-ceph-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ceph-csi-config
  namespace: ceph-storage
data:
  config.json: |
    [
      {
        "clusterID": "$CLUSTER_ID",
        "monitors": [$(echo "$MON_ADDRESSES" | sed 's/^/"/;s/$/"/;s/$/,/' | tr -d '\n' | sed 's/,$//')]
      }
    ]
EOF

# Apply the ConfigMap
oc apply -f openshift-ceph-config.yaml
Create OpenShift Storage Class:
cat > openshift-ceph-storageclass.yaml << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ceph-rbd-openshift
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: rbd.csi.ceph.com
parameters:
  clusterID: $CLUSTER_ID
  pool: kubernetes
  imageFeatures: layering
  csi.storage.k8s.io/provisioner-secret-name: ceph-secret
  csi.storage.k8s.io/provisioner-secret-namespace: ceph-storage
  csi.storage.k8s.io/controller-expand-secret-name: ceph-secret
  csi.storage.k8s.io/controller-expand-secret-namespace: ceph-storage
  csi.storage.k8s.io/node-stage-secret-name: ceph-secret
  csi.storage.k8s.io/node-stage-secret-namespace: ceph-storage
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate
EOF

# Apply the Storage Class
oc apply -f openshift-ceph-storageclass.yaml
Subtask 2.4: Test OpenShift Integration
Create test PVC in OpenShift:
cat > openshift-test-pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ceph-test-pvc
  namespace: ceph-storage
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: ceph-rbd-openshift
EOF

# Apply the PVC
oc apply -f openshift-test-pvc.yaml
Verify PVC binding:
# Check PVC status
oc get pvc ceph-test-pvc -n ceph-storage

# Wait for binding
oc wait --for=condition=bound pvc/ceph-test-pvc -n ceph-storage --timeout=60s
Deploy test application:
cat > openshift-test-app.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ceph-test-app
  namespace: ceph-storage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ceph-test-app
  template:
    metadata:
      labels:
        app: ceph-test-app
    spec:
      containers:
      - name: test-app
        image: registry.redhat.io/ubi8/ubi:latest
        command: ["/bin/sh"]
        args: ["-c", "while true; do echo $(date) >> /data/log.txt; sleep 30; done"]
        volumeMounts:
        - name: ceph-storage
          mountPath: /data
      volumes:
      - name: ceph-storage
        persistentVolumeClaim:
          claimName: ceph-test-pvc
EOF

# Deploy the application
oc apply -f openshift-test-app.yaml

# Wait for deployment to be ready
oc wait --for=condition=available deployment/ceph-test-app -n ceph-storage --timeout=120s
Task 3: Deploy and Manage Stateful Applications with Ceph
Subtask 3.1: Deploy PostgreSQL Database with Ceph Storage
Create namespace for database applications:
# Create namespace
kubectl create namespace database-apps

# Switch context
kubectl config set-context --current --namespace=database-apps
Create PostgreSQL StatefulSet with Ceph storage:
cat > postgres-statefulset.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: database-apps
type: Opaque
data:
  postgres-password: cG9zdGdyZXMxMjM=  # postgres123 base64 encoded
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: database-apps
spec:
  serviceName: postgres
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
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: postgres-password
        - name: POSTGRES_DB
          value: testdb
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: ceph-rbd
      resources:
        requests:
          storage: 5Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: database-apps
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
EOF

# Deploy PostgreSQL
kubectl apply -f postgres-statefulset.yaml
Wait for PostgreSQL to be ready:
# Wait for StatefulSet to be ready
kubectl wait --for=condition=ready pod/postgres-0 -n database-apps --timeout=300s

# Check StatefulSet status
kubectl get statefulset postgres -n database-apps

# Verify PVC creation
kubectl get pvc -n database-apps
Subtask 3.2: Test Database Persistence
Connect to PostgreSQL and create test data:
# Connect to PostgreSQL pod
kubectl exec -it postgres-0 -n database-apps -- psql -U postgres -d testdb

# Inside PostgreSQL prompt, create test table and data
# (Copy and paste these commands one by one)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES 
('John Doe', 'john@example.com'),
('Jane Smith', 'jane@example.com'),
('Bob Johnson', 'bob@example.com');

SELECT * FROM users;

\q
Test persistence by restarting the pod:
# Delete the PostgreSQL pod (StatefulSet will recreate it)
kubectl delete pod postgres-0 -n database-apps

# Wait for new pod to be ready
kubectl wait --for=condition=ready pod/postgres-0 -n database-apps --timeout=300s

# Verify data persistence
kubectl exec -it postgres-0 -n database-apps -- psql -U postgres -d testdb -c "SELECT * FROM users;"
Subtask 3.3: Deploy Redis Cluster with Ceph Storage
Create Redis cluster configuration:
cat > redis-cluster.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-config
  namespace: database-apps
data:
  redis.conf: |
    appendonly yes
    appendfsync everysec
    save 900 1
    save 300 10
    save 60 10000
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
  namespace: database-apps
spec:
  serviceName: redis
  replicas: 3
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        command:
        - redis-server
        - /etc/redis/redis.conf
        volumeMounts:
        - name: redis-config
          mountPath: /etc/redis
        - name: redis-storage
          mountPath: /data
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
      volumes:
      - name: redis-config
        configMap:
          name: redis-config
  volumeClaimTemplates:
  - metadata:
      name: redis-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: ceph-rbd
      resources:
        requests:
          storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: database-apps
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
  clusterIP: None
EOF

# Deploy Redis cluster
kubectl apply -f redis-cluster.yaml
Wait for Redis cluster to be ready:
# Wait for all Redis pods to be ready
kubectl wait --for=condition=ready pod -l app=redis -n database-apps --timeout=300s

# Check StatefulSet status
kubectl get statefulset redis -n database-apps

# List all pods
kubectl get pods -n database-apps
Test Redis functionality:
# Connect to first Redis instance
kubectl exec -it redis-0 -n database-apps -- redis-cli

# Inside Redis CLI, test basic operations
# (Copy and paste these commands one by one)
SET test:key1 "Hello from Ceph storage"
SET test:key2 "Redis with persistent storage"
GET test:key1
GET test:key2
KEYS test:*
QUIT
Subtask 3.4: Monitor Storage Usage and Performance
Check Ceph cluster usage:
# Switch to ceph user
sudo su - ceph

# Check overall cluster usage
ceph df

# Check pool usage
ceph osd pool stats kubernetes

# List RBD images in the pool
rbd ls kubernetes

# Get detailed information about RBD images
rbd ls -l kubernetes

# Exit ceph user
exit
Monitor Kubernetes storage resources:
# Check all PVCs across namespaces
kubectl get pvc --all-namespaces

# Check PV usage
kubectl get pv

# Get detailed information about storage classes
kubectl describe storageclass ceph-rbd
Check application storage usage:
# Check PostgreSQL storage usage
kubectl exec postgres-0 -n database-apps -- df -h /var/lib/postgresql/data

# Check Redis storage usage
kubectl exec redis-0 -n database-apps -- df -h /data

# View pod resource usage (if metrics-server is available)
kubectl top pods -n database-apps
Subtask 3.5: Backup and Recovery Testing
Create database backup:
# Create backup of PostgreSQL database
kubectl exec postgres-0 -n database-apps -- pg_dump -U postgres testdb > postgres-backup.sql

# Verify backup file
head -20 postgres-backup.sql
Test volume snapshot (if supported):
# Create VolumeSnapshotClass
cat > volume-snapshot-class.yaml << 'EOF'
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: ceph-rbd-snapshot-class
driver: rbd.csi.ceph.com
deletionPolicy: Delete
EOF

# Apply snapshot class
kubectl apply -f volume-snapshot-class.yaml

# Create snapshot of PostgreSQL PVC
cat > postgres-snapshot.yaml << 'EOF'
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: postgres-snapshot
  namespace: database-apps
spec:
  volumeSnapshotClassName: ceph-rbd-snapshot-class
  source:
    persistentVolumeClaimName: postgres-storage-postgres-0
EOF

# Create snapshot
kubectl apply -f postgres-snapshot.yaml

# Check snapshot status
kubectl get volumesnapshot -n database-apps
Troubleshooting Common Issues
Issue 1: CSI Driver Pods Not Starting
Symptoms: CSI driver pods stuck in pending or error state

Solution:

# Check pod logs
kubectl logs -n ceph-csi-rbd -l app=csi-rbdplugin

# Verify node labels and taints
kubectl describe nodes

# Check if required kernel modules are loaded
lsmod | grep rbd
Issue 2: PVC Stuck in Pending State
Symptoms: PVC remains in pending state and doesn't bind to PV

Solution:

# Check PVC events
kubectl describe pvc <pvc-name>

# Verify storage class exists
kubectl get storageclass

# Check CSI driver logs
kubectl logs -n ceph-csi-rbd -l app=csi-rbdplugin-provisioner

# Verify Ceph cluster health
sudo ceph health detail
Issue 3: Pod Cannot Mount Volume
Symptoms: Pod fails to start with volume mount errors

Solution:

# Check pod events
kubectl describe pod <pod-name>

# Verify RBD image exists in Ceph
sudo rbd ls kubernetes

# Check node plugin logs
kubectl logs -n ceph-csi-rbd -l app=csi-rbdplugin -c csi-rbdplugin

# Verify network connectivity to Ceph monitors
telnet <monitor-ip> 6789
Conclusion
In this comprehensive lab, you have successfully:

Configured Ceph as a persistent volume backend for Kubernetes by installing and configuring the Ceph CSI driver, creating storage classes, and testing volume provisioning
Integrated Ceph storage with OpenShift for container workloads, demonstrating enterprise-grade storage solutions for containerized applications
Deployed and managed stateful applications including PostgreSQL and Redis clusters using Ceph persistent storage, showing real-world use cases
Key Accomplishments
Storage Integration: You learned how to integrate Ceph distributed storage with container orchestration platforms, providing scalable and reliable persistent storage
Stateful Applications: You deployed production-ready database applications that maintain data persistence across pod restarts and failures
Enterprise Readiness: You configured storage solutions suitable for enterprise environments with proper security, monitoring, and backup capabilities
Why This Matters
Business Value: Organizations running containerized applications need reliable, scalable storage solutions. Ceph provides enterprise-grade distributed storage that can scale with growing data needs while maintaining high availability.

Technical Benefits:

Scalability: Ceph can scale from small clusters to petabyte-scale deployments
High Availability: Data replication ensures no single point of failure
Cost Effectiveness: Open-source solution reduces licensing costs
Flexibility: Supports block, object, and file storage interfaces
Career Relevance: Skills in configuring Ceph for containerized environments are highly valued in DevOps, Site Reliability Engineering, and Cloud Infrastructure roles, especially in organizations adopting cloud-native architectures.

This lab has provided you with practical, hands-on experience that directly applies to real-world container storage challenges in enterprise environments.
