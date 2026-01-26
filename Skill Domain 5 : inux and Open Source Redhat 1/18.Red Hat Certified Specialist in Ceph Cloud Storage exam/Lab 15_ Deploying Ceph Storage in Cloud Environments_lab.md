Lab 15: Deploying Ceph Storage in Cloud Environments
Objectives
By the end of this lab, students will be able to:

Understand the integration between Ceph storage and cloud platforms
Configure Ceph for OpenStack Cinder integration
Set up block storage services for cloud instances
Deploy and manage Ceph RBD (RADOS Block Device) pools
Test storage performance and monitor cloud storage metrics
Troubleshoot common Ceph-OpenStack integration issues
Implement best practices for cloud storage deployment
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with storage concepts (block, object, file storage)
Knowledge of virtualization and cloud computing fundamentals
Understanding of OpenStack architecture and components
Basic networking concepts (VLANs, subnets, routing)
Experience with configuration file editing (YAML, INI formats)
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machines.

Your lab environment includes:

3 Ceph nodes (ceph-node1, ceph-node2, ceph-node3)
1 OpenStack controller node (openstack-controller)
1 OpenStack compute node (openstack-compute)
Pre-installed Ceph Octopus and OpenStack Victoria
Task 1: Configure Ceph for OpenStack Cinder Integration
Subtask 1.1: Verify Ceph Cluster Status
First, let's ensure our Ceph cluster is healthy and ready for integration.

Connect to the Ceph admin node:
ssh ceph-admin@ceph-node1
Check cluster health:
sudo ceph health
sudo ceph status
Verify OSD status:
sudo ceph osd status
sudo ceph osd tree
Expected output should show all OSDs as up and in.

Subtask 1.2: Create Ceph Pools for OpenStack
Create pools for OpenStack services:
# Create pool for Cinder volumes
sudo ceph osd pool create volumes 128 128

# Create pool for Glance images
sudo ceph osd pool create images 64 64

# Create pool for Nova instances (optional)
sudo ceph osd pool create vms 64 64
Enable RBD application on pools:
sudo ceph osd pool application enable volumes rbd
sudo ceph osd pool application enable images rbd
sudo ceph osd pool application enable vms rbd
Verify pool creation:
sudo ceph osd lspools
sudo rados lspools
Subtask 1.3: Create Ceph Authentication Keys
Create client keys for OpenStack services:
# Create key for Cinder
sudo ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images'

# Create key for Glance
sudo ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images'
Export keys to files:
sudo ceph auth get-or-create client.cinder | sudo tee /etc/ceph/ceph.client.cinder.keyring
sudo ceph auth get-or-create client.glance | sudo tee /etc/ceph/ceph.client.glance.keyring
Set proper permissions:
sudo chown ceph:ceph /etc/ceph/ceph.client.*.keyring
sudo chmod 640 /etc/ceph/ceph.client.*.keyring
Subtask 1.4: Configure Ceph Configuration File
Edit the Ceph configuration file:
sudo nano /etc/ceph/ceph.conf
Add the following configuration:
[global]
fsid = your-cluster-fsid
mon_initial_members = ceph-node1, ceph-node2, ceph-node3
mon_host = 192.168.1.10, 192.168.1.11, 192.168.1.12
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx

# RBD default features (compatible with older kernels)
rbd_default_features = 1

[client]
rbd_cache = true
rbd_cache_writethrough_until_flush = true
rbd_concurrent_management_ops = 20
Copy configuration to OpenStack nodes:
sudo scp /etc/ceph/ceph.conf openstack-controller:/etc/ceph/
sudo scp /etc/ceph/ceph.client.*.keyring openstack-controller:/etc/ceph/
Task 2: Set Up Block Storage for Cloud Instances
Subtask 2.1: Install Ceph Client on OpenStack Nodes
Connect to OpenStack controller:
ssh ubuntu@openstack-controller
Install Ceph client packages:
sudo apt update
sudo apt install -y ceph-common python3-rbd python3-rados
Verify Ceph connectivity:
sudo ceph -s --name client.cinder
Subtask 2.2: Configure OpenStack Cinder for Ceph
Edit Cinder configuration:
sudo nano /etc/cinder/cinder.conf
Add Ceph backend configuration:
[DEFAULT]
enabled_backends = ceph
glance_api_version = 2

[ceph]
volume_driver = cinder.volume.drivers.rbd.RBDDriver
volume_backend_name = ceph
rbd_pool = volumes
rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_flatten_volume_from_snapshot = false
rbd_max_clone_depth = 5
rbd_store_chunk_size = 4
rados_connect_timeout = -1
rbd_user = cinder
rbd_secret_uuid = your-secret-uuid
Create secret UUID for libvirt:
uuidgen
Note the generated UUID for later use.

Subtask 2.3: Configure Nova for Ceph Integration
Edit Nova configuration:
sudo nano /etc/nova/nova.conf
Add Ceph configuration for ephemeral storage:
[libvirt]
images_type = rbd
images_rbd_pool = vms
images_rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_user = cinder
rbd_secret_uuid = your-secret-uuid
disk_cachemodes = "network=writeback"
live_migration_flag = "VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST,VIR_MIGRATE_TUNNELLED"
Subtask 2.4: Configure Glance for Ceph
Edit Glance API configuration:
sudo nano /etc/glance/glance-api.conf
Configure RBD store:
[DEFAULT]
show_image_direct_url = True

[glance_store]
stores = rbd
default_store = rbd
rbd_store_pool = images
rbd_store_user = glance
rbd_store_ceph_conf = /etc/ceph/ceph.conf
rbd_store_chunk_size = 8
Subtask 2.5: Create Libvirt Secret
Create secret XML file:
cat > secret.xml <<EOF
<secret ephemeral='no' private='no'>
  <uuid>your-secret-uuid</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>
EOF
Define and set the secret:
sudo virsh secret-define --file secret.xml
sudo virsh secret-set-value --secret your-secret-uuid --base64 $(sudo ceph auth get-key client.cinder)
Subtask 2.6: Restart OpenStack Services
Restart Cinder services:
sudo systemctl restart cinder-api
sudo systemctl restart cinder-scheduler
sudo systemctl restart cinder-volume
Restart Nova services:
sudo systemctl restart nova-api
sudo systemctl restart nova-scheduler
sudo systemctl restart nova-conductor
Restart Glance services:
sudo systemctl restart glance-api
Verify service status:
sudo systemctl status cinder-volume
sudo systemctl status nova-compute
sudo systemctl status glance-api
Task 3: Test and Monitor Cloud Storage Performance
Subtask 3.1: Create and Test Cinder Volumes
Source OpenStack credentials:
source /home/ubuntu/openrc
Create a volume type for Ceph:
openstack volume type create ceph
openstack volume type set ceph --property volume_backend_name=ceph
Create test volumes:
# Create a 10GB volume
openstack volume create --size 10 --type ceph test-volume-1

# Create a 20GB volume
openstack volume create --size 20 --type ceph test-volume-2
Verify volume creation:
openstack volume list
Check volumes in Ceph:
ssh ceph-admin@ceph-node1
sudo rbd ls volumes
sudo rbd info volumes/volume-your-volume-id
Subtask 3.2: Test Volume Operations
Create volume snapshot:
openstack volume snapshot create --volume test-volume-1 test-snapshot-1
Create volume from snapshot:
openstack volume create --snapshot test-snapshot-1 --size 10 test-volume-from-snap
Test volume attachment:
# Launch an instance (assuming you have an image and flavor)
openstack server create --image cirros --flavor m1.small --network private test-instance

# Attach volume to instance
openstack server add volume test-instance test-volume-1
Verify attachment:
openstack server show test-instance
Subtask 3.3: Performance Testing
Create a performance test script:
cat > ceph_perf_test.sh <<'EOF'
#!/bin/bash

echo "=== Ceph Storage Performance Test ==="

# Test sequential write performance
echo "Testing sequential write performance..."
sudo rbd create test-perf --size 1024 --pool volumes
sudo rbd map test-perf --pool volumes
DEVICE=$(sudo rbd showmapped | grep test-perf | awk '{print $5}')

echo "Running dd write test on $DEVICE"
sudo dd if=/dev/zero of=$DEVICE bs=1M count=100 oflag=direct 2>&1 | grep -E "(copied|MB/s)"

# Test sequential read performance
echo "Testing sequential read performance..."
sudo dd if=$DEVICE of=/dev/null bs=1M count=100 iflag=direct 2>&1 | grep -E "(copied|MB/s)"

# Cleanup
sudo rbd unmap $DEVICE
sudo rbd rm test-perf --pool volumes

echo "Performance test completed."
EOF

chmod +x ceph_perf_test.sh
Run performance test:
ssh ceph-admin@ceph-node1
./ceph_perf_test.sh
Subtask 3.4: Monitor Storage Performance
Install monitoring tools:
sudo apt install -y iotop htop
Monitor Ceph cluster performance:
# Real-time cluster status
sudo ceph -w

# OSD performance statistics
sudo ceph osd perf

# Pool statistics
sudo ceph osd pool stats
Create monitoring script:
cat > monitor_ceph.sh <<'EOF'
#!/bin/bash

echo "=== Ceph Cluster Monitoring ==="
echo "Cluster Health:"
sudo ceph health detail

echo -e "\nCluster Usage:"
sudo ceph df

echo -e "\nOSD Status:"
sudo ceph osd stat

echo -e "\nPool Statistics:"
sudo ceph osd pool stats

echo -e "\nTop OSD Performance:"
sudo ceph osd perf | head -10
EOF

chmod +x monitor_ceph.sh
Run monitoring script:
./monitor_ceph.sh
Subtask 3.5: Test Image Storage with Glance
Upload test image to Glance:
# Download a test image
wget http://download.cirros-cloud.net/0.5.2/cirros-0.5.2-x86_64-disk.img

# Upload to Glance
openstack image create --disk-format qcow2 --container-format bare --public --file cirros-0.5.2-x86_64-disk.img cirros-ceph
Verify image in Ceph:
ssh ceph-admin@ceph-node1
sudo rbd ls images
sudo rbd info images/your-image-id
Test image-based instance creation:
openstack server create --image cirros-ceph --flavor m1.small --network private test-ceph-instance
Subtask 3.6: Advanced Monitoring and Alerting
Set up Ceph dashboard (if not already configured):
sudo ceph mgr module enable dashboard
sudo ceph dashboard create-self-signed-cert
sudo ceph dashboard ac-user-create admin password administrator
Access dashboard:
sudo ceph mgr services
Note the dashboard URL and access it via web browser.

Monitor key metrics:
Cluster health status
OSD utilization
Pool usage and performance
Client I/O rates
Network throughput
Troubleshooting Common Issues
Issue 1: Ceph Authentication Errors
Symptoms: Authentication failures when OpenStack tries to access Ceph

Solution:

# Verify keyring permissions
sudo ls -la /etc/ceph/ceph.client.*.keyring

# Test authentication
sudo ceph auth list | grep client.cinder

# Recreate keys if necessary
sudo ceph auth del client.cinder
sudo ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes'
Issue 2: RBD Feature Compatibility
Symptoms: Kernel RBD client cannot map images

Solution:

# Check RBD features
sudo rbd feature disable volumes/volume-id exclusive-lock object-map fast-diff deep-flatten

# Or set default features in ceph.conf
echo "rbd_default_features = 1" | sudo tee -a /etc/ceph/ceph.conf
Issue 3: Performance Issues
Symptoms: Slow I/O performance

Solution:

# Check OSD performance
sudo ceph osd perf

# Verify network connectivity
sudo ceph osd tree

# Check for slow requests
sudo ceph health detail
Validation and Testing
Validation Checklist
Ceph Cluster Health:
sudo ceph health
# Should return: HEALTH_OK
OpenStack Volume Service:
openstack volume service list
# All services should be 'up'
Volume Creation Test:
openstack volume create --size 1 test-validation
openstack volume list | grep test-validation
# Should show 'available' status
Image Storage Test:
openstack image list
# Should show images stored in Ceph
Performance Benchmarks
Expected performance metrics for a healthy Ceph-OpenStack integration:

Volume Creation: < 30 seconds for 10GB volume
Snapshot Creation: < 60 seconds for 10GB volume
Sequential Read: > 100 MB/s per OSD
Sequential Write: > 80 MB/s per OSD
Random IOPS: > 1000 IOPS per OSD
Conclusion
In this comprehensive lab, you have successfully:

Configured Ceph for OpenStack Integration: Set up authentication, created storage pools, and configured client access for seamless integration between Ceph and OpenStack services.

Deployed Block Storage Services: Integrated Ceph RBD with OpenStack Cinder to provide scalable block storage for cloud instances, enabling dynamic volume creation, attachment, and management.

Implemented Performance Monitoring: Established monitoring and testing procedures to ensure optimal storage performance and identify potential bottlenecks in your cloud storage infrastructure.

Why This Matters:

This integration provides enterprise-grade storage capabilities for cloud environments, offering:

Scalability: Easily expand storage capacity by adding more OSDs
High Availability: Data replication ensures no single point of failure
Cost Effectiveness: Open-source solution reduces licensing costs
Performance: Distributed architecture provides excellent I/O performance
Flexibility: Supports multiple storage types (block, object, file)
The skills you've developed in this lab are directly applicable to real-world cloud deployments and are essential for the Red Hat Certified Specialist in Ceph Cloud Storage certification. You now have hands-on experience with one of the most popular software-defined storage solutions used in production cloud environments worldwide.

Next Steps: Consider exploring advanced topics such as Ceph erasure coding, multi-site replication, and integration with container orchestration platforms like Kubernetes for a complete cloud storage expertise.
