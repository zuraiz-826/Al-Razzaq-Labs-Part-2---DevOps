Lab 12: Managing Storage and Persistent Volumes
Objectives
By the end of this lab, you will be able to:

Understand the concepts of persistent storage in OpenShift
Create and configure Persistent Volume Claims (PVCs) for applications
Attach PVCs to pods and monitor storage usage
Modify and work with storage class settings
Troubleshoot common storage-related issues in OpenShift
Prerequisites
Before starting this lab, you should have:

Basic understanding of OpenShift/Kubernetes concepts (pods, deployments, services)
Familiarity with command-line interface operations
Knowledge of YAML file structure and syntax
Understanding of Linux file system concepts
Access to OpenShift CLI (oc command)
Ready-to-Use Cloud Machines
Al Nafi provides pre-configured Linux-based cloud machines with OpenShift already installed and configured. Simply click Start Lab to access your environment. No need to build your own VM or install OpenShift from scratch.

Your lab environment includes:

OpenShift cluster with administrative access
Pre-configured storage classes
Command-line tools (oc, kubectl)
Text editors (vi, nano)
Lab Environment Setup
Verify Your Environment
First, let's verify that your OpenShift environment is ready:

# Check OpenShift cluster status
oc cluster-info

# Verify you have admin privileges
oc whoami

# Check available storage classes
oc get storageclass
Create a Project for This Lab
# Create a new project for storage testing
oc new-project storage-lab

# Verify the project was created
oc project storage-lab
Task 1: Create Persistent Volume Claims (PVCs) for Storage
Subtask 1.1: Understanding Storage Classes
Before creating PVCs, let's examine the available storage classes:

# List all storage classes with details
oc get storageclass -o wide

# Get detailed information about a specific storage class
oc describe storageclass <storage-class-name>
Subtask 1.2: Create Your First PVC
Create a basic PVC for general application storage:

# Create a file for the PVC definition
cat > basic-pvc.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: basic-storage-pvc
  namespace: storage-lab
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: gp2
EOF
Apply the PVC:

# Create the PVC
oc apply -f basic-pvc.yaml

# Check the PVC status
oc get pvc

# Get detailed information about the PVC
oc describe pvc basic-storage-pvc
Subtask 1.3: Create a Shared Storage PVC
Create a PVC that can be shared across multiple pods:

# Create a shared storage PVC
cat > shared-pvc.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-storage-pvc
  namespace: storage-lab
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs
EOF
Apply the shared PVC:

# Create the shared PVC
oc apply -f shared-pvc.yaml

# Verify both PVCs are created
oc get pvc
Subtask 1.4: Create a Database-Specific PVC
Create a PVC optimized for database workloads:

# Create a database PVC with specific performance requirements
cat > database-pvc.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-storage-pvc
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
  storageClassName: fast-ssd
EOF
Apply the database PVC:

# Create the database PVC
oc apply -f database-pvc.yaml

# Check all PVCs
oc get pvc -o wide
Task 2: Attach PVCs to Pods and Check Storage Usage
Subtask 2.1: Create a Pod with Basic Storage
Create a simple pod that uses the basic PVC:

# Create a pod with mounted storage
cat > storage-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: storage-test-pod
  namespace: storage-lab
spec:
  containers:
  - name: storage-container
    image: registry.redhat.io/ubi8/ubi:latest
    command: ["/bin/bash"]
    args: ["-c", "while true; do sleep 30; done"]
    volumeMounts:
    - name: storage-volume
      mountPath: /data
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
  volumes:
  - name: storage-volume
    persistentVolumeClaim:
      claimName: basic-storage-pvc
  restartPolicy: Always
EOF
Deploy the pod:

# Create the pod
oc apply -f storage-pod.yaml

# Wait for the pod to be ready
oc get pods -w

# Once running, check the pod details
oc describe pod storage-test-pod
Subtask 2.2: Test Storage Functionality
Access the pod and test the storage:

# Execute commands inside the pod
oc exec -it storage-test-pod -- /bin/bash

# Inside the pod, run these commands:
# Check mounted storage
df -h /data

# Create test files
echo "This is a test file" > /data/test.txt
echo "Storage test $(date)" > /data/timestamp.txt

# Create a directory and more files
mkdir /data/testdir
echo "Directory test" > /data/testdir/dirtest.txt

# Check disk usage
du -sh /data/*

# List all files
ls -la /data/

# Exit the pod
exit
Subtask 2.3: Create a Deployment with Persistent Storage
Create a deployment that uses persistent storage:

# Create a deployment with persistent storage
cat > web-app-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-with-storage
  namespace: storage-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-container
        image: registry.redhat.io/ubi8/httpd-24:latest
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: web-content
          mountPath: /var/www/html
        - name: logs
          mountPath: /var/log/httpd
      volumes:
      - name: web-content
        persistentVolumeClaim:
          claimName: basic-storage-pvc
      - name: logs
        persistentVolumeClaim:
          claimName: shared-storage-pvc
EOF
Deploy the application:

# Create the deployment
oc apply -f web-app-deployment.yaml

# Check deployment status
oc get deployment web-app-with-storage

# Check pods
oc get pods -l app=web-app

# Check which PVCs are bound
oc get pvc
Subtask 2.4: Monitor Storage Usage
Check storage usage across your pods:

# Get storage usage for all PVCs
oc get pvc -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage,STORAGECLASS:.spec.storageClassName

# Check pod storage usage
for pod in $(oc get pods -l app=web-app -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== Storage usage for pod: $pod ==="
  oc exec $pod -- df -h
  echo ""
done
Create and monitor storage usage:

# Create test data in the web application
oc exec deployment/web-app-with-storage -- /bin/bash -c "
echo '<h1>Welcome to Storage Lab</h1>' > /var/www/html/index.html
echo '<p>Storage test page created on $(date)</p>' >> /var/www/html/index.html
mkdir -p /var/www/html/data
for i in {1..10}; do
  echo 'Test data file $i content' > /var/www/html/data/file$i.txt
done
"

# Check the created content
oc exec deployment/web-app-with-storage -- ls -la /var/www/html/
oc exec deployment/web-app-with-storage -- ls -la /var/www/html/data/
Task 3: Modify Storage Class Settings
Subtask 3.1: Examine Current Storage Classes
First, let's examine the existing storage classes in detail:

# Get all storage classes with detailed output
oc get storageclass -o yaml > current-storage-classes.yaml

# View the default storage class
oc get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}'

# Examine a specific storage class
oc describe storageclass gp2
Subtask 3.2: Create a Custom Storage Class
Create a new storage class with custom settings:

# Create a custom storage class
cat > custom-storage-class.yaml << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: custom-fast-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF
Apply the custom storage class:

# Create the custom storage class
oc apply -f custom-storage-class.yaml

# Verify the storage class was created
oc get storageclass custom-fast-storage

# Get detailed information
oc describe storageclass custom-fast-storage
Subtask 3.3: Test the Custom Storage Class
Create a PVC using the custom storage class:

# Create a PVC using the custom storage class
cat > custom-storage-pvc.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: custom-fast-pvc
  namespace: storage-lab
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 15Gi
  storageClassName: custom-fast-storage
EOF
Apply and test:

# Create the PVC
oc apply -f custom-storage-pvc.yaml

# Check the PVC status
oc get pvc custom-fast-pvc

# Create a pod to test the custom storage
cat > custom-storage-test-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: custom-storage-test
  namespace: storage-lab
spec:
  containers:
  - name: test-container
    image: registry.redhat.io/ubi8/ubi:latest
    command: ["/bin/bash"]
    args: ["-c", "while true; do sleep 30; done"]
    volumeMounts:
    - name: custom-storage
      mountPath: /custom-data
  volumes:
  - name: custom-storage
    persistentVolumeClaim:
      claimName: custom-fast-pvc
EOF
Deploy and test:

# Create the test pod
oc apply -f custom-storage-test-pod.yaml

# Wait for pod to be ready
oc wait --for=condition=Ready pod/custom-storage-test --timeout=300s

# Test the custom storage
oc exec custom-storage-test -- df -h /custom-data
oc exec custom-storage-test -- dd if=/dev/zero of=/custom-data/speedtest bs=1M count=100
oc exec custom-storage-test -- ls -lh /custom-data/
Subtask 3.4: Modify Storage Class Default Settings
Change the default storage class:

# Remove default annotation from current default storage class
CURRENT_DEFAULT=$(oc get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}')
echo "Current default storage class: $CURRENT_DEFAULT"

# Remove default annotation (if you want to change it)
oc patch storageclass $CURRENT_DEFAULT -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

# Set your custom storage class as default
oc patch storageclass custom-fast-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Verify the change
oc get storageclass
Subtask 3.5: Test Volume Expansion
Test the volume expansion feature:

# Check current PVC size
oc get pvc custom-fast-pvc -o jsonpath='{.status.capacity.storage}'

# Expand the PVC
oc patch pvc custom-fast-pvc -p '{"spec":{"resources":{"requests":{"storage":"25Gi"}}}}'

# Monitor the expansion
oc get pvc custom-fast-pvc -w

# Check the expanded storage in the pod
oc exec custom-storage-test -- df -h /custom-data
Verification and Testing
Comprehensive Storage Status Check
Run these commands to verify all your storage configurations:

# Check all PVCs
echo "=== All Persistent Volume Claims ==="
oc get pvc -o wide

# Check all storage classes
echo "=== All Storage Classes ==="
oc get storageclass

# Check pods using storage
echo "=== Pods with Storage ==="
oc get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,VOLUMES:.spec.volumes[*].persistentVolumeClaim.claimName

# Check storage usage summary
echo "=== Storage Usage Summary ==="
oc get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,STATUS:.status.phase,CLAIM:.spec.claimRef.name,STORAGECLASS:.spec.storageClassName
Performance Testing
Test storage performance:

# Create a performance test script
cat > storage-performance-test.sh << 'EOF'
#!/bin/bash
echo "=== Storage Performance Test ==="
POD_NAME="custom-storage-test"
MOUNT_PATH="/custom-data"

echo "Testing write performance..."
oc exec $POD_NAME -- dd if=/dev/zero of=$MOUNT_PATH/write-test bs=1M count=500 2>&1 | grep -E "(copied|MB/s)"

echo "Testing read performance..."
oc exec $POD_NAME -- dd if=$MOUNT_PATH/write-test of=/dev/null bs=1M 2>&1 | grep -E "(copied|MB/s)"

echo "Testing random I/O..."
oc exec $POD_NAME -- dd if=/dev/urandom of=$MOUNT_PATH/random-test bs=4k count=1000 2>&1 | grep -E "(copied|MB/s)"

echo "Cleaning up test files..."
oc exec $POD_NAME -- rm -f $MOUNT_PATH/write-test $MOUNT_PATH/random-test
EOF

# Make the script executable and run it
chmod +x storage-performance-test.sh
./storage-performance-test.sh
Troubleshooting Common Issues
Issue 1: PVC Stuck in Pending State
# Check PVC events
oc describe pvc <pvc-name>

# Check if storage class exists
oc get storageclass

# Check node capacity
oc describe nodes | grep -A 5 "Allocated resources"
Issue 2: Pod Cannot Mount Volume
# Check pod events
oc describe pod <pod-name>

# Check PVC status
oc get pvc

# Check if PVC is bound
oc get pv
Issue 3: Storage Class Issues
# Verify storage class parameters
oc describe storageclass <storage-class-name>

# Check provisioner logs
oc logs -n kube-system -l app=ebs-csi-controller
Cleanup
Clean up the resources created in this lab:

# Delete all pods
oc delete pod storage-test-pod custom-storage-test

# Delete deployment
oc delete deployment web-app-with-storage

# Delete PVCs (this will also delete the associated PVs)
oc delete pvc basic-storage-pvc shared-storage-pvc database-storage-pvc custom-fast-pvc

# Delete custom storage class
oc delete storageclass custom-fast-storage

# Restore original default storage class (if changed)
oc patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Delete the project
oc delete project storage-lab
Conclusion
In this lab, you have successfully:

Created multiple types of PVCs with different access modes and storage requirements
Attached persistent storage to pods and verified data persistence across pod restarts
Monitored storage usage and performed performance testing
Created and configured custom storage classes with specific parameters
Modified default storage class settings and tested volume expansion capabilities
Troubleshot common storage issues and learned debugging techniques
Key Takeaways
Storage Management Skills: You now understand how to provision, attach, and manage persistent storage in OpenShift, which is crucial for stateful applications like databases and content management systems.

Performance Optimization: You learned how to create storage classes with specific performance characteristics, enabling you to optimize storage for different workload requirements.

Operational Excellence: The troubleshooting skills you developed will help you diagnose and resolve storage-related issues in production environments.

Real-World Applications
These skills are essential for:

Database Administration: Managing persistent storage for database workloads
Application Development: Ensuring data persistence for stateful applications
DevOps Operations: Optimizing storage performance and costs
Disaster Recovery: Understanding storage backup and recovery procedures
This knowledge directly supports the Red Hat Certified OpenShift Administrator exam objectives and prepares you for managing enterprise OpenShift environments where proper storage management is critical for application reliability and performance.
