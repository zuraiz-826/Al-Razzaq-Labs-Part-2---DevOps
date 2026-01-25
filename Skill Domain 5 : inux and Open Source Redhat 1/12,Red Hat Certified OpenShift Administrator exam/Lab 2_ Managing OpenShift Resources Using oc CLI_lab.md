Lab 2: Managing OpenShift Resources Using oc CLI
Lab Objectives
By the end of this lab, you will be able to:

Use the OpenShift CLI (oc) to manage cluster resources effectively
Create and manage pods using command-line interface
Scale applications by adjusting replica sets to meet demand
Use oc describe command to inspect pod details and troubleshoot issues
Monitor the status of objects in the OpenShift cluster
Understand the relationship between pods, deployments, and replica sets
Prerequisites
Before starting this lab, you should have:

Basic understanding of containerization concepts
Familiarity with Linux command-line interface
Knowledge of YAML file structure
Understanding of Kubernetes/OpenShift basic concepts (pods, deployments, services)
Completed Lab 1 or equivalent OpenShift CLI installation experience
Lab Environment Setup
Good News! Al Nafi provides ready-to-use Linux-based cloud machines with OpenShift CLI pre-installed. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

Pre-configured OpenShift cluster access
OpenShift CLI (oc) tool installed and ready to use
Sample application files for hands-on practice
Administrative privileges for cluster management
Task 1: Create and Manage Pods Using oc
Subtask 1.1: Verify OpenShift CLI Connection
First, let's ensure your OpenShift CLI is properly connected to the cluster.

Open your terminal in the provided cloud machine
Check the current OpenShift version and connection status:
oc version
Verify cluster information:
oc cluster-info
Check your current project/namespace:
oc project
If you're not in a project, create a new one for this lab:

oc new-project lab2-resources
Subtask 1.2: Create Your First Pod
Now let's create a simple pod using the OpenShift CLI.

Create a pod using the oc run command:
oc run nginx-pod --image=nginx:latest --port=80
Verify the pod was created:
oc get pods
You should see output similar to:

NAME        READY   STATUS    RESTARTS   AGE
nginx-pod   1/1     Running   0          30s
Get more detailed information about all resources:
oc get all
Subtask 1.3: Create a Pod Using YAML Definition
For more complex configurations, we'll use YAML files.

Create a YAML file for a custom pod:
cat > custom-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: webapp-pod
  labels:
    app: webapp
    tier: frontend
spec:
  containers:
  - name: webapp-container
    image: httpd:2.4
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
Apply the YAML configuration:
oc apply -f custom-pod.yaml
Verify both pods are running:
oc get pods -o wide
Subtask 1.4: Manage Pod Lifecycle
Learn how to interact with your running pods.

Execute commands inside a pod:
oc exec nginx-pod -- nginx -v
Get an interactive shell inside the pod:
oc exec -it nginx-pod -- /bin/bash
Inside the pod, run:

echo "Hello from inside the pod" > /usr/share/nginx/html/index.html
exit
View pod logs:
oc logs nginx-pod
Delete a specific pod:
oc delete pod webapp-pod
Task 2: Scale Applications by Adjusting Replica Sets
Subtask 2.1: Create a Deployment
Pods created directly cannot be scaled. We need deployments for scaling capabilities.

Create a deployment instead of a standalone pod:
oc create deployment web-app --image=nginx:latest --replicas=2
Verify the deployment and its pods:
oc get deployments
oc get pods -l app=web-app
Check the replica set created by the deployment:
oc get replicasets
Subtask 2.2: Scale Applications Up
Now let's scale our application to handle more traffic.

Scale the deployment to 5 replicas:
oc scale deployment web-app --replicas=5
Watch the scaling process in real-time:
oc get pods -l app=web-app -w
Press Ctrl+C to stop watching after you see all 5 pods running.

Verify the current scale:
oc get deployment web-app
Subtask 2.3: Scale Applications Down
Learn how to reduce resources when demand decreases.

Scale down to 2 replicas:
oc scale deployment web-app --replicas=2
Observe which pods are terminated:
oc get pods -l app=web-app
Check the deployment status:
oc get deployment web-app -o yaml | grep replicas
Subtask 2.4: Autoscaling Configuration
Set up horizontal pod autoscaling based on CPU usage.

Create a horizontal pod autoscaler:
oc autoscale deployment web-app --min=2 --max=10 --cpu-percent=70
View the autoscaler configuration:
oc get hpa
Describe the autoscaler for detailed information:
oc describe hpa web-app
Task 3: Use oc describe to Inspect Pod Details
Subtask 3.1: Inspect Pod Configuration
The oc describe command provides comprehensive information about resources.

Get detailed information about a specific pod:
oc describe pod nginx-pod
Examine the key sections in the output:
Metadata: Name, namespace, labels, annotations
Spec: Container specifications, volumes, security context
Status: Current state, conditions, container statuses
Events: Recent activities and state changes
Subtask 3.2: Troubleshoot Pod Issues
Let's create a problematic pod to practice troubleshooting.

Create a pod with an invalid image:
oc run broken-pod --image=nonexistent-image:latest
Check the pod status:
oc get pods broken-pod
Use describe to investigate the issue:
oc describe pod broken-pod
Look for the Events section at the bottom to understand what went wrong.

Check pod logs (even for failed pods):
oc logs broken-pod
Subtask 3.3: Inspect Deployment and ReplicaSet Details
Understand the relationship between deployments, replica sets, and pods.

Describe the deployment:
oc describe deployment web-app
Get the replica set name and describe it:
oc get rs -l app=web-app
oc describe rs <replica-set-name>
Replace <replica-set-name> with the actual name from the previous command.

Compare the information across all three resource types:
oc describe deployment web-app | grep -A 5 "Pod Template"
oc describe rs <replica-set-name> | grep -A 5 "Pod Template"
oc describe pod <pod-name> | grep -A 10 "Containers"
Subtask 3.4: Monitor Resource Usage and Events
Learn to monitor cluster resources effectively.

View events across the namespace:
oc get events --sort-by='.lastTimestamp'
Filter events for specific resources:
oc get events --field-selector involvedObject.name=web-app
Monitor resource usage:
oc top pods
Get resource quotas and limits:
oc describe limitrange
oc describe resourcequota
Advanced Operations and Best Practices
Working with Labels and Selectors
Add labels to existing pods:
oc label pod nginx-pod environment=production
Query pods using label selectors:
oc get pods -l environment=production
oc get pods -l app=web-app,environment!=production
Remove labels:
oc label pod nginx-pod environment-
Resource Management Commands
View resource usage:
oc adm top pods
oc adm top nodes
Export resource definitions:
oc get deployment web-app -o yaml > web-app-backup.yaml
Edit resources directly:
oc edit deployment web-app
Cleanup
Before concluding the lab, let's clean up the resources we created.

Delete all pods and deployments:
oc delete deployment web-app
oc delete pod nginx-pod broken-pod
oc delete hpa web-app
Remove custom files:
rm -f custom-pod.yaml web-app-backup.yaml
Verify cleanup:
oc get all
Troubleshooting Tips
Common Issues and Solutions
Issue: Pod stuck in Pending state

Solution: Check node resources with oc describe nodes and pod events with oc describe pod <pod-name>
Issue: Pod in CrashLoopBackOff state

Solution: Examine logs with oc logs <pod-name> --previous and check container configuration
Issue: Cannot scale deployment

Solution: Verify deployment exists with oc get deployments and check resource quotas
Issue: oc command not found

Solution: Verify OpenShift CLI installation and PATH configuration
Useful Debugging Commands
# Get comprehensive cluster information
oc get all --all-namespaces

# Check cluster node status
oc get nodes -o wide

# View detailed resource information
oc explain pod.spec.containers

# Monitor real-time changes
oc get pods -w

# Check API resources available
oc api-resources
Conclusion
Congratulations! You have successfully completed Lab 2: Managing OpenShift Resources Using oc CLI.

What You Accomplished
In this lab, you have:

Mastered Pod Management: Created pods using both imperative commands and declarative YAML files, managed their lifecycle, and learned to interact with running containers
Implemented Application Scaling: Successfully scaled applications up and down using deployments and replica sets, and configured horizontal pod autoscaling
Developed Troubleshooting Skills: Used oc describe to inspect resource details, diagnosed issues, and monitored cluster events
Why This Matters
These skills are fundamental for OpenShift administrators and developers because:

Operational Excellence: Proper resource management ensures applications run reliably and efficiently
Cost Optimization: Scaling capabilities help optimize resource usage and reduce operational costs
Problem Resolution: Troubleshooting skills minimize downtime and improve system reliability
Career Advancement: These competencies are essential for Red Hat Certified OpenShift Administrator certification
Next Steps
To continue your OpenShift journey:

Practice these commands in different scenarios
Explore advanced scaling strategies and resource limits
Learn about persistent volumes and storage management
Study networking concepts including services and routes
Prepare for the next lab focusing on application deployment and management
The skills you've developed today form the foundation for advanced OpenShift administration and will serve you well in production environments.
