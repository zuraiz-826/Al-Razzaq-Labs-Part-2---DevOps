Lab 17: Deploying Stateful Applications
Objectives
By the end of this lab, you will be able to:

Understand the difference between stateless and stateful applications in Kubernetes
Deploy a database application using StatefulSets
Configure persistent storage for stateful applications
Monitor and scale StatefulSets while maintaining data consistency
Ensure data persistence across pod restarts and failures
Implement ordered deployment and scaling for stateful workloads
Prerequisites
Before starting this lab, you should have:

Basic understanding of Kubernetes concepts (Pods, Services, Deployments)
Familiarity with YAML configuration files
Knowledge of basic Linux command-line operations
Understanding of container concepts and Docker basics
Previous experience with kubectl commands
Completion of previous Kubernetes labs covering Deployments and Services
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines with Kubernetes pre-installed. Simply click Start Lab to access your environment - no need to build your own VM or install Kubernetes manually.

Your lab environment includes:

Ubuntu 20.04 LTS with kubectl pre-configured
Minikube cluster ready for use
All necessary tools and dependencies installed
Persistent storage configured and available
Task 1: Create a StatefulSet for a Database Application
Subtask 1.1: Understanding StatefulSets
StatefulSets are designed for applications that require:

Stable network identities: Each pod gets a predictable hostname
Ordered deployment and scaling: Pods are created and terminated in order
Persistent storage: Each pod maintains its own persistent volume
Subtask 1.2: Create Persistent Volume Claims
First, let's create the storage infrastructure for our database:

# Create a directory for our lab files
mkdir -p ~/lab17-stateful
cd ~/lab17-stateful
Create a file named pv-storage.yaml:

apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv-0
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /tmp/mysql-data-0
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv-1
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /tmp/mysql-data-1
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv-2
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /tmp/mysql-data-2
Apply the persistent volumes:

kubectl apply -f pv-storage.yaml
Verify the persistent volumes are created:

kubectl get pv
Subtask 1.3: Create a MySQL StatefulSet
Create a file named mysql-statefulset.yaml:

apiVersion: v1
kind: Service
metadata:
  name: mysql-headless
  labels:
    app: mysql
spec:
  ports:
  - port: 3306
    name: mysql
  clusterIP: None
  selector:
    app: mysql
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql-headless
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
          name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "rootpassword123"
        - name: MYSQL_DATABASE
          value: "testdb"
        - name: MYSQL_USER
          value: "testuser"
        - name: MYSQL_PASSWORD
          value: "testpass123"
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - mysql
            - -h
            - localhost
            - -u
            - root
            - -prootpassword123
            - -e
            - "SELECT 1"
          initialDelaySeconds: 5
          periodSeconds: 2
  volumeClaimTemplates:
  - metadata:
      name: mysql-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: manual
      resources:
        requests:
          storage: 1Gi
Deploy the StatefulSet:

kubectl apply -f mysql-statefulset.yaml
Subtask 1.4: Verify StatefulSet Deployment
Monitor the StatefulSet deployment:

# Watch the pods being created in order
kubectl get pods -l app=mysql -w
Note: Press Ctrl+C to stop watching after all pods are running.

Check the StatefulSet status:

kubectl get statefulset mysql
Verify the persistent volume claims:

kubectl get pvc
Examine the pod names and their stable network identities:

kubectl get pods -l app=mysql -o wide
Key Observation: Notice that StatefulSet pods have predictable names (mysql-0, mysql-1, mysql-2) and are created in order.

Task 2: Monitor and Scale the StatefulSet
Subtask 2.1: Monitor StatefulSet Health
Create a monitoring script named monitor-statefulset.sh:

#!/bin/bash

echo "=== StatefulSet Status ==="
kubectl get statefulset mysql

echo -e "\n=== Pod Status ==="
kubectl get pods -l app=mysql

echo -e "\n=== Persistent Volume Claims ==="
kubectl get pvc

echo -e "\n=== Service Endpoints ==="
kubectl get endpoints mysql-headless

echo -e "\n=== Pod Details ==="
for pod in $(kubectl get pods -l app=mysql -o jsonpath='{.items[*].metadata.name}'); do
    echo "--- $pod ---"
    kubectl get pod $pod -o jsonpath='{.status.phase}' && echo
    kubectl get pod $pod -o jsonpath='{.status.podIP}' && echo
done
Make the script executable and run it:

chmod +x monitor-statefulset.sh
./monitor-statefulset.sh
Subtask 2.2: Test Database Connectivity
Connect to the first MySQL pod and create some test data:

# Connect to mysql-0 pod
kubectl exec -it mysql-0 -- mysql -u root -prootpassword123

# Inside MySQL prompt, run these commands:
# USE testdb;
# CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50), email VARCHAR(100));
# INSERT INTO users (name, email) VALUES ('John Doe', 'john@example.com');
# INSERT INTO users (name, email) VALUES ('Jane Smith', 'jane@example.com');
# SELECT * FROM users;
# EXIT;
Alternative method using a single command:

kubectl exec -it mysql-0 -- mysql -u root -prootpassword123 -e "
USE testdb;
CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50), email VARCHAR(100));
INSERT INTO users (name, email) VALUES ('John Doe', 'john@example.com');
INSERT INTO users (name, email) VALUES ('Jane Smith', 'jane@example.com');
SELECT * FROM users;
"
Subtask 2.3: Scale the StatefulSet
Scale the StatefulSet to 5 replicas:

kubectl scale statefulset mysql --replicas=5
Watch the scaling process:

kubectl get pods -l app=mysql -w
Note: Observe that new pods are created in order (mysql-3, then mysql-4).

Verify the scaling:

kubectl get statefulset mysql
kubectl get pvc
Scale down to 2 replicas:

kubectl scale statefulset mysql --replicas=2
Monitor the scale-down process:

kubectl get pods -l app=mysql -w
Key Observation: StatefulSets scale down in reverse order (mysql-4, then mysql-3, etc.).

Task 3: Ensure Data Persistence Across Pod Restarts
Subtask 3.1: Test Data Persistence
First, verify our test data still exists in mysql-0:

kubectl exec -it mysql-0 -- mysql -u root -prootpassword123 -e "
USE testdb;
SELECT * FROM users;
"
Subtask 3.2: Simulate Pod Failure
Delete the mysql-0 pod to simulate a failure:

kubectl delete pod mysql-0
Watch the pod being recreated:

kubectl get pods -l app=mysql -w
Wait for the new mysql-0 pod to be ready, then verify data persistence:

# Wait for pod to be ready
kubectl wait --for=condition=ready pod/mysql-0 --timeout=300s

# Check if our data survived the pod restart
kubectl exec -it mysql-0 -- mysql -u root -prootpassword123 -e "
USE testdb;
SELECT * FROM users;
"
Subtask 3.3: Test Persistent Volume Binding
Check which persistent volume is bound to mysql-0:

kubectl get pvc mysql-storage-mysql-0 -o yaml | grep volumeName
Describe the persistent volume claim:

kubectl describe pvc mysql-storage-mysql-0
Subtask 3.4: Create a Data Verification Script
Create a script named verify-persistence.sh:

#!/bin/bash

echo "=== Testing Data Persistence ==="

# Function to check data
check_data() {
    echo "Checking data in mysql-0..."
    kubectl exec -it mysql-0 -- mysql -u root -prootpassword123 -e "
    USE testdb;
    SELECT COUNT(*) as record_count FROM users;
    SELECT * FROM users;
    " 2>/dev/null || echo "Database not ready yet..."
}

# Initial data check
check_data

echo -e "\n=== Deleting mysql-0 pod ==="
kubectl delete pod mysql-0

echo "Waiting for pod to be recreated..."
kubectl wait --for=condition=ready pod/mysql-0 --timeout=300s

echo -e "\n=== Verifying data after pod restart ==="
sleep 10  # Give MySQL time to start
check_data

echo -e "\n=== Data persistence test completed ==="
Make it executable and run:

chmod +x verify-persistence.sh
./verify-persistence.sh
Subtask 3.5: Advanced Persistence Testing
Add more data and test persistence with multiple restarts:

# Add more test data
kubectl exec -it mysql-0 -- mysql -u root -prootpassword123 -e "
USE testdb;
INSERT INTO users (name, email) VALUES ('Alice Johnson', 'alice@example.com');
INSERT INTO users (name, email) VALUES ('Bob Wilson', 'bob@example.com');
SELECT COUNT(*) as total_users FROM users;
"

# Restart the entire StatefulSet
kubectl rollout restart statefulset mysql

# Wait for rollout to complete
kubectl rollout status statefulset mysql

# Verify data persistence
kubectl exec -it mysql-0 -- mysql -u root -prootpassword123 -e "
USE testdb;
SELECT COUNT(*) as total_users FROM users;
SELECT * FROM users ORDER BY id;
"
Troubleshooting Common Issues
Issue 1: Pods Stuck in Pending State
Symptoms: Pods remain in Pending state Solution:

# Check if persistent volumes are available
kubectl get pv

# Check pod events for storage issues
kubectl describe pod mysql-0

# Verify storage class exists
kubectl get storageclass
Issue 2: MySQL Connection Refused
Symptoms: Cannot connect to MySQL database Solution:

# Check pod logs
kubectl logs mysql-0

# Verify MySQL is running
kubectl exec mysql-0 -- ps aux | grep mysql

# Check if port is listening
kubectl exec mysql-0 -- netstat -tlnp | grep 3306
Issue 3: Data Not Persisting
Symptoms: Data disappears after pod restart Solution:

# Verify PVC is bound
kubectl get pvc mysql-storage-mysql-0

# Check mount points
kubectl exec mysql-0 -- df -h | grep mysql

# Verify volume mount in pod spec
kubectl get pod mysql-0 -o yaml | grep -A 10 volumeMounts
Lab Cleanup
When you're finished with the lab, clean up the resources:

# Delete the StatefulSet
kubectl delete statefulset mysql

# Delete the headless service
kubectl delete service mysql-headless

# Delete persistent volume claims
kubectl delete pvc mysql-storage-mysql-0 mysql-storage-mysql-1

# Delete persistent volumes
kubectl delete pv mysql-pv-0 mysql-pv-1 mysql-pv-2

# Verify cleanup
kubectl get all,pvc,pv | grep mysql
Conclusion
In this lab, you have successfully:

Deployed a stateful application using StatefulSets, understanding how they differ from regular Deployments
Configured persistent storage that maintains data across pod restarts and failures
Monitored and scaled StatefulSets while observing their ordered deployment behavior
Verified data persistence through multiple pod restart scenarios
Implemented health checks and resource management for database workloads
Why This Matters: StatefulSets are crucial for running databases, message queues, and other applications that require stable network identities and persistent storage in Kubernetes. This knowledge is essential for the Red Hat Certified OpenShift Administrator exam and real-world container orchestration scenarios.

Key Takeaways:

StatefulSets provide ordered deployment, stable network identities, and persistent storage
Each pod in a StatefulSet gets its own persistent volume claim
Scaling operations happen in order (0, 1, 2... for scale-up and reverse for scale-down)
Data persists across pod restarts when properly configured with persistent volumes
Headless services enable direct pod-to-pod communication in StatefulSets
This foundation prepares you for managing complex stateful applications in production Kubernetes environments and demonstrates the power of container orchestration for enterprise workloads.
