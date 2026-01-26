Lab 6: Configuring Ceph Object Storage (RGW)
Objectives
By the end of this lab, students will be able to:

Install and configure the RADOS Gateway (RGW) service for Ceph object storage
Create and manage user authentication for S3 and Swift API access
Perform object storage operations including upload and download using S3 API
Understand the architecture and components of Ceph object storage
Configure bucket policies and access controls
Troubleshoot common RGW configuration issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph storage architecture and components
Familiarity with Linux command line operations
Knowledge of REST APIs and HTTP protocols
Understanding of object storage concepts (buckets, objects, keys)
Completion of previous Ceph cluster setup labs
Basic knowledge of JSON formatting
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph cluster already deployed. Simply click Start Lab to access your environment - no need to build your own VM or install Ceph from scratch.

Your lab environment includes:

3 Ceph monitor nodes (ceph-mon1, ceph-mon2, ceph-mon3)
3 Ceph OSD nodes (ceph-osd1, ceph-osd2, ceph-osd3)
1 Ceph admin node (ceph-admin)
Pre-installed Ceph Quincy release
Network connectivity between all nodes
Task 1: Install and Configure RADOS Gateway (RGW)
Subtask 1.1: Verify Ceph Cluster Status
First, let's ensure our Ceph cluster is healthy and ready for RGW deployment.

Connect to the admin node:
ssh ceph-admin
Check cluster health:
sudo ceph health
sudo ceph status
Expected output should show HEALTH_OK status.

Verify available pools:
sudo ceph osd lspools
Subtask 1.2: Install RGW Package
Install the RGW package on the admin node:
sudo dnf install -y ceph-radosgw
Verify installation:
radosgw --version
Subtask 1.3: Create RGW Pools
RGW requires several pools to store metadata and data. Let's create them with appropriate placement groups.

Create the required pools:
# Create pools for RGW metadata
sudo ceph osd pool create .rgw.root 8 8
sudo ceph osd pool create default.rgw.control 8 8
sudo ceph osd pool create default.rgw.meta 8 8
sudo ceph osd pool create default.rgw.log 8 8

# Create pools for RGW data
sudo ceph osd pool create default.rgw.buckets.index 16 16
sudo ceph osd pool create default.rgw.buckets.data 32 32
sudo ceph osd pool create default.rgw.buckets.non-ec 8 8
Enable RGW application on pools:
sudo ceph osd pool application enable .rgw.root rgw
sudo ceph osd pool application enable default.rgw.control rgw
sudo ceph osd pool application enable default.rgw.meta rgw
sudo ceph osd pool application enable default.rgw.log rgw
sudo ceph osd pool application enable default.rgw.buckets.index rgw
sudo ceph osd pool application enable default.rgw.buckets.data rgw
sudo ceph osd pool application enable default.rgw.buckets.non-ec rgw
Subtask 1.4: Configure RGW Service
Create RGW configuration directory:
sudo mkdir -p /var/lib/ceph/radosgw/ceph-rgw.ceph-admin
Create RGW keyring:
sudo ceph auth get-or-create client.rgw.ceph-admin \
    osd 'allow rwx' \
    mon 'allow rw' \
    -o /var/lib/ceph/radosgw/ceph-rgw.ceph-admin/keyring
Set proper ownership:
sudo chown ceph:ceph /var/lib/ceph/radosgw/ceph-rgw.ceph-admin/keyring
Create RGW configuration file:
sudo tee /etc/ceph/ceph.conf.rgw >> /etc/ceph/ceph.conf << EOF

[client.rgw.ceph-admin]
host = ceph-admin
keyring = /var/lib/ceph/radosgw/ceph-rgw.ceph-admin/keyring
log file = /var/log/ceph/ceph-rgw-ceph-admin.log
rgw frontends = civetweb port=8080
rgw thread pool size = 512
rgw print continue = false
rgw enable usage log = true
EOF
Subtask 1.5: Start RGW Service
Enable and start the RGW service:
sudo systemctl enable ceph-radosgw@rgw.ceph-admin
sudo systemctl start ceph-radosgw@rgw.ceph-admin
Check service status:
sudo systemctl status ceph-radosgw@rgw.ceph-admin
Verify RGW is listening on port 8080:
sudo netstat -tlnp | grep 8080
Test RGW endpoint:
curl http://localhost:8080
You should see an XML response indicating the RGW service is running.

Task 2: Create and Manage User Authentication
Subtask 2.1: Create RGW Admin User
Create an admin user for RGW management:
sudo radosgw-admin user create \
    --uid=admin-user \
    --display-name="Admin User" \
    --email=admin@example.com \
    --caps="users=*;buckets=*;metadata=*;usage=*;zone=*" \
    --access-key=ADMIN123456789 \
    --secret-key=AdminSecretKey123456789
Verify user creation:
sudo radosgw-admin user info --uid=admin-user
Subtask 2.2: Create Regular S3 Users
Create a regular S3 user:
sudo radosgw-admin user create \
    --uid=testuser1 \
    --display-name="Test User 1" \
    --email=testuser1@example.com \
    --access-key=TESTUSER123456789 \
    --secret-key=TestUserSecretKey123
Create another user with auto-generated keys:
sudo radosgw-admin user create \
    --uid=testuser2 \
    --display-name="Test User 2" \
    --email=testuser2@example.com
List all users:
sudo radosgw-admin user list
Subtask 2.3: Manage User Keys and Permissions
View user information:
sudo radosgw-admin user info --uid=testuser2
Create additional access key for a user:
sudo radosgw-admin key create \
    --uid=testuser1 \
    --key-type=s3 \
    --access-key=TESTUSER987654321 \
    --secret-key=AnotherSecretKey456
Remove an access key:
sudo radosgw-admin key rm \
    --uid=testuser1 \
    --key-type=s3 \
    --access-key=TESTUSER987654321
Modify user quota:
sudo radosgw-admin quota set \
    --quota-scope=user \
    --uid=testuser1 \
    --max-objects=1000 \
    --max-size=1G

sudo radosgw-admin quota enable \
    --quota-scope=user \
    --uid=testuser1
Task 3: Perform Object Operations Using S3 API
Subtask 3.1: Install and Configure S3 Client Tools
Install AWS CLI and s3cmd:
sudo dnf install -y python3-pip
pip3 install --user awscli s3cmd
Add pip bin directory to PATH:
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
Configure AWS CLI for our RGW endpoint:
aws configure set aws_access_key_id TESTUSER123456789
aws configure set aws_secret_access_key TestUserSecretKey123
aws configure set default.region us-east-1
aws configure set default.output json
Create AWS CLI config for RGW endpoint:
mkdir -p ~/.aws
cat > ~/.aws/config << EOF
[default]
region = us-east-1
output = json
s3 =
    endpoint_url = http://localhost:8080
    signature_version = s3v4
EOF
Subtask 3.2: Create and Manage S3 Buckets
Create a bucket using AWS CLI:
aws s3 mb s3://test-bucket-1 --endpoint-url http://localhost:8080
List buckets:
aws s3 ls --endpoint-url http://localhost:8080
Create another bucket with different user:
# First, get the keys for testuser2
sudo radosgw-admin user info --uid=testuser2 | grep -E "(access_key|secret_key)"

# Configure for testuser2 (replace with actual keys from above command)
aws configure set aws_access_key_id YOUR_TESTUSER2_ACCESS_KEY
aws configure set aws_secret_access_key YOUR_TESTUSER2_SECRET_KEY

# Create bucket
aws s3 mb s3://test-bucket-2 --endpoint-url http://localhost:8080
Switch back to testuser1:
aws configure set aws_access_key_id TESTUSER123456789
aws configure set aws_secret_access_key TestUserSecretKey123
Subtask 3.3: Upload and Download Objects
Create test files for upload:
echo "This is test file 1" > testfile1.txt
echo "This is test file 2 with more content for testing" > testfile2.txt
dd if=/dev/zero of=largefile.bin bs=1M count=10
Upload files to bucket:
# Upload single file
aws s3 cp testfile1.txt s3://test-bucket-1/ --endpoint-url http://localhost:8080

# Upload with metadata
aws s3 cp testfile2.txt s3://test-bucket-1/ \
    --metadata "author=testuser,purpose=demo" \
    --endpoint-url http://localhost:8080

# Upload large file
aws s3 cp largefile.bin s3://test-bucket-1/ --endpoint-url http://localhost:8080
List objects in bucket:
aws s3 ls s3://test-bucket-1/ --endpoint-url http://localhost:8080
Download objects:
# Create download directory
mkdir downloads

# Download single file
aws s3 cp s3://test-bucket-1/testfile1.txt downloads/ --endpoint-url http://localhost:8080

# Download all files
aws s3 sync s3://test-bucket-1/ downloads/ --endpoint-url http://localhost:8080
Verify downloaded files:
ls -la downloads/
cat downloads/testfile1.txt
Subtask 3.4: Advanced Object Operations
Set object ACL (Access Control List):
aws s3api put-object-acl \
    --bucket test-bucket-1 \
    --key testfile1.txt \
    --acl public-read \
    --endpoint-url http://localhost:8080
Get object metadata:
aws s3api head-object \
    --bucket test-bucket-1 \
    --key testfile2.txt \
    --endpoint-url http://localhost:8080
Copy object within bucket:
aws s3 cp s3://test-bucket-1/testfile1.txt s3://test-bucket-1/testfile1-copy.txt \
    --endpoint-url http://localhost:8080
Delete objects:
# Delete single object
aws s3 rm s3://test-bucket-1/testfile1-copy.txt --endpoint-url http://localhost:8080

# Delete multiple objects
aws s3 rm s3://test-bucket-1/ --recursive --exclude "testfile1.txt" \
    --endpoint-url http://localhost:8080
Subtask 3.5: Bucket Policies and Lifecycle Management
Create a bucket policy:
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::test-bucket-1/*"
        }
    ]
}
EOF
Apply bucket policy:
aws s3api put-bucket-policy \
    --bucket test-bucket-1 \
    --policy file://bucket-policy.json \
    --endpoint-url http://localhost:8080
Get bucket policy:
aws s3api get-bucket-policy \
    --bucket test-bucket-1 \
    --endpoint-url http://localhost:8080
Enable versioning on bucket:
aws s3api put-bucket-versioning \
    --bucket test-bucket-1 \
    --versioning-configuration Status=Enabled \
    --endpoint-url http://localhost:8080
Task 4: Monitor and Troubleshoot RGW
Subtask 4.1: Monitor RGW Performance
Check RGW usage statistics:
sudo radosgw-admin usage show --uid=testuser1
View bucket statistics:
sudo radosgw-admin bucket stats --bucket=test-bucket-1
Monitor RGW logs:
sudo tail -f /var/log/ceph/ceph-rgw-ceph-admin.log
Subtask 4.2: Common Troubleshooting
Check RGW service status:
sudo systemctl status ceph-radosgw@rgw.ceph-admin
Verify RGW pools:
sudo ceph osd pool ls | grep rgw
Test connectivity:
curl -v http://localhost:8080
Check user permissions:
sudo radosgw-admin user info --uid=testuser1
Verification and Testing
Final Verification Steps
Verify all services are running:
sudo systemctl status ceph-radosgw@rgw.ceph-admin
sudo ceph health
Test complete S3 workflow:
# Create test file
echo "Final verification test" > final-test.txt

# Upload
aws s3 cp final-test.txt s3://test-bucket-1/ --endpoint-url http://localhost:8080

# List
aws s3 ls s3://test-bucket-1/ --endpoint-url http://localhost:8080

# Download
aws s3 cp s3://test-bucket-1/final-test.txt final-test-downloaded.txt \
    --endpoint-url http://localhost:8080

# Verify content
cat final-test-downloaded.txt
Clean up test files:
rm -f testfile*.txt largefile.bin final-test*.txt bucket-policy.json
rm -rf downloads/
Troubleshooting Common Issues
Issue 1: RGW Service Won't Start
Symptoms: Service fails to start or immediately stops

Solutions:

# Check logs
sudo journalctl -u ceph-radosgw@rgw.ceph-admin -f

# Verify keyring permissions
sudo ls -la /var/lib/ceph/radosgw/ceph-rgw.ceph-admin/keyring
sudo chown ceph:ceph /var/lib/ceph/radosgw/ceph-rgw.ceph-admin/keyring

# Check port availability
sudo netstat -tlnp | grep 8080
Issue 2: Access Denied Errors
Symptoms: 403 Forbidden or Access Denied responses

Solutions:

# Verify user exists and has correct keys
sudo radosgw-admin user info --uid=testuser1

# Check bucket ownership
sudo radosgw-admin bucket stats --bucket=test-bucket-1

# Verify user capabilities
sudo radosgw-admin caps add --uid=testuser1 --caps="buckets=*"
Issue 3: Connection Timeouts
Symptoms: Slow responses or connection timeouts

Solutions:

# Check cluster health
sudo ceph health detail

# Monitor OSD performance
sudo ceph osd perf

# Adjust RGW thread pool
sudo vim /etc/ceph/ceph.conf
# Add: rgw thread pool size = 1024
sudo systemctl restart ceph-radosgw@rgw.ceph-admin
Conclusion
In this comprehensive lab, you have successfully:

Installed and configured the RADOS Gateway (RGW) service, transforming your Ceph cluster into a fully functional object storage system compatible with Amazon S3 and OpenStack Swift APIs
Created and managed user authentication systems, including admin users with full capabilities and regular users with appropriate permissions and quotas
Performed extensive object operations using the S3 API, including bucket creation, file uploads/downloads, metadata management, and access control policies
Implemented advanced features such as bucket policies, versioning, and lifecycle management
Learned monitoring and troubleshooting techniques to maintain a healthy RGW deployment
Why This Matters: Object storage is a critical component in modern cloud infrastructure, providing scalable, durable, and highly available storage for applications, backups, and data archiving. The skills you've developed in this lab are directly applicable to:

Enterprise Storage Solutions: Managing petabyte-scale object storage for large organizations
Cloud Service Providers: Offering S3-compatible storage services to customers
Application Development: Integrating applications with object storage for media files, backups, and data lakes
DevOps and Automation: Implementing infrastructure-as-code for storage provisioning and management
The RADOS Gateway provides a cost-effective, open-source alternative to proprietary object storage solutions while maintaining full API compatibility with industry standards. Your newly acquired expertise in Ceph RGW configuration and management positions you well for roles in cloud infrastructure, storage engineering, and enterprise IT operations.

Next Steps: Consider exploring advanced RGW features such as multi-site replication, bucket notifications, and integration with external authentication systems like LDAP or Active Directory to further enhance your object storage expertise.
