Lab 7: Viewing and Managing Logs in OpenShift
Objectives
By the end of this lab, you will be able to:

View logs of pods, deployments, and services to monitor application behavior
Use the oc logs command effectively to retrieve container logs
Filter logs for errors and specific events using various command-line options
Understand log aggregation concepts using EFK stack (Elasticsearch, Fluentd, Kibana)
Diagnose application issues using log analysis techniques
Implement log management best practices in OpenShift environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of OpenShift concepts (pods, deployments, services)
Familiarity with command-line interface operations
Knowledge of YAML file structure
Understanding of containerized applications
Completion of previous OpenShift labs or equivalent experience
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines with OpenShift pre-installed. Simply click Start Lab to access your environment - no need to build your own VM or install OpenShift manually.

Your lab environment includes:

OpenShift cluster with administrative access
Pre-configured oc command-line tool
Sample applications for log analysis
EFK stack components (where applicable)
Task 1: Using oc logs to View Pod Logs
Subtask 1.1: Deploy a Sample Application
First, let's deploy a sample application that will generate logs for our analysis.

Create a new project for this lab:
oc new-project log-management-lab
Deploy a sample web application:
oc new-app --name=sample-app --docker-image=httpd:2.4
Verify the deployment:
oc get pods
Wait until the pod status shows Running.

Subtask 1.2: View Basic Pod Logs
Get the pod name:
POD_NAME=$(oc get pods -l app=sample-app -o jsonpath='{.items[0].metadata.name}')
echo "Pod name: $POD_NAME"
View current logs:
oc logs $POD_NAME
View logs with timestamps:
oc logs $POD_NAME --timestamps=true
Follow logs in real-time:
oc logs -f $POD_NAME
Press Ctrl+C to stop following logs.

Subtask 1.3: View Logs from Previous Container Instances
View logs from previous container instance (if the pod has restarted):
oc logs $POD_NAME --previous
Get detailed information about the pod:
oc describe pod $POD_NAME
Subtask 1.4: View Logs from Multi-Container Pods
Let's deploy an application with multiple containers to practice viewing logs from specific containers.

Create a multi-container pod configuration:
cat > multi-container-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-app
  labels:
    app: multi-container
spec:
  containers:
  - name: web-server
    image: httpd:2.4
    ports:
    - containerPort: 80
  - name: log-generator
    image: busybox
    command: ['sh', '-c', 'while true; do echo "Log from sidecar: $(date)"; sleep 10; done']
EOF
Deploy the multi-container pod:
oc apply -f multi-container-pod.yaml
Wait for the pod to be ready:
oc get pods -w
Press Ctrl+C when the pod is running.

View logs from specific container:
# View logs from web-server container
oc logs multi-container-app -c web-server

# View logs from log-generator container
oc logs multi-container-app -c log-generator
View logs from all containers:
oc logs multi-container-app --all-containers=true
Task 2: Filtering Logs for Errors and Specific Events
Subtask 2.1: Generate Application Logs with Errors
Deploy an application that generates various log levels:
cat > log-generator-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: log-generator
spec:
  replicas: 1
  selector:
    matchLabels:
      app: log-generator
  template:
    metadata:
      labels:
        app: log-generator
    spec:
      containers:
      - name: log-generator
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          while true; do
            echo "INFO: Application started successfully"
            sleep 5
            echo "WARNING: Memory usage is high"
            sleep 3
            echo "ERROR: Failed to connect to database"
            sleep 7
            echo "DEBUG: Processing user request"
            sleep 2
            echo "FATAL: Critical system failure"
            sleep 10
          done
EOF
Deploy the log generator:
oc apply -f log-generator-deployment.yaml
Wait for deployment to be ready:
oc rollout status deployment/log-generator
Subtask 2.2: Filter Logs Using Command-Line Tools
Get the log generator pod name:
LOG_POD=$(oc get pods -l app=log-generator -o jsonpath='{.items[0].metadata.name}')
echo "Log generator pod: $LOG_POD"
View all logs and filter for ERROR messages:
oc logs $LOG_POD | grep ERROR
Filter for multiple log levels:
oc logs $LOG_POD | grep -E "(ERROR|FATAL|WARNING)"
View logs with line numbers:
oc logs $LOG_POD | grep -n ERROR
Count occurrences of specific log levels:
echo "Error count:"
oc logs $LOG_POD | grep -c ERROR

echo "Warning count:"
oc logs $LOG_POD | grep -c WARNING
Subtask 2.3: Advanced Log Filtering Techniques
View logs from the last 10 minutes:
oc logs $LOG_POD --since=10m
View last 50 lines of logs:
oc logs $LOG_POD --tail=50
Combine time-based and content filtering:
oc logs $LOG_POD --since=5m | grep ERROR
Save filtered logs to a file:
oc logs $LOG_POD | grep -E "(ERROR|FATAL)" > error_logs.txt
cat error_logs.txt
Task 3: Understanding Log Aggregation with EFK Stack
Subtask 3.1: Understanding the EFK Stack Components
The EFK stack consists of:

Elasticsearch: Distributed search and analytics engine for storing logs
Fluentd: Data collector that unifies log data collection and consumption
Kibana: Visualization platform for exploring and analyzing logs
Subtask 3.2: Viewing Logs Through OpenShift Console
Access the OpenShift web console (if available in your environment):
oc whoami --show-console
Navigate to your project:

Go to Developer perspective
Select your project: log-management-lab
Click on Topology
View pod logs through the console:

Click on your application pod
Select the Logs tab
Explore the filtering options available
Subtask 3.3: Simulate Log Aggregation Concepts
Since a full EFK stack requires significant resources, we'll simulate log aggregation concepts using command-line tools.

Create a script to collect logs from multiple pods:
cat > collect_logs.sh << 'EOF'
#!/bin/bash

echo "=== Log Collection Script ==="
echo "Timestamp: $(date)"
echo "================================"

# Get all pods in the current project
PODS=$(oc get pods -o jsonpath='{.items[*].metadata.name}')

for pod in $PODS; do
    echo ""
    echo "--- Logs from Pod: $pod ---"
    oc logs $pod --tail=10 2>/dev/null || echo "No logs available for $pod"
    echo "--- End of logs for $pod ---"
done

echo ""
echo "=== Log Collection Complete ==="
EOF

chmod +x collect_logs.sh
Run the log collection script:
./collect_logs.sh
Create a log analysis script:
cat > analyze_logs.sh << 'EOF'
#!/bin/bash

echo "=== Log Analysis Report ==="
echo "Generated at: $(date)"
echo "============================"

# Collect all logs and analyze
ALL_LOGS=$(mktemp)
PODS=$(oc get pods -o jsonpath='{.items[*].metadata.name}')

for pod in $PODS; do
    oc logs $pod 2>/dev/null >> $ALL_LOGS
done

echo ""
echo "Log Level Summary:"
echo "=================="
echo "INFO messages: $(grep -c INFO $ALL_LOGS 2>/dev/null || echo 0)"
echo "WARNING messages: $(grep -c WARNING $ALL_LOGS 2>/dev/null || echo 0)"
echo "ERROR messages: $(grep -c ERROR $ALL_LOGS 2>/dev/null || echo 0)"
echo "FATAL messages: $(grep -c FATAL $ALL_LOGS 2>/dev/null || echo 0)"

echo ""
echo "Recent Error Messages:"
echo "====================="
grep ERROR $ALL_LOGS 2>/dev/null | tail -5 || echo "No error messages found"

# Cleanup
rm -f $ALL_LOGS
EOF

chmod +x analyze_logs.sh
Run the log analysis script:
./analyze_logs.sh
Subtask 3.4: Implementing Log Retention Policies
Create a deployment with log rotation configuration:
cat > app-with-log-config.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-logs
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-with-logs
  template:
    metadata:
      labels:
        app: app-with-logs
    spec:
      containers:
      - name: app
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          while true; do
            echo "$(date): Application log entry - ID: $RANDOM"
            sleep 2
          done
        resources:
          limits:
            memory: "128Mi"
            cpu: "100m"
          requests:
            memory: "64Mi"
            cpu: "50m"
EOF
Deploy the application:
oc apply -f app-with-log-config.yaml
Monitor log growth:
APP_POD=$(oc get pods -l app=app-with-logs -o jsonpath='{.items[0].metadata.name}')

# Check log size over time
for i in {1..5}; do
    echo "Check $i - Lines: $(oc logs $APP_POD | wc -l)"
    sleep 10
done
Task 4: Troubleshooting Common Issues
Subtask 4.1: Diagnosing Pod Startup Issues
Create a pod that will fail to start:
cat > failing-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: failing-pod
spec:
  containers:
  - name: failing-container
    image: nonexistent-image:latest
    command: ['sh', '-c', 'echo "This will fail"']
EOF
Deploy the failing pod:
oc apply -f failing-pod.yaml
Check pod status:
oc get pods failing-pod
View pod events and logs:
# View pod description for events
oc describe pod failing-pod

# Try to view logs (will show error)
oc logs failing-pod
Clean up the failing pod:
oc delete pod failing-pod
Subtask 4.2: Analyzing Application Performance Issues
Create a resource-constrained application:
cat > resource-constrained-app.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: resource-app
  template:
    metadata:
      labels:
        app: resource-app
    spec:
      containers:
      - name: app
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          while true; do
            echo "$(date): Processing request - Memory usage increasing"
            # Simulate memory usage
            dd if=/dev/zero of=/tmp/memtest bs=1M count=10 2>/dev/null
            sleep 5
            echo "$(date): WARNING - High memory usage detected"
            rm -f /tmp/memtest
            sleep 5
          done
        resources:
          limits:
            memory: "64Mi"
            cpu: "100m"
          requests:
            memory: "32Mi"
            cpu: "50m"
EOF
Deploy the resource-constrained application:
oc apply -f resource-constrained-app.yaml
Monitor the application logs:
RESOURCE_POD=$(oc get pods -l app=resource-app -o jsonpath='{.items[0].metadata.name}')
oc logs -f $RESOURCE_POD
Press Ctrl+C after observing the logs for a minute.

Check for resource-related issues:
oc describe pod $RESOURCE_POD | grep -A 10 -B 10 -i "memory\|cpu\|resource"
Task 5: Best Practices for Log Management
Subtask 5.1: Implementing Structured Logging
Create an application with structured JSON logs:
cat > structured-logging-app.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: structured-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: structured-app
  template:
    metadata:
      labels:
        app: structured-app
    spec:
      containers:
      - name: app
        image: busybox
        command: ['sh', '-c']
        args:
        - |
          while true; do
            echo "{\"timestamp\":\"$(date -Iseconds)\",\"level\":\"INFO\",\"message\":\"User login successful\",\"user_id\":\"$RANDOM\",\"ip\":\"192.168.1.$((RANDOM%255))\"}"
            sleep 3
            echo "{\"timestamp\":\"$(date -Iseconds)\",\"level\":\"WARNING\",\"message\":\"High CPU usage\",\"cpu_percent\":$((RANDOM%100))}"
            sleep 2
            echo "{\"timestamp\":\"$(date -Iseconds)\",\"level\":\"ERROR\",\"message\":\"Database connection failed\",\"error_code\":\"DB001\"}"
            sleep 5
          done
EOF
Deploy the structured logging application:
oc apply -f structured-logging-app.yaml
View and parse structured logs:
STRUCT_POD=$(oc get pods -l app=structured-app -o jsonpath='{.items[0].metadata.name}')

# View raw structured logs
oc logs $STRUCT_POD --tail=10

# Parse JSON logs (if jq is available)
oc logs $STRUCT_POD --tail=10 | head -1 | python3 -m json.tool 2>/dev/null || echo "JSON parsing not available"
Subtask 5.2: Log Monitoring and Alerting Concepts
Create a monitoring script:
cat > log_monitor.sh << 'EOF'
#!/bin/bash

THRESHOLD=3
CHECK_INTERVAL=30

echo "Starting log monitoring (ERROR threshold: $THRESHOLD errors per check)"
echo "Press Ctrl+C to stop"

while true; do
    PODS=$(oc get pods -o jsonpath='{.items[*].metadata.name}')
    TOTAL_ERRORS=0
    
    for pod in $PODS; do
        ERROR_COUNT=$(oc logs $pod --since=30s 2>/dev/null | grep -c ERROR || echo 0)
        if [ $ERROR_COUNT -gt 0 ]; then
            echo "$(date): Pod $pod has $ERROR_COUNT errors in last 30s"
            TOTAL_ERRORS=$((TOTAL_ERRORS + ERROR_COUNT))
        fi
    done
    
    if [ $TOTAL_ERRORS -gt $THRESHOLD ]; then
        echo "ALERT: Total errors ($TOTAL_ERRORS) exceeded threshold ($THRESHOLD)"
    else
        echo "$(date): System healthy - $TOTAL_ERRORS total errors"
    fi
    
    sleep $CHECK_INTERVAL
done
EOF

chmod +x log_monitor.sh
Run the monitoring script for a short time:
timeout 60 ./log_monitor.sh
Cleanup
Clean up the resources created during this lab:

# Delete all deployments
oc delete deployment --all

# Delete all pods
oc delete pod --all

# Delete the project (optional)
oc delete project log-management-lab
Troubleshooting Tips
Common Issues and Solutions
Pod logs not showing:

Check if the pod is running: oc get pods
Verify the pod name is correct
Use oc describe pod <pod-name> to check events
Permission denied errors:

Ensure you have proper permissions in the project
Check if you're logged in: oc whoami
No logs available:

The application might not be generating logs
Check if the container is running properly
Use --previous flag to see logs from crashed containers
Command not found errors:

Ensure oc command is properly installed and configured
Check your PATH environment variable
Conclusion
In this lab, you have successfully learned how to:

View pod logs using the oc logs command with various options and filters
Filter logs effectively to find specific events, errors, and patterns
Understand log aggregation concepts and the EFK stack components
Troubleshoot applications using log analysis techniques
Implement log management best practices including structured logging and monitoring
These skills are essential for:

Monitoring application health and performance in production environments
Diagnosing issues quickly when applications fail or behave unexpectedly
Implementing effective logging strategies that support operational requirements
Preparing for the Red Hat Certified OpenShift Administrator exam where log management is a key competency
Log management is a critical skill for OpenShift administrators and developers. The techniques you've learned will help you maintain reliable, observable applications in your OpenShift clusters. Continue practicing these skills with your own applications to become proficient in log analysis and troubleshooting.
