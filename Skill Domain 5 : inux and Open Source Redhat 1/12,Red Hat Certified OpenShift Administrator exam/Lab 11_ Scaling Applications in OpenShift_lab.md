Lab 11: Scaling Applications in OpenShift
Objectives
By the end of this lab, you will be able to:

Scale applications manually using the oc scale command
Configure horizontal pod autoscaling (HPA) based on CPU and memory usage
Monitor scaling behavior and resource allocation in OpenShift
Understand the relationship between resource requests, limits, and autoscaling
Implement best practices for application scaling in production environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of OpenShift concepts (pods, deployments, services)
Familiarity with command-line interface operations
Knowledge of YAML configuration files
Understanding of Kubernetes resource management concepts
Completion of previous OpenShift labs covering deployment and service creation
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift installed and ready to use. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

OpenShift cluster with administrative access
Pre-installed oc command-line tool
Sample applications ready for deployment
Monitoring tools configured and accessible
Task 1: Manual Scaling with oc scale
Subtask 1.1: Deploy a Sample Application
First, let's deploy a simple web application that we can scale.

Login to OpenShift cluster:
oc login -u admin -p admin https://api.crc.testing:6443
Create a new project for this lab:
oc new-project scaling-lab
Deploy a sample application:
oc new-app --name=web-app --image=quay.io/redhattraining/hello-world-nginx:v1.0
Verify the deployment:
oc get pods
oc get deployment
You should see one pod running with the web-app deployment.

Subtask 1.2: Scale Up the Application Manually
Check current replica count:
oc get deployment web-app -o wide
Scale the application to 3 replicas:
oc scale deployment web-app --replicas=3
Monitor the scaling process:
oc get pods -w
Press Ctrl+C to stop watching after all pods are running.

Verify the scaling operation:
oc get deployment web-app
oc get pods -l app=web-app
You should now see 3 pods running.

Subtask 1.3: Scale Down the Application
Scale down to 1 replica:
oc scale deployment web-app --replicas=1
Observe the termination process:
oc get pods -l app=web-app -w
Verify the scale-down operation:
oc get deployment web-app
Task 2: Configure Auto-Scaling Policies
Subtask 2.1: Set Resource Requests and Limits
Before implementing autoscaling, we need to configure resource requests and limits for our application.

Create a deployment configuration with resource specifications:
cat > web-app-with-resources.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-autoscale
  labels:
    app: web-app-autoscale
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app-autoscale
  template:
    metadata:
      labels:
        app: web-app-autoscale
    spec:
      containers:
      - name: web-app
        image: quay.io/redhattraining/hello-world-nginx:v1.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
EOF
Apply the deployment:
oc apply -f web-app-with-resources.yaml
Create a service for the deployment:
oc expose deployment web-app-autoscale --port=8080 --target-port=8080
Verify the deployment and resource allocation:
oc describe deployment web-app-autoscale
oc get pods -l app=web-app-autoscale
Subtask 2.2: Create Horizontal Pod Autoscaler (HPA)
Create an HPA based on CPU utilization:
oc autoscale deployment web-app-autoscale --min=2 --max=10 --cpu-percent=50
Verify the HPA creation:
oc get hpa
oc describe hpa web-app-autoscale
Create a more advanced HPA using YAML for both CPU and memory:
cat > advanced-hpa.yaml << EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-advanced-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app-autoscale
  minReplicas: 2
  maxReplicas: 15
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
EOF
Delete the simple HPA and apply the advanced one:
oc delete hpa web-app-autoscale
oc apply -f advanced-hpa.yaml
Verify the advanced HPA:
oc get hpa web-app-advanced-hpa
oc describe hpa web-app-advanced-hpa
Subtask 2.3: Test Autoscaling with Load Generation
Create a load generator pod:
cat > load-generator.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: load-generator
spec:
  containers:
  - name: load-generator
    image: busybox:1.35
    command:
    - /bin/sh
    - -c
    - |
      while true; do
        wget -q -O- http://web-app-autoscale:8080/ > /dev/null 2>&1
        sleep 0.01
      done
  restartPolicy: Never
EOF
Deploy the load generator:
oc apply -f load-generator.yaml
Monitor the load generator:
oc logs load-generator -f
Press Ctrl+C after a few seconds to stop following logs.

Task 3: Monitor Scaling Behavior and Resource Allocation
Subtask 3.1: Monitor HPA Behavior
Watch the HPA status in real-time:
oc get hpa web-app-advanced-hpa -w
Keep this running in one terminal window.

In another terminal, monitor pod scaling:
oc get pods -l app=web-app-autoscale -w
Check resource utilization:
oc top pods -l app=web-app-autoscale
View detailed HPA events:
oc describe hpa web-app-advanced-hpa
Subtask 3.2: Analyze Scaling Events
Check deployment events:
oc describe deployment web-app-autoscale
View cluster events related to scaling:
oc get events --sort-by='.lastTimestamp' | grep -i scale
Monitor resource usage over time:
oc adm top pods -l app=web-app-autoscale --containers
Subtask 3.3: Test Scale-Down Behavior
Stop the load generator:
oc delete pod load-generator
Monitor the scale-down process:
oc get hpa web-app-advanced-hpa -w
Observe pod termination:
oc get pods -l app=web-app-autoscale -w
Verify final state:
oc get deployment web-app-autoscale
oc get hpa web-app-advanced-hpa
Subtask 3.4: Advanced Monitoring and Troubleshooting
Create a monitoring script to track scaling metrics:
cat > monitor-scaling.sh << 'EOF'
#!/bin/bash
echo "Monitoring OpenShift Application Scaling"
echo "========================================"
echo "Timestamp,Replicas,CPU_Usage,Memory_Usage,HPA_Target_CPU,HPA_Target_Memory"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    REPLICAS=$(oc get deployment web-app-autoscale -o jsonpath='{.status.replicas}' 2>/dev/null || echo "N/A")
    CPU_USAGE=$(oc top pods -l app=web-app-autoscale --no-headers 2>/dev/null | awk '{sum+=$2} END {print sum"m"}' || echo "N/A")
    MEMORY_USAGE=$(oc top pods -l app=web-app-autoscale --no-headers 2>/dev/null | awk '{sum+=$3} END {print sum"Mi"}' || echo "N/A")
    HPA_CPU=$(oc get hpa web-app-advanced-hpa -o jsonpath='{.status.currentMetrics[0].resource.current.averageUtilization}' 2>/dev/null || echo "N/A")
    HPA_MEMORY=$(oc get hpa web-app-advanced-hpa -o jsonpath='{.status.currentMetrics[1].resource.current.averageUtilization}' 2>/dev/null || echo "N/A")
    
    echo "$TIMESTAMP,$REPLICAS,$CPU_USAGE,$MEMORY_USAGE,$HPA_CPU%,$HPA_MEMORY%"
    sleep 30
done
EOF
Make the script executable and run it:
chmod +x monitor-scaling.sh
./monitor-scaling.sh
Press Ctrl+C to stop monitoring after observing several data points.

Check HPA status and conditions:
oc get hpa web-app-advanced-hpa -o yaml
Verify metrics server is working:
oc get apiservice v1beta1.metrics.k8s.io -o yaml
Troubleshooting Common Issues
Issue 1: HPA Shows "Unknown" Status
Problem: HPA displays "Unknown" for current metrics.

Solution:

# Check if metrics server is running
oc get pods -n openshift-monitoring | grep metrics

# Verify resource requests are set
oc describe deployment web-app-autoscale | grep -A 10 "Requests"

# Check HPA conditions
oc describe hpa web-app-advanced-hpa
Issue 2: Pods Not Scaling Despite High CPU Usage
Problem: Application doesn't scale even with high resource utilization.

Solution:

# Check HPA configuration
oc get hpa web-app-advanced-hpa -o yaml

# Verify deployment has correct labels
oc get deployment web-app-autoscale -o yaml | grep -A 5 labels

# Check for resource quotas
oc describe quota
Issue 3: Scaling Too Aggressive or Too Slow
Problem: Application scales too quickly or too slowly.

Solution: Adjust HPA behavior policies:

# Edit the HPA to modify scaling behavior
oc edit hpa web-app-advanced-hpa

# Look for the behavior section and adjust:
# - stabilizationWindowSeconds
# - scaleUp/scaleDown policies
# - periodSeconds values
Lab Cleanup
Remove all created resources:
oc delete hpa web-app-advanced-hpa
oc delete deployment web-app-autoscale
oc delete deployment web-app
oc delete service web-app-autoscale
oc delete -f load-generator.yaml --ignore-not-found
Delete the project:
oc delete project scaling-lab
Clean up local files:
rm -f web-app-with-resources.yaml advanced-hpa.yaml load-generator.yaml monitor-scaling.sh
Conclusion
In this comprehensive lab, you have successfully learned how to scale applications in OpenShift using both manual and automatic scaling techniques. You accomplished the following key tasks:

Manual Scaling: You learned to use the oc scale command to manually adjust the number of pod replicas, understanding how to scale applications up and down based on immediate needs.

Automatic Scaling: You configured Horizontal Pod Autoscalers (HPA) with both simple CPU-based scaling and advanced multi-metric scaling policies, including CPU and memory utilization targets with custom scaling behaviors.

Monitoring and Analysis: You implemented comprehensive monitoring solutions to track scaling behavior, resource allocation, and application performance during scaling events.

Best Practices: You learned the importance of setting appropriate resource requests and limits, configuring stabilization windows, and implementing gradual scaling policies to ensure stable application performance.

These scaling techniques are essential for maintaining application performance and cost efficiency in production OpenShift environments. Manual scaling provides immediate control for planned events, while autoscaling ensures your applications can handle varying workloads automatically. The monitoring skills you developed will help you optimize scaling policies and troubleshoot performance issues in real-world scenarios.

Understanding application scaling is crucial for the Red Hat Certified OpenShift Administrator exam and for managing production workloads effectively. The hands-on experience gained in this lab provides a solid foundation for implementing scalable, resilient applications in enterprise OpenShift environments.
