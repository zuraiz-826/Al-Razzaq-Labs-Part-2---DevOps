Lab 6: Accessing Object Storage in ODF
Objectives
By the end of this lab, students will be able to:

• Understand the fundamentals of object storage in OpenShift Data Foundation (ODF) • Create and manage Object Bucket Claims (OBC) for application storage needs • Configure S3-compatible object storage endpoints for external access • Integrate applications with ODF object storage using standard S3 APIs • Troubleshoot common object storage connectivity issues • Implement best practices for object storage security and access control

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Kubernetes concepts (pods, services, secrets) • Familiarity with OpenShift Container Platform fundamentals • Knowledge of YAML configuration files • Understanding of storage concepts (persistent volumes, storage classes) • Basic command-line interface experience • Completion of previous ODF labs or equivalent knowledge of ODF installation

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift and ODF already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes: • OpenShift Container Platform 4.12 or later • OpenShift Data Foundation 4.12 or later with Ceph storage • Pre-configured storage cluster with object storage capabilities • Command-line tools (oc, kubectl) • Web console access

Task 1: Create Object Bucket Claims (OBC)
Object Bucket Claims provide a way for applications to request object storage in a Kubernetes-native manner, similar to how Persistent Volume Claims work for block storage.

Subtask 1.1: Verify ODF Object Storage Components
First, let's verify that the object storage components are running properly.

Login to your OpenShift cluster:
oc login -u admin -p admin https://api.cluster.local:6443
Check the openshift-storage namespace:
oc get pods -n openshift-storage | grep -E "(rgw|noobaa)"
Expected output should show running pods for either Ceph RGW or NooBaa object storage.

Verify storage classes for object storage:
oc get storageclass | grep bucket
You should see storage classes like openshift-storage.noobaa.io or similar.

Subtask 1.2: Create Your First Object Bucket Claim
Create a new project for testing:
oc new-project object-storage-lab
Create an Object Bucket Claim YAML file:
cat > my-first-obc.yaml << 'EOF'
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: my-app-bucket
  namespace: object-storage-lab
spec:
  generateBucketName: my-app-bucket
  storageClassName: openshift-storage.noobaa.io
  additionalConfig:
    bucketclass: noobaa-default-bucket-class
EOF
Apply the Object Bucket Claim:
oc apply -f my-first-obc.yaml
Verify the OBC was created successfully:
oc get obc -n object-storage-lab
Check the status of your OBC:
oc describe obc my-app-bucket -n object-storage-lab
The status should show Bound when successful.

Subtask 1.3: Examine Generated Resources
When an OBC is created, several resources are automatically generated.

Check for the generated ConfigMap:
oc get configmap my-app-bucket -n object-storage-lab -o yaml
This ConfigMap contains the bucket name and endpoint information.

Check for the generated Secret:
oc get secret my-app-bucket -n object-storage-lab -o yaml
This Secret contains the access credentials (access key and secret key).

View the bucket endpoint details:
oc get configmap my-app-bucket -n object-storage-lab -o jsonpath='{.data.BUCKET_HOST}'
echo
Task 2: Set up S3-Compatible Object Storage Endpoints
Now we'll configure external access to the object storage using S3-compatible endpoints.

Subtask 2.1: Expose Object Storage Service
Find the object storage service:
oc get svc -n openshift-storage | grep -E "(rgw|noobaa)"
Create a route for external access:
cat > object-storage-route.yaml << 'EOF'
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: s3-object-storage
  namespace: openshift-storage
spec:
  to:
    kind: Service
    name: s3
  port:
    targetPort: s3
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
EOF
Apply the route:
oc apply -f object-storage-route.yaml
Get the external endpoint URL:
oc get route s3-object-storage -n openshift-storage -o jsonpath='{.spec.host}'
echo
Subtask 2.2: Configure S3 Client Access
Install the AWS CLI tool (if not already available):
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
Extract credentials from the OBC secret:
ACCESS_KEY=$(oc get secret my-app-bucket -n object-storage-lab -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 -d)
SECRET_KEY=$(oc get secret my-app-bucket -n object-storage-lab -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 -d)
BUCKET_NAME=$(oc get configmap my-app-bucket -n object-storage-lab -o jsonpath='{.data.BUCKET_NAME}')
ENDPOINT_URL=$(oc get configmap my-app-bucket -n object-storage-lab -o jsonpath='{.data.BUCKET_HOST}')
Configure AWS CLI with the credentials:
aws configure set aws_access_key_id $ACCESS_KEY
aws configure set aws_secret_access_key $SECRET_KEY
aws configure set default.region us-east-1
Test the S3 connection:
aws s3 ls --endpoint-url=https://$ENDPOINT_URL
Subtask 2.3: Perform Basic S3 Operations
Create a test file:
echo "Hello from OpenShift Data Foundation Object Storage!" > test-file.txt
Upload the file to your bucket:
aws s3 cp test-file.txt s3://$BUCKET_NAME/ --endpoint-url=https://$ENDPOINT_URL
List objects in your bucket:
aws s3 ls s3://$BUCKET_NAME/ --endpoint-url=https://$ENDPOINT_URL
Download the file with a different name:
aws s3 cp s3://$BUCKET_NAME/test-file.txt downloaded-file.txt --endpoint-url=https://$ENDPOINT_URL
Verify the download:
cat downloaded-file.txt
Task 3: Integrate Applications with Object Storage
Now we'll create a sample application that uses the object storage for data persistence.

Subtask 3.1: Create a Python Application
Create a simple Python application that uses S3:
cat > s3-app.py << 'EOF'
import boto3
import os
from botocore.exceptions import ClientError

def create_s3_client():
    """Create S3 client using environment variables"""
    return boto3.client(
        's3',
        endpoint_url=f"https://{os.environ['BUCKET_HOST']}",
        aws_access_key_id=os.environ['AWS_ACCESS_KEY_ID'],
        aws_secret_access_key=os.environ['AWS_SECRET_ACCESS_KEY'],
        region_name='us-east-1'
    )

def upload_file(s3_client, bucket_name, file_name, object_name=None):
    """Upload a file to S3 bucket"""
    if object_name is None:
        object_name = file_name
    
    try:
        s3_client.upload_file(file_name, bucket_name, object_name)
        print(f"File {file_name} uploaded successfully to {bucket_name}/{object_name}")
        return True
    except ClientError as e:
        print(f"Error uploading file: {e}")
        return False

def list_objects(s3_client, bucket_name):
    """List objects in S3 bucket"""
    try:
        response = s3_client.list_objects_v2(Bucket=bucket_name)
        if 'Contents' in response:
            print(f"Objects in bucket {bucket_name}:")
            for obj in response['Contents']:
                print(f"  - {obj['Key']} (Size: {obj['Size']} bytes)")
        else:
            print(f"No objects found in bucket {bucket_name}")
    except ClientError as e:
        print(f"Error listing objects: {e}")

if __name__ == "__main__":
    # Create S3 client
    s3 = create_s3_client()
    bucket_name = os.environ['BUCKET_NAME']
    
    # Create a sample file
    with open('app-data.txt', 'w') as f:
        f.write('This is data from my application!\n')
        f.write('Stored in OpenShift Data Foundation Object Storage.\n')
    
    # Upload file
    upload_file(s3, bucket_name, 'app-data.txt')
    
    # List objects
    list_objects(s3, bucket_name)
EOF
Create a Dockerfile for the application:
cat > Dockerfile << 'EOF'
FROM python:3.9-slim

WORKDIR /app

RUN pip install boto3

COPY s3-app.py .

CMD ["python", "s3-app.py"]
EOF
Subtask 3.2: Build and Deploy the Application
Create a BuildConfig to build the application:
cat > app-buildconfig.yaml << 'EOF'
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: s3-app
  namespace: object-storage-lab
spec:
  source:
    type: Binary
  strategy:
    type: Docker
    dockerStrategy:
      from:
        kind: DockerImage
        name: python:3.9-slim
  output:
    to:
      kind: ImageStreamTag
      name: s3-app:latest
EOF
Create an ImageStream:
oc create imagestream s3-app -n object-storage-lab
Apply the BuildConfig:
oc apply -f app-buildconfig.yaml
Start the build:
oc start-build s3-app --from-dir=. --follow -n object-storage-lab
Subtask 3.3: Deploy the Application with Object Storage Integration
Create a Deployment that uses the OBC credentials:
cat > s3-app-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: s3-app
  namespace: object-storage-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: s3-app
  template:
    metadata:
      labels:
        app: s3-app
    spec:
      containers:
      - name: s3-app
        image: image-registry.openshift-image-registry.svc:5000/object-storage-lab/s3-app:latest
        env:
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: my-app-bucket
              key: AWS_ACCESS_KEY_ID
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: my-app-bucket
              key: AWS_SECRET_ACCESS_KEY
        - name: BUCKET_NAME
          valueFrom:
            configMapKeyRef:
              name: my-app-bucket
              key: BUCKET_NAME
        - name: BUCKET_HOST
          valueFrom:
            configMapKeyRef:
              name: my-app-bucket
              key: BUCKET_HOST
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
EOF
Deploy the application:
oc apply -f s3-app-deployment.yaml
Check the deployment status:
oc get pods -n object-storage-lab -l app=s3-app
View the application logs:
oc logs -f deployment/s3-app -n object-storage-lab
You should see output indicating successful file upload and object listing.

Subtask 3.4: Create a Web Application Example
Create a simple web application that demonstrates object storage:
cat > web-app.py << 'EOF'
from flask import Flask, request, render_template_string, redirect, url_for
import boto3
import os
from botocore.exceptions import ClientError

app = Flask(__name__)

def get_s3_client():
    return boto3.client(
        's3',
        endpoint_url=f"https://{os.environ['BUCKET_HOST']}",
        aws_access_key_id=os.environ['AWS_ACCESS_KEY_ID'],
        aws_secret_access_key=os.environ['AWS_SECRET_ACCESS_KEY'],
        region_name='us-east-1'
    )

HTML_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
    <title>ODF Object Storage Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .upload-form { background: #f5f5f5; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .file-list { background: #fff; border: 1px solid #ddd; padding: 20px; border-radius: 5px; }
        input[type="file"] { margin: 10px 0; }
        button { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 3px; cursor: pointer; }
        button:hover { background: #0056b3; }
    </style>
</head>
<body>
    <div class="container">
        <h1>OpenShift Data Foundation Object Storage Demo</h1>
        
        <div class="upload-form">
            <h2>Upload File</h2>
            <form method="post" enctype="multipart/form-data">
                <input type="file" name="file" required>
                <br>
                <button type="submit">Upload to Object Storage</button>
            </form>
        </div>
        
        <div class="file-list">
            <h2>Files in Object Storage</h2>
            {% if files %}
                <ul>
                {% for file in files %}
                    <li>{{ file.name }} ({{ file.size }} bytes) - {{ file.modified }}</li>
                {% endfor %}
                </ul>
            {% else %}
                <p>No files found in the bucket.</p>
            {% endif %}
        </div>
        
        {% if message %}
            <div style="background: #d4edda; color: #155724; padding: 10px; border-radius: 3px; margin: 10px 0;">
                {{ message }}
            </div>
        {% endif %}
    </div>
</body>
</html>
'''

@app.route('/', methods=['GET', 'POST'])
def index():
    message = None
    
    if request.method == 'POST':
        file = request.files['file']
        if file and file.filename:
            try:
                s3 = get_s3_client()
                bucket_name = os.environ['BUCKET_NAME']
                s3.upload_fileobj(file, bucket_name, file.filename)
                message = f"File '{file.filename}' uploaded successfully!"
            except Exception as e:
                message = f"Error uploading file: {str(e)}"
    
    # List files
    files = []
    try:
        s3 = get_s3_client()
        bucket_name = os.environ['BUCKET_NAME']
        response = s3.list_objects_v2(Bucket=bucket_name)
        if 'Contents' in response:
            for obj in response['Contents']:
                files.append({
                    'name': obj['Key'],
                    'size': obj['Size'],
                    'modified': obj['LastModified'].strftime('%Y-%m-%d %H:%M:%S')
                })
    except Exception as e:
        message = f"Error listing files: {str(e)}"
    
    return render_template_string(HTML_TEMPLATE, files=files, message=message)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF
Create a Dockerfile for the web application:
cat > Dockerfile-web << 'EOF'
FROM python:3.9-slim

WORKDIR /app

RUN pip install flask boto3

COPY web-app.py .

EXPOSE 8080

CMD ["python", "web-app.py"]
EOF
Build the web application:
oc new-build --name=s3-web-app --binary --strategy=docker -n object-storage-lab
oc start-build s3-web-app --from-file=Dockerfile-web --from-file=web-app.py --follow -n object-storage-lab
Deploy the web application:
cat > web-app-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: s3-web-app
  namespace: object-storage-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: s3-web-app
  template:
    metadata:
      labels:
        app: s3-web-app
    spec:
      containers:
      - name: s3-web-app
        image: image-registry.openshift-image-registry.svc:5000/object-storage-lab/s3-web-app:latest
        ports:
        - containerPort: 8080
        env:
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: my-app-bucket
              key: AWS_ACCESS_KEY_ID
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: my-app-bucket
              key: AWS_SECRET_ACCESS_KEY
        - name: BUCKET_NAME
          valueFrom:
            configMapKeyRef:
              name: my-app-bucket
              key: BUCKET_NAME
        - name: BUCKET_HOST
          valueFrom:
            configMapKeyRef:
              name: my-app-bucket
              key: BUCKET_HOST
---
apiVersion: v1
kind: Service
metadata:
  name: s3-web-app
  namespace: object-storage-lab
spec:
  selector:
    app: s3-web-app
  ports:
  - port: 8080
    targetPort: 8080
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: s3-web-app
  namespace: object-storage-lab
spec:
  to:
    kind: Service
    name: s3-web-app
  port:
    targetPort: 8080
EOF
Apply the web application deployment:
oc apply -f web-app-deployment.yaml
Get the web application URL:
oc get route s3-web-app -n object-storage-lab -o jsonpath='{.spec.host}'
echo
Test the web application: Open the URL in your browser and try uploading files to see them stored in object storage.
Troubleshooting Common Issues
Issue 1: OBC Not Binding
Symptoms: OBC remains in Pending state

Solutions:

# Check storage class availability
oc get storageclass

# Check ODF operator status
oc get pods -n openshift-storage

# Check events for more details
oc describe obc my-app-bucket -n object-storage-lab
Issue 2: S3 Connection Failures
Symptoms: AWS CLI or applications cannot connect to object storage

Solutions:

# Verify route is accessible
oc get route -n openshift-storage

# Check if certificates are valid
curl -k https://$(oc get route s3-object-storage -n openshift-storage -o jsonpath='{.spec.host}')

# Verify credentials
oc get secret my-app-bucket -n object-storage-lab -o yaml
Issue 3: Application Pod Failures
Symptoms: Application pods fail to start or crash

Solutions:

# Check pod logs
oc logs -f deployment/s3-app -n object-storage-lab

# Verify environment variables
oc exec deployment/s3-app -n object-storage-lab -- env | grep -E "(AWS|BUCKET)"

# Check resource limits
oc describe pod -l app=s3-app -n object-storage-lab
Best Practices and Security Considerations
Security Best Practices
Use RBAC for OBC Access:
cat > obc-rbac.yaml << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: object-storage-lab
  name: obc-user
rules:
- apiGroups: ["objectbucket.io"]
  resources: ["objectbucketclaims"]
  verbs: ["get", "list", "create", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: obc-user-binding
  namespace: object-storage-lab
subjects:
- kind: User
  name: developer
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: obc-user
  apiGroup: rbac.authorization.k8s.io
EOF
Implement Network Policies:
cat > object-storage-netpol.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-object-storage
  namespace: object-storage-lab
spec:
  podSelector:
    matchLabels:
      app: s3-app
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: openshift-storage
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
EOF
Performance Optimization
Configure appropriate resource limits
Use connection pooling in applications
Implement proper error handling and retries
Monitor object storage usage and performance
Verification and Testing
Final Verification Steps
Verify all components are working:
# Check OBC status
oc get obc -n object-storage-lab

# Check application deployments
oc get deployments -n object-storage-lab

# Test S3 operations
aws s3 ls s3://$BUCKET_NAME/ --endpoint-url=https://$ENDPOINT_URL
Performance test:
# Upload a larger file
dd if=/dev/zero of=large-test-file.dat bs=1M count=10
aws s3 cp large-test-file.dat s3://$BUCKET_NAME/ --endpoint-url=https://$ENDPOINT_URL

# Measure download speed
time aws s3 cp s3://$BUCKET_NAME/large-test-file.dat downloaded-large-file.dat --endpoint-url=https://$ENDPOINT_URL
Cleanup
To clean up the lab environment:

# Delete the project (this removes all resources)
oc delete project object-storage-lab

# Remove the object storage route
oc delete route s3-object-storage -n openshift-storage

# Clean up local files
rm -f *.yaml *.py *.txt *.dat Dockerfile*
Conclusion
In this comprehensive lab, you have successfully:

• Created Object Bucket Claims (OBC) to provision object storage in a Kubernetes-native way, learning how ODF automatically generates the necessary credentials and configuration • Set up S3-compatible endpoints for external access, enabling applications outside the cluster to interact with your object storage • Integrated applications with object storage by building both command-line and web-based applications that demonstrate real-world usage patterns

Why This Matters: Object storage is crucial for modern cloud-native applications that need to store unstructured data like images, documents, backups, and logs. By mastering ODF's object storage capabilities, you can:

Provide scalable storage solutions for applications
Implement backup and archival strategies
Enable data sharing between applications and external systems
Build cloud-native applications that follow industry standards
The skills you've learned in this lab are directly applicable to the Red Hat Certified Specialist in OpenShift Data Foundation exam and real-world enterprise environments where object storage is essential for application data persistence and integration.

Next Steps: Consider exploring advanced topics like bucket policies, lifecycle management, and multi-site object storage replication to further enhance your ODF expertise.
