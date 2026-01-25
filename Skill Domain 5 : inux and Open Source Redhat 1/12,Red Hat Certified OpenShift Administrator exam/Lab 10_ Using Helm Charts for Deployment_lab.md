Lab 10: Using Helm Charts for Deployment
Objectives
By the end of this lab, you will be able to:

Install and configure Helm on OpenShift
Deploy applications using Helm charts
Modify chart values to customize application configurations
Upgrade applications using Helm
Roll back applications to previous versions using Helm
Understand Helm chart structure and best practices
Prerequisites
Before starting this lab, you should have:

Basic understanding of Kubernetes and OpenShift concepts
Familiarity with YAML syntax
Knowledge of command-line interface operations
Understanding of containerized applications
Basic knowledge of package management concepts
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines with OpenShift pre-installed. Simply click Start Lab to begin - no need to build your own VM or install additional software.

Your lab environment includes:

OpenShift cluster with admin access
Helm 3.x pre-installed
kubectl and oc CLI tools configured
Internet access for downloading Helm charts
Task 1: Install a Helm Chart for an Application
Subtask 1.1: Verify Helm Installation and Setup
First, let's verify that Helm is properly installed and configure it for use with OpenShift.

Check Helm version:
helm version
Verify OpenShift connection:
oc whoami
oc cluster-info
Create a new project for this lab:
oc new-project helm-lab
oc project helm-lab
Subtask 1.2: Add Helm Repository
We'll use the Bitnami repository, which contains many popular applications.

Add the Bitnami Helm repository:
helm repo add bitnami https://charts.bitnami.com/bitnami
Update the repository index:
helm repo update
List available repositories:
helm repo list
Search for available charts:
helm search repo bitnami/nginx
Subtask 1.3: Install NGINX Using Helm Chart
Now we'll install NGINX web server using a Helm chart.

View chart information:
helm show chart bitnami/nginx
View default values:
helm show values bitnami/nginx
Install NGINX with default values:
helm install my-nginx bitnami/nginx
Check the installation status:
helm status my-nginx
List all Helm releases:
helm list
Verify the deployment in OpenShift:
oc get pods
oc get services
oc get deployments
Subtask 1.4: Access the Application
Create a route to access NGINX:
oc expose service my-nginx
Get the route URL:
oc get routes
Test the application (replace with your actual route URL):
curl http://my-nginx-helm-lab.apps.your-cluster.com
Task 2: Modify Values in the Chart for Configuration
Subtask 2.1: Create Custom Values File
We'll customize the NGINX deployment by creating a custom values file.

Create a custom values file:
cat > custom-values.yaml << EOF
replicaCount: 3

image:
  tag: "1.21.6"

service:
  type: ClusterIP
  port: 8080

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

ingress:
  enabled: false

serverBlock: |
  server {
    listen 8080;
    server_name _;
    location / {
      return 200 'Hello from Custom NGINX - Lab 10!\n';
      add_header Content-Type text/plain;
    }
  }
EOF
View the custom values file:
cat custom-values.yaml
Subtask 2.2: Deploy with Custom Values
Install a new release with custom values:
helm install my-custom-nginx bitnami/nginx -f custom-values.yaml
Verify the custom configuration:
helm get values my-custom-nginx
Check the pods and services:
oc get pods -l app.kubernetes.io/instance=my-custom-nginx
oc get services -l app.kubernetes.io/instance=my-custom-nginx
Create a route for the custom NGINX:
oc expose service my-custom-nginx --port=8080
Test the custom configuration:
oc get routes
# Test with curl using the route URL
curl http://my-custom-nginx-helm-lab.apps.your-cluster.com
Subtask 2.3: Override Values Using Command Line
You can also override values directly from the command line.

Install another release with command-line overrides:
helm install my-cli-nginx bitnami/nginx \
  --set replicaCount=2 \
  --set service.port=9090 \
  --set image.tag=1.21.6
Verify the overrides:
helm get values my-cli-nginx
Task 3: Upgrade or Roll Back the Application Using Helm
Subtask 3.1: Upgrade an Application
Let's upgrade our NGINX deployment with new configurations.

Create an updated values file:
cat > updated-values.yaml << EOF
replicaCount: 5

image:
  tag: "1.22.1"

service:
  type: ClusterIP
  port: 8080

resources:
  limits:
    cpu: 300m
    memory: 512Mi
  requests:
    cpu: 150m
    memory: 256Mi

serverBlock: |
  server {
    listen 8080;
    server_name _;
    location / {
      return 200 'Hello from UPGRADED NGINX - Version 2.0!\n';
      add_header Content-Type text/plain;
    }
    location /health {
      return 200 'OK';
      add_header Content-Type text/plain;
    }
  }
EOF
Upgrade the release:
helm upgrade my-custom-nginx bitnami/nginx -f updated-values.yaml
Check the upgrade status:
helm status my-custom-nginx
Verify the upgrade:
oc get pods -l app.kubernetes.io/instance=my-custom-nginx
curl http://my-custom-nginx-helm-lab.apps.your-cluster.com
curl http://my-custom-nginx-helm-lab.apps.your-cluster.com/health
Subtask 3.2: View Release History
Check the release history:
helm history my-custom-nginx
Get detailed information about a specific revision:
helm get all my-custom-nginx --revision 1
helm get all my-custom-nginx --revision 2
Subtask 3.3: Roll Back the Application
Sometimes you need to roll back to a previous version due to issues.

Roll back to the previous revision:
helm rollback my-custom-nginx 1
Verify the rollback:
helm history my-custom-nginx
helm status my-custom-nginx
Test the rolled-back application:
curl http://my-custom-nginx-helm-lab.apps.your-cluster.com
Check that the health endpoint is no longer available (should return 404):
curl http://my-custom-nginx-helm-lab.apps.your-cluster.com/health
Subtask 3.4: Advanced Helm Operations
Dry run an upgrade to see what would change:
helm upgrade my-custom-nginx bitnami/nginx -f updated-values.yaml --dry-run --debug
Upgrade with a specific timeout:
helm upgrade my-custom-nginx bitnami/nginx -f updated-values.yaml --timeout 300s
Force an upgrade if needed:
helm upgrade my-custom-nginx bitnami/nginx -f updated-values.yaml --force
Task 4: Helm Chart Management and Cleanup
Subtask 4.1: Chart Information and Dependencies
Show chart dependencies:
helm show chart bitnami/nginx
Download a chart for offline inspection:
helm pull bitnami/nginx --untar
ls -la nginx/
cat nginx/Chart.yaml
cat nginx/values.yaml
Subtask 4.2: Cleanup Resources
List all releases:
helm list
Uninstall releases:
helm uninstall my-nginx
helm uninstall my-custom-nginx
helm uninstall my-cli-nginx
Verify cleanup:
helm list
oc get pods
oc get services
Clean up the project:
oc delete project helm-lab
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Helm command not found

Solution: Verify Helm is installed with which helm
If not installed, download from https://helm.sh/docs/intro/install/
Issue 2: Permission denied errors

Solution: Ensure you have proper OpenShift permissions
Check with oc whoami and oc auth can-i create pods
Issue 3: Chart installation fails

Solution: Check resource quotas and limits
Use oc describe events to see detailed error messages
Issue 4: Application not accessible

Solution: Verify routes are created properly
Check service endpoints with oc get endpoints
Issue 5: Upgrade fails

Solution: Use helm rollback to return to a working state
Check logs with oc logs deployment/my-custom-nginx
Key Concepts Summary
Helm Terminology
Chart: A package of pre-configured Kubernetes resources
Release: An instance of a chart running in a cluster
Repository: A collection of charts
Values: Configuration parameters for a chart
Important Helm Commands
# Repository management
helm repo add <name> <url>
helm repo update
helm search repo <keyword>

# Installation and management
helm install <release-name> <chart>
helm upgrade <release-name> <chart>
helm rollback <release-name> <revision>
helm uninstall <release-name>

# Information commands
helm list
helm status <release-name>
helm history <release-name>
helm get values <release-name>
Conclusion
In this lab, you have successfully:

Installed Helm charts to deploy applications in OpenShift, learning how package management simplifies application deployment
Customized application configurations using values files and command-line overrides, demonstrating the flexibility of Helm charts
Performed application upgrades and rollbacks using Helm, showing how to manage application lifecycle safely
Why This Matters: Helm is the de facto package manager for Kubernetes and OpenShift, making it essential for:

Simplified Deployments: Complex applications can be deployed with a single command
Configuration Management: Easy customization without modifying original charts
Version Control: Track and manage application versions with rollback capabilities
Reusability: Share and reuse application configurations across environments
These skills are crucial for the Red Hat Certified OpenShift Administrator exam and real-world OpenShift operations, where Helm charts are commonly used to deploy and manage applications efficiently. You now have the foundation to work with Helm in production environments and can explore creating your own custom charts for specific application needs.
