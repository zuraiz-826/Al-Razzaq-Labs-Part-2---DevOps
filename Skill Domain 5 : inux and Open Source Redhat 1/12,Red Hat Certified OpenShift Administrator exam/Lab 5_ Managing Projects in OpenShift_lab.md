Lab 5: Managing Projects in OpenShift
Objectives
By the end of this lab, you will be able to:

Create and manage OpenShift projects using the command line interface
Configure resource quotas and limits for projects
Set up role-based access control (RBAC) for project permissions
Monitor project resource usage
Properly delete projects and clean up associated resources
Understand the relationship between OpenShift projects and Kubernetes namespaces
Prerequisites
Before starting this lab, you should have:

Basic understanding of containerization concepts
Familiarity with Linux command line operations
Knowledge of YAML file structure and syntax
Understanding of Kubernetes fundamentals (pods, services, deployments)
Access to an OpenShift cluster with cluster-admin privileges
OpenShift CLI (oc) tool installed and configured
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift access. Simply click Start Lab to begin - no need to build your own virtual machine or install additional software.

Your lab environment includes:

Red Hat Enterprise Linux 8 or 9
OpenShift CLI (oc) pre-installed
Access to an OpenShift 4.x cluster
Administrative privileges for project management
Task 1: Create a Project Using oc new-project
Subtask 1.1: Verify OpenShift Connection
First, let's verify that you're connected to the OpenShift cluster and check your current context.

# Check OpenShift cluster connection
oc whoami

# Display cluster information
oc cluster-info

# List current projects you have access to
oc get projects
Subtask 1.2: Create a New Project
Now we'll create a new project called development-lab with a description and display name.

# Create a new project with description and display name
oc new-project development-lab \
  --description="Development environment for Lab 5" \
  --display-name="Development Lab Project"
Expected Output:

Now using project "development-lab" on server "https://api.cluster.example.com:6443".

You can add applications to this project with the 'oc new-app' command. For example, try:

    oc new-app rails-postgresql-example

to build a new example application in Ruby. Or use kubectl to deploy a simple Kubernetes application:

    kubectl create deployment hello-node --image=k8s.gcr.io/serve_hostname
Subtask 1.3: Verify Project Creation
Let's verify that our project was created successfully and examine its properties.

# Check current project context
oc project

# Get detailed information about the project
oc describe project development-lab

# List all projects to see our new project
oc get projects
Subtask 1.4: Explore Project Resources
Examine the default resources created with the new project.

# List all resources in the current project
oc get all

# Check for default service accounts
oc get serviceaccounts

# View default role bindings
oc get rolebindings
Task 2: Set Resource Limits and Quotas
Subtask 2.1: Create Resource Quota
Resource quotas help control resource consumption within a project. Let's create a comprehensive resource quota.

First, create a YAML file for the resource quota:

# Create resource quota configuration file
cat > resource-quota.yaml << 'EOF'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: development-quota
  namespace: development-lab
spec:
  hard:
    # Compute resources
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    
    # Storage resources
    requests.storage: 10Gi
    persistentvolumeclaims: "5"
    
    # Object count quotas
    pods: "10"
    services: "5"
    secrets: "10"
    configmaps: "10"
    replicationcontrollers: "5"
    
    # OpenShift specific resources
    openshift.io/imagestreams: "5"
    openshift.io/imagestreamtags: "10"
EOF
Apply the resource quota to the project:

# Apply the resource quota
oc apply -f resource-quota.yaml

# Verify the resource quota was created
oc get resourcequota

# Get detailed information about the quota
oc describe resourcequota development-quota
Subtask 2.2: Create Limit Range
Limit ranges set default and maximum resource limits for individual objects within the project.

# Create limit range configuration file
cat > limit-range.yaml << 'EOF'
apiVersion: v1
kind: LimitRange
metadata:
  name: development-limits
  namespace: development-lab
spec:
  limits:
  # Container limits
  - type: Container
    default:
      cpu: 200m
      memory: 256Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    max:
      cpu: 500m
      memory: 512Mi
    min:
      cpu: 50m
      memory: 64Mi
      
  # Pod limits
  - type: Pod
    max:
      cpu: "1"
      memory: 1Gi
    min:
      cpu: 100m
      memory: 128Mi
      
  # Persistent Volume Claim limits
  - type: PersistentVolumeClaim
    max:
      storage: 5Gi
    min:
      storage: 1Gi
EOF
Apply the limit range:

# Apply the limit range
oc apply -f limit-range.yaml

# Verify the limit range was created
oc get limitrange

# Get detailed information about the limit range
oc describe limitrange development-limits
Subtask 2.3: Test Resource Limits
Let's create a test deployment to see how our resource limits work.

# Create a test deployment
cat > test-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  namespace: development-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: test-container
        image: registry.access.redhat.com/ubi8/ubi-minimal:latest
        command: ["/bin/sh"]
        args: ["-c", "while true; do echo 'Hello from test app'; sleep 30; done"]
        # Note: No resource requests/limits specified - will use defaults from LimitRange
EOF
Deploy and examine the test application:

# Apply the test deployment
oc apply -f test-deployment.yaml

# Check the deployment status
oc get deployments

# Examine the pods to see applied resource limits
oc get pods

# Get detailed information about a pod to see resource limits
POD_NAME=$(oc get pods -l app=test-app -o jsonpath='{.items[0].metadata.name}')
oc describe pod $POD_NAME
Subtask 2.4: Monitor Resource Usage
Check how resources are being consumed against our quotas.

# Check current resource quota usage
oc describe resourcequota development-quota

# Get resource usage summary
oc top pods

# Check project resource consumption
oc adm top pods -n development-lab
Task 3: Configure Project Permissions
Subtask 3.1: Create Additional Users (Simulation)
For this lab, we'll work with service accounts to simulate different user roles.

# Create a developer service account
oc create serviceaccount developer-sa

# Create a viewer service account
oc create serviceaccount viewer-sa

# List service accounts
oc get serviceaccounts
Subtask 3.2: Assign Role-Based Permissions
Configure different permission levels for our service accounts.

# Grant edit permissions to developer service account
oc policy add-role-to-user edit system:serviceaccount:development-lab:developer-sa

# Grant view permissions to viewer service account
oc policy add-role-to-user view system:serviceaccount:development-lab:viewer-sa

# List role bindings in the project
oc get rolebindings

# Get detailed information about role bindings
oc describe rolebinding
Subtask 3.3: Test Permissions
Let's verify that our permission assignments work correctly.

# Check what the developer service account can do
oc policy can-i create pods --as=system:serviceaccount:development-lab:developer-sa

# Check what the viewer service account can do
oc policy can-i create pods --as=system:serviceaccount:development-lab:viewer-sa
oc policy can-i get pods --as=system:serviceaccount:development-lab:viewer-sa

# List all permissions for developer service account
oc policy can-i --list --as=system:serviceaccount:development-lab:developer-sa
Task 4: Advanced Project Management
Subtask 4.1: Create Network Policies
Implement network security within the project.

# Create a network policy to control traffic
cat > network-policy.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: development-network-policy
  namespace: development-lab
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: development-lab
    - podSelector: {}
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: development-lab
    - podSelector: {}
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
EOF
Apply the network policy:

# Apply the network policy
oc apply -f network-policy.yaml

# Verify network policy creation
oc get networkpolicy

# Describe the network policy
oc describe networkpolicy development-network-policy
Subtask 4.2: Configure Project Annotations and Labels
Add metadata to help organize and manage the project.

# Add labels to the project
oc label namespace development-lab environment=development
oc label namespace development-lab team=backend
oc label namespace development-lab cost-center=engineering

# Add annotations to the project
oc annotate namespace development-lab contact="admin@company.com"
oc annotate namespace development-lab purpose="Development and testing environment"

# View project with labels and annotations
oc get namespace development-lab --show-labels
oc describe namespace development-lab
Task 5: Delete Project and Clean Up Resources
Subtask 5.1: Backup Important Resources (Optional)
Before deleting the project, let's backup any important configurations.

# Create a backup directory
mkdir -p ~/project-backup/development-lab

# Export project configuration
oc get project development-lab -o yaml > ~/project-backup/development-lab/project.yaml

# Export resource quota
oc get resourcequota development-quota -o yaml > ~/project-backup/development-lab/resource-quota.yaml

# Export limit range
oc get limitrange development-limits -o yaml > ~/project-backup/development-lab/limit-range.yaml

# Export network policy
oc get networkpolicy development-network-policy -o yaml > ~/project-backup/development-lab/network-policy.yaml

# List backup files
ls -la ~/project-backup/development-lab/
Subtask 5.2: Verify Resources Before Deletion
Check all resources that will be deleted with the project.

# List all resources in the project
oc get all -n development-lab

# Check for persistent volume claims
oc get pvc -n development-lab

# Check for secrets and config maps
oc get secrets,configmaps -n development-lab

# Check for service accounts and role bindings
oc get serviceaccounts,rolebindings -n development-lab
Subtask 5.3: Delete the Project
Now we'll delete the project and all its resources.

# Delete the project (this will delete all resources within it)
oc delete project development-lab
Note: This command will delete the project and ALL resources within it. The deletion process may take a few minutes.

Subtask 5.4: Verify Project Deletion
Confirm that the project and its resources have been completely removed.

# Check if the project still exists
oc get projects | grep development-lab

# Try to switch to the deleted project (should fail)
oc project development-lab

# Verify no resources remain
oc get all -n development-lab
Subtask 5.5: Clean Up Local Files
Remove the configuration files we created during the lab.

# Remove configuration files
rm -f resource-quota.yaml
rm -f limit-range.yaml
rm -f test-deployment.yaml
rm -f network-policy.yaml

# Optionally remove backup directory
# rm -rf ~/project-backup/development-lab
Troubleshooting Common Issues
Issue 1: Project Creation Fails
Problem: oc new-project command fails with permission errors.

Solution:

# Check your current permissions
oc whoami
oc auth can-i create projects

# If you don't have permissions, contact your cluster administrator
Issue 2: Resource Quota Not Applied
Problem: Pods are created without respecting resource quotas.

Solution:

# Verify resource quota exists and is active
oc get resourcequota
oc describe resourcequota development-quota

# Check if limit range is properly configured
oc get limitrange
oc describe limitrange development-limits
Issue 3: Project Deletion Hangs
Problem: Project deletion takes too long or appears stuck.

Solution:

# Check project status
oc get project development-lab -o yaml

# Look for finalizers that might be blocking deletion
oc get project development-lab -o jsonpath='{.metadata.finalizers}'

# Force deletion if necessary (use with caution)
oc patch project development-lab -p '{"metadata":{"finalizers":null}}' --type=merge
Issue 4: Network Policy Blocks Required Traffic
Problem: Applications can't communicate after applying network policy.

Solution:

# Check network policy configuration
oc describe networkpolicy development-network-policy

# Temporarily delete network policy for testing
oc delete networkpolicy development-network-policy

# Recreate with more permissive rules if needed
Best Practices for Project Management
Resource Management
Always set appropriate resource quotas to prevent resource exhaustion
Use limit ranges to ensure consistent resource allocation
Monitor resource usage regularly
Plan for growth when setting quotas
Security
Follow the principle of least privilege when assigning permissions
Use network policies to control traffic flow
Regularly audit role bindings and permissions
Keep service accounts to a minimum
Organization
Use meaningful project names and descriptions
Apply consistent labeling and annotation strategies
Document project purposes and ownership
Implement naming conventions
Cleanup
Regularly review and clean up unused projects
Backup important configurations before deletion
Verify complete resource cleanup after project deletion
Maintain an inventory of active projects
Conclusion
In this lab, you have successfully learned how to manage OpenShift projects comprehensively. You accomplished the following key tasks:

Project Creation and Management:

Created a new OpenShift project with proper naming and documentation
Explored the relationship between OpenShift projects and Kubernetes namespaces
Understood the default resources created with new projects
Resource Control and Governance:

Implemented resource quotas to control compute, storage, and object consumption
Configured limit ranges to set default and maximum resource limits
Tested resource limits with real deployments
Monitored resource usage against defined quotas
Security and Access Control:

Set up role-based access control (RBAC) with different permission levels
Created and managed service accounts for different user roles
Implemented network policies for traffic control
Verified permission assignments and access controls
Advanced Project Features:

Applied labels and annotations for better project organization
Configured network security policies
Implemented backup strategies for project configurations
Learned troubleshooting techniques for common issues
Proper Cleanup Procedures:

Backed up important project configurations
Safely deleted projects and verified complete resource cleanup
Understood the implications of project deletion
Cleaned up local configuration files
Why This Matters: These skills are essential for OpenShift administrators because proper project management ensures:

Resource Efficiency: Prevents resource waste and ensures fair allocation
Security: Maintains proper access controls and network isolation
Scalability: Enables organized growth of applications and teams
Compliance: Helps meet organizational governance requirements
Cost Control: Manages resource consumption and associated costs
This knowledge directly applies to the Red Hat Certified OpenShift Administrator exam and real-world OpenShift administration scenarios. You now have the foundation to manage multi-tenant OpenShift environments effectively, implement proper resource governance, and maintain secure, well-organized container platforms.

The hands-on experience gained in this lab will help you confidently manage OpenShift projects in production environments, ensuring both security and efficiency in your container orchestration platform.
