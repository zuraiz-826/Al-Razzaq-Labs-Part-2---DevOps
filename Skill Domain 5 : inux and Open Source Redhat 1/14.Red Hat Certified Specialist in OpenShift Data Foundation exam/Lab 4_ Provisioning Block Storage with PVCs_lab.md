Lab 4: Provisioning Block Storage with PVCs
Objectives
By the end of this lab, you will be able to:

Understand the concepts of Persistent Volumes (PVs) and Persistent Volume Claims (PVCs) in OpenShift Data Foundation
Create and configure Persistent Volume Claims for block storage
Deploy stateful applications that utilize block storage through PVCs
Validate storage provisioning and verify data persistence
Troubleshoot common storage-related issues in OpenShift environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of Kubernetes/OpenShift concepts
Familiarity with YAML configuration files
Knowledge of command-line interface operations
Completed previous labs in the OpenShift Data Foundation series
Access to an OpenShift cluster with OpenShift Data Foundation installed
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift and OpenShift Data Foundation already installed. Simply click Start Lab to begin - no need to build your own virtual machine or install software.

Your lab environment includes:

OpenShift 4.12+ cluster
OpenShift Data Foundation 4.12+
Pre-configured storage classes
Command-line tools (oc, kubectl)
Task 1: Create PVCs for Block Storage
Subtask 1.1: Examine Available Storage Classes
First, let's explore the storage classes available in your OpenShift Data Foundation environment.

Login to your OpenShift cluster:
oc login -u admin -p admin https://api.cluster.example.com:6443
List available storage classes:
oc get storageclass
Examine the ODF block storage class details:
oc describe storageclass ocs-storagecluster-ceph-rbd
Expected Output: You should see storage classes including ocs-storagecluster-ceph-rbd for block storage, which uses Ceph RBD (RADOS Block Device) as the backend.

Subtask 1.2: Create a Basic PVC for Block Storage
Now we'll create our first Persistent Volume Claim for block storage.

Create a project for this lab:
oc new-project storage-lab
Create a basic PVC configuration file:
cat > basic-block-pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: basic-block-pvc
  namespace: storage-lab
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Apply the PVC configuration:
oc apply -f basic-block-pvc.yaml
Verify the PVC creation:
oc get pvc basic-block-pvc
Check the PVC status in detail:
oc describe pvc basic-block-pvc
Key Concepts:

ReadWriteOnce: The volume can be mounted as read-write by a single node
Storage Class: Defines the type of storage and provisioner to use
Bound Status: Indicates the PVC has been successfully matched with a PV
Subtask 1.3: Create Multiple PVCs with Different Configurations
Let's create additional PVCs with various configurations to understand different use cases.

Create a larger PVC for database storage:
cat > database-pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-pvc
  namespace: storage-lab
  labels:
    app: database
    tier: storage
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Create a PVC with specific performance requirements:
cat > high-performance-pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: high-performance-pvc
  namespace: storage-lab
  annotations:
    volume.beta.kubernetes.io/storage-class: ocs-storagecluster-ceph-rbd
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Apply both PVC configurations:
oc apply -f database-pvc.yaml
oc apply -f high-performance-pvc.yaml
Verify all PVCs are created and bound:
oc get pvc -n storage-lab
Task 2: Attach PVCs to Stateful Applications
Subtask 2.1: Deploy a Database Application with Block Storage
We'll deploy a PostgreSQL database that uses our block storage PVC.

Create a PostgreSQL deployment with persistent storage:
cat > postgres-with-storage.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-db
  namespace: storage-lab
  labels:
    app: postgres
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
          value: "testdb"
        - name: POSTGRES_USER
          value: "testuser"
        - name: POSTGRES_PASSWORD
          value: "testpass123"
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
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
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: database-pvc
EOF
Deploy the PostgreSQL application:
oc apply -f postgres-with-storage.yaml
Create a service for the database:
cat > postgres-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: storage-lab
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
EOF
Apply the service configuration:
oc apply -f postgres-service.yaml
Verify the deployment is running:
oc get pods -n storage-lab -l app=postgres
Subtask 2.2: Deploy a Web Application with Block Storage
Now let's deploy a web application that also uses block storage for file uploads.

Create a simple web application with persistent storage:
cat > webapp-with-storage.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: storage-lab
  labels:
    app: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: nginx:1.21
        ports:
        - containerPort: 80
        volumeMounts:
        - name: webapp-storage
          mountPath: /usr/share/nginx/html/uploads
        - name: config-volume
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: webapp-storage
        persistentVolumeClaim:
          claimName: basic-block-pvc
      - name: config-volume
        configMap:
          name: nginx-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: storage-lab
data:
  default.conf: |
    server {
        listen 80;
        server_name localhost;
        
        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
        }
        
        location /uploads {
            alias /usr/share/nginx/html/uploads;
            autoindex on;
        }
    }
EOF
Deploy the web application:
oc apply -f webapp-with-storage.yaml
Create a service for the web application:
cat > webapp-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
  namespace: storage-lab
spec:
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
Apply the service:
oc apply -f webapp-service.yaml
Verify both applications are running:
oc get pods -n storage-lab
Subtask 2.3: Create a StatefulSet with Block Storage
StatefulSets are ideal for applications that require stable, persistent storage.

Create a StatefulSet with persistent storage:
cat > statefulset-with-storage.yaml << 'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: data-processor
  namespace: storage-lab
spec:
  serviceName: "data-processor"
  replicas: 2
  selector:
    matchLabels:
      app: data-processor
  template:
    metadata:
      labels:
        app: data-processor
    spec:
      containers:
      - name: data-processor
        image: busybox:1.35
        command:
        - sh
        - -c
        - |
          echo "Starting data processor $(hostname)" > /data/startup.log
          date >> /data/startup.log
          while true; do
            echo "Processing data at $(date)" >> /data/processing.log
            sleep 30
          done
        volumeMounts:
        - name: data-storage
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: data-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: ocs-storagecluster-ceph-rbd
      resources:
        requests:
          storage: 5Gi
EOF
Deploy the StatefulSet:
oc apply -f statefulset-with-storage.yaml
Create a headless service for the StatefulSet:
cat > statefulset-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: data-processor
  namespace: storage-lab
spec:
  clusterIP: None
  selector:
    app: data-processor
  ports:
  - port: 80
EOF
Apply the headless service:
oc apply -f statefulset-service.yaml
Verify the StatefulSet deployment:
oc get statefulset -n storage-lab
oc get pods -n storage-lab -l app=data-processor
Task 3: Validate Storage Provisioning
Subtask 3.1: Verify PVC Binding and Volume Creation
Let's validate that our storage provisioning is working correctly.

Check all PVCs in the namespace:
oc get pvc -n storage-lab
Examine the automatically created Persistent Volumes:
oc get pv
Get detailed information about a specific PVC:
oc describe pvc database-pvc -n storage-lab
Check the storage usage:
oc get pvc -n storage-lab -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage,STORAGECLASS:.spec.storageClassName
Subtask 3.2: Test Data Persistence
Now let's verify that data persists across pod restarts.

Connect to the PostgreSQL pod and create test data:
# Get the pod name
POSTGRES_POD=$(oc get pods -n storage-lab -l app=postgres -o jsonpath='{.items[0].metadata.name}')

# Connect to PostgreSQL and create test data
oc exec -it $POSTGRES_POD -n storage-lab -- psql -U testuser -d testdb -c "
CREATE TABLE test_persistence (
    id SERIAL PRIMARY KEY,
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO test_persistence (message) VALUES 
('Data created before restart'),
('Testing persistence'),
('This should survive pod restart');

SELECT * FROM test_persistence;
"
Create test files in the web application storage:
# Get the webapp pod name
WEBAPP_POD=$(oc get pods -n storage-lab -l app=webapp -o jsonpath='{.items[0].metadata.name}')

# Create test files
oc exec -it $WEBAPP_POD -n storage-lab -- sh -c "
echo 'Test file 1 - Created at $(date)' > /usr/share/nginx/html/uploads/test1.txt
echo 'Test file 2 - Should persist' > /usr/share/nginx/html/uploads/test2.txt
ls -la /usr/share/nginx/html/uploads/
"
Check StatefulSet data:
# Check data in first StatefulSet pod
oc exec -it data-processor-0 -n storage-lab -- cat /data/startup.log
oc exec -it data-processor-0 -n storage-lab -- tail -5 /data/processing.log
Subtask 3.3: Test Pod Restart and Data Persistence
Let's restart the pods and verify data persistence.

Delete the PostgreSQL pod to trigger restart:
oc delete pod $POSTGRES_POD -n storage-lab
Wait for the new pod to be ready:
oc wait --for=condition=Ready pod -l app=postgres -n storage-lab --timeout=120s
Verify data persistence in PostgreSQL:
# Get the new pod name
NEW_POSTGRES_POD=$(oc get pods -n storage-lab -l app=postgres -o jsonpath='{.items[0].metadata.name}')

# Check if data persisted
oc exec -it $NEW_POSTGRES_POD -n storage-lab -- psql -U testuser -d testdb -c "SELECT * FROM test_persistence;"
Restart the web application pod:
oc delete pod $WEBAPP_POD -n storage-lab
oc wait --for=condition=Ready pod -l app=webapp -n storage-lab --timeout=120s
Verify web application files persisted:
# Get the new webapp pod name
NEW_WEBAPP_POD=$(oc get pods -n storage-lab -l app=webapp -o jsonpath='{.items[0].metadata.name}')

# Check if files persisted
oc exec -it $NEW_WEBAPP_POD -n storage-lab -- ls -la /usr/share/nginx/html/uploads/
oc exec -it $NEW_WEBAPP_POD -n storage-lab -- cat /usr/share/nginx/html/uploads/test1.txt
Subtask 3.4: Monitor Storage Usage and Performance
Let's examine storage usage and performance metrics.

Check storage usage in the OpenShift console or via CLI:
# Get storage usage information
oc get pvc -n storage-lab -o custom-columns=NAME:.metadata.name,CAPACITY:.status.capacity.storage,USED:.status.capacity.storage

# Check node storage usage
oc adm top nodes
Examine Ceph storage cluster status:
# Check ODF storage cluster status
oc get storagecluster -n openshift-storage

# Check Ceph cluster health
oc get cephcluster -n openshift-storage
View storage-related events:
oc get events -n storage-lab --field-selector involvedObject.kind=PersistentVolumeClaim
Troubleshooting Common Issues
Issue 1: PVC Stuck in Pending State
Symptoms: PVC remains in "Pending" status Solution:

# Check storage class availability
oc get storageclass

# Check if ODF is properly installed
oc get pods -n openshift-storage

# Describe the PVC for error details
oc describe pvc <pvc-name> -n storage-lab
Issue 2: Pod Cannot Mount Volume
Symptoms: Pod fails to start with volume mount errors Solution:

# Check pod events
oc describe pod <pod-name> -n storage-lab

# Verify PVC is bound
oc get pvc -n storage-lab

# Check node resources
oc describe node <node-name>
Issue 3: Storage Performance Issues
Symptoms: Slow I/O operations Solution:

# Check Ceph cluster health
oc exec -it $(oc get pods -n openshift-storage -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}') -n openshift-storage -- ceph status

# Monitor storage metrics
oc get cephcluster -n openshift-storage -o yaml
Validation Checklist
Before completing this lab, ensure you have:

 Successfully created multiple PVCs with different configurations
 Deployed applications that use block storage through PVCs
 Verified data persistence across pod restarts
 Tested StatefulSet with persistent volume claim templates
 Monitored storage usage and performance
 Troubleshot common storage issues
Conclusion
In this lab, you have successfully:

Created Persistent Volume Claims: You learned how to provision block storage using PVCs with different configurations and storage classes in OpenShift Data Foundation.

Attached Storage to Applications: You deployed various types of applications (databases, web applications, and StatefulSets) that utilize persistent block storage, demonstrating real-world use cases.

Validated Storage Provisioning: You verified that storage is properly provisioned, data persists across pod restarts, and learned how to monitor storage usage and performance.

Why This Matters: Block storage with PVCs is fundamental for stateful applications in Kubernetes environments. Understanding how to properly provision and manage persistent storage ensures your applications can maintain data integrity and availability. This knowledge is essential for production deployments where data persistence is critical.

Key Takeaways:

PVCs provide an abstraction layer between applications and storage infrastructure
Different access modes serve different application requirements
StatefulSets with volume claim templates provide scalable persistent storage
Proper monitoring and troubleshooting skills are essential for production environments
This lab has prepared you with practical skills for the Red Hat Certified Specialist in OpenShift Data Foundation exam and real-world storage management scenarios.
