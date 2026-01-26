Lab 14: Implementing Cloud Integration with Ceph
Objectives
By the end of this lab, students will be able to:

Integrate Ceph storage cluster with OpenStack Cinder for block storage services
Configure Ceph RadosGW for object storage in cloud environments
Test and validate cloud storage functionality with real-world scenarios
Understand the architecture and benefits of Ceph in cloud infrastructure
Troubleshoot common integration issues between Ceph and cloud platforms
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with storage concepts (block, object, and file storage)
Knowledge of virtualization and cloud computing fundamentals
Understanding of OpenStack architecture and components
Previous experience with Ceph storage cluster basics
Network configuration knowledge (IP addressing, routing)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or install software from scratch.

Your lab environment includes:

3 Ceph cluster nodes (ceph-node1, ceph-node2, ceph-node3)
1 OpenStack controller node (openstack-controller)
1 OpenStack compute node (openstack-compute)
Pre-installed Ceph Octopus and OpenStack Victoria
Network connectivity between all nodes
Task 1: Integrate Ceph with OpenStack Cinder for Block Storage
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

Subtask 1.2: Create Ceph Pool for OpenStack Volumes
Create a dedicated pool for OpenStack volumes:
sudo ceph osd pool create volumes 128 128
sudo ceph osd pool create images 128 128
sudo ceph osd pool create backups 128 128
sudo ceph osd pool create vms 128 128
Enable RBD application on pools:
sudo ceph osd pool application enable volumes rbd
sudo ceph osd pool application enable images rbd
sudo ceph osd pool application enable backups rbd
sudo ceph osd pool application enable vms rbd
Verify pool creation:
sudo ceph osd lspools
Subtask 1.3: Create Ceph User for OpenStack
Create a dedicated user for OpenStack Cinder:
sudo ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd pool=images'
Create user for OpenStack Glance (image service):
sudo ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images'
Create user for Nova (compute service):
sudo ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups'
Export authentication keys:
sudo ceph auth get-or-create client.cinder | sudo tee /etc/ceph/ceph.client.cinder.keyring
sudo ceph auth get-or-create client.glance | sudo tee /etc/ceph/ceph.client.glance.keyring
sudo ceph auth get-or-create client.cinder-backup | sudo tee /etc/ceph/ceph.client.cinder-backup.keyring
Subtask 1.4: Configure OpenStack Cinder
Connect to OpenStack controller node:
ssh openstack@openstack-controller
Copy Ceph configuration files:
sudo scp ceph-admin@ceph-node1:/etc/ceph/ceph.conf /etc/ceph/
sudo scp ceph-admin@ceph-node1:/etc/ceph/ceph.client.cinder.keyring /etc/ceph/
sudo scp ceph-admin@ceph-node1:/etc/ceph/ceph.client.glance.keyring /etc/ceph/
sudo scp ceph-admin@ceph-node1:/etc/ceph/ceph.client.cinder-backup.keyring /etc/ceph/
Set proper permissions:
sudo chown cinder:cinder /etc/ceph/ceph.client.cinder.keyring
sudo chown glance:glance /etc/ceph/ceph.client.glance.keyring
sudo chown cinder:cinder /etc/ceph/ceph.client.cinder-backup.keyring
Configure Cinder for Ceph backend:
sudo nano /etc/cinder/cinder.conf
Add the following configuration:

[DEFAULT]
enabled_backends = ceph

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
rbd_secret_uuid = 457eb676-33da-42ec-9a8c-9293d545c337
Subtask 1.5: Configure Libvirt Secret for Nova
Connect to compute node:
ssh openstack@openstack-compute
Create libvirt secret XML file:
cat > secret.xml <<EOF
<secret ephemeral='no' private='no'>
  <uuid>457eb676-33da-42ec-9a8c-9293d545c337</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>
EOF
Define and set the secret:
sudo virsh secret-define --file secret.xml
sudo virsh secret-set-value --secret 457eb676-33da-42ec-9a8c-9293d545c337 --base64 $(sudo ceph auth get-key client.cinder)
Subtask 1.6: Restart OpenStack Services
On controller node, restart Cinder services:
sudo systemctl restart openstack-cinder-api
sudo systemctl restart openstack-cinder-scheduler
sudo systemctl restart openstack-cinder-volume
sudo systemctl restart openstack-cinder-backup
Verify service status:
sudo systemctl status openstack-cinder-volume
openstack volume service list
Task 2: Configure Cloud-Based Storage with Ceph for Object Storage
Subtask 2.1: Install and Configure Ceph RadosGW
Connect to Ceph node designated for RadosGW:
ssh ceph-admin@ceph-node2
Install RadosGW package:
sudo yum install -y ceph-radosgw
Create RadosGW instance:
sudo mkdir -p /var/lib/ceph/radosgw/ceph-rgw.ceph-node2
Create RadosGW keyring:
sudo ceph auth get-or-create client.rgw.ceph-node2 osd 'allow rwx' mon 'allow rwx' -o /var/lib/ceph/radosgw/ceph-rgw.ceph-node2/keyring
Set proper ownership:
sudo chown -R ceph:ceph /var/lib/ceph/radosgw/
Subtask 2.2: Configure RadosGW Service
Create RadosGW configuration:
sudo nano /etc/ceph/ceph.conf
Add the following section:

[client.rgw.ceph-node2]
host = ceph-node2
keyring = /var/lib/ceph/radosgw/ceph-rgw.ceph-node2/keyring
log file = /var/log/ceph/ceph-rgw-ceph-node2.log
rgw frontends = civetweb port=7480
rgw thread pool size = 512
rgw print continue = false
rgw enable usage log = true
Start and enable RadosGW service:
sudo systemctl start ceph-radosgw@rgw.ceph-node2
sudo systemctl enable ceph-radosgw@rgw.ceph-node2
Verify RadosGW is running:
sudo systemctl status ceph-radosgw@rgw.ceph-node2
curl http://ceph-node2:7480
Subtask 2.3: Create S3 User and Access Keys
Create S3 user:
sudo radosgw-admin user create --uid=testuser --display-name="Test User" --email=test@example.com
Create access keys:
sudo radosgw-admin key create --uid=testuser --key-type=s3 --gen-access-key --gen-secret
List user information:
sudo radosgw-admin user info --uid=testuser
Note down the access_key and secret_key for testing.

Subtask 2.4: Configure Swift API Support
Create Swift subuser:
sudo radosgw-admin subuser create --uid=testuser --subuser=testuser:swift --access=full
Create Swift secret key:
sudo radosgw-admin key create --subuser=testuser:swift --key-type=swift --gen-secret
Verify Swift configuration:
sudo radosgw-admin subuser list --uid=testuser
Task 3: Test Cloud Storage Functionality
Subtask 3.1: Test Cinder Block Storage Integration
Connect to OpenStack controller:
ssh openstack@openstack-controller
Source OpenStack credentials:
source /root/keystonerc_admin
Create a volume type for Ceph:
openstack volume type create ceph-volumes
openstack volume type set --property volume_backend_name=ceph ceph-volumes
Create test volume:
openstack volume create --size 10 --type ceph-volumes test-volume
Verify volume creation:
openstack volume list
openstack volume show test-volume
Check volume in Ceph:
ssh ceph-admin@ceph-node1 "sudo rbd ls volumes"
ssh ceph-admin@ceph-node1 "sudo rbd info volumes/volume-$(openstack volume show test-volume -f value -c id)"
Subtask 3.2: Test Volume Attachment to Instance
Create test instance:
openstack server create --flavor m1.small --image cirros --network private test-instance
Wait for instance to be active:
openstack server list
Attach volume to instance:
openstack server add volume test-instance test-volume
Verify attachment:
openstack server show test-instance
openstack volume show test-volume
Subtask 3.3: Test Object Storage with S3 API
Install S3 client tools:
sudo yum install -y python3-pip
pip3 install --user boto3 awscli
Configure AWS CLI:
aws configure set aws_access_key_id YOUR_ACCESS_KEY
aws configure set aws_secret_access_key YOUR_SECRET_KEY
aws configure set default.region us-east-1
Test S3 operations:
# Create bucket
aws --endpoint-url http://ceph-node2:7480 s3 mb s3://test-bucket

# List buckets
aws --endpoint-url http://ceph-node2:7480 s3 ls

# Upload file
echo "Hello Ceph Object Storage" > test-file.txt
aws --endpoint-url http://ceph-node2:7480 s3 cp test-file.txt s3://test-bucket/

# List objects
aws --endpoint-url http://ceph-node2:7480 s3 ls s3://test-bucket/

# Download file
aws --endpoint-url http://ceph-node2:7480 s3 cp s3://test-bucket/test-file.txt downloaded-file.txt
cat downloaded-file.txt
Subtask 3.4: Test Swift API Functionality
Install Swift client:
pip3 install --user python-swiftclient
Test Swift operations:
# Set environment variables
export ST_AUTH=http://ceph-node2:7480/auth/1.0
export ST_USER=testuser:swift
export ST_KEY=YOUR_SWIFT_SECRET_KEY

# Create container
swift post test-container

# List containers
swift list

# Upload object
swift upload test-container test-file.txt

# List objects
swift list test-container

# Download object
swift download test-container test-file.txt -o swift-downloaded.txt
cat swift-downloaded.txt
Subtask 3.5: Performance and Monitoring Tests
Monitor Ceph cluster during operations:
ssh ceph-admin@ceph-node1 "sudo ceph -w"
Check I/O statistics:
ssh ceph-admin@ceph-node1 "sudo ceph osd perf"
Test volume snapshot functionality:
openstack volume snapshot create --volume test-volume test-snapshot
openstack volume snapshot list
Create volume from snapshot:
openstack volume create --snapshot test-snapshot --size 10 volume-from-snapshot
openstack volume list
Troubleshooting Common Issues
Issue 1: Cinder Volume Creation Fails
Symptoms: Volume stuck in "creating" state

Solution:

# Check Cinder logs
sudo tail -f /var/log/cinder/volume.log

# Verify Ceph connectivity
sudo ceph auth get client.cinder
sudo rbd ls volumes
Issue 2: RadosGW Not Accessible
Symptoms: Connection refused on port 7480

Solution:

# Check service status
sudo systemctl status ceph-radosgw@rgw.ceph-node2

# Check firewall
sudo firewall-cmd --list-ports
sudo firewall-cmd --add-port=7480/tcp --permanent
sudo firewall-cmd --reload
Issue 3: Authentication Errors
Symptoms: Permission denied errors

Solution:

# Verify user permissions
sudo ceph auth get client.cinder
sudo ceph auth caps client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes'
Conclusion
In this comprehensive lab, you have successfully:

Integrated Ceph with OpenStack Cinder to provide scalable block storage for cloud instances
Configured Ceph RadosGW to offer S3 and Swift-compatible object storage services
Tested cloud storage functionality through practical scenarios including volume creation, attachment, and object storage operations
Implemented enterprise-grade storage solutions that can scale to petabytes of data
This integration demonstrates how Ceph serves as a unified storage backend for modern cloud infrastructures, providing:

Cost-effective storage compared to proprietary solutions
High availability through data replication and fault tolerance
Scalability to meet growing storage demands
Multi-protocol support (block, object, and file storage)
OpenStack compatibility for seamless cloud integration
The skills learned in this lab are directly applicable to real-world cloud deployments and are essential for managing enterprise storage infrastructure. You now have hands-on experience with one of the most popular open-source storage solutions used in production environments worldwide.

Next Steps: Consider exploring advanced Ceph features such as erasure coding, cache tiering, and multi-site replication to further enhance your cloud storage expertise.
