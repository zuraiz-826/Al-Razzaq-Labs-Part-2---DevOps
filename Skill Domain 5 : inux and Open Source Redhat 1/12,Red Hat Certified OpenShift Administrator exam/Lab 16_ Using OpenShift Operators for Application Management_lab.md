Lab 16: Using OpenShift Operators for Application Management
Objectives
By the end of this lab, students will be able to:

Understand the concept and benefits of OpenShift Operators
Navigate and use the OpenShift Operator Hub
Install an Operator from the Operator Hub
Configure an Operator to manage application lifecycle
Deploy applications using Operators
Test automatic scaling capabilities using Operators
Monitor and manage Operator-deployed applications
Troubleshoot common Operator-related issues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Kubernetes concepts (pods, services, deployments)
Familiarity with OpenShift web console navigation
Knowledge of YAML configuration files
Basic command-line interface experience
Understanding of containerized applications
Completion of previous OpenShift labs or equivalent experience
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift cluster access. Simply click Start Lab to begin - no need to build your own virtual machine or install OpenShift locally.

Your lab environment includes:

OpenShift 4.12+ cluster with admin access
Pre-configured oc command-line tool
Web browser access to OpenShift console
All necessary permissions for Operator installation
What are OpenShift Operators?
OpenShift Operators are software extensions that use custom resources to manage applications and their components. They follow the Operator Pattern, which extends Kubernetes functionality to automate the deployment, scaling, and management of complex applications.

Key Benefits:

Automation: Reduces manual intervention in application management
Consistency: Ensures applications are deployed and managed uniformly
Self-healing: Automatically recovers from failures
Lifecycle Management: Handles updates, backups, and scaling automatically
Task 1: Install an Operator from the OpenShift Operator Hub
Subtask 1.1: Access the OpenShift Web Console
Open your web browser and navigate to the OpenShift console URL provided in your lab environment

Log in using the credentials provided:

Username: admin
Password: [provided in lab environment]
Verify your access by checking that you can see the OpenShift dashboard

Subtask 1.2: Navigate to the Operator Hub
Click on the Administrator perspective in the left sidebar (if not already selected)

Navigate to Operators → OperatorHub in the left navigation menu

Explore the Operator Hub interface:

Notice the search functionality
Observe different categories (Database, Monitoring, Security, etc.)
Review the available Operators
Subtask 1.3: Search and Select the PostgreSQL Operator
Use the search bar to find the PostgreSQL Operator:

Search term: "postgresql"
Select the "PostgreSQL Operator" from the search results

Look for the one provided by Dev4Ddevs.com
This is a community operator that's perfect for learning
Review the Operator details:

Read the description
Check the supported OpenShift versions
Review the capabilities (Basic Install, Seamless Upgrades, etc.)
Subtask 1.4: Install the PostgreSQL Operator
Click the "Install" button on the Operator details page

Configure the installation settings:

Installation Mode: All namespaces on the cluster
Installed Namespace: openshift-operators
Update Channel: alpha (or stable if available)
Approval Strategy: Automatic
Click "Install" to begin the installation process

Wait for the installation to complete:

Monitor the installation progress
Look for the "Succeeded" status
This typically takes 2-3 minutes
Subtask 1.5: Verify Operator Installation
Navigate to Operators → Installed Operators

Verify the PostgreSQL Operator appears in the list with status "Succeeded"

Check the Operator details:

Click on the PostgreSQL Operator name
Review the Overview tab
Note the Provided APIs section
Verify using the command line:

oc get operators
oc get csv -n openshift-operators | grep postgresql
Task 2: Configure the Operator to Manage Application Lifecycle
Subtask 2.1: Create a New Project for Testing
Create a new project using the web console:

Click Home → Projects
Click Create Project
Enter project details:
Name: postgresql-demo
Display Name: PostgreSQL Demo Project
Description: Testing PostgreSQL Operator functionality
Verify project creation using the command line:

oc new-project postgresql-demo
oc project postgresql-demo
Subtask 2.2: Deploy PostgreSQL Database Using the Operator
Navigate to your project:

Go to Home → Projects
Click on postgresql-demo
Access the PostgreSQL Operator:

Go to Operators → Installed Operators
Ensure you're in the postgresql-demo project
Click on PostgreSQL Operator
Create a PostgreSQL instance:

Click on the Database tab
Click Create Database
Use the following YAML configuration:
apiVersion: postgresql.dev4devs.com/v1alpha1
kind: Database
metadata:
  name: postgresql-sample
  namespace: postgresql-demo
spec:
  databaseCpu: "100m"
  databaseCpuLimit: "200m"
  databaseMemoryLimit: "512Mi"
  databaseMemoryRequest: "256Mi"
  databaseName: "sampledb"
  databaseNameKeyEnvVar: "POSTGRESQL_DATABASE"
  databasePassword: "postgres123"
  databasePasswordKeyEnvVar: "POSTGRESQL_PASSWORD"
  databaseStorageRequest: "1Gi"
  databaseUser: "postgresuser"
  databaseUserKeyEnvVar: "POSTGRESQL_USER"
  image: "centos/postgresql-12-centos7"
  size: 1
Click "Create" to deploy the database

Subtask 2.3: Verify Database Deployment
Check the deployment status in the web console:

Go to Workloads → Deployments
Look for the PostgreSQL deployment
Verify it shows "1 of 1 pods"
Verify using command line:

oc get databases
oc get pods
oc get services
oc get pvc
Check the database logs:

oc logs deployment/postgresql-sample
Subtask 2.4: Test Database Connectivity
Get the service information:

oc get svc postgresql-sample
Create a test pod to connect to the database:

oc run postgresql-client --image=centos/postgresql-12-centos7 --rm -it --restart=Never -- bash
Inside the test pod, connect to PostgreSQL:

psql -h postgresql-sample -U postgresuser -d sampledb
# When prompted, enter password: postgres123
Test basic database operations:

\l
CREATE TABLE test_table (id SERIAL PRIMARY KEY, name VARCHAR(50));
INSERT INTO test_table (name) VALUES ('OpenShift Operator Test');
SELECT * FROM test_table;
\q
Exit the test pod:

exit
Task 3: Test Automatic Scaling Using the Operator
Subtask 3.1: Install the Horizontal Pod Autoscaler Operator
Return to the Operator Hub:

Navigate to Operators → OperatorHub
Search for "Kubernetes HPA" or use a different scaling operator:

For this lab, we'll demonstrate scaling using the built-in OpenShift capabilities
Subtask 3.2: Configure Horizontal Pod Autoscaling
Create a resource quota for the project:

oc create quota postgresql-quota --hard=requests.cpu=1,requests.memory=2Gi,limits.cpu=2,limits.memory=4Gi
Create an HPA configuration for the PostgreSQL deployment:

oc autoscale deployment postgresql-sample --cpu-percent=70 --min=1 --max=3
Verify the HPA creation:

oc get hpa
oc describe hpa postgresql-sample
Subtask 3.3: Test Scaling by Modifying the Database Configuration
Edit the Database custom resource to increase resource requests:

oc edit database postgresql-sample
Modify the spec section:

spec:
  size: 2  # Change from 1 to 2
  databaseCpu: "200m"  # Increase CPU request
  databaseMemoryRequest: "512Mi"  # Increase memory request
Save and exit the editor

Monitor the scaling process:

oc get pods -w
Verify the scaling occurred:

oc get deployment postgresql-sample
oc describe database postgresql-sample
Subtask 3.4: Test Operator Self-Healing Capabilities
Delete one of the PostgreSQL pods to test self-healing:

oc get pods
oc delete pod [postgresql-pod-name]
Watch the Operator recreate the pod:

oc get pods -w
Verify data persistence by connecting to the new pod:

oc run postgresql-client --image=centos/postgresql-12-centos7 --rm -it --restart=Never -- bash
psql -h postgresql-sample -U postgresuser -d sampledb
SELECT * FROM test_table;
\q
exit
Subtask 3.5: Monitor Operator Metrics and Events
Check Operator events:

oc get events --sort-by=.metadata.creationTimestamp
View Operator logs:

oc logs -n openshift-operators deployment/postgresql-operator
Check resource utilization:

oc top pods
oc describe database postgresql-sample
Advanced Configuration and Management
Backup and Recovery Testing
Create a backup configuration (if supported by your Operator):

apiVersion: postgresql.dev4devs.com/v1alpha1
kind: Backup
metadata:
  name: postgresql-backup
  namespace: postgresql-demo
spec:
  database: postgresql-sample
  schedule: "0 2 * * *"  # Daily at 2 AM
Apply the backup configuration:

oc apply -f backup-config.yaml
Update and Upgrade Testing
Check for Operator updates:

Go to Operators → Installed Operators
Look for update notifications
Review update channels
Simulate an application update by modifying the database image:

oc patch database postgresql-sample -p '{"spec":{"image":"centos/postgresql-13-centos7"}}' --type=merge
Monitor the rolling update:

oc rollout status deployment/postgresql-sample
Troubleshooting Common Issues
Issue 1: Operator Installation Fails
Symptoms: Operator shows "Failed" status in Installed Operators

Solutions:

# Check Operator logs
oc logs -n openshift-operators deployment/postgresql-operator

# Verify cluster permissions
oc auth can-i create customresourcedefinitions --as=system:serviceaccount:openshift-operators:postgresql-operator

# Check resource quotas
oc describe quota -n openshift-operators
Issue 2: Database Pod Fails to Start
Symptoms: PostgreSQL pod in CrashLoopBackOff state

Solutions:

# Check pod logs
oc logs postgresql-sample-[pod-id]

# Verify persistent volume claims
oc get pvc
oc describe pvc postgresql-sample

# Check resource constraints
oc describe pod postgresql-sample-[pod-id]
Issue 3: Scaling Not Working
Symptoms: HPA not scaling pods despite load

Solutions:

# Verify metrics server is running
oc get pods -n openshift-monitoring

# Check HPA status
oc describe hpa postgresql-sample

# Verify resource requests are set
oc describe deployment postgresql-sample
Cleanup
Remove All Created Resources
Delete the Database instance:

oc delete database postgresql-sample
Delete the HPA:

oc delete hpa postgresql-sample
Delete the project:

oc delete project postgresql-demo
Uninstall the Operator (optional):

Go to Operators → Installed Operators
Click on PostgreSQL Operator
Click Actions → Uninstall Operator
Conclusion
In this comprehensive lab, you have successfully:

Installed an OpenShift Operator from the Operator Hub, learning how to navigate and select appropriate Operators for your needs
Configured the PostgreSQL Operator to manage database lifecycle, including deployment, scaling, and self-healing capabilities
Tested automatic scaling using Horizontal Pod Autoscaler and Operator-managed scaling features
Verified self-healing capabilities by simulating pod failures and observing automatic recovery
Explored advanced features like backup configuration and rolling updates
Learned troubleshooting techniques for common Operator-related issues
Why This Matters:

OpenShift Operators represent a paradigm shift in application management, moving from manual, script-based deployments to intelligent, automated lifecycle management. By mastering Operators, you gain the ability to:

Reduce operational overhead through automation
Ensure consistency across different environments
Implement best practices automatically
Scale applications intelligently based on demand
Maintain high availability through self-healing capabilities
This knowledge is essential for the Red Hat Certified OpenShift Administrator exam and real-world OpenShift deployments. Operators are becoming the standard way to deploy and manage complex applications in Kubernetes and OpenShift environments.

Next Steps:

Explore other Operators in the Operator Hub
Learn to create custom Operators using the Operator SDK
Practice with more complex multi-tier applications
Study Operator Lifecycle Manager (OLM) concepts
Implement Operators in production environments
The skills you've developed in this lab form the foundation for advanced OpenShift administration and will serve you well in managing enterprise-grade containerized applications.
