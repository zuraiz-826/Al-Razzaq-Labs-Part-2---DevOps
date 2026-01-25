Lab 20: Troubleshooting Cluster Issues
Objectives
By the end of this lab, you will be able to:

Use OpenShift troubleshooting tools including oc logs, oc describe, and oc get events to diagnose cluster problems
Debug common pod, service, and deployment failures systematically
Analyze resource usage patterns and optimize cluster configurations
Apply troubleshooting methodologies to resolve real-world OpenShift issues
Understand the relationship between different OpenShift objects and how failures propagate
Prerequisites
Before starting this lab, you should have:

Basic understanding of OpenShift/Kubernetes concepts (pods, services, deployments)
Familiarity with command-line interface operations
Knowledge of YAML configuration files
Understanding of container concepts and lifecycle
Previous experience with oc command-line tool basics
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines with OpenShift cluster access pre-configured. Simply click Start Lab to begin - no need to build your own VM or install additional software.

Your lab environment includes:

OpenShift cluster with admin access
Pre-installed oc CLI tool
Sample applications with intentional issues for troubleshooting practice
Task 1: Using Core Troubleshooting Tools
Subtask 1.1: Exploring oc logs Command
The oc logs command is your primary tool for examining application output and error messages.

Step 1: First, let's create a problematic application to troubleshoot:

# Create a new project for our troubleshooting exercises
oc new-project troubleshooting-lab

# Create a deployment with an intentional issue
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-app
  namespace: troubleshooting-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: broken-app
  template:
    metadata:
      labels:
        app: broken-app
    spec:
      containers:
      - name: web-server
        image: nginx:1.20
        ports:
        - containerPort: 80
        env:
        - name: INVALID_CONFIG
          value: "this-will-cause-issues"
        command: ["/bin/sh"]
        args: ["-c", "echo 'Starting broken app' && sleep 10 && exit 1"]
EOF
Step 2: Check the deployment status:

# View deployment status
oc get deployments

# Check pod status
oc get pods
Step 3: Use oc logs to examine container output:

# Get logs from a specific pod (replace POD_NAME with actual pod name)
oc logs POD_NAME

# Get logs from all pods with the same label
oc logs -l app=broken-app

# Follow logs in real-time
oc logs -f -l app=broken-app

# Get logs from previous container instance (useful for crashed containers)
oc logs POD_NAME --previous
Subtask 1.2: Using oc describe for Detailed Information
The oc describe command provides comprehensive information about OpenShift objects and their current state.

Step 1: Describe the deployment to understand its configuration:

# Describe the deployment
oc describe deployment broken-app
Step 2: Describe a pod to see detailed status and events:

# Get a pod name first
POD_NAME=$(oc get pods -l app=broken-app -o jsonpath='{.items[0].metadata.name}')

# Describe the pod
oc describe pod $POD_NAME
Step 3: Examine the Events section in the describe output. This shows:

Container creation attempts
Image pull status
Restart reasons
Resource allocation issues
Subtask 1.3: Analyzing Cluster Events
Events provide a chronological view of what's happening in your cluster.

Step 1: View events in the current namespace:

# Get events in current namespace
oc get events

# Sort events by timestamp
oc get events --sort-by='.lastTimestamp'

# Filter events by type
oc get events --field-selector type=Warning
Step 2: Get events for specific objects:

# Events related to our deployment
oc get events --field-selector involvedObject.name=broken-app

# Events in the last 30 minutes
oc get events --field-selector type=Warning --sort-by='.lastTimestamp' | head -20
Task 2: Debugging Pod, Service, and Deployment Failures
Subtask 2.1: Debugging Pod Failures
Step 1: Create a pod with common failure scenarios:

# Create a pod with image pull issues
cat << EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: image-pull-error
  namespace: troubleshooting-lab
spec:
  containers:
  - name: non-existent
    image: non-existent-registry.com/fake-image:latest
    ports:
    - containerPort: 8080
EOF
Step 2: Diagnose the image pull failure:

# Check pod status
oc get pod image-pull-error

# Describe the pod to see the error
oc describe pod image-pull-error

# Look for ImagePullBackOff or ErrImagePull status
Step 3: Create a pod with resource constraints:

# Create a pod that requests too many resources
cat << EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: resource-constrained
  namespace: troubleshooting-lab
spec:
  containers:
  - name: memory-hog
    image: nginx:1.20
    resources:
      requests:
        memory: "10Gi"
        cpu: "4"
      limits:
        memory: "10Gi"
        cpu: "4"
EOF
Step 4: Analyze the resource constraint issue:

# Check if pod is pending
oc get pod resource-constrained

# Describe to see scheduling issues
oc describe pod resource-constrained

# Check node resources
oc describe nodes
Subtask 2.2: Debugging Service Issues
Step 1: Create a service with endpoint problems:

# Create a service that doesn't match any pods
cat << EOF | oc apply -f -
apiVersion: v1
kind: Service
metadata:
  name: mismatched-service
  namespace: troubleshooting-lab
spec:
  selector:
    app: non-existent-app
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
EOF
Step 2: Debug the service connectivity:

# Check service status
oc get service mismatched-service

# Describe the service
oc describe service mismatched-service

# Check endpoints (should be empty)
oc get endpoints mismatched-service

# Verify no pods match the selector
oc get pods -l app=non-existent-app
Step 3: Create a working application and service:

# Create a proper deployment
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: troubleshooting-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: troubleshooting-lab
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
Step 4: Verify service connectivity:

# Check that endpoints are populated
oc get endpoints web-service

# Test service connectivity from within cluster
oc run test-pod --image=curlimages/curl --rm -it --restart=Never -- curl web-service.troubleshooting-lab.svc.cluster.local
Subtask 2.3: Debugging Deployment Failures
Step 1: Create a deployment with configuration issues:

# Create deployment with invalid configuration
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-error-app
  namespace: troubleshooting-lab
spec:
  replicas: 3
  selector:
    matchLabels:
      app: config-error-app
  template:
    metadata:
      labels:
        app: config-error-app
    spec:
      containers:
      - name: app
        image: nginx:1.20
        ports:
        - containerPort: 80
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: non-existent-secret
              key: url
EOF
Step 2: Analyze deployment rollout issues:

# Check deployment status
oc get deployment config-error-app

# Check rollout status
oc rollout status deployment/config-error-app --timeout=60s

# Describe deployment for detailed information
oc describe deployment config-error-app

# Check replica set status
oc get replicasets -l app=config-error-app
Step 3: Examine pod creation failures:

# Get pods created by the deployment
oc get pods -l app=config-error-app

# Describe a failed pod
POD_NAME=$(oc get pods -l app=config-error-app -o jsonpath='{.items[0].metadata.name}')
oc describe pod $POD_NAME
Task 3: Analyzing Resource Usage and Optimization
Subtask 3.1: Monitoring Resource Consumption
Step 1: Check cluster resource usage:

# View node resource usage
oc adm top nodes

# View pod resource usage in current namespace
oc adm top pods

# View resource usage for specific pods
oc adm top pods -l app=web-app
Step 2: Analyze resource requests and limits:

# Check resource quotas in namespace
oc get resourcequota

# Describe resource quota details
oc describe resourcequota

# Check limit ranges
oc get limitrange
oc describe limitrange
Step 3: Create a resource quota for testing:

# Create a resource quota
cat << EOF | oc apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: troubleshooting-lab
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    pods: "10"
EOF
Subtask 3.2: Identifying Resource Bottlenecks
Step 1: Create an application that will hit resource limits:

# Create deployment that will exceed quota
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-heavy-app
  namespace: troubleshooting-lab
spec:
  replicas: 5
  selector:
    matchLabels:
      app: resource-heavy-app
  template:
    metadata:
      labels:
        app: resource-heavy-app
    spec:
      containers:
      - name: cpu-intensive
        image: nginx:1.20
        resources:
          requests:
            cpu: "1"
            memory: "1Gi"
          limits:
            cpu: "1"
            memory: "1Gi"
EOF
Step 2: Analyze quota violations:

# Check deployment status
oc get deployment resource-heavy-app

# Check resource quota usage
oc describe resourcequota compute-quota

# Check events for quota-related errors
oc get events --field-selector reason=FailedCreate
Subtask 3.3: Optimizing Resource Configurations
Step 1: Identify over-provisioned resources:

# Compare actual usage vs requests
oc adm top pods
oc describe pods -l app=web-app | grep -A 5 -B 5 "Requests\|Limits"
Step 2: Create optimized resource configuration:

# Update deployment with optimized resources
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: optimized-app
  namespace: troubleshooting-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: optimized-app
  template:
    metadata:
      labels:
        app: optimized-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
EOF
Step 3: Monitor the optimized application:

# Check deployment rollout
oc rollout status deployment/optimized-app

# Monitor resource usage
oc adm top pods -l app=optimized-app

# Verify health checks are working
oc describe pods -l app=optimized-app | grep -A 10 "Conditions"
Advanced Troubleshooting Techniques
Debugging Network Issues
Step 1: Test network connectivity between pods:

# Create a debug pod for network testing
oc run network-debug --image=nicolaka/netshoot --rm -it --restart=Never -- /bin/bash

# From within the debug pod, test connectivity
# nslookup web-service.troubleshooting-lab.svc.cluster.local
# curl web-service.troubleshooting-lab.svc.cluster.local
# ping POD_IP
Examining Cluster-Level Issues
Step 1: Check cluster operator status:

# View cluster operators
oc get clusteroperators

# Check for degraded operators
oc get clusteroperators | grep -v "True.*False.*False"
Step 2: Examine node conditions:

# Check node status and conditions
oc get nodes -o wide

# Describe nodes to see detailed conditions
oc describe nodes | grep -A 5 "Conditions"
Troubleshooting Best Practices
Systematic Approach
Start with the obvious: Check pod status, recent changes, and events
Follow the data flow: Trace from user request through service to pod
Check dependencies: Verify secrets, configmaps, and external services
Examine logs systematically: Application logs, then system logs
Use multiple tools: Combine oc logs, oc describe, and oc get events
Common Issues and Solutions
ImagePullBackOff:

Verify image name and tag
Check registry credentials
Ensure network connectivity to registry
CrashLoopBackOff:

Examine application logs
Check resource limits
Verify application configuration
Pending Pods:

Check node resources
Verify node selectors and taints
Examine resource quotas
Cleanup
Remove all resources created during this lab:

# Delete the troubleshooting project
oc delete project troubleshooting-lab

# Verify cleanup
oc get projects | grep troubleshooting
Conclusion
In this lab, you have learned essential OpenShift troubleshooting skills that are crucial for maintaining healthy cluster operations. You practiced using the three core troubleshooting tools:

oc logs: For examining application output and identifying runtime issues
oc describe: For getting detailed object information and status
oc get events: For understanding the sequence of cluster activities
You also gained hands-on experience debugging common failure scenarios including pod crashes, service connectivity issues, and deployment problems. The resource analysis and optimization techniques you learned will help you maintain efficient cluster operations.

These troubleshooting skills are fundamental for the Red Hat Certified OpenShift Administrator exam and essential for real-world OpenShift operations. The systematic approach and best practices covered in this lab will serve as your foundation for resolving complex cluster issues in production environments.

Remember that effective troubleshooting is often about asking the right questions and following a logical sequence of investigation steps. Practice these techniques regularly to build confidence and speed in problem resolution.
