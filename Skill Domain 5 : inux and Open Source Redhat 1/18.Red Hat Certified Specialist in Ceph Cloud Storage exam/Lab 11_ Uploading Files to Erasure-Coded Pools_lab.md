Lab 11: Uploading Files to Erasure-Coded Pools
Objectives
By the end of this lab, you will be able to:

Upload and manage files in an erasure-coded pool using Ceph's object storage interface
Verify data integrity and access patterns in erasure-coded storage
Use Ceph monitoring tools to observe data distribution across OSDs
Understand the performance characteristics of erasure-coded pools
Troubleshoot common issues with erasure-coded storage operations
Prerequisites
Before starting this lab, you should have:

Basic understanding of Ceph storage architecture
Familiarity with Linux command-line operations
Knowledge of object storage concepts
Completion of previous Ceph labs (particularly erasure coding setup)
Understanding of RADOS Gateway (RGW) basics
Required Knowledge Areas
Ceph cluster administration
Object storage principles
Erasure coding fundamentals
Linux file system operations
Network storage concepts
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph already installed and configured. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Environment Details
Operating System: CentOS 8 / Rocky Linux 8
Ceph Version: Pacific (16.x) or later
Pre-configured Components:
Ceph cluster with multiple OSDs
Erasure-coded pool already created
RADOS Gateway configured
Monitoring tools installed
Task 1: Upload Files to the Erasure-Coded Pool
Subtask 1.1: Verify Erasure-Coded Pool Status
First, let's confirm our erasure-coded pool is ready for use.

Check cluster status:
sudo ceph -s
List available pools:
sudo ceph osd lspools
Verify erasure-coded pool details:
sudo ceph osd pool ls detail | grep -A 5 -B 5 erasure
Check the erasure code profile:
sudo ceph osd erasure-code-profile ls
sudo ceph osd erasure-code-profile get default
Subtask 1.2: Prepare Test Files
Create various types of files to test different upload scenarios.

Create a directory for test files:
mkdir -p ~/ceph-upload-test
cd ~/ceph-upload-test
Generate test files of different sizes:
# Small text file
echo "This is a small test file for erasure coding" > small-file.txt

# Medium binary file (1MB)
dd if=/dev/urandom of=medium-file.bin bs=1M count=1

# Large file (10MB)
dd if=/dev/urandom of=large-file.bin bs=1M count=10

# Create a structured data file
cat > structured-data.json << EOF
{
  "test_data": {
    "timestamp": "$(date -Iseconds)",
    "file_type": "json",
    "purpose": "erasure coding test",
    "data": [
      {"id": 1, "value": "sample_data_1"},
      {"id": 2, "value": "sample_data_2"},
      {"id": 3, "value": "sample_data_3"}
    ]
  }
}
EOF
Verify created files:
ls -lh ~/ceph-upload-test/
Subtask 1.3: Upload Files Using RADOS Commands
Upload files directly to the erasure-coded pool using RADOS.

Set the erasure-coded pool name (replace 'ec-pool' with your actual pool name):
EC_POOL_NAME="ec-pool"
Upload files to the erasure-coded pool:
# Upload small file
sudo rados -p $EC_POOL_NAME put small-test small-file.txt

# Upload medium file
sudo rados -p $EC_POOL_NAME put medium-test medium-file.bin

# Upload large file
sudo rados -p $EC_POOL_NAME put large-test large-file.bin

# Upload structured data
sudo rados -p $EC_POOL_NAME put json-test structured-data.json
Verify uploads completed successfully:
sudo rados -p $EC_POOL_NAME ls
Check object details:
sudo rados -p $EC_POOL_NAME stat small-test
sudo rados -p $EC_POOL_NAME stat large-test
Subtask 1.4: Upload Files Using RGW (S3 Interface)
Configure and use the RADOS Gateway for S3-compatible uploads.

Create RGW user for testing:
sudo radosgw-admin user create --uid=testuser --display-name="Test User" --email=test@example.com
Create access keys:
sudo radosgw-admin key create --uid=testuser --key-type=s3 --gen-access-key --gen-secret
Get user information (note the access_key and secret_key):
sudo radosgw-admin user info --uid=testuser
Install S3 client tools:
sudo yum install -y python3-pip
pip3 install --user boto3 awscli
Configure AWS CLI:
aws configure set aws_access_key_id YOUR_ACCESS_KEY
aws configure set aws_secret_access_key YOUR_SECRET_KEY
aws configure set default.region us-east-1
aws configure set default.output json
Create S3 bucket:
aws --endpoint-url http://localhost:8080 s3 mb s3://erasure-test-bucket
Upload files via S3 interface:
# Upload files to S3 bucket
aws --endpoint-url http://localhost:8080 s3 cp small-file.txt s3://erasure-test-bucket/
aws --endpoint-url http://localhost:8080 s3 cp medium-file.bin s3://erasure-test-bucket/
aws --endpoint-url http://localhost:8080 s3 cp large-file.bin s3://erasure-test-bucket/
aws --endpoint-url http://localhost:8080 s3 cp structured-data.json s3://erasure-test-bucket/
List uploaded objects:
aws --endpoint-url http://localhost:8080 s3 ls s3://erasure-test-bucket/
Task 2: Verify Data Integrity and Access
Subtask 2.1: Test Data Retrieval
Verify that uploaded files can be retrieved correctly.

Create directory for downloaded files:
mkdir -p ~/ceph-download-test
cd ~/ceph-download-test
Download files using RADOS:
# Download from erasure-coded pool
sudo rados -p $EC_POOL_NAME get small-test downloaded-small.txt
sudo rados -p $EC_POOL_NAME get medium-test downloaded-medium.bin
sudo rados -p $EC_POOL_NAME get large-test downloaded-large.bin
sudo rados -p $EC_POOL_NAME get json-test downloaded-json.json
Download files using S3 interface:
aws --endpoint-url http://localhost:8080 s3 cp s3://erasure-test-bucket/small-file.txt s3-small-file.txt
aws --endpoint-url http://localhost:8080 s3 cp s3://erasure-test-bucket/large-file.bin s3-large-file.bin
Verify file integrity using checksums:
# Compare original and downloaded files
cd ~/ceph-upload-test
md5sum small-file.txt medium-file.bin large-file.bin structured-data.json > ~/original-checksums.txt

cd ~/ceph-download-test
md5sum downloaded-small.txt downloaded-medium.bin downloaded-large.bin downloaded-json.json > ~/downloaded-checksums.txt
md5sum s3-small-file.txt s3-large-file.bin > ~/s3-checksums.txt

# Compare checksums
echo "=== Original Files ==="
cat ~/original-checksums.txt
echo "=== Downloaded via RADOS ==="
cat ~/downloaded-checksums.txt
echo "=== Downloaded via S3 ==="
cat ~/s3-checksums.txt
Subtask 2.2: Test Partial Object Access
Test reading specific byte ranges from objects.

Read specific byte ranges:
# Read first 100 bytes of large file
sudo rados -p $EC_POOL_NAME get large-test - --offset=0 --length=100 | hexdump -C

# Read middle section
sudo rados -p $EC_POOL_NAME get large-test - --offset=5000000 --length=1000 | hexdump -C
Test concurrent access:
# Create script for concurrent reads
cat > concurrent_read_test.sh << 'EOF'
#!/bin/bash
POOL_NAME=$1
OBJECT_NAME=$2

for i in {1..5}; do
    (
        echo "Reader $i starting..."
        sudo rados -p $POOL_NAME get $OBJECT_NAME /tmp/concurrent_read_$i.tmp
        echo "Reader $i completed"
    ) &
done

wait
echo "All concurrent reads completed"
ls -la /tmp/concurrent_read_*.tmp
EOF

chmod +x concurrent_read_test.sh
./concurrent_read_test.sh $EC_POOL_NAME large-test
Subtask 2.3: Performance Testing
Measure upload and download performance.

Create performance test script:
cat > performance_test.sh << 'EOF'
#!/bin/bash

POOL_NAME=$1
TEST_FILE_SIZE=${2:-50}  # Size in MB

echo "Creating test file of ${TEST_FILE_SIZE}MB..."
dd if=/dev/urandom of=perf_test_file.bin bs=1M count=$TEST_FILE_SIZE 2>/dev/null

echo "Testing upload performance..."
time sudo rados -p $POOL_NAME put perf-test perf_test_file.bin

echo "Testing download performance..."
time sudo rados -p $POOL_NAME get perf-test downloaded_perf_test.bin

echo "Verifying integrity..."
if cmp -s perf_test_file.bin downloaded_perf_test.bin; then
    echo "✓ Files match - integrity verified"
else
    echo "✗ Files don't match - integrity check failed"
fi

# Cleanup
rm -f perf_test_file.bin downloaded_perf_test.bin
sudo rados -p $POOL_NAME rm perf-test
EOF

chmod +x performance_test.sh
./performance_test.sh $EC_POOL_NAME 10
Task 3: Use Ceph Tools to Monitor Data Distribution
Subtask 3.1: Monitor Object Placement
Examine how objects are distributed across OSDs in the erasure-coded pool.

Check object mapping:
# Show where objects are stored
sudo ceph osd map $EC_POOL_NAME small-test
sudo ceph osd map $EC_POOL_NAME large-test
Get detailed placement information:
# Show object location details
sudo rados -p $EC_POOL_NAME ls -l
Examine PG (Placement Group) distribution:
# Show PG statistics for erasure-coded pool
sudo ceph pg ls-by-pool $EC_POOL_NAME
Check OSD usage:
sudo ceph osd df
sudo ceph osd utilization
Subtask 3.2: Monitor Erasure Coding Operations
Track the erasure coding process and chunk distribution.

Enable detailed logging (temporarily):
sudo ceph tell osd.* config set debug_osd 10
sudo ceph tell osd.* config set debug_filestore 5
Upload a file while monitoring:
# Create a test file
dd if=/dev/urandom of=monitor-test.bin bs=1M count=5

# Upload while monitoring in another terminal
sudo rados -p $EC_POOL_NAME put monitor-test monitor-test.bin
Check erasure code chunk distribution:
# Get object information
sudo rados -p $EC_POOL_NAME stat monitor-test

# Check which OSDs store the chunks
sudo ceph osd map $EC_POOL_NAME monitor-test
Reset logging levels:
sudo ceph tell osd.* config set debug_osd 1
sudo ceph tell osd.* config set debug_filestore 1
Subtask 3.3: Use Ceph Dashboard for Monitoring
Access and use the Ceph Dashboard for visual monitoring.

Enable Ceph Dashboard (if not already enabled):
sudo ceph mgr module enable dashboard
sudo ceph dashboard create-self-signed-cert
Create dashboard admin user:
sudo ceph dashboard ac-user-create admin password administrator
Get dashboard URL:
sudo ceph mgr services
Monitor through dashboard:
Access the dashboard URL in a web browser
Navigate to Pools section
Select your erasure-coded pool
Observe object distribution and performance metrics
Subtask 3.4: Advanced Monitoring with Custom Scripts
Create monitoring scripts for ongoing observation.

Create pool monitoring script:
cat > monitor_ec_pool.sh << 'EOF'
#!/bin/bash

POOL_NAME=$1
if [ -z "$POOL_NAME" ]; then
    echo "Usage: $0 <pool_name>"
    exit 1
fi

echo "=== Erasure-Coded Pool Monitoring Report ==="
echo "Pool: $POOL_NAME"
echo "Timestamp: $(date)"
echo

echo "=== Pool Statistics ==="
sudo ceph osd pool stats $POOL_NAME

echo
echo "=== Object Count ==="
sudo rados -p $POOL_NAME ls | wc -l

echo
echo "=== Storage Usage ==="
sudo ceph df | grep -A 1 -B 1 $POOL_NAME

echo
echo "=== PG Status ==="
sudo ceph pg ls-by-pool $POOL_NAME | head -10

echo
echo "=== OSD Distribution ==="
sudo ceph osd df | head -10

echo
echo "=== Recent Operations ==="
sudo ceph osd perf | head -10
EOF

chmod +x monitor_ec_pool.sh
./monitor_ec_pool.sh $EC_POOL_NAME
Create continuous monitoring script:
cat > continuous_monitor.sh << 'EOF'
#!/bin/bash

POOL_NAME=$1
INTERVAL=${2:-30}  # Default 30 seconds

if [ -z "$POOL_NAME" ]; then
    echo "Usage: $0 <pool_name> [interval_seconds]"
    exit 1
fi

echo "Starting continuous monitoring of pool: $POOL_NAME"
echo "Update interval: $INTERVAL seconds"
echo "Press Ctrl+C to stop"

while true; do
    clear
    echo "=== Continuous Pool Monitor - $(date) ==="
    echo "Pool: $POOL_NAME"
    echo
    
    echo "Objects in pool: $(sudo rados -p $POOL_NAME ls | wc -l)"
    echo
    
    sudo ceph osd pool stats $POOL_NAME
    echo
    
    sudo ceph health
    
    sleep $INTERVAL
done
EOF

chmod +x continuous_monitor.sh
# Run this in background or separate terminal if needed
# ./continuous_monitor.sh $EC_POOL_NAME 60
Troubleshooting Common Issues
Issue 1: Upload Failures
Symptoms: Objects fail to upload or return errors

Solutions:

# Check cluster health
sudo ceph health detail

# Verify pool exists and is accessible
sudo ceph osd pool ls

# Check OSD status
sudo ceph osd tree

# Verify erasure code profile
sudo ceph osd erasure-code-profile get default
Issue 2: Slow Performance
Symptoms: Uploads/downloads are slower than expected

Solutions:

# Check OSD performance
sudo ceph osd perf

# Monitor network usage
sudo iotop
sudo nethogs

# Check for recovery operations
sudo ceph -w
Issue 3: Data Integrity Issues
Symptoms: Downloaded files don't match originals

Solutions:

# Run scrub on the pool
sudo ceph pg scrub <pg_id>

# Check for inconsistent PGs
sudo ceph health detail | grep inconsistent

# Verify object checksums
sudo rados -p $EC_POOL_NAME listxattr <object_name>
Issue 4: RGW Access Problems
Symptoms: S3 operations fail or return authentication errors

Solutions:

# Check RGW status
sudo systemctl status ceph-radosgw@*

# Verify user credentials
sudo radosgw-admin user info --uid=testuser

# Check RGW logs
sudo journalctl -u ceph-radosgw@* -f
Lab Validation
Validation Checklist
Complete these steps to verify your lab work:

File Upload Verification:

 Successfully uploaded files via RADOS
 Successfully uploaded files via S3 interface
 All uploaded objects are listed correctly
Data Integrity Verification:

 Downloaded files match original checksums
 Partial reads work correctly
 Concurrent access functions properly
Monitoring Verification:

 Object placement information is accessible
 PG distribution is visible
 Performance metrics are collected
 Dashboard shows pool statistics
Performance Testing:

 Upload performance measured
 Download performance measured
 Results are reasonable for your environment
Final Validation Commands
Run these commands to generate a final report:

cat > lab_validation.sh << 'EOF'
#!/bin/bash

POOL_NAME=$1
echo "=== Lab 11 Validation Report ==="
echo "Generated: $(date)"
echo "Pool: $POOL_NAME"
echo

echo "1. Cluster Health:"
sudo ceph health

echo
echo "2. Pool Objects:"
sudo rados -p $POOL_NAME ls | wc -l

echo
echo "3. Pool Statistics:"
sudo ceph osd pool stats $POOL_NAME

echo
echo "4. Sample Object Details:"
FIRST_OBJECT=$(sudo rados -p $POOL_NAME ls | head -1)
if [ ! -z "$FIRST_OBJECT" ]; then
    sudo rados -p $POOL_NAME stat $FIRST_OBJECT
    sudo ceph osd map $POOL_NAME $FIRST_OBJECT
fi

echo
echo "5. OSD Usage Summary:"
sudo ceph osd df | head -5

echo
echo "=== Validation Complete ==="
EOF

chmod +x lab_validation.sh
./lab_validation.sh $EC_POOL_NAME
Conclusion
In this lab, you have successfully:

Uploaded files to erasure-coded pools using both RADOS and S3 interfaces, demonstrating the flexibility of Ceph's storage access methods
Verified data integrity and access patterns, ensuring that erasure coding maintains data reliability while providing efficient access
Used Ceph monitoring tools to observe data distribution, understanding how erasure coding spreads data across OSDs for fault tolerance
Measured performance characteristics of erasure-coded storage, gaining insights into the trade-offs between storage efficiency and performance
Implemented monitoring solutions for ongoing observation of erasure-coded pool operations
Key Takeaways
Erasure Coding Benefits: You've experienced how erasure coding provides storage efficiency while maintaining data durability through mathematical redundancy rather than simple replication.

Access Method Flexibility: Both native RADOS and S3-compatible interfaces work seamlessly with erasure-coded pools, providing application compatibility.

Monitoring Importance: Proper monitoring of erasure-coded pools is crucial for understanding performance characteristics and ensuring optimal operation.

Performance Considerations: Erasure coding involves computational overhead for encoding/decoding, which affects performance compared to replicated pools.

Real-World Applications
This knowledge is essential for:

Cloud Storage Providers: Implementing cost-effective storage solutions
Enterprise Backup Systems: Balancing storage costs with data protection requirements
Content Distribution Networks: Storing large amounts of data efficiently
Research Data Management: Managing large datasets with optimal storage utilization
Next Steps
Consider exploring:

Advanced erasure code profiles and their impact on performance
Hybrid storage strategies combining replicated and erasure-coded pools
Automated tiering between different storage types
Integration with container orchestration platforms
This lab has provided you with practical experience in managing erasure-coded storage, a critical skill for modern distributed storage administration and the Red Hat Certified Specialist in Ceph Cloud Storage certification.
