Lab 4: Import and Export Kubernetes Resources
Objectives
By the end of this lab, you will be able to:

Import Kubernetes resource definitions from YAML files into your cluster
Export existing resource configurations using the oc get -o yaml command
Modify exported configurations and reapply them using oc apply
Understand the workflow of resource management in OpenShift/Kubernetes environments
Practice configuration management best practices for containerized applications
Prerequisites
Before starting this lab, you should have:

Basic understanding of Kubernetes/OpenShift concepts (pods, services, deployments)
Familiarity with YAML file structure and syntax
Basic command-line interface (CLI) experience
Understanding of text editors (vi, nano, or similar)
Completed previous labs in this series or equivalent OpenShift experience
Lab Environment Setup
Good News! Al Nafi provides ready-to-use Linux-based cloud machines with OpenShift CLI (oc) pre-installed. Simply click Start Lab to access your environment - no need to build your own virtual machine or install additional software.

Your lab environment includes:

Red Hat Enterprise Linux 8/9 with OpenShift CLI tools
Pre-configured cluster access
Text editors (vi, nano)
All necessary permissions for resource management
Task 1: Import Resource Definitions from YAML Files
Subtask 1.1: Create Sample YAML Resource Files
First, let's create some sample Kubernetes resource files that we'll use for importing.

Create a working directory for this lab:
mkdir ~/k8s-import-export-lab
cd ~/k8s-import-export-lab
Create a sample deployment YAML file:
cat > sample-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF
Create a sample service YAML file:
cat > sample-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  labels:
    app: nginx
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
EOF
Create a sample ConfigMap YAML file:
cat > sample-configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    server {
        listen 80;
        server_name localhost;
        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
        }
    }
  app.properties: |
    app.name=nginx-app
    app.version=1.0
    debug=false
EOF
Subtask 1.2: Import Resources Using oc apply
Now let's import these resources into our OpenShift cluster.

Create a new project for this lab:
oc new-project import-export-lab
Import the deployment resource:
oc apply -f sample-deployment.yaml
Expected output:

deployment.apps/nginx-deployment created
Import the service resource:
oc apply -f sample-service.yaml
Expected output:

service/nginx-service created
Import the ConfigMap resource:
oc apply -f sample-configmap.yaml
Expected output:

configmap/nginx-config created
Import all resources at once (alternative method):
# First, let's delete the existing resources to demonstrate bulk import
oc delete -f sample-deployment.yaml -f sample-service.yaml -f sample-configmap.yaml

# Now import all at once
oc apply -f .
Subtask 1.3: Verify Imported Resources
Check that all resources were created successfully:
oc get all
Verify specific resource types:
# Check deployments
oc get deployments

# Check services
oc get services

# Check ConfigMaps
oc get configmaps
Get detailed information about the deployment:
oc describe deployment nginx-deployment
Task 2: Export Current Resource Configurations Using oc get -o yaml
Subtask 2.1: Export Individual Resources
Now let's learn how to export existing resources from the cluster.

Export the deployment to YAML format:
oc get deployment nginx-deployment -o yaml > exported-deployment.yaml
Export the service to YAML format:
oc get service nginx-service -o yaml > exported-service.yaml
Export the ConfigMap to YAML format:
oc get configmap nginx-config -o yaml > exported-configmap.yaml
View the exported deployment file:
cat exported-deployment.yaml
Note: The exported YAML will contain additional fields that Kubernetes added automatically, such as:

status section
metadata.uid
metadata.resourceVersion
metadata.creationTimestamp
Subtask 2.2: Export Multiple Resources
Export all deployments in the current namespace:
oc get deployments -o yaml > all-deployments.yaml
Export all resources of multiple types:
oc get deployment,service,configmap -o yaml > all-resources.yaml
Export resources with specific labels:
oc get all -l app=nginx -o yaml > nginx-resources.yaml
Subtask 2.3: Clean Exported Files for Re-import
When exporting resources for re-import, we need to clean them up by removing cluster-specific fields.

Create a cleaned version of the exported deployment:
oc get deployment nginx-deployment -o yaml | \
  grep -v '^\s*uid:' | \
  grep -v '^\s*resourceVersion:' | \
  grep -v '^\s*creationTimestamp:' | \
  grep -v '^\s*generation:' | \
  sed '/^status:/,$d' > clean-deployment.yaml
View the cleaned file:
cat clean-deployment.yaml
Task 3: Modify Configurations and Reapply Using oc apply
Subtask 3.1: Modify Resource Configurations
Let's modify our exported resources and reapply them to see the changes.

Create a modified version of the deployment with more replicas:
cp sample-deployment.yaml modified-deployment.yaml
Edit the deployment to increase replicas from 2 to 4:
sed -i 's/replicas: 2/replicas: 4/' modified-deployment.yaml
Also update the nginx image version:
sed -i 's/nginx:1.21/nginx:1.22/' modified-deployment.yaml
View the changes:
cat modified-deployment.yaml
Subtask 3.2: Apply Modified Configurations
Apply the modified deployment:
oc apply -f modified-deployment.yaml
Expected output:

deployment.apps/nginx-deployment configured
Verify the changes took effect:
oc get deployment nginx-deployment
You should see that the deployment now has 4 replicas instead of 2.

Check the pods to see the scaling in action:
oc get pods -l app=nginx
Verify the image version was updated:
oc describe deployment nginx-deployment | grep Image
Subtask 3.3: Modify and Reapply Service Configuration
Create a modified service that changes from ClusterIP to NodePort:
cp sample-service.yaml modified-service.yaml
Edit the service type:
sed -i 's/type: ClusterIP/type: NodePort/' modified-service.yaml
Apply the modified service:
oc apply -f modified-service.yaml
Verify the service change:
oc get service nginx-service
You should now see a NodePort assigned to the service.

Subtask 3.4: Modify ConfigMap and Reapply
Create a modified ConfigMap with additional configuration:
cat > modified-configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    server {
        listen 80;
        server_name localhost;
        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
        }
        location /health {
            return 200 'healthy\n';
            add_header Content-Type text/plain;
        }
    }
  app.properties: |
    app.name=nginx-app
    app.version=2.0
    debug=true
    environment=development
  database.properties: |
    db.host=localhost
    db.port=5432
    db.name=myapp
EOF
Apply the modified ConfigMap:
oc apply -f modified-configmap.yaml
Verify the ConfigMap was updated:
oc describe configmap nginx-config
Subtask 3.5: Practice Complete Export-Modify-Import Workflow
Let's practice the complete workflow with a new resource.

Create a new deployment:
cat > test-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  labels:
    app: test-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: test-app
        image: httpd:2.4
        ports:
        - containerPort: 80
EOF
Apply the test deployment:
oc apply -f test-deployment.yaml
Export the deployment after it's running:
oc get deployment test-app -o yaml > exported-test-deployment.yaml
Create a clean version for modification:
oc get deployment test-app -o yaml | \
  grep -v '^\s*uid:' | \
  grep -v '^\s*resourceVersion:' | \
  grep -v '^\s*creationTimestamp:' | \
  grep -v '^\s*generation:' | \
  sed '/^status:/,$d' > clean-test-deployment.yaml
Modify the clean version (change replicas and add resource limits):
cat > modified-test-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  labels:
    app: test-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: test-app
        image: httpd:2.4
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
EOF
Apply the modified deployment:
oc apply -f modified-test-deployment.yaml
Verify the changes:
oc get deployment test-app
oc describe deployment test-app
Troubleshooting Common Issues
Issue 1: Resource Already Exists Error
If you get an error saying a resource already exists:

# Delete the existing resource first
oc delete deployment nginx-deployment

# Then reapply
oc apply -f sample-deployment.yaml
Issue 2: YAML Formatting Errors
If you encounter YAML formatting errors:

# Validate YAML syntax
oc apply -f your-file.yaml --dry-run=client
Issue 3: Permission Denied
If you get permission errors:

# Check your current project
oc project

# Make sure you're in the correct project
oc project import-export-lab
Issue 4: Resource Not Found During Export
If a resource doesn't exist when trying to export:

# List all resources to see what's available
oc get all

# Check specific resource types
oc get deployments
oc get services
oc get configmaps
Lab Verification and Testing
Verification Checklist
Verify all imported resources exist:
oc get deployment nginx-deployment
oc get service nginx-service
oc get configmap nginx-config
oc get deployment test-app
Verify modifications were applied:
# Check nginx deployment has 4 replicas
oc get deployment nginx-deployment -o jsonpath='{.spec.replicas}'

# Check service is NodePort type
oc get service nginx-service -o jsonpath='{.spec.type}'

# Check test-app has 3 replicas
oc get deployment test-app -o jsonpath='{.spec.replicas}'
Verify exported files exist:
ls -la *.yaml
Clean Up Resources
After completing the lab, clean up the resources:

# Delete all resources in the project
oc delete all --all

# Delete ConfigMaps
oc delete configmap --all

# Or delete the entire project
oc delete project import-export-lab
Conclusion
Congratulations! You have successfully completed Lab 4: Import and Export Kubernetes Resources. In this lab, you accomplished the following:

Key Achievements:

Resource Import Mastery: You learned how to import Kubernetes resources from YAML files using oc apply, including individual files and bulk imports
Export Proficiency: You mastered exporting existing resources using oc get -o yaml and learned how to clean exported files for re-import
Configuration Management: You practiced the complete workflow of exporting, modifying, and reapplying resource configurations
Real-world Skills: You gained hands-on experience with common DevOps practices for managing containerized applications
Why This Matters:

Infrastructure as Code: These skills are fundamental to implementing Infrastructure as Code practices in Kubernetes environments
Disaster Recovery: Knowing how to export and import resources is crucial for backup and disaster recovery scenarios
Environment Migration: These techniques are essential when moving applications between different clusters or environments
Configuration Management: This workflow is the foundation of GitOps and modern DevOps practices
Red Hat Certification: These skills directly support objectives tested in the Red Hat Certified OpenShift Administrator exam
Next Steps:

Practice these workflows with more complex applications involving multiple resource types
Explore advanced techniques like using Kustomize for configuration management
Learn about Helm charts as another method for packaging and deploying Kubernetes applications
Study GitOps workflows that automate the import/export process through CI/CD pipelines
You now have the foundational skills needed to manage Kubernetes resources effectively in production environments, making you better prepared for both real-world scenarios and certification exams.
