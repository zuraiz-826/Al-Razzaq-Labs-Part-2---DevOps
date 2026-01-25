Lab 1: Setting Up OpenShift Web Console
Objectives
By the end of this lab, you will be able to:

Successfully log in to the OpenShift Web Console
Navigate the OpenShift Web Console interface effectively
Explore and understand cluster overview information including nodes and pods
Locate and examine cluster resources through the console
Modify deployment resources using the web-based interface
Understand the relationship between different OpenShift components
Use the console to monitor cluster health and resource utilization
Prerequisites
Before starting this lab, you should have:

Basic understanding of containerization concepts (Docker, containers)
Familiarity with Kubernetes fundamentals (pods, deployments, services)
Basic knowledge of Linux command line operations
Understanding of web application concepts
Access to a web browser (Chrome, Firefox, or Safari recommended)
Basic networking knowledge (IP addresses, ports, URLs)
Note: Al Nafi provides ready-to-use Linux-based cloud machines with OpenShift pre-installed. Simply click Start Lab to begin - no need to build your own virtual machine or install OpenShift manually.

Lab Environment Setup
Your Al Nafi cloud machine comes pre-configured with:

OpenShift Container Platform (latest stable version)
All necessary networking configurations
Sample applications for testing
Administrative access credentials
Task 1: Log in to the OpenShift Web Console
Subtask 1.1: Access the OpenShift Web Console URL
Open your web browser and navigate to the OpenShift console URL provided in your lab environment

The URL will typically be in the format: https://console-openshift-console.apps.cluster-name.domain
Your lab instructor will provide the specific URL for your environment
Accept the security certificate if prompted

Click Advanced if you see a security warning
Click Proceed to [URL] to continue
This is normal for lab environments with self-signed certificates
Subtask 1.2: Authenticate to the Console
Select authentication method

You will see the OpenShift login page
Choose the appropriate authentication provider (typically htpasswd for lab environments)
Enter your credentials

Username: Use the credentials provided by your lab instructor
Password: Use the password provided by your lab instructor
Click Log in
Verify successful login

You should see the OpenShift Web Console dashboard
The interface will display the main navigation menu on the left side
You should see your username in the top-right corner
Subtask 1.3: Familiarize Yourself with the Console Layout
Examine the main navigation menu (left sidebar):

Home: Dashboard and overview information
Workloads: Deployments, pods, and other workload resources
Networking: Services, routes, and network policies
Storage: Persistent volumes and storage classes
Administration: Cluster settings and administrative functions
Identify the top navigation bar:

Project selector: Dropdown to switch between projects/namespaces
Help menu: Documentation and support resources
User menu: Account settings and logout option
Note the main content area:

This is where detailed information and forms will be displayed
Currently showing the cluster overview dashboard
Task 2: Explore Cluster Overview Including Nodes and Pods
Subtask 2.1: Navigate to Cluster Overview
Access the cluster overview

Click on Home in the left navigation menu
Select Overview if not already selected
This provides a high-level view of your cluster status
Review cluster status information

Cluster status: Shows overall health (Healthy, Warning, Error)
Resource utilization: CPU, memory, and storage usage graphs
Recent events: Latest cluster activities and alerts
Subtask 2.2: Examine Cluster Nodes
Navigate to the Nodes section

Click on Compute in the left navigation menu
Select Nodes from the submenu
This displays all nodes in your OpenShift cluster
Analyze node information

Node names: Identify master and worker nodes
Status: Verify all nodes show Ready status
Roles: Note which nodes are masters, workers, or both
Version: Check the OpenShift version running on each node
Examine individual node details

Click on any node name to view detailed information
Review the Overview tab for:
Node conditions and status
Resource capacity (CPU, memory, storage)
Operating system information
Container runtime details
Check node resource utilization

Click on the Metrics tab
Observe CPU usage graphs over time
Review memory utilization patterns
Note network and storage I/O statistics
Subtask 2.3: Explore Pod Information
Navigate to Pods view

Click on Workloads in the left navigation menu
Select Pods from the submenu
This shows all pods across all projects you have access to
Filter pods by project

Use the Project dropdown at the top
Select All Projects to see system pods
Try selecting specific projects to filter the view
Examine pod details

Status column: Look for Running, Pending, or Failed pods
Ready column: Shows containers ready vs total containers
Restarts: Indicates pod stability
Age: Shows how long pods have been running
Investigate a specific pod

Click on any running pod name
Review the Details tab:
Pod phase and conditions
Container information
Resource requests and limits
Node assignment
Check pod logs

Click on the Logs tab
Select different containers if the pod has multiple containers
Use the log filtering options to search for specific entries
Note the timestamp format and log levels
Subtask 2.4: Understand Resource Relationships
Explore the topology view

Click on Topology under the Developer perspective
Switch to Developer perspective using the dropdown in the top-left
This provides a visual representation of application components
Examine resource connections

Observe how deployments connect to services
See how routes expose services externally
Notice the relationship between deployments and pods
Task 3: Modify a Deployment Resource Using the Console
Subtask 3.1: Locate an Existing Deployment
Switch to Administrator perspective

Click on the perspective switcher in the top-left corner
Select Administrator if not already selected
Navigate to Deployments

Click on Workloads in the left navigation
Select Deployments from the submenu
Choose a project with deployments

Use the project selector to choose a project with existing deployments
If no deployments exist, create a simple one using the following steps:
# Create a new project (if needed)
oc new-project lab-demo

# Create a simple deployment
oc create deployment nginx-demo --image=nginx:latest
Select a deployment to modify
Click on the deployment name to open its details
Review the current configuration in the Details tab
Subtask 3.2: Scale the Deployment
Access scaling options

In the deployment details page, locate the Replica count section
Note the current number of replicas
Modify replica count

Click on the Actions dropdown menu
Select Edit Deployment
Alternatively, click the pencil icon next to the replica count
Update the replica count

Change the replica count to a different number (e.g., from 1 to 3)
Click Save to apply the changes
Verify the scaling operation

Watch the Pods section update in real-time
Navigate to Workloads > Pods to see new pods being created
Confirm all pods reach Running status
Subtask 3.3: Modify Environment Variables
Edit deployment configuration

Return to your deployment details page
Click Actions > Edit Deployment
Navigate to environment variables

Scroll down to the Environment Variables section
Click Add Environment Variable
Add a new environment variable

Name: DEMO_ENV
Value: production
Click Save
Verify the update

Watch for the deployment to trigger a new rollout
Check that pods are recreated with the new environment variable
Click on a pod and verify the environment variable in the Environment tab
Subtask 3.4: Update Resource Limits
Access resource configuration

In the deployment details, click Actions > Edit Deployment
Scroll to the Resource Limits section
Set CPU and memory limits

CPU Request: 100m (100 millicores)
CPU Limit: 200m (200 millicores)
Memory Request: 128Mi (128 MiB)
Memory Limit: 256Mi (256 MiB)
Apply the changes

Click Save to update the deployment
Monitor the rollout progress in the deployment details
Verify resource limits

Navigate to a pod created after the update
Check the Details tab for the new resource limits
Confirm the limits are applied correctly
Subtask 3.5: Monitor Deployment History
Access revision history

In the deployment details page, click on the Revision History tab
Review the list of deployment revisions
Examine revision details

Click on different revision numbers
Compare the changes between revisions
Note the timestamps and change causes
Practice rollback (optional)

Click Actions > Rollback
Select a previous revision
Confirm the rollback operation
Observe how the deployment reverts to the previous configuration
Troubleshooting Common Issues
Issue 1: Cannot Access Web Console
Symptoms: Browser shows connection timeout or certificate errors

Solutions:

Verify the console URL is correct
Check network connectivity to the cluster
Accept security certificates for lab environments
Try a different web browser
Clear browser cache and cookies
Issue 2: Authentication Failures
Symptoms: Login page shows invalid credentials error

Solutions:

Verify username and password with lab instructor
Check if the authentication provider is correct
Ensure caps lock is not enabled
Try logging out completely and logging back in
Issue 3: Missing Resources or Empty Views
Symptoms: No deployments, pods, or other resources visible

Solutions:

Check the selected project/namespace
Verify you have appropriate permissions
Switch between Administrator and Developer perspectives
Refresh the browser page
Issue 4: Deployment Modifications Not Taking Effect
Symptoms: Changes to deployments don't trigger updates

Solutions:

Wait for the rollout to complete (may take a few minutes)
Check the Events tab for error messages
Verify resource quotas are not exceeded
Ensure the cluster has sufficient resources
Key Concepts Summary
OpenShift Web Console Components
Administrator Perspective: Cluster-wide management and monitoring
Developer Perspective: Application-focused development tools
Project/Namespace: Logical grouping of resources
Workloads: Applications and their components (deployments, pods)
Resource Hierarchy
Cluster: The entire OpenShift environment
Nodes: Physical or virtual machines running containers
Projects: Namespaces for organizing resources
Deployments: Desired state for application instances
Pods: Running instances of containers
Management Operations
Scaling: Adjusting the number of running instances
Rolling Updates: Updating applications without downtime
Resource Management: Setting CPU and memory limits
Monitoring: Tracking application and cluster health
Conclusion
In this lab, you have successfully:

Logged into the OpenShift Web Console and familiarized yourself with its interface
Explored cluster overview information including nodes, pods, and their relationships
Modified deployment resources through scaling, environment variables, and resource limits
Learned to navigate between different perspectives and resource views
Gained hands-on experience with the primary management interface for OpenShift
Why This Matters
The OpenShift Web Console is the primary interface for managing containerized applications in enterprise environments. Understanding how to navigate and use this console effectively is crucial for:

Day-to-day operations: Managing applications and troubleshooting issues
Resource optimization: Monitoring and adjusting resource allocation
Application lifecycle management: Deploying, updating, and scaling applications
Collaboration: Providing a user-friendly interface for team members with different technical backgrounds
Next Steps
With this foundation in place, you are now prepared to:

Explore more advanced OpenShift features through the console
Learn command-line operations using the oc CLI tool
Implement CI/CD pipelines and automated deployments
Configure advanced networking and security policies
Prepare for the Red Hat Certified OpenShift Administrator exam
The skills you have developed in this lab form the foundation for effective OpenShift cluster administration and will be essential as you progress through more advanced OpenShift topics and real-world scenarios.
