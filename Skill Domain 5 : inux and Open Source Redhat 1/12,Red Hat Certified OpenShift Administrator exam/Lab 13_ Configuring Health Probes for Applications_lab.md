Lab 13: Configuring Health Probes for Applications
Objectives
By the end of this lab, you will be able to:

Understand the difference between readiness and liveness probes in OpenShift
Create and configure health probes in application deployments
Test probe functionality by simulating application failures
Adjust probe settings for optimal performance and reliability
Monitor application health status through OpenShift console and CLI
Troubleshoot common probe configuration issues
Prerequisites
Before starting this lab, you should have:

Basic understanding of OpenShift/Kubernetes concepts
Familiarity with YAML configuration files
Knowledge of container deployments and services
Experience with OpenShift CLI (oc) commands
Understanding of HTTP status codes and web applications
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines with OpenShift pre-installed. Simply click Start Lab to access your environment - no need to build your own VM or install OpenShift locally.

Your lab environment includes:

OpenShift cluster with admin access
Pre-configured CLI tools (oc, kubectl)
Sample applications for testing
Web console access
Task 1: Create and Configure Health Probes in a Deployment
Subtask 1.1: Create a Sample Application with Basic Health Probes
First, let's create a simple web application that we can use to demonstrate health probes.

Create a new project for this lab:
oc new-project health-probes-lab
Create a sample application deployment file:
cat > sample-app-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-web-app
  namespace: health-probes-lab
  labels:
    app: sample-web-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-web-app
  template:
    metadata:
      labels:
        app: sample-web-app
    spec:
      containers:
      - name: web-container
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        # Basic readiness probe
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 3
        # Basic liveness probe
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
EOF
Apply the deployment:
oc apply -f sample-app-deployment.yaml
Verify the deployment is running:
oc get deployments
oc get pods
Subtask 1.2: Create a Service to Expose the Application
Create a service for the application:
cat > sample-app-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: sample-web-service
  namespace: health-probes-lab
spec:
  selector:
    app: sample-web-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
EOF
Apply the service:
oc apply -f sample-app-service.yaml
Verify the service is created:
oc get services
Subtask 1.3: Create an Advanced Application with Custom Health Endpoints
Now let's create a more sophisticated application with custom health check endpoints.

Create a custom application with health endpoints:
cat > advanced-app-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: advanced-health-app
  namespace: health-probes-lab
  labels:
    app: advanced-health-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: advanced-health-app
  template:
    metadata:
      labels:
        app: advanced-health-app
    spec:
      containers:
      - name: health-app
        image: quay.io/redhattraining/hello-world-nginx:v1.0
        ports:
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        # Startup probe - ensures container is ready before other probes start
        startupProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 6
        # Readiness probe - determines if pod should receive traffic
        readinessProbe:
          httpGet:
            path: /
            port: 8080
            httpHeaders:
            - name: Custom-Header
              value: readiness-check
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 3
        # Liveness probe - determines if container should be restarted
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 15
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
EOF
Apply the advanced deployment:
oc apply -f advanced-app-deployment.yaml
Monitor the pod startup process:
oc get pods -w
Press Ctrl+C to stop watching after the pod is running.

Task 2: Test the Probes by Simulating Failures
Subtask 2.1: Monitor Current Probe Status
Check the current status of all pods:
oc get pods -o wide
Get detailed information about probe status:
oc describe pod $(oc get pods -l app=advanced-health-app -o jsonpath='{.items[0].metadata.name}')
View pod events to see probe activity:
oc get events --sort-by='.lastTimestamp' | grep -E "(Readiness|Liveness|Startup)"
Subtask 2.2: Simulate Readiness Probe Failure
Create a deployment that will fail readiness checks:
cat > failing-readiness-app.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: failing-readiness-app
  namespace: health-probes-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: failing-readiness-app
  template:
    metadata:
      labels:
        app: failing-readiness-app
    spec:
      containers:
      - name: failing-app
        image: nginx:1.21
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /nonexistent-endpoint
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 2
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 20
EOF
Apply the failing deployment:
oc apply -f failing-readiness-app.yaml
Monitor the pod status:
oc get pods -l app=failing-readiness-app
Check the pod's readiness status:
oc describe pod $(oc get pods -l app=failing-readiness-app -o jsonpath='{.items[0].metadata.name}') | grep -A 10 "Conditions:"
Subtask 2.3: Simulate Liveness Probe Failure
Create a script to simulate application failure:
cat > simulate-failure.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-test-app
  namespace: health-probes-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: liveness-test-app
  template:
    metadata:
      labels:
        app: liveness-test-app
    spec:
      containers:
      - name: test-container
        image: busybox:1.35
        command: ["/bin/sh"]
        args:
        - -c
        - |
          # Create a health file initially
          touch /tmp/healthy
          # Start a simple HTTP server
          while true; do
            if [ -f /tmp/healthy ]; then
              echo "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK" | nc -l -p 8080
            else
              echo "HTTP/1.1 500 Internal Server Error\r\nContent-Length: 5\r\n\r\nERROR" | nc -l -p 8080
            fi
          done &
          # Remove health file after 2 minutes to simulate failure
          sleep 120
          rm -f /tmp/healthy
          # Keep container running
          while true; do sleep 30; done
        ports:
        - containerPort: 8080
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 15
          timeoutSeconds: 5
          failureThreshold: 2
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
          failureThreshold: 2
EOF
Apply the liveness test deployment:
oc apply -f simulate-failure.yaml
Monitor the pod for restart behavior:
# Watch for restarts (this will take a few minutes)
watch -n 10 'oc get pods -l app=liveness-test-app'
Press Ctrl+C to stop watching after observing restarts.

Check restart count and events:
oc get pods -l app=liveness-test-app
oc describe pod $(oc get pods -l app=liveness-test-app -o jsonpath='{.items[0].metadata.name}') | grep -A 5 "Events:"
Task 3: Adjust Probe Settings for Optimal Performance
Subtask 3.1: Analyze Current Probe Performance
Review probe timing and failure patterns:
# Get detailed probe information
oc get pods -o yaml | grep -A 20 -B 5 "Probe"
Check resource usage impact:
oc top pods --containers
Subtask 3.2: Create Optimized Probe Configurations
Create a deployment with optimized probe settings:
cat > optimized-probes-app.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: optimized-probes-app
  namespace: health-probes-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: optimized-probes-app
  template:
    metadata:
      labels:
        app: optimized-probes-app
    spec:
      containers:
      - name: optimized-app
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        # Startup probe - gives application time to initialize
        startupProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 2
          successThreshold: 1
          failureThreshold: 12  # 60 seconds total startup time
        # Optimized readiness probe
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 0  # No delay since startup probe handles initialization
          periodSeconds: 5        # Check every 5 seconds
          timeoutSeconds: 2       # Quick timeout
          successThreshold: 1     # Ready after 1 success
          failureThreshold: 2     # Not ready after 2 failures (10 seconds)
        # Optimized liveness probe
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 0  # No delay since startup probe handles initialization
          periodSeconds: 30       # Check every 30 seconds (less frequent)
          timeoutSeconds: 5       # Longer timeout for liveness
          successThreshold: 1
          failureThreshold: 3     # Restart after 3 failures (90 seconds)
EOF
Apply the optimized deployment:
oc apply -f optimized-probes-app.yaml
Compare startup times:
# Monitor the optimized deployment startup
time oc rollout status deployment/optimized-probes-app
Subtask 3.3: Configure TCP and Command-Based Probes
Create a deployment using different probe types:
cat > mixed-probes-app.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mixed-probes-app
  namespace: health-probes-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mixed-probes-app
  template:
    metadata:
      labels:
        app: mixed-probes-app
    spec:
      containers:
      - name: mixed-app
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        # TCP Socket probe for readiness
        readinessProbe:
          tcpSocket:
            port: 6379
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3
        # Command-based liveness probe
        livenessProbe:
          exec:
            command:
            - redis-cli
            - ping
          initialDelaySeconds: 30
          periodSeconds: 15
          timeoutSeconds: 5
          failureThreshold: 3
      - name: sidecar-app
        image: busybox:1.35
        command: ["/bin/sh", "-c", "while true; do echo 'Sidecar running'; sleep 30; done"]
        # Command-based readiness probe for sidecar
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - "ps aux | grep -v grep | grep sleep"
          initialDelaySeconds: 5
          periodSeconds: 10
        # Command-based liveness probe for sidecar
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - "ps aux | grep -v grep | grep sleep"
          initialDelaySeconds: 10
          periodSeconds: 30
EOF
Apply the mixed probes deployment:
oc apply -f mixed-probes-app.yaml
Monitor the multi-container pod:
oc get pods -l app=mixed-probes-app
oc describe pod $(oc get pods -l app=mixed-probes-app -o jsonpath='{.items[0].metadata.name}')
Subtask 3.4: Test Probe Performance Under Load
Create a service for the optimized app:
oc expose deployment optimized-probes-app --port=80
Create a load testing pod:
cat > load-test-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: load-test
  namespace: health-probes-lab
spec:
  containers:
  - name: load-tester
    image: busybox:1.35
    command: ["/bin/sh"]
    args:
    - -c
    - |
      while true; do
        for i in $(seq 1 10); do
          wget -q -O- http://optimized-probes-app/ &
        done
        wait
        sleep 1
      done
  restartPolicy: Never
EOF
Apply the load test:
oc apply -f load-test-pod.yaml
Monitor probe behavior under load:
# Watch pod status during load test
oc get pods -l app=optimized-probes-app -w
Press Ctrl+C after observing for a few minutes.

Clean up the load test:
oc delete pod load-test
Monitoring and Troubleshooting
View Probe Status in OpenShift Console
Access the OpenShift web console (URL provided in your lab environment)

Navigate to your project:

Go to Projects → health-probes-lab
View deployment health:

Click on Workloads → Deployments
Select any deployment to see probe status
Monitor pod health:

Go to Workloads → Pods
Click on a pod to see detailed health information
Common Troubleshooting Commands
Check probe failures:
oc get events --field-selector reason=Unhealthy
View probe configuration:
oc get deployment optimized-probes-app -o yaml | grep -A 15 -B 5 "Probe"
Debug probe endpoints:
# Test probe endpoint manually
oc exec -it $(oc get pods -l app=optimized-probes-app -o jsonpath='{.items[0].metadata.name}') -- curl -I localhost:80/
Check resource constraints:
oc describe nodes | grep -A 5 "Allocated resources"
Lab Cleanup
Remove all created resources:
oc delete project health-probes-lab
Verify cleanup:
oc get projects | grep health-probes-lab
Conclusion
In this lab, you have successfully:

Created and configured health probes for OpenShift applications using HTTP, TCP, and command-based probe types
Implemented startup, readiness, and liveness probes with appropriate timing and threshold configurations
Tested probe functionality by simulating various failure scenarios and observing OpenShift's automated responses
Optimized probe settings for better performance and reliability in production environments
Monitored application health using both CLI commands and the OpenShift web console
Why This Matters: Health probes are critical for maintaining application reliability in production environments. They enable OpenShift to:

Automatically restart unhealthy containers (liveness probes)
Route traffic only to ready pods (readiness probes)
Provide sufficient startup time for slow-starting applications (startup probes)
Maintain service availability during deployments and failures
These skills are essential for the Red Hat Certified OpenShift Administrator exam and for managing production OpenShift clusters effectively. Proper health probe configuration ensures your applications remain available and responsive to users while minimizing manual intervention during failures.

Key Takeaways:

Always configure appropriate probe timeouts and failure thresholds for your application's characteristics
Use startup probes for applications with long initialization times
Monitor probe performance impact on system resources
Test probe configurations thoroughly before deploying to production
Combine different probe types (HTTP, TCP, exec) based on your application's architecture
