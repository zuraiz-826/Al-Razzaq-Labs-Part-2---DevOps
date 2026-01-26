Lab 7: Configuring NooBaa for Object Storage
Objectives
By the end of this lab, you will be able to:

• Install and configure NooBaa as the object storage interface in OpenShift Data Foundation (ODF) • Set up object bucket policies and manage object storage through NooBaa • Monitor NooBaa health and performance metrics • Create and manage object buckets using both CLI and web interface • Understand NooBaa architecture and its role in hybrid cloud storage

Prerequisites
Before starting this lab, you should have:

• Basic understanding of OpenShift Container Platform concepts • Familiarity with Kubernetes storage concepts (PVs, PVCs, StorageClasses) • Knowledge of object storage concepts (buckets, objects, policies) • Experience with command-line interface operations • Understanding of YAML configuration files • Completion of previous OpenShift Data Foundation labs (recommended)

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift cluster access. Simply click Start Lab to begin - no need to build your own virtual machines or configure the environment from scratch.

Your lab environment includes: • OpenShift Container Platform 4.12+ cluster • OpenShift Data Foundation operator installed • Administrative access to the cluster • Pre-configured storage nodes • Web console and CLI access

Task 1: Install and Configure NooBaa in OpenShift
Subtask 1.1: Verify OpenShift Data Foundation Installation
First, let's verify that OpenShift Data Foundation is properly installed and ready for NooBaa configuration.

Log into your OpenShift cluster:
oc login -u admin -p <password> <cluster-url>
Verify ODF operator installation:
oc get csv -n openshift-storage | grep odf-operator
Check storage cluster status:
oc get storagecluster -n openshift-storage
Verify storage nodes are ready:
oc get nodes -l cluster.ocs.openshift.io/openshift-storage=
Subtask 1.2: Deploy NooBaa System
NooBaa is automatically deployed as part of ODF, but we need to verify and configure it properly.

Check if NooBaa system exists:
oc get noobaa -n openshift-storage
If NooBaa system doesn't exist, create it:
cat << EOF | oc apply -f -
apiVersion: noobaa.io/v1alpha1
kind: NooBaa
metadata:
  name: noobaa
  namespace: openshift-storage
spec:
  dbResources:
    requests:
      cpu: 500m
      memory: 1Gi
  coreResources:
    requests:
      cpu: 500m
      memory: 1Gi
EOF
Wait for NooBaa system to be ready:
oc wait --for=condition=Available noobaa/noobaa -n openshift-storage --timeout=600s
Verify NooBaa pods are running:
oc get pods -n openshift-storage | grep noobaa
Subtask 1.3: Access NooBaa Management Console
Get NooBaa management console route:
oc get route noobaa-mgmt -n openshift-storage -o jsonpath='{.spec.host}'
Get NooBaa admin credentials:
# Get admin email
oc get secret noobaa-admin -n openshift-storage -o jsonpath='{.data.email}' | base64 -d

# Get admin password
oc get secret noobaa-admin -n openshift-storage -o jsonpath='{.data.password}' | base64 -d
Access the NooBaa console:
Open a web browser
Navigate to the route URL obtained in step 1
Login with the credentials from step 2
Subtask 1.4: Install NooBaa CLI
Download and install NooBaa CLI:
# Download the latest noobaa CLI
curl -LO https://github.com/noobaa/noobaa-operator/releases/latest/download/noobaa-linux-v5.13.0

# Make it executable
chmod +x noobaa-linux-v5.13.0

# Move to system path
sudo mv noobaa-linux-v5.13.0 /usr/local/bin/noobaa
Verify NooBaa CLI installation:
noobaa version
Configure NooBaa CLI to connect to your system:
noobaa status -n openshift-storage
Task 2: Set Up Object Bucket Policies and Manage Object Storage
Subtask 2.1: Create Object Bucket Claims
Object Bucket Claims (OBCs) are used to request object storage buckets in NooBaa.

Create a basic Object Bucket Claim:
cat << EOF | oc apply -f -
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: my-bucket-claim
  namespace: default
spec:
  generateBucketName: my-app-bucket
  storageClassName: openshift-storage.noobaa.io
EOF
Verify the OBC was created successfully:
oc get obc my-bucket-claim -n default
Check the generated Object Bucket:
oc get ob -n default
Get bucket access credentials:
# Get the secret name
SECRET_NAME=$(oc get obc my-bucket-claim -n default -o jsonpath='{.spec.objectBucketName}')

# Get access key
oc get secret $SECRET_NAME -n default -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 -d

# Get secret key
oc get secret $SECRET_NAME -n default -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 -d
Subtask 2.2: Configure Bucket Policies
Create a bucket policy for read-only access:
cat << EOF > bucket-policy-readonly.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOnlyAccess",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-app-bucket-*",
        "arn:aws:s3:::my-app-bucket-*/*"
      ]
    }
  ]
}
EOF
Create a bucket class with specific policies:
cat << EOF | oc apply -f -
apiVersion: objectbucket.io/v1alpha1
kind: BucketClass
metadata:
  name: secure-bucket-class
  namespace: openshift-storage
spec:
  storageClassName: openshift-storage.noobaa.io
  parameters:
    bucketPolicy: |
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::*/*"
          }
        ]
      }
EOF
Create an OBC using the custom bucket class:
cat << EOF | oc apply -f -
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: secure-bucket-claim
  namespace: default
spec:
  generateBucketName: secure-app-bucket
  bucketClassName: secure-bucket-class
EOF
Subtask 2.3: Test Object Storage Operations
Install AWS CLI for testing:
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
Configure AWS CLI with NooBaa credentials:
# Get S3 endpoint
S3_ENDPOINT=$(oc get route s3 -n openshift-storage -o jsonpath='{.spec.host}')

# Get credentials from the secret
ACCESS_KEY=$(oc get secret $SECRET_NAME -n default -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 -d)
SECRET_KEY=$(oc get secret $SECRET_NAME -n default -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 -d)

# Configure AWS CLI
aws configure set aws_access_key_id $ACCESS_KEY
aws configure set aws_secret_access_key $SECRET_KEY
aws configure set default.region us-east-1
Test bucket operations:
# List buckets
aws s3 ls --endpoint-url https://$S3_ENDPOINT

# Create a test file
echo "Hello NooBaa!" > test-file.txt

# Upload file to bucket
BUCKET_NAME=$(oc get obc my-bucket-claim -n default -o jsonpath='{.spec.bucketName}')
aws s3 cp test-file.txt s3://$BUCKET_NAME/ --endpoint-url https://$S3_ENDPOINT

# List objects in bucket
aws s3 ls s3://$BUCKET_NAME/ --endpoint-url https://$S3_ENDPOINT

# Download file from bucket
aws s3 cp s3://$BUCKET_NAME/test-file.txt downloaded-file.txt --endpoint-url https://$S3_ENDPOINT
Subtask 2.4: Manage Backing Stores
Backing stores define where NooBaa actually stores the data.

View existing backing stores:
oc get backingstore -n openshift-storage
Create a PV pool backing store:
cat << EOF | oc apply -f -
apiVersion: noobaa.io/v1alpha1
kind: BackingStore
metadata:
  name: pv-pool-backing-store
  namespace: openshift-storage
spec:
  type: pv-pool
  pvPool:
    numVolumes: 3
    resources:
      requests:
        storage: 50Gi
    storageClass: ocs-storagecluster-ceph-rbd
EOF
Create a bucket class using the new backing store:
cat << EOF | oc apply -f -
apiVersion: noobaa.io/v1alpha1
kind: BucketClass
metadata:
  name: pv-pool-bucket-class
  namespace: openshift-storage
spec:
  placementPolicy:
    tiers:
    - backingStores:
      - pv-pool-backing-store
EOF
Task 3: Monitor NooBaa Health and Performance
Subtask 3.1: Check NooBaa System Status
Use NooBaa CLI to check system status:
noobaa status -n openshift-storage
Check NooBaa system health:
oc get noobaa noobaa -n openshift-storage -o yaml
Verify all NooBaa components are healthy:
oc get pods -n openshift-storage -l app=noobaa
Subtask 3.2: Monitor Resource Usage
Check NooBaa resource consumption:
# Check CPU and memory usage
oc top pods -n openshift-storage | grep noobaa

# Check storage usage
oc get pvc -n openshift-storage | grep noobaa
View NooBaa metrics through the web console:

Navigate to the NooBaa management console
Go to the Dashboard section
Review storage capacity, throughput, and IOPS metrics
Check backing store status:

oc get backingstore -n openshift-storage -o wide
Subtask 3.3: Set Up Monitoring and Alerts
Create a ServiceMonitor for NooBaa metrics:
cat << EOF | oc apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: noobaa-metrics
  namespace: openshift-storage
spec:
  selector:
    matchLabels:
      app: noobaa
  endpoints:
  - port: mgmt-https
    scheme: https
    tlsConfig:
      insecureSkipVerify: true
EOF
View NooBaa metrics in Prometheus:
# Get Prometheus route
oc get route prometheus-k8s -n openshift-monitoring -o jsonpath='{.spec.host}'
Create a basic alert rule for NooBaa:
cat << EOF | oc apply -f -
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: noobaa-alerts
  namespace: openshift-storage
spec:
  groups:
  - name: noobaa.rules
    rules:
    - alert: NooBaaSystemDown
      expr: up{job="noobaa-mgmt-service"} == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "NooBaa system is down"
        description: "NooBaa management service has been down for more than 5 minutes"
EOF
Subtask 3.4: Performance Testing
Create a performance test script:
cat << 'EOF' > noobaa-performance-test.sh
#!/bin/bash

BUCKET_NAME=$1
ENDPOINT_URL=$2
FILE_SIZE=${3:-1M}
NUM_FILES=${4:-10}

if [ -z "$BUCKET_NAME" ] || [ -z "$ENDPOINT_URL" ]; then
    echo "Usage: $0 <bucket-name> <endpoint-url> [file-size] [num-files]"
    exit 1
fi

echo "Starting performance test..."
echo "Bucket: $BUCKET_NAME"
echo "Endpoint: $ENDPOINT_URL"
echo "File size: $FILE_SIZE"
echo "Number of files: $NUM_FILES"

# Create test files
for i in $(seq 1 $NUM_FILES); do
    dd if=/dev/zero of=test-file-$i.dat bs=$FILE_SIZE count=1 2>/dev/null
done

# Upload test
echo "Starting upload test..."
start_time=$(date +%s)
for i in $(seq 1 $NUM_FILES); do
    aws s3 cp test-file-$i.dat s3://$BUCKET_NAME/ --endpoint-url $ENDPOINT_URL >/dev/null 2>&1
done
end_time=$(date +%s)
upload_duration=$((end_time - start_time))

echo "Upload completed in $upload_duration seconds"

# Download test
echo "Starting download test..."
start_time=$(date +%s)
for i in $(seq 1 $NUM_FILES); do
    aws s3 cp s3://$BUCKET_NAME/test-file-$i.dat downloaded-$i.dat --endpoint-url $ENDPOINT_URL >/dev/null 2>&1
done
end_time=$(date +%s)
download_duration=$((end_time - start_time))

echo "Download completed in $download_duration seconds"

# Cleanup
rm -f test-file-*.dat downloaded-*.dat

echo "Performance test completed!"
EOF

chmod +x noobaa-performance-test.sh
Run the performance test:
./noobaa-performance-test.sh $BUCKET_NAME https://$S3_ENDPOINT 1M 5
Troubleshooting Common Issues
Issue 1: NooBaa Pods Not Starting
Symptoms: NooBaa pods remain in Pending or CrashLoopBackOff state

Solution:

# Check pod events
oc describe pod -n openshift-storage -l app=noobaa

# Check resource availability
oc get nodes -o wide
oc describe nodes

# Verify storage class exists
oc get storageclass
Issue 2: Object Bucket Claim Stuck in Pending
Symptoms: OBC remains in Pending state and bucket is not created

Solution:

# Check OBC events
oc describe obc my-bucket-claim -n default

# Verify NooBaa system is ready
oc get noobaa -n openshift-storage

# Check backing store status
oc get backingstore -n openshift-storage
Issue 3: S3 Operations Failing
Symptoms: AWS CLI commands return authentication or connection errors

Solution:

# Verify S3 route is accessible
curl -k https://$S3_ENDPOINT

# Check credentials are correct
oc get secret $SECRET_NAME -n default -o yaml

# Verify bucket exists
oc get ob -n default
Lab Validation
To verify your lab completion, run these validation commands:

Verify NooBaa system is running:
oc get noobaa noobaa -n openshift-storage -o jsonpath='{.status.phase}'
Expected output: Ready

Verify Object Bucket Claims are bound:
oc get obc -A
Expected output: All OBCs should show Bound status

Test S3 operations:
aws s3 ls --endpoint-url https://$S3_ENDPOINT
Expected output: List of buckets should be displayed

Check backing stores are available:
oc get backingstore -n openshift-storage -o jsonpath='{.items[*].status.phase}'
Expected output: Ready

Conclusion
Congratulations! You have successfully completed Lab 7: Configuring NooBaa for Object Storage. In this lab, you accomplished the following:

Key Achievements: • Installed and configured NooBaa as the object storage interface in OpenShift Data Foundation • Created and managed Object Bucket Claims to provision S3-compatible storage buckets • Configured bucket policies to control access and security for object storage • Set up backing stores to define where NooBaa stores data physically • Implemented monitoring and alerting for NooBaa health and performance • Performed performance testing to validate object storage operations

Why This Matters: NooBaa provides a crucial hybrid cloud storage layer that enables organizations to:

Unify storage management across on-premises and cloud environments
Provide S3-compatible APIs for application integration
Implement data lifecycle policies for cost optimization
Enable seamless data mobility between different storage tiers
Support modern cloud-native applications with object storage requirements
Real-World Applications: The skills you've learned are directly applicable to:

Container-native storage solutions for Kubernetes workloads
Hybrid cloud data management strategies
Application modernization projects requiring object storage
Data lake and analytics platform implementations
Backup and disaster recovery solutions
This lab has prepared you for the Red Hat Certified Specialist in OpenShift Data Foundation exam by providing hands-on experience with NooBaa configuration, management, and troubleshooting. You now have the practical knowledge to implement and maintain object storage solutions in enterprise OpenShift environments.
