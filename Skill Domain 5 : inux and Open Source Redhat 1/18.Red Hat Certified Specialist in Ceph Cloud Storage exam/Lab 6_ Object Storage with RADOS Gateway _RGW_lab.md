Lab 6: Object Storage with RADOS Gateway (RGW)
Objectives
By the end of this lab, students will be able to:

Install and configure RADOS Gateway (RGW) for S3-compatible object storage
Create and manage RGW users with appropriate access policies
Perform object storage operations using S3 API commands
Understand the architecture and components of Ceph object storage
Troubleshoot common RGW configuration issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph cluster architecture
Familiarity with Linux command line operations
Knowledge of HTTP/REST API concepts
Understanding of object storage principles
Completed previous Ceph labs or equivalent experience
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph cluster already deployed. Simply click Start Lab to access your environment - no need to build your own VM or install Ceph from scratch.

Your lab environment includes:

3 Ceph nodes (ceph-node1, ceph-node2, ceph-node3)
Pre-configured Ceph cluster with OSDs and monitors
Administrative access to all nodes
Network connectivity between all components
Task 1: Install and Configure RADOS Gateway
Subtask 1.1: Verify Ceph Cluster Status
First, let's ensure our Ceph cluster is healthy and ready for RGW deployment.

Connect to the admin node and verify cluster status:
# Check overall cluster health
sudo ceph status

# Verify all OSDs are up and in
sudo ceph osd status

# Check monitor status
sudo ceph mon status
Verify the cluster has sufficient resources:
# Check available space
sudo ceph df

# List existing pools
sudo ceph osd lspools
Expected output should show a healthy cluster with all components running.

Subtask 1.2: Install RGW Package
Install the RADOS Gateway package on the designated RGW node:
# Update package repository
sudo yum update -y

# Install RGW package (for RHEL/CentOS)
sudo yum install -y ceph-radosgw

# For Ubuntu/Debian systems, use:
# sudo apt-get update
# sudo apt-get install -y radosgw
Verify the installation:
# Check if RGW binary is installed
which radosgw

# Check RGW version
radosgw --version
Subtask 1.3: Create RGW Pools
RGW requires several pools to store metadata and data. Let's create them:

Create the required pools:
# Create pools for RGW metadata and data
sudo ceph osd pool create .rgw.root 32 32
sudo ceph osd pool create default.rgw.control 32 32
sudo ceph osd pool create default.rgw.meta 32 32
sudo ceph osd pool create default.rgw.log 32 32
sudo ceph osd pool create default.rgw.buckets.index 32 32
sudo ceph osd pool create default.rgw.buckets.data 32 32
sudo ceph osd pool create default.rgw.buckets.non-ec 32 32
Enable RGW application on pools:
# Enable rgw application on all RGW pools
sudo ceph osd pool application enable .rgw.root rgw
sudo ceph osd pool application enable default.rgw.control rgw
sudo ceph osd pool application enable default.rgw.meta rgw
sudo ceph osd pool application enable default.rgw.log rgw
sudo ceph osd pool application enable default.rgw.buckets.index rgw
sudo ceph osd pool application enable default.rgw.buckets.data rgw
sudo ceph osd pool application enable default.rgw.buckets.non-ec rgw
Subtask 1.4: Configure RGW Instance
Create RGW configuration directory:
# Create configuration directory
sudo mkdir -p /var/lib/ceph/radosgw/ceph-rgw.$(hostname -s)

# Set proper ownership
sudo chown ceph:ceph /var/lib/ceph/radosgw/ceph-rgw.$(hostname -s)
Create RGW keyring:
# Create keyring for RGW
sudo ceph auth get-or-create client.rgw.$(hostname -s) \
  osd 'allow rwx' \
  mon 'allow rw' \
  -o /var/lib/ceph/radosgw/ceph-rgw.$(hostname -s)/keyring

# Set proper permissions
sudo chown ceph:ceph /var/lib/ceph/radosgw/ceph-rgw.$(hostname -s)/keyring
sudo chmod 600 /var/lib/ceph/radosgw/ceph-rgw.$(hostname -s)/keyring
Configure RGW in ceph.conf:
# Add RGW configuration to ceph.conf
sudo tee -a /etc/ceph/ceph.conf << EOF

[client.rgw.$(hostname -s)]
host = $(hostname -s)
keyring = /var/lib/ceph/radosgw/ceph-rgw.$(hostname -s)/keyring
log file = /var/log/ceph/ceph-rgw-$(hostname -s).log
rgw frontends = civetweb port=8080
rgw thread pool size = 512
rgw print continue = false
rgw enable usage log = true
EOF
Subtask 1.5: Start RGW Service
Start and enable RGW service:
# Start RGW service
sudo systemctl start ceph-radosgw@rgw.$(hostname -s)

# Enable service to start on boot
sudo systemctl enable ceph-radosgw@rgw.$(hostname -s)

# Check service status
sudo systemctl status ceph-radosgw@rgw.$(hostname -s)
Verify RGW is listening:
# Check if RGW is listening on port 8080
sudo netstat -tlnp | grep 8080

# Test basic connectivity
curl http://localhost:8080
You should see an XML response indicating the RGW is running.

Task 2: Set Up User Authentication and Access Policies
Subtask 2.1: Create RGW Admin User
Create an administrative user:
# Create admin user with full permissions
sudo radosgw-admin user create \
  --uid=admin-user \
  --display-name="Admin User" \
  --email=admin@example.com \
  --access-key=ADMIN123456789 \
  --secret-key=AdminSecretKey123456789 \
  --caps="users=*;buckets=*;metadata=*;usage=*;zone=*"
Verify admin user creation:
# List all users
sudo radosgw-admin user list

# Get detailed user information
sudo radosgw-admin user info --uid=admin-user
Subtask 2.2: Create Regular Users
Create a regular user for testing:
# Create regular user
sudo radosgw-admin user create \
  --uid=test-user \
  --display-name="Test User" \
  --email=test@example.com \
  --access-key=TEST123456789 \
  --secret-key=TestSecretKey123456789
Create another user with limited permissions:
# Create limited user
sudo radosgw-admin user create \
  --uid=limited-user \
  --display-name="Limited User" \
  --email=limited@example.com \
  --access-key=LIMITED123456789 \
  --secret-key=LimitedSecretKey123456789 \
  --max-buckets=5
Subtask 2.3: Configure User Quotas
Set bucket quota for test user:
# Enable bucket quota
sudo radosgw-admin quota set --quota-scope=bucket --uid=test-user --max-objects=1000 --max-size=1G

# Enable the quota
sudo radosgw-admin quota enable --quota-scope=bucket --uid=test-user
Set user quota for limited user:
# Set user-level quota
sudo radosgw-admin quota set --quota-scope=user --uid=limited-user --max-objects=500 --max-size=500M

# Enable user quota
sudo radosgw-admin quota enable --quota-scope=user --uid=limited-user
Verify quota settings:
# Check quota for test-user
sudo radosgw-admin user info --uid=test-user | grep -A 10 quota

# Check quota for limited-user
sudo radosgw-admin user info --uid=limited-user | grep -A 10 quota
Subtask 2.4: Create and Manage Subusers
Create a subuser for the test user:
# Create subuser with read-write permissions
sudo radosgw-admin subuser create \
  --uid=test-user \
  --subuser=test-user:subuser1 \
  --access=readwrite \
  --secret-key=SubuserSecret123

# Create subuser with read-only permissions
sudo radosgw-admin subuser create \
  --uid=test-user \
  --subuser=test-user:readonly \
  --access=read \
  --secret-key=ReadOnlySecret123
List subusers:
# View subuser information
sudo radosgw-admin user info --uid=test-user | grep -A 5 subusers
Task 3: Test Object Operations Using S3 API
Subtask 3.1: Install and Configure AWS CLI
Install AWS CLI:
# Install pip if not available
sudo yum install -y python3-pip

# Install AWS CLI
pip3 install --user awscli

# Add to PATH if needed
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
Configure AWS CLI for RGW:
# Configure AWS CLI with test user credentials
aws configure set aws_access_key_id TEST123456789
aws configure set aws_secret_access_key TestSecretKey123456789
aws configure set default.region us-east-1
aws configure set default.output json

# Set custom endpoint for RGW
aws configure set default.s3.endpoint_url http://localhost:8080
aws configure set default.s3.signature_version s3v4
Subtask 3.2: Test Basic Bucket Operations
Create buckets:
# Create a test bucket
aws s3 mb s3://test-bucket --endpoint-url http://localhost:8080

# Create another bucket
aws s3 mb s3://data-bucket --endpoint-url http://localhost:8080

# List all buckets
aws s3 ls --endpoint-url http://localhost:8080
Verify bucket creation in RGW:
# List buckets using radosgw-admin
sudo radosgw-admin bucket list

# Get bucket information
sudo radosgw-admin bucket stats --bucket=test-bucket
Subtask 3.3: Test Object Upload and Download
Create test files:
# Create test files of different sizes
echo "This is a small test file" > small-file.txt
dd if=/dev/zero of=large-file.dat bs=1M count=10
echo '{"name": "test", "type": "json"}' > test.json
Upload objects to bucket:
# Upload small file
aws s3 cp small-file.txt s3://test-bucket/ --endpoint-url http://localhost:8080

# Upload large file
aws s3 cp large-file.dat s3://test-bucket/ --endpoint-url http://localhost:8080

# Upload JSON file with metadata
aws s3 cp test.json s3://test-bucket/ \
  --metadata '{"content-type":"application/json","author":"lab-user"}' \
  --endpoint-url http://localhost:8080
List objects in bucket:
# List all objects
aws s3 ls s3://test-bucket/ --endpoint-url http://localhost:8080

# List with detailed information
aws s3 ls s3://test-bucket/ --recursive --human-readable --summarize --endpoint-url http://localhost:8080
Subtask 3.4: Test Object Metadata and Properties
Get object metadata:
# Get object metadata
aws s3api head-object --bucket test-bucket --key test.json --endpoint-url http://localhost:8080

# Get object with custom metadata
aws s3api get-object-attributes \
  --bucket test-bucket \
  --key test.json \
  --object-attributes ETag,Checksum,ObjectSize,StorageClass \
  --endpoint-url http://localhost:8080
Set object ACL:
# Set object to public-read
aws s3api put-object-acl \
  --bucket test-bucket \
  --key small-file.txt \
  --acl public-read \
  --endpoint-url http://localhost:8080

# Get object ACL
aws s3api get-object-acl \
  --bucket test-bucket \
  --key small-file.txt \
  --endpoint-url http://localhost:8080
Subtask 3.5: Test Multipart Upload
Perform multipart upload for large files:
# Create a larger test file
dd if=/dev/zero of=very-large-file.dat bs=1M count=50

# Upload using multipart (AWS CLI handles this automatically for large files)
aws s3 cp very-large-file.dat s3://test-bucket/ \
  --endpoint-url http://localhost:8080

# Verify upload
aws s3 ls s3://test-bucket/very-large-file.dat --endpoint-url http://localhost:8080
Manual multipart upload example:
# Initiate multipart upload
UPLOAD_ID=$(aws s3api create-multipart-upload \
  --bucket test-bucket \
  --key manual-multipart-file.dat \
  --endpoint-url http://localhost:8080 \
  --query 'UploadId' --output text)

echo "Upload ID: $UPLOAD_ID"

# Split file into parts (example with 5MB parts)
split -b 5M very-large-file.dat part_

# Upload parts
ETAG1=$(aws s3api upload-part \
  --bucket test-bucket \
  --key manual-multipart-file.dat \
  --part-number 1 \
  --upload-id $UPLOAD_ID \
  --body part_aa \
  --endpoint-url http://localhost:8080 \
  --query 'ETag' --output text)

# Complete multipart upload
aws s3api complete-multipart-upload \
  --bucket test-bucket \
  --key manual-multipart-file.dat \
  --upload-id $UPLOAD_ID \
  --multipart-upload "Parts=[{ETag=$ETAG1,PartNumber=1}]" \
  --endpoint-url http://localhost:8080
Subtask 3.6: Test Object Versioning
Enable versioning on bucket:
# Enable versioning
aws s3api put-bucket-versioning \
  --bucket test-bucket \
  --versioning-configuration Status=Enabled \
  --endpoint-url http://localhost:8080

# Check versioning status
aws s3api get-bucket-versioning \
  --bucket test-bucket \
  --endpoint-url http://localhost:8080
Upload multiple versions of the same object:
# Create different versions of the same file
echo "Version 1 content" > version-test.txt
aws s3 cp version-test.txt s3://test-bucket/ --endpoint-url http://localhost:8080

echo "Version 2 content" > version-test.txt
aws s3 cp version-test.txt s3://test-bucket/ --endpoint-url http://localhost:8080

echo "Version 3 content" > version-test.txt
aws s3 cp version-test.txt s3://test-bucket/ --endpoint-url http://localhost:8080

# List object versions
aws s3api list-object-versions \
  --bucket test-bucket \
  --prefix version-test.txt \
  --endpoint-url http://localhost:8080
Subtask 3.7: Test with Different User Credentials
Configure AWS CLI for limited user:
# Create new profile for limited user
aws configure set aws_access_key_id LIMITED123456789 --profile limited
aws configure set aws_secret_access_key LimitedSecretKey123456789 --profile limited
aws configure set default.region us-east-1 --profile limited
aws configure set default.s3.endpoint_url http://localhost:8080 --profile limited
Test operations with limited user:
# Try to create bucket with limited user
aws s3 mb s3://limited-bucket --endpoint-url http://localhost:8080 --profile limited

# Upload file with limited user
echo "Limited user file" > limited-file.txt
aws s3 cp limited-file.txt s3://limited-bucket/ --endpoint-url http://localhost:8080 --profile limited

# Check quota usage
sudo radosgw-admin user stats --uid=limited-user
Troubleshooting Common Issues
Issue 1: RGW Service Won't Start
Symptoms: Service fails to start or immediately stops

Solutions:

# Check service logs
sudo journalctl -u ceph-radosgw@rgw.$(hostname -s) -f

# Verify keyring permissions
sudo ls -la /var/lib/ceph/radosgw/ceph-rgw.$(hostname -s)/keyring

# Check port availability
sudo netstat -tlnp | grep 8080

# Verify Ceph cluster connectivity
sudo ceph status
Issue 2: Authentication Failures
Symptoms: Access denied errors when using S3 API

Solutions:

# Verify user exists
sudo radosgw-admin user info --uid=test-user

# Check access keys
sudo radosgw-admin user info --uid=test-user | grep access_key

# Verify RGW logs
sudo tail -f /var/log/ceph/ceph-rgw-$(hostname -s).log
Issue 3: Slow Performance
Symptoms: Slow upload/download speeds

Solutions:

# Check OSD performance
sudo ceph osd perf

# Monitor cluster performance
sudo ceph -w

# Adjust RGW thread pool size in ceph.conf
# rgw thread pool size = 1024
Verification and Testing
Comprehensive Test Script
Create a comprehensive test script to verify all functionality:

#!/bin/bash
# RGW Functionality Test Script

echo "=== RGW Comprehensive Test ==="

# Test 1: Service Status
echo "1. Checking RGW service status..."
systemctl is-active ceph-radosgw@rgw.$(hostname -s)

# Test 2: Basic connectivity
echo "2. Testing basic connectivity..."
curl -s http://localhost:8080 > /dev/null && echo "RGW responding" || echo "RGW not responding"

# Test 3: Bucket operations
echo "3. Testing bucket operations..."
aws s3 mb s3://test-verification --endpoint-url http://localhost:8080
aws s3 ls --endpoint-url http://localhost:8080 | grep test-verification

# Test 4: Object operations
echo "4. Testing object operations..."
echo "Test content" > test-verify.txt
aws s3 cp test-verify.txt s3://test-verification/ --endpoint-url http://localhost:8080
aws s3 ls s3://test-verification/ --endpoint-url http://localhost:8080

# Test 5: Download verification
echo "5. Testing download..."
aws s3 cp s3://test-verification/test-verify.txt downloaded-file.txt --endpoint-url http://localhost:8080
diff test-verify.txt downloaded-file.txt && echo "Download verified" || echo "Download failed"

# Test 6: User quota check
echo "6. Checking user quotas..."
sudo radosgw-admin user stats --uid=test-user

# Cleanup
aws s3 rm s3://test-verification/test-verify.txt --endpoint-url http://localhost:8080
aws s3 rb s3://test-verification --endpoint-url http://localhost:8080
rm -f test-verify.txt downloaded-file.txt

echo "=== Test Complete ==="
Run the test script:

chmod +x rgw-test.sh
./rgw-test.sh
Performance Monitoring
Monitor RGW Performance
Check RGW statistics:
# Get RGW performance stats
sudo ceph daemon /var/run/ceph/ceph-client.rgw.$(hostname -s).asok perf dump

# Monitor RGW operations
sudo ceph daemon /var/run/ceph/ceph-client.rgw.$(hostname -s).asok perf schema
Monitor bucket and user statistics:
# Get bucket statistics
sudo radosgw-admin bucket stats --bucket=test-bucket

# Get user statistics
sudo radosgw-admin user stats --uid=test-user

# Get usage statistics
sudo radosgw-admin usage show --uid=test-user
Conclusion
In this comprehensive lab, you have successfully:

Installed and configured RADOS Gateway (RGW) - You set up a complete S3-compatible object storage service on top of your Ceph cluster, including all necessary pools and configuration files.

Implemented user authentication and access policies - You created multiple types of users (admin, regular, and limited), configured quotas, and set up subusers with different permission levels.

Performed extensive S3 API testing - You used AWS CLI to test all major object storage operations including bucket management, object upload/download, metadata handling, versioning, and multipart uploads.

Why This Matters:

Enterprise Storage Solutions: RGW provides enterprise-grade object storage that's compatible with Amazon S3, making it easy to migrate applications or provide cloud storage services.

Cost-Effective Alternative: Organizations can build their own object storage infrastructure instead of relying solely on public cloud providers, reducing costs for large-scale storage needs.

Scalability and Reliability: Built on Ceph's distributed architecture, RGW can scale to petabytes of data while maintaining high availability and data durability.

API Compatibility: S3 API compatibility means existing applications and tools can work with RGW without modification, reducing migration complexity.

Certification Preparation: This hands-on experience directly prepares you for the Red Hat Certified Specialist in Ceph Cloud Storage exam, demonstrating practical skills in deploying and managing enterprise storage solutions.

The skills you've developed in this lab are directly applicable to real-world scenarios where organizations need scalable, reliable object storage solutions. You now understand how to deploy, configure, and manage a production-ready object storage service that can handle everything from simple file storage to complex multi-tenant cloud storage platforms.
