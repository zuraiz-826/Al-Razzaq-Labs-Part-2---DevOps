Lab 15: Setting Up Multi-Site Replication in RGW
Objectives
By the end of this lab, students will be able to:

Configure multi-site replication for Ceph's RADOS Gateway (RGW) across multiple regions
Implement data consistency mechanisms between geographically distributed sites
Set up automated failure recovery procedures for cross-site scenarios
Test and validate object replication functionality between regions
Monitor and troubleshoot multi-site replication issues
Understand the architecture and benefits of RGW multi-site deployment
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph storage architecture and components
Familiarity with RADOS Gateway (RGW) concepts and operations
Knowledge of Linux command-line operations and system administration
Understanding of network concepts including DNS, routing, and firewalls
Experience with S3 API operations and object storage concepts
Basic knowledge of JSON configuration files and REST APIs
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines.

Your lab environment includes:

Primary Site (us-east): 3 Ceph nodes with RGW configured
Secondary Site (us-west): 3 Ceph nodes with RGW configured
Client Machine: For testing and validation
All necessary networking and DNS resolution pre-configured
Task 1: Set Up Multi-Site Replication in RGW
Subtask 1.1: Understand Multi-Site Architecture
Multi-site replication in RGW allows you to replicate data across geographically distributed Ceph clusters. This provides:

Disaster Recovery: Protection against site-wide failures
Data Locality: Improved performance for geographically distributed users
High Availability: Continued service during maintenance or outages
The architecture consists of:

Realm: Top-level container for multi-site configuration
Zonegroup: Collection of zones that replicate data
Zone: Individual RGW deployment within a site
Subtask 1.2: Configure the Primary Site (us-east)
First, let's set up the primary site which will be the master for replication.

Connect to the primary site master node:
# SSH to the primary site
ssh ceph-admin@primary-site-node1
Create a new realm for multi-site replication:
# Create the realm
sudo radosgw-admin realm create --rgw-realm=multisite --default

# Verify realm creation
sudo radosgw-admin realm list
Create a master zonegroup:
# Create the master zonegroup
sudo radosgw-admin zonegroup create --rgw-zonegroup=us-zonegroup \
  --rgw-realm=multisite --master --default

# Set the zonegroup endpoints
sudo radosgw-admin zonegroup modify --rgw-zonegroup=us-zonegroup \
  --endpoints=http://primary-site-node1:8080,http://primary-site-node2:8080
Create the primary zone:
# Create the master zone
sudo radosgw-admin zone create --rgw-zonegroup=us-zonegroup \
  --rgw-zone=us-east --master --default \
  --endpoints=http://primary-site-node1:8080,http://primary-site-node2:8080

# Verify zone creation
sudo radosgw-admin zone list
Create system user for inter-site communication:
# Create system user for replication
sudo radosgw-admin user create --uid=replication-user \
  --display-name="Replication User" --system \
  --access-key=REPLICATION_ACCESS_KEY \
  --secret-key=REPLICATION_SECRET_KEY

# Verify user creation
sudo radosgw-admin user info --uid=replication-user
Subtask 1.3: Update RGW Configuration on Primary Site
Update Ceph configuration file:
# Edit the Ceph configuration
sudo nano /etc/ceph/ceph.conf
Add the following configuration:

[client.rgw.primary-site-node1]
rgw_realm = multisite
rgw_zonegroup = us-zonegroup
rgw_zone = us-east
rgw_enable_apis = s3, s3website
rgw_s3_auth_use_keystone = false

[client.rgw.primary-site-node2]
rgw_realm = multisite
rgw_zonegroup = us-zonegroup
rgw_zone = us-east
rgw_enable_apis = s3, s3website
rgw_s3_auth_use_keystone = false
Commit the period configuration:
# Commit the period to make changes active
sudo radosgw-admin period update --commit

# Verify period status
sudo radosgw-admin period get
Restart RGW services:
# Restart RGW on all primary site nodes
sudo systemctl restart ceph-radosgw@rgw.primary-site-node1
sudo systemctl restart ceph-radosgw@rgw.primary-site-node2

# Verify services are running
sudo systemctl status ceph-radosgw@rgw.primary-site-node1
sudo systemctl status ceph-radosgw@rgw.primary-site-node2
Subtask 1.4: Configure the Secondary Site (us-west)
Now let's configure the secondary site to replicate from the primary.

Connect to the secondary site:
# SSH to the secondary site
ssh ceph-admin@secondary-site-node1
Pull the realm configuration from primary site:
# Pull realm configuration
sudo radosgw-admin realm pull --url=http://primary-site-node1:8080 \
  --access-key=REPLICATION_ACCESS_KEY \
  --secret=REPLICATION_SECRET_KEY

# Set the pulled realm as default
sudo radosgw-admin realm default --rgw-realm=multisite
Pull the period configuration:
# Pull the latest period
sudo radosgw-admin period pull --url=http://primary-site-node1:8080 \
  --access-key=REPLICATION_ACCESS_KEY \
  --secret=REPLICATION_SECRET_KEY
Create the secondary zone:
# Create secondary zone
sudo radosgw-admin zone create --rgw-zonegroup=us-zonegroup \
  --rgw-zone=us-west \
  --endpoints=http://secondary-site-node1:8080,http://secondary-site-node2:8080 \
  --access-key=REPLICATION_ACCESS_KEY \
  --secret=REPLICATION_SECRET_KEY

# Set the zone as default
sudo radosgw-admin zone default --rgw-zone=us-west
Update the period with the new zone:
# Update and commit the period
sudo radosgw-admin period update --commit

# Verify the configuration
sudo radosgw-admin zonegroup get --rgw-zonegroup=us-zonegroup
Subtask 1.5: Configure RGW on Secondary Site
Update Ceph configuration:
# Edit the Ceph configuration
sudo nano /etc/ceph/ceph.conf
Add the following configuration:

[client.rgw.secondary-site-node1]
rgw_realm = multisite
rgw_zonegroup = us-zonegroup
rgw_zone = us-west
rgw_enable_apis = s3, s3website
rgw_s3_auth_use_keystone = false

[client.rgw.secondary-site-node2]
rgw_realm = multisite
rgw_zonegroup = us-zonegroup
rgw_zone = us-west
rgw_enable_apis = s3, s3website
rgw_s3_auth_use_keystone = false
Start RGW services on secondary site:
# Start RGW services
sudo systemctl start ceph-radosgw@rgw.secondary-site-node1
sudo systemctl start ceph-radosgw@rgw.secondary-site-node2

# Enable services for automatic startup
sudo systemctl enable ceph-radosgw@rgw.secondary-site-node1
sudo systemctl enable ceph-radosgw@rgw.secondary-site-node2

# Verify services are running
sudo systemctl status ceph-radosgw@rgw.secondary-site-node1
Task 2: Configure Data Consistency and Failure Recovery
Subtask 2.1: Configure Metadata Synchronization
Enable metadata sync on primary site:
# Connect to primary site
ssh ceph-admin@primary-site-node1

# Configure metadata sync
sudo radosgw-admin sync status
Start data sync agents:
# Start metadata sync on secondary site
ssh ceph-admin@secondary-site-node1

# Check sync status
sudo radosgw-admin sync status

# If sync is not running, start it manually
sudo radosgw-admin metadata sync run
Subtask 2.2: Configure Data Sync Policies
Set up sync policies for consistent replication:
# On primary site, configure sync policy
sudo radosgw-admin sync policy get

# Create custom sync policy if needed
cat > sync-policy.json << 'EOF'
{
  "sync_policy_id": "default-policy",
  "groups": [
    {
      "id": "default-group",
      "data_flow": {
        "symmetrical": false
      },
      "pipes": [
        {
          "id": "default-pipe",
          "source": {
            "zones": ["us-east"]
          },
          "dest": {
            "zones": ["us-west"]
          }
        }
      ]
    }
  ]
}
EOF

# Apply the sync policy
sudo radosgw-admin sync policy create --policy-id=default-policy \
  --source-zone=us-east --dest-zone=us-west
Subtask 2.3: Configure Failure Recovery Mechanisms
Set up automated failover scripts:
# Create failover script
cat > /usr/local/bin/rgw-failover.sh << 'EOF'
#!/bin/bash

PRIMARY_ENDPOINT="http://primary-site-node1:8080"
SECONDARY_ENDPOINT="http://secondary-site-node1:8080"

# Function to check RGW health
check_rgw_health() {
    local endpoint=$1
    curl -s --connect-timeout 5 "$endpoint" > /dev/null 2>&1
    return $?
}

# Check primary site health
if ! check_rgw_health "$PRIMARY_ENDPOINT"; then
    echo "Primary site is down, initiating failover..."
    
    # Promote secondary zone to master
    radosgw-admin zone modify --rgw-zone=us-west --master
    radosgw-admin period update --commit
    
    # Restart RGW services
    systemctl restart ceph-radosgw@rgw.secondary-site-node1
    systemctl restart ceph-radosgw@rgw.secondary-site-node2
    
    echo "Failover completed successfully"
else
    echo "Primary site is healthy"
fi
EOF

# Make script executable
sudo chmod +x /usr/local/bin/rgw-failover.sh
Create monitoring and recovery service:
# Create systemd service for monitoring
cat > /etc/systemd/system/rgw-monitor.service << 'EOF'
[Unit]
Description=RGW Multi-Site Monitor
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/rgw-monitor.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# Create monitoring script
cat > /usr/local/bin/rgw-monitor.sh << 'EOF'
#!/bin/bash

while true; do
    /usr/local/bin/rgw-failover.sh
    sleep 60
done
EOF

# Make executable and start service
sudo chmod +x /usr/local/bin/rgw-monitor.sh
sudo systemctl daemon-reload
sudo systemctl enable rgw-monitor.service
sudo systemctl start rgw-monitor.service
Subtask 2.4: Configure Consistency Checks
Set up data consistency verification:
# Create consistency check script
cat > /usr/local/bin/check-consistency.sh << 'EOF'
#!/bin/bash

# Function to compare object counts between sites
compare_object_counts() {
    local bucket=$1
    
    # Get object count from primary site
    primary_count=$(s3cmd ls s3://$bucket --host=primary-site-node1:8080 | wc -l)
    
    # Get object count from secondary site
    secondary_count=$(s3cmd ls s3://$bucket --host=secondary-site-node1:8080 | wc -l)
    
    echo "Bucket: $bucket"
    echo "Primary site objects: $primary_count"
    echo "Secondary site objects: $secondary_count"
    
    if [ "$primary_count" -eq "$secondary_count" ]; then
        echo "✓ Object counts match"
    else
        echo "✗ Object count mismatch detected"
    fi
}

# Check all buckets
for bucket in $(s3cmd ls --host=primary-site-node1:8080 | awk '{print $3}' | sed 's|s3://||'); do
    compare_object_counts "$bucket"
    echo "---"
done
EOF

sudo chmod +x /usr/local/bin/check-consistency.sh
Task 3: Test Object Replication Between Regions
Subtask 3.1: Create Test User and Configure S3 Client
Create a test user on the primary site:
# Connect to primary site
ssh ceph-admin@primary-site-node1

# Create test user
sudo radosgw-admin user create --uid=testuser \
  --display-name="Test User" \
  --email=testuser@example.com \
  --access-key=TESTUSER_ACCESS_KEY \
  --secret-key=TESTUSER_SECRET_KEY

# Verify user creation
sudo radosgw-admin user info --uid=testuser
Configure S3 client on the client machine:
# Connect to client machine
ssh ceph-admin@client-machine

# Install s3cmd if not already installed
sudo yum install -y s3cmd

# Configure s3cmd for primary site
cat > ~/.s3cfg-primary << 'EOF'
[default]
access_key = TESTUSER_ACCESS_KEY
secret_key = TESTUSER_SECRET_KEY
host_base = primary-site-node1:8080
host_bucket = primary-site-node1:8080
use_https = False
signature_v2 = True
EOF

# Configure s3cmd for secondary site
cat > ~/.s3cfg-secondary << 'EOF'
[default]
access_key = TESTUSER_ACCESS_KEY
secret_key = TESTUSER_SECRET_KEY
host_base = secondary-site-node1:8080
host_bucket = secondary-site-node1:8080
use_https = False
signature_v2 = True
EOF
Subtask 3.2: Test Basic Object Replication
Create test bucket and upload objects:
# Create bucket on primary site
s3cmd -c ~/.s3cfg-primary mb s3://test-replication-bucket

# Create test files
echo "This is test file 1" > test-file-1.txt
echo "This is test file 2" > test-file-2.txt
echo "This is test file 3" > test-file-3.txt

# Upload files to primary site
s3cmd -c ~/.s3cfg-primary put test-file-1.txt s3://test-replication-bucket/
s3cmd -c ~/.s3cfg-primary put test-file-2.txt s3://test-replication-bucket/
s3cmd -c ~/.s3cfg-primary put test-file-3.txt s3://test-replication-bucket/

# List objects on primary site
echo "Objects on primary site:"
s3cmd -c ~/.s3cfg-primary ls s3://test-replication-bucket/
Wait for replication and verify on secondary site:
# Wait for replication (typically takes 30-60 seconds)
echo "Waiting for replication to complete..."
sleep 60

# Check if objects replicated to secondary site
echo "Objects on secondary site:"
s3cmd -c ~/.s3cfg-secondary ls s3://test-replication-bucket/

# Download and verify file content from secondary site
s3cmd -c ~/.s3cfg-secondary get s3://test-replication-bucket/test-file-1.txt downloaded-file-1.txt
cat downloaded-file-1.txt
Subtask 3.3: Test Large File Replication
Create and upload large test file:
# Create a large test file (100MB)
dd if=/dev/urandom of=large-test-file.bin bs=1M count=100

# Upload large file to primary site
s3cmd -c ~/.s3cfg-primary put large-test-file.bin s3://test-replication-bucket/

# Monitor replication progress
echo "Monitoring replication progress..."
while true; do
    primary_size=$(s3cmd -c ~/.s3cfg-primary ls s3://test-replication-bucket/large-test-file.bin | awk '{print $3}')
    secondary_size=$(s3cmd -c ~/.s3cfg-secondary ls s3://test-replication-bucket/large-test-file.bin 2>/dev/null | awk '{print $3}')
    
    echo "Primary size: $primary_size, Secondary size: $secondary_size"
    
    if [ "$primary_size" = "$secondary_size" ] && [ -n "$secondary_size" ]; then
        echo "Large file replication completed successfully!"
        break
    fi
    
    sleep 10
done
Subtask 3.4: Test Metadata Replication
Test bucket metadata replication:
# Set bucket policy on primary site
cat > bucket-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::test-replication-bucket/*"
    }
  ]
}
EOF

# Apply bucket policy (using AWS CLI syntax adapted for RGW)
s3cmd -c ~/.s3cfg-primary setpolicy bucket-policy.json s3://test-replication-bucket

# Wait for metadata replication
sleep 30

# Verify policy replicated to secondary site
echo "Checking bucket policy replication..."
s3cmd -c ~/.s3cfg-secondary info s3://test-replication-bucket
Subtask 3.5: Test Replication Monitoring and Troubleshooting
Monitor sync status:
# Check sync status on secondary site
ssh ceph-admin@secondary-site-node1

# Check overall sync status
sudo radosgw-admin sync status

# Check data sync status
sudo radosgw-admin data sync status

# Check metadata sync status
sudo radosgw-admin metadata sync status

# Check for any sync errors
sudo radosgw-admin sync error list
Create replication monitoring script:
# Create comprehensive monitoring script
cat > /usr/local/bin/monitor-replication.sh << 'EOF'
#!/bin/bash

echo "=== RGW Multi-Site Replication Status ==="
echo "Date: $(date)"
echo

# Check sync status
echo "1. Overall Sync Status:"
radosgw-admin sync status
echo

# Check data sync
echo "2. Data Sync Status:"
radosgw-admin data sync status
echo

# Check metadata sync
echo "3. Metadata Sync Status:"
radosgw-admin metadata sync status
echo

# Check for errors
echo "4. Sync Errors:"
error_count=$(radosgw-admin sync error list | wc -l)
if [ $error_count -gt 0 ]; then
    echo "Found $error_count sync errors:"
    radosgw-admin sync error list
else
    echo "No sync errors found"
fi
echo

# Check bucket replication status
echo "5. Bucket Replication Status:"
for bucket in $(radosgw-admin bucket list | jq -r '.[]'); do
    echo "Bucket: $bucket"
    radosgw-admin bucket sync status --bucket=$bucket
    echo "---"
done
EOF

sudo chmod +x /usr/local/bin/monitor-replication.sh

# Run the monitoring script
sudo /usr/local/bin/monitor-replication.sh
Subtask 3.6: Test Failover Scenarios
Simulate primary site failure:
# On primary site, stop RGW services to simulate failure
ssh ceph-admin@primary-site-node1
sudo systemctl stop ceph-radosgw@rgw.primary-site-node1
sudo systemctl stop ceph-radosgw@rgw.primary-site-node2
Test secondary site accessibility:
# From client machine, test access to secondary site
s3cmd -c ~/.s3cfg-secondary ls s3://test-replication-bucket/

# Verify all objects are accessible
s3cmd -c ~/.s3cfg-secondary get s3://test-replication-bucket/test-file-1.txt failover-test.txt
cat failover-test.txt
Restore primary site and test recovery:
# Restart primary site services
ssh ceph-admin@primary-site-node1
sudo systemctl start ceph-radosgw@rgw.primary-site-node1
sudo systemctl start ceph-radosgw@rgw.primary-site-node2

# Wait for services to stabilize
sleep 30

# Check sync status after recovery
sudo radosgw-admin sync status
Troubleshooting Common Issues
Issue 1: Sync Not Starting
Symptoms: Objects uploaded to primary site don't appear on secondary site

Solution:

# Check if sync agents are running
sudo radosgw-admin sync status

# Restart sync if needed
sudo radosgw-admin metadata sync run
sudo radosgw-admin data sync run

# Check for configuration issues
sudo radosgw-admin period get
sudo radosgw-admin zonegroup get
Issue 2: Authentication Errors
Symptoms: "Access Denied" errors during replication

Solution:

# Verify system user exists and has correct permissions
sudo radosgw-admin user info --uid=replication-user

# Recreate system user if needed
sudo radosgw-admin user rm --uid=replication-user
sudo radosgw-admin user create --uid=replication-user \
  --display-name="Replication User" --system \
  --access-key=REPLICATION_ACCESS_KEY \
  --secret-key=REPLICATION_SECRET_KEY
Issue 3: Partial Replication
Symptoms: Some objects replicate but others don't

Solution:

# Check for sync errors
sudo radosgw-admin sync error list

# Retry failed sync operations
sudo radosgw-admin sync error trim --error-id=<error-id>

# Force full sync if needed
sudo radosgw-admin data sync init --source-zone=us-east
Conclusion
In this comprehensive lab, you have successfully:

Configured Multi-Site Replication: Set up a complete multi-site RGW deployment with primary and secondary sites, including realm, zonegroup, and zone configurations.

Implemented Data Consistency: Established automated synchronization mechanisms and consistency checks to ensure data integrity across sites.

Configured Failure Recovery: Created monitoring and failover scripts to handle site failures automatically and maintain service availability.

Tested Replication Functionality: Validated object replication, metadata synchronization, and large file transfers between geographically distributed sites.

Implemented Monitoring: Set up comprehensive monitoring tools to track replication status and identify potential issues.

Why This Matters: Multi-site replication in RGW provides critical capabilities for enterprise storage deployments:

Business Continuity: Ensures data availability even during site-wide outages
Disaster Recovery: Protects against data loss from natural disasters or infrastructure failures
Performance Optimization: Allows users to access data from the nearest geographic location
Compliance: Meets regulatory requirements for data redundancy and geographic distribution
This lab has provided you with practical experience in implementing enterprise-grade storage replication, which is essential for modern cloud infrastructure and data protection strategies. The skills learned here are directly applicable to production environments and are highly valued in the industry for roles involving distributed storage systems and disaster recovery planning.
