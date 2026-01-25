Lab 14: Managing Application Updates
Objectives
By the end of this lab, students will be able to:

• Perform rolling updates of applications in OpenShift using the oc set image command • Execute rollbacks to previous deployment versions when updates fail • Implement and test zero-downtime updates using OpenShift's rolling update strategy • Monitor deployment status and verify application availability during updates • Understand the deployment history and revision management in OpenShift

Prerequisites
Before starting this lab, students should have:

• Basic understanding of OpenShift concepts including pods, deployments, and services • Familiarity with the OpenShift CLI (oc command) • Knowledge of container images and image tags • Understanding of YAML configuration files • Completion of previous OpenShift labs covering basic application deployment

Ready-to-Use Cloud Machines
Al Nafi provides pre-configured Linux-based cloud machines with OpenShift already installed and configured. Simply click Start Lab to access your environment. No need to build your own VM or install OpenShift from scratch.

Your lab environment includes: • OpenShift cluster with administrative access • Pre-installed oc CLI tool • Sample applications ready for deployment • All necessary networking and storage configurations

Lab Tasks
Task 1: Update Application Images Using oc set image
Subtask 1.1: Deploy Initial Application
First, we'll deploy a sample application that we can later update.

Step 1: Log into your OpenShift cluster

oc login -u admin -p admin https://api.crc.testing:6443
Step 2: Create a new project for this lab

oc new-project app-updates-lab
Step 3: Deploy a sample nginx application

oc new-app --name=web-app --docker-image=nginx:1.20
Step 4: Expose the application as a service

oc expose svc/web-app
Step 5: Verify the deployment

oc get pods
oc get deployments
oc describe deployment web-app
Subtask 1.2: Check Current Application Version
Step 1: View the current image being used

oc describe deployment web-app | grep Image
Step 2: Check the deployment configuration

oc get deployment web-app -o yaml | grep image:
Step 3: Access the application to verify it's working

oc get route web-app
curl $(oc get route web-app -o jsonpath='{.spec.host}')
Subtask 1.3: Perform Rolling Update
Step 1: Update the application image to a newer version

oc set image deployment/web-app nginx=nginx:1.21
Step 2: Monitor the rolling update progress

oc rollout status deployment/web-app
Step 3: Watch pods being replaced in real-time

oc get pods -w
Note: Press Ctrl+C to stop watching after you see the new pods running.

Step 4: Verify the new image version

oc describe deployment web-app | grep Image
Subtask 1.4: Update with Custom Image
Step 1: Create a custom HTML file for testing

cat > index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Updated Application - Version 2.0</title>
</head>
<body>
    <h1>Welcome to Updated Web Application</h1>
    <p>This is version 2.0 of our application</p>
    <p>Updated on: $(date)</p>
</body>
</html>
EOF
Step 2: Create a ConfigMap with the custom content

oc create configmap web-content --from-file=index.html
Step 3: Update the deployment to use the ConfigMap

oc set volume deployment/web-app --add --type=configmap --configmap-name=web-content --mount-path=/usr/share/nginx/html --name=web-content
Task 2: Roll Back to Previous Deployment
Subtask 2.1: View Deployment History
Step 1: Check the rollout history

oc rollout history deployment/web-app
Step 2: Get detailed information about a specific revision

oc rollout history deployment/web-app --revision=1
oc rollout history deployment/web-app --revision=2
Subtask 2.2: Simulate a Failed Update
Step 1: Intentionally deploy a broken image

oc set image deployment/web-app nginx=nginx:nonexistent-tag
Step 2: Monitor the failed deployment

oc rollout status deployment/web-app --timeout=60s
Step 3: Check pod status to see the failure

oc get pods
oc describe pod $(oc get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}')
Subtask 2.3: Perform Rollback
Step 1: Roll back to the previous working version

oc rollout undo deployment/web-app
Step 2: Monitor the rollback process

oc rollout status deployment/web-app
Step 3: Verify the rollback was successful

oc get pods
oc describe deployment web-app | grep Image
Subtask 2.4: Roll Back to Specific Revision
Step 1: Roll back to a specific revision number

oc rollout undo deployment/web-app --to-revision=1
Step 2: Verify the specific rollback

oc rollout history deployment/web-app
oc describe deployment web-app | grep Image
Task 3: Test Zero-Downtime Updates Using Rolling Updates
Subtask 3.1: Configure Rolling Update Strategy
Step 1: View current rolling update configuration

oc describe deployment web-app | grep -A 5 "RollingUpdateStrategy"
Step 2: Update the rolling update strategy for better zero-downtime

oc patch deployment web-app -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":"50%","maxUnavailable":"25%"}}}}'
Step 3: Verify the strategy change

oc describe deployment web-app | grep -A 5 "RollingUpdateStrategy"
Subtask 3.2: Scale Application for Better Testing
Step 1: Scale the application to multiple replicas

oc scale deployment web-app --replicas=4
Step 2: Wait for all replicas to be ready

oc rollout status deployment/web-app
Step 3: Verify all pods are running

oc get pods -l app=web-app
Subtask 3.3: Test Zero-Downtime Update
Step 1: Create a script to continuously test application availability

cat > test-availability.sh << 'EOF'
#!/bin/bash
ROUTE_URL=$(oc get route web-app -o jsonpath='{.spec.host}')
echo "Testing application availability during update..."
echo "Application URL: http://$ROUTE_URL"

# Counter for requests
SUCCESS_COUNT=0
FAIL_COUNT=0
TOTAL_REQUESTS=0

# Test for 2 minutes
END_TIME=$((SECONDS + 120))

while [ $SECONDS -lt $END_TIME ]; do
    TOTAL_REQUESTS=$((TOTAL_REQUESTS + 1))
    
    if curl -s -o /dev/null -w "%{http_code}" "http://$ROUTE_URL" | grep -q "200"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo "Request $TOTAL_REQUESTS: SUCCESS"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "Request $TOTAL_REQUESTS: FAILED"
    fi
    
    sleep 2
done

echo "Test completed!"
echo "Total requests: $TOTAL_REQUESTS"
echo "Successful requests: $SUCCESS_COUNT"
echo "Failed requests: $FAIL_COUNT"
echo "Success rate: $(echo "scale=2; $SUCCESS_COUNT * 100 / $TOTAL_REQUESTS" | bc)%"
EOF

chmod +x test-availability.sh
Step 2: Start the availability test in background

./test-availability.sh &
TEST_PID=$!
Step 3: Perform an update while the test is running

oc set image deployment/web-app nginx=nginx:1.22
Step 4: Monitor the update progress

oc rollout status deployment/web-app
Step 5: Wait for the availability test to complete

wait $TEST_PID
Subtask 3.4: Analyze Update Behavior
Step 1: Check the deployment events

oc describe deployment web-app | tail -20
Step 2: Review pod replacement pattern

oc get events --sort-by='.lastTimestamp' | grep web-app
Step 3: Verify final state

oc get pods -l app=web-app
oc describe deployment web-app | grep Image
Subtask 3.5: Test Readiness and Liveness Probes
Step 1: Add health checks to ensure proper rolling updates

oc set probe deployment/web-app --readiness --get-url=http://:8080/ --initial-delay-seconds=5 --period-seconds=10
oc set probe deployment/web-app --liveness --get-url=http://:8080/ --initial-delay-seconds=15 --period-seconds=20
Step 2: Verify probes are configured

oc describe deployment web-app | grep -A 10 "Liveness\|Readiness"
Step 3: Test update with health checks

oc set image deployment/web-app nginx=nginx:1.23
oc rollout status deployment/web-app
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Update gets stuck in progress

# Check pod status
oc get pods -l app=web-app

# Check events for errors
oc get events --sort-by='.lastTimestamp'

# Force restart if needed
oc rollout restart deployment/web-app
Issue 2: Rollback fails

# Check rollout history
oc rollout history deployment/web-app

# Manually specify a known good revision
oc rollout undo deployment/web-app --to-revision=1
Issue 3: Application becomes unavailable during update

# Check rolling update strategy
oc describe deployment web-app | grep -A 5 "RollingUpdateStrategy"

# Adjust strategy for better availability
oc patch deployment web-app -p '{"spec":{"strategy":{"rollingUpdate":{"maxUnavailable":"0"}}}}'
Issue 4: Image pull errors

# Check pod events
oc describe pod <pod-name>

# Verify image exists
oc set image deployment/web-app nginx=nginx:latest --dry-run=client
Verification Commands
Use these commands to verify your lab completion:

# Check deployment status
oc get deployments

# Verify rollout history
oc rollout history deployment/web-app

# Check current image version
oc describe deployment web-app | grep Image

# Test application accessibility
curl $(oc get route web-app -o jsonpath='{.spec.host}')

# Verify rolling update strategy
oc describe deployment web-app | grep -A 5 "RollingUpdateStrategy"
Conclusion
In this lab, you have successfully learned how to manage application updates in OpenShift. You accomplished the following key tasks:

• Performed Rolling Updates: Used the oc set image command to update application images while maintaining service availability • Executed Rollbacks: Successfully rolled back failed deployments to previous working versions using OpenShift's rollout history • Implemented Zero-Downtime Updates: Configured and tested rolling update strategies to ensure continuous application availability • Monitored Deployment Health: Used readiness and liveness probes to ensure proper application health during updates

These skills are essential for maintaining production applications in OpenShift environments. Rolling updates and rollbacks are critical capabilities that allow you to deploy new features and fixes while minimizing service disruption. The ability to perform zero-downtime updates ensures that your applications remain available to users even during maintenance windows.

Understanding these concepts and techniques will help you in real-world scenarios where application availability is crucial, and they are fundamental skills tested in the Red Hat Certified OpenShift Administrator exam. The hands-on experience gained from this lab provides you with the confidence to manage application lifecycles in production OpenShift environments.
