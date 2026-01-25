Lab 18: Automating Cluster Updates
Objectives
By the end of this lab, students will be able to:

• Understand the OpenShift cluster upgrade process and best practices • Perform a controlled upgrade to a new OpenShift version using the web console and CLI • Monitor upgrade progress and identify potential issues during the process • Validate cluster health and functionality after completing an upgrade • Implement automated upgrade strategies for production environments • Troubleshoot common upgrade-related problems

Prerequisites
Before starting this lab, students should have:

• Basic understanding of OpenShift cluster architecture and components • Familiarity with OpenShift web console navigation • Experience with OpenShift CLI (oc) commands • Knowledge of Kubernetes concepts including nodes, pods, and deployments • Understanding of cluster operators and their roles • Access to cluster-admin privileges in an OpenShift environment

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift clusters already deployed. Simply click Start Lab to access your environment - no need to build your own VM or install OpenShift from scratch.

Your lab environment includes: • OpenShift 4.12 cluster with 3 master nodes and 2 worker nodes • Pre-installed OpenShift CLI tools • Web console access with cluster-admin privileges • Sample applications for testing upgrade functionality

Task 1: Prepare for Cluster Upgrade
Subtask 1.1: Verify Current Cluster Status
First, let's examine the current state of our OpenShift cluster before beginning the upgrade process.

Access the OpenShift CLI
Open your terminal and verify CLI access:

# Check current cluster version
oc version

# Verify cluster status
oc get clusterversion
Review Cluster Operators
Check that all cluster operators are in a healthy state:

# List all cluster operators and their status
oc get clusteroperators

# Get detailed information about any degraded operators
oc get clusteroperators -o wide
Check Node Health
Ensure all nodes are ready and healthy:

# List all nodes with their status
oc get nodes

# Get detailed node information
oc describe nodes
Subtask 1.2: Create Pre-Upgrade Backup
Before proceeding with the upgrade, create a backup of critical cluster configuration.

Backup etcd Data
# Create a backup directory
mkdir -p ~/cluster-backup

# Export cluster configuration
oc get all --all-namespaces -o yaml > ~/cluster-backup/all-resources-backup.yaml

# Backup cluster operators configuration
oc get clusteroperators -o yaml > ~/cluster-backup/clusteroperators-backup.yaml
Document Current Application State
# List all running applications
oc get pods --all-namespaces > ~/cluster-backup/pods-status.txt

# Export persistent volume information
oc get pv -o yaml > ~/cluster-backup/persistent-volumes-backup.yaml
Subtask 1.3: Deploy Test Application
Deploy a sample application to validate functionality after the upgrade.

Create Test Namespace
# Create a new project for testing
oc new-project upgrade-test

# Switch to the test project
oc project upgrade-test
Deploy Sample Application
# Create a simple web application
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  namespace: upgrade-test
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
      - name: test-app
        image: registry.redhat.io/ubi8/httpd-24:latest
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: test-app-service
  namespace: upgrade-test
spec:
  selector:
    app: test-app
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
EOF
Verify Application Deployment
# Check deployment status
oc get deployments -n upgrade-test

# Verify pods are running
oc get pods -n upgrade-test

# Test application connectivity
oc get svc -n upgrade-test
Task 2: Perform OpenShift Cluster Upgrade
Subtask 2.1: Check Available Updates
Before initiating the upgrade, identify available OpenShift versions.

Using OpenShift CLI
# Check available updates
oc adm upgrade

# Get detailed upgrade information
oc get clusterversion -o yaml
Using Web Console
Navigate to the OpenShift web console: • Go to Administration → Cluster Settings • Click on the Details tab • Review the Update Status section • Note available update channels and versions

Subtask 2.2: Configure Update Channel
Set the appropriate update channel for your cluster upgrade.

View Current Update Channel
# Check current channel configuration
oc get clusterversion version -o jsonpath='{.spec.channel}'
Set Update Channel (if needed)
# Update to stable channel for production upgrades
oc patch clusterversion version --type merge --patch '{"spec":{"channel":"stable-4.13"}}'

# Verify channel update
oc get clusterversion version -o yaml | grep channel
Subtask 2.3: Initiate Cluster Upgrade
Now we'll start the actual upgrade process.

Start Upgrade via CLI
# Initiate upgrade to the latest available version
oc adm upgrade --to-latest

# Alternative: Upgrade to specific version
# oc adm upgrade --to=4.13.x
Start Upgrade via Web Console
Alternative method using the web console: • Navigate to Administration → Cluster Settings • Click Update button • Select the target version • Click Update to confirm

Verify Upgrade Initiation
# Check upgrade status
oc get clusterversion

# Monitor upgrade progress
oc adm upgrade status
Task 3: Monitor Upgrade Process
Subtask 3.1: Monitor Using CLI Tools
Track the upgrade progress using command-line tools.

Create Monitoring Script
# Create a monitoring script
cat << 'EOF' > ~/monitor-upgrade.sh
#!/bin/bash

echo "OpenShift Cluster Upgrade Monitor"
echo "================================="

while true; do
    clear
    echo "Current Time: $(date)"
    echo ""
    
    echo "Cluster Version Status:"
    oc get clusterversion
    echo ""
    
    echo "Cluster Operators Status:"
    oc get clusteroperators | grep -E "(AVAILABLE|PROGRESSING|DEGRADED|False|True)"
    echo ""
    
    echo "Node Status:"
    oc get nodes
    echo ""
    
    echo "Upgrade Progress:"
    oc adm upgrade status
    echo ""
    
    sleep 30
done
EOF

# Make script executable
chmod +x ~/monitor-upgrade.sh
Run Monitoring Script
# Execute monitoring script
~/monitor-upgrade.sh
Subtask 3.2: Monitor Using Web Console
Use the OpenShift web console to track upgrade progress.

Access Cluster Status Dashboard
• Navigate to Administration → Cluster Settings • Monitor the Update Status section • Observe the progress bar and current phase

Monitor Cluster Operators
• Go to Administration → Cluster Operators • Watch for operators showing Progressing status • Note any operators that become Degraded

Check Node Updates
• Navigate to Compute → Nodes • Monitor nodes as they restart during the upgrade • Verify nodes return to Ready status

Subtask 3.3: Monitor Critical Components
Keep track of essential cluster components during the upgrade.

Monitor Master Node Updates
# Watch master node status
watch "oc get nodes -l node-role.kubernetes.io/master"

# Check master node conditions
oc describe nodes -l node-role.kubernetes.io/master | grep -A 5 Conditions
Monitor Worker Node Updates
# Watch worker node status
watch "oc get nodes -l node-role.kubernetes.io/worker"

# Check for node cordoning during updates
oc get nodes -o wide
Monitor etcd Health
# Check etcd cluster status
oc get pods -n openshift-etcd | grep etcd

# Verify etcd operator status
oc get clusteroperator etcd
Task 4: Validate Post-Upgrade Cluster Health
Subtask 4.1: Verify Cluster Version
Confirm the upgrade completed successfully.

Check Updated Version
# Verify new cluster version
oc version

# Check cluster version details
oc get clusterversion -o yaml
Validate Update History
# Review upgrade history
oc get clusterversion -o jsonpath='{.status.history}' | jq '.'

# Check for any failed updates
oc describe clusterversion
Subtask 4.2: Validate Cluster Operators
Ensure all cluster operators are functioning correctly after the upgrade.

Check Operator Status
# List all cluster operators
oc get clusteroperators

# Identify any degraded operators
oc get clusteroperators | grep -v "True.*False.*False"
Investigate Operator Issues
# Get detailed information about problematic operators
oc describe clusteroperator <operator-name>

# Check operator logs if needed
oc logs -n openshift-<operator-namespace> deployment/<operator-deployment>
Subtask 4.3: Validate Node Health
Verify all nodes are healthy and ready after the upgrade.

Check Node Status
# Verify all nodes are ready
oc get nodes

# Check node resource usage
oc top nodes
Validate Node Configuration
# Check kubelet version on nodes
oc get nodes -o wide

# Verify node conditions
oc describe nodes | grep -A 10 Conditions
Subtask 4.4: Test Application Functionality
Validate that applications continue to function correctly after the upgrade.

Check Test Application
# Verify test application is still running
oc get pods -n upgrade-test

# Check application logs
oc logs -n upgrade-test deployment/test-app
Test Application Connectivity
# Create a test route
oc expose service test-app-service -n upgrade-test

# Get route URL
oc get route -n upgrade-test

# Test application response
curl $(oc get route test-app-service -n upgrade-test -o jsonpath='{.spec.host}')
Deploy New Test Application
# Deploy another application to test cluster functionality
oc new-app --name=post-upgrade-test \
  --image=registry.redhat.io/ubi8/nginx-120:latest \
  -n upgrade-test

# Verify deployment
oc get pods -n upgrade-test -l app=post-upgrade-test
Task 5: Implement Automated Update Strategies
Subtask 5.1: Configure Automatic Updates
Set up automated update policies for future upgrades.

Create Update Policy
# Create automatic update configuration
cat << EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: ClusterVersion
metadata:
  name: version
spec:
  channel: stable-4.13
  upstream: https://api.openshift.com/api/upgrades_info/v1/graph
  capabilities:
    baselineCapabilitySet: v4.13
    additionalEnabledCapabilities: []
  overrides: []
EOF
Configure Update Windows
# Create a maintenance window configuration
cat << EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-update-policy
  namespace: openshift-config
data:
  policy.yaml: |
    updatePolicy:
      automatic: true
      maintenanceWindow:
        start: "02:00"
        duration: "4h"
        timezone: "America/New_York"
        days: ["Saturday", "Sunday"]
EOF
Subtask 5.2: Create Update Monitoring
Set up monitoring and alerting for cluster updates.

Create Update Status Script
# Create automated status checking script
cat << 'EOF' > ~/check-update-status.sh
#!/bin/bash

# Check if update is in progress
UPDATE_STATUS=$(oc get clusterversion -o jsonpath='{.status.conditions[?(@.type=="Progressing")].status}')

if [ "$UPDATE_STATUS" = "True" ]; then
    echo "Cluster update in progress"
    oc adm upgrade status
    
    # Check for any failed operators
    FAILED_OPERATORS=$(oc get clusteroperators | grep -v "True.*False.*False" | wc -l)
    if [ $FAILED_OPERATORS -gt 1 ]; then
        echo "WARNING: Some operators are not healthy"
        oc get clusteroperators | grep -v "True.*False.*False"
    fi
else
    echo "No cluster update in progress"
    echo "Current version: $(oc get clusterversion -o jsonpath='{.status.desired.version}')"
fi
EOF

chmod +x ~/check-update-status.sh
Set Up Automated Checks
# Add to crontab for regular monitoring
echo "0 */2 * * * ~/check-update-status.sh >> ~/update-monitor.log 2>&1" | crontab -

# Verify crontab entry
crontab -l
Troubleshooting Common Issues
Issue 1: Stuck Cluster Operators
If cluster operators become stuck during upgrade:

# Identify stuck operators
oc get clusteroperators | grep -E "False|Unknown"

# Force operator reconciliation
oc patch clusteroperator <operator-name> --type merge --patch '{"metadata":{"annotations":{"release.openshift.io/force-reconcile":"true"}}}'

# Restart operator pods if necessary
oc delete pods -n openshift-<operator-namespace> -l app=<operator-name>
Issue 2: Node Update Failures
If nodes fail to update properly:

# Check node conditions
oc describe node <node-name>

# Drain and uncordon node manually
oc adm drain <node-name> --ignore-daemonsets --delete-emptydir-data
oc adm uncordon <node-name>

# Restart node if necessary (in cloud environments)
oc debug node/<node-name> -- chroot /host systemctl reboot
Issue 3: Application Connectivity Issues
If applications lose connectivity after upgrade:

# Check service endpoints
oc get endpoints -n <namespace>

# Verify network policies
oc get networkpolicies -n <namespace>

# Restart application pods
oc rollout restart deployment/<deployment-name> -n <namespace>
Cleanup
After completing the lab, clean up the test resources:

# Delete test project
oc delete project upgrade-test

# Remove monitoring scripts
rm ~/monitor-upgrade.sh ~/check-update-status.sh

# Remove backup files (optional)
rm -rf ~/cluster-backup
Conclusion
In this lab, you have successfully:

• Performed a complete OpenShift cluster upgrade from version 4.12 to 4.13, gaining hands-on experience with the upgrade process that is critical for maintaining production OpenShift environments

• Mastered monitoring techniques using both CLI tools and the web console to track upgrade progress, identify issues, and ensure cluster health throughout the update process

• Validated cluster functionality after the upgrade by checking cluster operators, node health, and application connectivity, ensuring that the upgrade didn't impact existing workloads

• Implemented automated update strategies including update policies and monitoring scripts that can be used in production environments to streamline future upgrades

• Developed troubleshooting skills for common upgrade scenarios, preparing you to handle real-world upgrade challenges in enterprise OpenShift deployments

This knowledge is essential for OpenShift administrators managing production clusters, as regular updates are crucial for security, stability, and access to new features. The automated monitoring and update strategies you've learned will help ensure minimal downtime and smooth upgrade processes in enterprise environments. These skills directly support the Red Hat OpenShift Administration III certification objectives and prepare you for scaling deployments in enterprise settings.
