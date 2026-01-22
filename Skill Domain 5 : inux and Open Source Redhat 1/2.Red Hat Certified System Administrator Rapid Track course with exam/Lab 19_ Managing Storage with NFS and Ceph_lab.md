Lab 19: Managing Storage with NFS and Ceph
Objectives
By the end of this lab, students will be able to:

• Configure and deploy an NFS (Network File System) server for shared storage • Set up Ceph distributed storage cluster for block storage • Integrate NFS and Ceph storage solutions with Kubernetes • Understand the differences between network-attached storage (NFS) and distributed block storage (Ceph) • Configure persistent volumes in Kubernetes using both NFS and Ceph • Troubleshoot common storage configuration issues

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Familiarity with file systems and storage concepts • Basic knowledge of Kubernetes concepts (pods, services, persistent volumes) • Understanding of network configuration basics • Experience with text editors like vi/vim or nano

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure complex networking.

Your lab environment includes: • 4 CentOS/RHEL 8 virtual machines • Pre-installed Docker and Kubernetes • Network connectivity between all machines • Root access to all systems

Task 1: Configure an NFS Server
Subtask 1.1: Install and Configure NFS Server
Step 1: Connect to your NFS server machine (server1)

# Update the system
sudo dnf update -y

# Install NFS utilities
sudo dnf install -y nfs-utils
Step 2: Create directories for NFS shares

# Create shared directories
sudo mkdir -p /nfs/shared
sudo mkdir -p /nfs/data

# Set appropriate permissions
sudo chmod 755 /nfs/shared
sudo chmod 755 /nfs/data

# Change ownership to nobody for NFS compatibility
sudo chown nobody:nobody /nfs/shared
sudo chown nobody:nobody /nfs/data
Step 3: Configure NFS exports

# Create the exports configuration file
sudo nano /etc/exports

# Add the following lines to the file:
/nfs/shared *(rw,sync,no_subtree_check,no_root_squash)
/nfs/data *(rw,sync,no_subtree_check,no_root_squash)
Explanation of NFS export options: • rw: Read-write access • sync: Synchronous writes • no_subtree_check: Improves performance by disabling subtree checking • no_root_squash: Allows root user on client to have root privileges

Step 4: Start and enable NFS services

# Enable and start the NFS server
sudo systemctl enable nfs-server
sudo systemctl start nfs-server

# Enable and start related services
sudo systemctl enable rpcbind
sudo systemctl start rpcbind

# Export the NFS shares
sudo exportfs -a

# Verify exports
sudo exportfs -v
Subtask 1.2: Configure NFS Client
Step 1: Connect to your client machine (server2)

# Install NFS client utilities
sudo dnf install -y nfs-utils

# Create mount points
sudo mkdir -p /mnt/nfs-shared
sudo mkdir -p /mnt/nfs-data
Step 2: Mount NFS shares

# Replace SERVER_IP with your NFS server's IP address
SERVER_IP="192.168.1.10"  # Example IP - use your actual server IP

# Mount the NFS shares
sudo mount -t nfs ${SERVER_IP}:/nfs/shared /mnt/nfs-shared
sudo mount -t nfs ${SERVER_IP}:/nfs/data /mnt/nfs-data

# Verify mounts
df -h | grep nfs
Step 3: Test NFS functionality

# Create a test file on the client
echo "Hello from NFS client" | sudo tee /mnt/nfs-shared/test.txt

# Verify the file appears on the server
# (Switch to server1 terminal)
cat /nfs/shared/test.txt
Step 4: Configure persistent mounting

# Add entries to fstab for persistent mounting
echo "${SERVER_IP}:/nfs/shared /mnt/nfs-shared nfs defaults 0 0" | sudo tee -a /etc/fstab
echo "${SERVER_IP}:/nfs/data /mnt/nfs-data nfs defaults 0 0" | sudo tee -a /etc/fstab

# Test fstab configuration
sudo umount /mnt/nfs-shared /mnt/nfs-data
sudo mount -a
Task 2: Set up Ceph for Distributed Block Storage
Subtask 2.1: Install Ceph Components
Step 1: Prepare Ceph cluster nodes (server1, server2, server3)

On each node, run:

# Add Ceph repository
sudo dnf install -y centos-release-ceph-pacific

# Install Ceph packages
sudo dnf install -y ceph ceph-radosgw

# Install cephadm for cluster management
sudo dnf install -y cephadm
Step 2: Initialize Ceph cluster on the first node (server1)

# Initialize the cluster
sudo cephadm bootstrap --mon-ip 192.168.1.10

# The command will output the dashboard URL and admin password
# Save this information for later use
Step 3: Add additional nodes to the cluster

# On server1, get the join command
sudo ceph orch host add server2 192.168.1.11
sudo ceph orch host add server3 192.168.1.12

# Verify cluster status
sudo ceph status
Subtask 2.2: Configure Ceph Storage
Step 1: Add OSDs (Object Storage Daemons)

# List available devices
sudo ceph orch device ls

# Add OSDs (replace /dev/sdb with your actual device)
sudo ceph orch daemon add osd server1:/dev/sdb
sudo ceph orch daemon add osd server2:/dev/sdb
sudo ceph orch daemon add osd server3:/dev/sdb

# Check OSD status
sudo ceph osd status
Step 2: Create a storage pool

# Create a replicated pool for block storage
sudo ceph osd pool create rbd 32 32

# Enable RBD application on the pool
sudo ceph osd pool application enable rbd rbd

# Initialize the pool for RBD
sudo rbd pool init rbd
Step 3: Create a block device

# Create a 10GB RBD image
sudo rbd create --size 10G rbd/test-volume

# List RBD images
sudo rbd ls rbd

# Get image information
sudo rbd info rbd/test-volume
Subtask 2.3: Test Ceph Block Storage
Step 1: Map and mount the RBD device

# Map the RBD device
sudo rbd map rbd/test-volume

# Check mapped devices
rbd showmapped

# Format the device (usually /dev/rbd0)
sudo mkfs.ext4 /dev/rbd0

# Create mount point and mount
sudo mkdir -p /mnt/ceph-block
sudo mount /dev/rbd0 /mnt/ceph-block

# Test write operations
echo "Hello from Ceph block storage" | sudo tee /mnt/ceph-block/test.txt
cat /mnt/ceph-block/test.txt
Task 3: Integrate NFS/Ceph with Kubernetes
Subtask 3.1: Configure NFS Storage in Kubernetes
Step 1: Create NFS Persistent Volume

# Create NFS PV configuration
cat << EOF > nfs-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 192.168.1.10  # Replace with your NFS server IP
    path: /nfs/shared
  persistentVolumeReclaimPolicy: Retain
EOF

# Apply the configuration
kubectl apply -f nfs-pv.yaml
Step 2: Create Persistent Volume Claim

# Create NFS PVC configuration
cat << EOF > nfs-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
EOF

# Apply the configuration
kubectl apply -f nfs-pvc.yaml

# Verify PVC status
kubectl get pvc
Step 3: Deploy application using NFS storage

# Create deployment with NFS storage
cat << EOF > nfs-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nfs-app
  template:
    metadata:
      labels:
        app: nfs-app
    spec:
      containers:
      - name: app
        image: nginx:latest
        volumeMounts:
        - name: nfs-storage
          mountPath: /usr/share/nginx/html
      volumes:
      - name: nfs-storage
        persistentVolumeClaim:
          claimName: nfs-pvc
EOF

# Deploy the application
kubectl apply -f nfs-deployment.yaml

# Check deployment status
kubectl get deployments
kubectl get pods
Subtask 3.2: Configure Ceph Storage in Kubernetes
Step 1: Install Ceph CSI driver

# Clone Ceph CSI repository
git clone https://github.com/ceph/ceph-csi.git
cd ceph-csi/deploy/rbd/kubernetes

# Deploy CSI driver
kubectl apply -f csi-provisioner-rbac.yaml
kubectl apply -f csi-nodeplugin-rbac.yaml
kubectl apply -f csi-rbdplugin-provisioner.yaml
kubectl apply -f csi-rbdplugin.yaml
Step 2: Create Ceph storage class

# Get Ceph cluster information
CLUSTER_ID=$(sudo ceph fsid)
MON_ENDPOINTS=$(sudo ceph mon dump | grep "mon\." | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')

# Create storage class configuration
cat << EOF > ceph-storageclass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ceph-rbd
provisioner: rbd.csi.ceph.com
parameters:
  clusterID: ${CLUSTER_ID}
  pool: rbd
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

# Apply storage class
kubectl apply -f ceph-storageclass.yaml
Step 3: Create Ceph authentication secret

# Get Ceph admin key
CEPH_ADMIN_KEY=$(sudo ceph auth get-key client.admin)

# Create secret
kubectl create secret generic csi-rbd-secret \
  --from-literal=userID=admin \
  --from-literal=userKey=${CEPH_ADMIN_KEY}
Step 4: Test Ceph storage with PVC

# Create PVC using Ceph storage
cat << EOF > ceph-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ceph-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: ceph-rbd
EOF

# Apply PVC
kubectl apply -f ceph-pvc.yaml

# Verify PVC creation
kubectl get pvc ceph-pvc
Step 5: Deploy application using Ceph storage

# Create deployment with Ceph storage
cat << EOF > ceph-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ceph-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ceph-app
  template:
    metadata:
      labels:
        app: ceph-app
    spec:
      containers:
      - name: app
        image: nginx:latest
        volumeMounts:
        - name: ceph-storage
          mountPath: /data
      volumes:
      - name: ceph-storage
        persistentVolumeClaim:
          claimName: ceph-pvc
EOF

# Deploy the application
kubectl apply -f ceph-deployment.yaml

# Verify deployment
kubectl get pods -l app=ceph-app
Troubleshooting Common Issues
NFS Troubleshooting
Issue: NFS mount fails with "access denied"

# Check NFS exports
sudo exportfs -v

# Verify firewall settings
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-service=nfs
sudo firewall-cmd --reload
Issue: Permission denied when writing to NFS share

# Check directory permissions on server
ls -la /nfs/shared

# Adjust ownership if needed
sudo chown nobody:nobody /nfs/shared
sudo chmod 755 /nfs/shared
Ceph Troubleshooting
Issue: Ceph cluster health warnings

# Check cluster status
sudo ceph status
sudo ceph health detail

# Check OSD status
sudo ceph osd status
sudo ceph osd tree
Issue: RBD mapping fails

# Check if RBD kernel module is loaded
lsmod | grep rbd

# Load RBD module if needed
sudo modprobe rbd

# Check RBD images
sudo rbd ls rbd
Kubernetes Storage Troubleshooting
Issue: PVC stuck in Pending state

# Check PVC events
kubectl describe pvc <pvc-name>

# Check storage class
kubectl get storageclass

# Check CSI driver pods
kubectl get pods -n kube-system | grep csi
Verification and Testing
Test NFS Integration
# Create test file in NFS-mounted pod
kubectl exec -it <nfs-pod-name> -- touch /usr/share/nginx/html/nfs-test.txt

# Verify file exists on NFS server
ls -la /nfs/shared/
Test Ceph Integration
# Create test file in Ceph-mounted pod
kubectl exec -it <ceph-pod-name> -- touch /data/ceph-test.txt

# Check RBD usage
sudo rbd du rbd/test-volume
Conclusion
In this lab, you have successfully:

• Configured NFS Server: Set up a Network File System server that provides shared storage accessible by multiple clients simultaneously. This is ideal for scenarios requiring shared access to files across multiple systems.

• Deployed Ceph Distributed Storage: Implemented a robust, distributed block storage solution that provides high availability and scalability. Ceph's distributed nature ensures data redundancy and fault tolerance.

• Integrated Storage with Kubernetes: Connected both NFS and Ceph storage systems with Kubernetes, enabling persistent storage for containerized applications. This integration allows applications to maintain data persistence across pod restarts and migrations.

Key Takeaways:

• NFS is excellent for shared file access scenarios where multiple clients need simultaneous read/write access to the same files • Ceph provides enterprise-grade distributed storage with built-in redundancy and scalability • Kubernetes integration enables cloud-native applications to leverage persistent storage seamlessly • Storage Classes in Kubernetes provide dynamic provisioning capabilities for different storage backends

Real-world Applications: • NFS is commonly used for home directories, shared application data, and content management systems • Ceph is utilized in cloud environments, big data analytics, and high-availability applications • Both technologies are essential components in modern infrastructure and container orchestration platforms

This knowledge prepares you for managing enterprise storage solutions and is valuable for Red Hat certification paths, particularly in system administration and OpenShift container platform management.
