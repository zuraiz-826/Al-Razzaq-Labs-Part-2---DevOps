Lab 19: Performance Tuning for Containers
Objectives
By the end of this lab, students will be able to:

Monitor container performance using docker stats and kubectl top commands
Analyze CPU, memory, and I/O metrics for containerized applications
Configure and adjust resource limits and requests for containers
Implement performance optimization strategies for containers under load
Troubleshoot performance bottlenecks in containerized environments
Apply best practices for container resource management
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with Docker containers and basic Docker commands
Knowledge of Kubernetes concepts including pods, deployments, and services
Understanding of system resource concepts (CPU, memory, I/O)
Experience with YAML configuration files
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Docker and Kubernetes already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

Ubuntu 22.04 LTS with Docker Engine
Kubernetes cluster (single-node setup)
kubectl command-line tool
Monitoring tools and utilities
Sample applications for testing
Task 1: Monitor Container Performance with Docker Stats and Kubectl Top
Subtask 1.1: Set Up Sample Applications
First, let's deploy sample applications to monitor their performance.

Step 1: Create a CPU-intensive Docker container

# Create a simple CPU stress container
docker run -d --name cpu-stress --cpus="1.0" --memory="512m" \
  alpine:latest sh -c "while true; do dd if=/dev/zero of=/dev/null bs=1M count=100; done"
Step 2: Create a memory-intensive Docker container

# Create a memory stress container
docker run -d --name memory-stress --memory="1g" \
  alpine:latest sh -c "while true; do dd if=/dev/zero of=/tmp/memory bs=1M count=500; sleep 5; rm /tmp/memory; done"
Step 3: Deploy a sample application in Kubernetes

# Create a namespace for our lab
kubectl create namespace performance-lab

# Create a deployment with resource specifications
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: performance-lab
spec:
  replicas: 3
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
        image: nginx:latest
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        ports:
        - containerPort: 80
EOF
Subtask 1.2: Monitor Docker Container Performance
Step 1: Use docker stats to monitor real-time performance

# Monitor all running containers
docker stats

# Monitor specific containers with custom format
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
Step 2: Analyze container resource usage

# Get detailed stats for a specific container
docker stats cpu-stress --no-stream

# Monitor container performance over time
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" --no-stream
Step 3: Export performance data for analysis

# Create a script to log performance data
cat << 'EOF' > monitor_docker.sh
#!/bin/bash
echo "Timestamp,Container,CPU%,Memory Usage,Memory Limit,Memory%,Net I/O,Block I/O" > docker_performance.csv
for i in {1..10}; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    docker stats --no-stream --format "$timestamp,{{.Container}},{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}},{{.NetIO}},{{.BlockIO}}" >> docker_performance.csv
    sleep 10
done
EOF

chmod +x monitor_docker.sh
./monitor_docker.sh &
Subtask 1.3: Monitor Kubernetes Container Performance
Step 1: Use kubectl top to monitor node and pod performance

# Monitor node resource usage
kubectl top nodes

# Monitor pod resource usage in all namespaces
kubectl top pods --all-namespaces

# Monitor pods in specific namespace
kubectl top pods -n performance-lab
Step 2: Get detailed resource information

# Describe node resources
kubectl describe nodes

# Get detailed pod resource information
kubectl describe pods -n performance-lab

# Check resource quotas and limits
kubectl get resourcequota -n performance-lab
Step 3: Monitor container metrics over time

# Create a monitoring script for Kubernetes
cat << 'EOF' > monitor_k8s.sh
#!/bin/bash
echo "Monitoring Kubernetes pod performance..."
echo "Timestamp,Pod,CPU,Memory" > k8s_performance.csv
for i in {1..10}; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    kubectl top pods -n performance-lab --no-headers | while read line; do
        echo "$timestamp,$line" >> k8s_performance.csv
    done
    sleep 30
done
EOF

chmod +x monitor_k8s.sh
./monitor_k8s.sh &
Task 2: Adjust Resource Limits for Containers
Subtask 2.1: Configure Docker Container Resource Limits
Step 1: Create containers with specific CPU limits

# Create container with CPU limit (0.5 CPU cores)
docker run -d --name limited-cpu --cpus="0.5" \
  alpine:latest sh -c "while true; do echo 'CPU limited container'; sleep 1; done"

# Create container with CPU shares (relative weight)
docker run -d --name cpu-shares --cpu-shares=512 \
  alpine:latest sh -c "while true; do echo 'CPU shares container'; sleep 1; done"
Step 2: Configure memory limits and swap

# Create container with memory limit and no swap
docker run -d --name memory-limited --memory="256m" --memory-swap="256m" \
  alpine:latest sh -c "while true; do echo 'Memory limited'; sleep 2; done"

# Create container with memory reservation
docker run -d --name memory-reserved --memory="512m" --memory-reservation="256m" \
  alpine:latest sh -c "while true; do echo 'Memory reserved'; sleep 2; done"
Step 3: Set I/O limits for containers

# Create container with block I/O limits
docker run -d --name io-limited \
  --device-read-bps /dev/sda:1mb \
  --device-write-bps /dev/sda:1mb \
  alpine:latest sh -c "while true; do dd if=/dev/zero of=/tmp/test bs=1M count=10; rm /tmp/test; sleep 5; done"
Subtask 2.2: Update Kubernetes Resource Limits
Step 1: Create a deployment with comprehensive resource specifications

cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-demo
  namespace: performance-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: resource-demo
  template:
    metadata:
      labels:
        app: resource-demo
    spec:
      containers:
      - name: app-container
        image: nginx:latest
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
            ephemeral-storage: 1Gi
          limits:
            cpu: 1000m
            memory: 1Gi
            ephemeral-storage: 2Gi
        ports:
        - containerPort: 80
EOF
Step 2: Create a LimitRange to enforce resource constraints

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: performance-lab
spec:
  limits:
  - default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
  - max:
      cpu: 2000m
      memory: 2Gi
    min:
      cpu: 50m
      memory: 64Mi
    type: Container
EOF
Step 3: Create a ResourceQuota for the namespace

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: namespace-quota
  namespace: performance-lab
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    pods: "10"
EOF
Subtask 2.3: Dynamic Resource Adjustment
Step 1: Update running container resources (Docker)

# Update CPU limit for running container
docker update --cpus="1.0" cpu-stress

# Update memory limit for running container
docker update --memory="1g" memory-stress

# Verify the changes
docker inspect cpu-stress | grep -A 10 "HostConfig"
Step 2: Update Kubernetes deployment resources

# Update deployment resources using kubectl patch
kubectl patch deployment web-app -n performance-lab -p='{"spec":{"template":{"spec":{"containers":[{"name":"nginx","resources":{"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"200m","memory":"256Mi"}}}]}}}}'

# Verify the update
kubectl describe deployment web-app -n performance-lab
Step 3: Use Horizontal Pod Autoscaler (HPA)

# Create HPA for automatic scaling
kubectl autoscale deployment web-app -n performance-lab --cpu-percent=70 --min=2 --max=10

# Check HPA status
kubectl get hpa -n performance-lab

# Create a more detailed HPA configuration
cat << EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
  namespace: performance-lab
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF
Task 3: Optimize Container Performance Under Load
Subtask 3.1: Generate Load for Testing
Step 1: Create a load testing tool container

# Create a load generator container
docker run -d --name load-generator \
  alpine:latest sh -c "apk add --no-cache curl && while true; do curl -s http://web-service.performance-lab.svc.cluster.local > /dev/null; sleep 0.1; done"
Step 2: Deploy a load testing pod in Kubernetes

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: load-tester
  namespace: performance-lab
spec:
  containers:
  - name: load-generator
    image: busybox:latest
    command: ["/bin/sh"]
    args: ["-c", "while true; do wget -q -O- http://web-app-service:80; sleep 0.1; done"]
  restartPolicy: Always
EOF
Step 3: Create a service for the web application

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
  namespace: performance-lab
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
Subtask 3.2: Implement Performance Optimizations
Step 1: Optimize container startup and resource allocation

# Create an optimized deployment with init containers
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: optimized-app
  namespace: performance-lab
spec:
  replicas: 3
  selector:
    matchLabels:
      app: optimized-app
  template:
    metadata:
      labels:
        app: optimized-app
    spec:
      initContainers:
      - name: init-setup
        image: busybox:latest
        command: ['sh', '-c', 'echo "Initializing application..." && sleep 2']
      containers:
      - name: nginx
        image: nginx:latest
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config
EOF
Step 2: Create optimized nginx configuration

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: performance-lab
data:
  nginx.conf: |
    events {
        worker_connections 1024;
        use epoll;
        multi_accept on;
    }
    
    http {
        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 65;
        keepalive_requests 100;
        
        gzip on;
        gzip_vary on;
        gzip_min_length 1024;
        gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
        
        server {
            listen 80;
            location / {
                root /usr/share/nginx/html;
                index index.html;
            }
        }
    }
EOF
Step 3: Implement container image optimization

# Create a Dockerfile for optimized container
cat << 'EOF' > Dockerfile.optimized
FROM nginx:alpine

# Remove unnecessary packages and files
RUN apk del --purge \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

# Copy optimized configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create non-root user
RUN addgroup -g 1001 -S nginx-user && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx-user -g nginx-user nginx-user

# Set proper permissions
RUN chown -R nginx-user:nginx-user /var/cache/nginx && \
    chown -R nginx-user:nginx-user /var/log/nginx && \
    chown -R nginx-user:nginx-user /etc/nginx/conf.d

USER nginx-user

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
EOF
Subtask 3.3: Monitor and Analyze Performance Under Load
Step 1: Create comprehensive monitoring script

cat << 'EOF' > performance_monitor.sh
#!/bin/bash

NAMESPACE="performance-lab"
DURATION=300  # 5 minutes
INTERVAL=10   # 10 seconds

echo "Starting performance monitoring for $DURATION seconds..."
echo "Timestamp,Node_CPU,Node_Memory,Pod_Count,Avg_Pod_CPU,Avg_Pod_Memory" > performance_report.csv

start_time=$(date +%s)
end_time=$((start_time + DURATION))

while [ $(date +%s) -lt $end_time ]; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Get node metrics
    node_metrics=$(kubectl top nodes --no-headers | awk '{print $2","$4}')
    
    # Get pod count
    pod_count=$(kubectl get pods -n $NAMESPACE --no-headers | wc -l)
    
    # Get average pod metrics
    pod_metrics=$(kubectl top pods -n $NAMESPACE --no-headers | awk '{cpu+=$2; mem+=$3; count++} END {if(count>0) print cpu/count","mem/count; else print "0,0"}')
    
    echo "$timestamp,$node_metrics,$pod_count,$pod_metrics" >> performance_report.csv
    
    sleep $INTERVAL
done

echo "Performance monitoring completed. Report saved to performance_report.csv"
EOF

chmod +x performance_monitor.sh
Step 2: Run load tests and monitor performance

# Start the performance monitor
./performance_monitor.sh &

# Generate sustained load
kubectl run load-generator --image=busybox --restart=Never -n performance-lab -- /bin/sh -c "while true; do wget -q -O- http://web-app-service:80; done"

# Monitor HPA scaling
watch kubectl get hpa -n performance-lab
Step 3: Analyze performance bottlenecks

# Create analysis script
cat << 'EOF' > analyze_performance.sh
#!/bin/bash

echo "=== Performance Analysis Report ==="
echo

echo "1. Container Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
echo

echo "2. Kubernetes Pod Performance:"
kubectl top pods -n performance-lab
echo

echo "3. Node Resource Utilization:"
kubectl top nodes
echo

echo "4. HPA Status:"
kubectl get hpa -n performance-lab
echo

echo "5. Resource Quotas:"
kubectl describe resourcequota -n performance-lab
echo

echo "6. Top Resource Consuming Pods:"
kubectl top pods -n performance-lab --sort-by=cpu
echo

echo "7. Container Restart Count:"
kubectl get pods -n performance-lab -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[0].restartCount
EOF

chmod +x analyze_performance.sh
./analyze_performance.sh
Subtask 3.4: Implement Advanced Optimization Techniques
Step 1: Configure CPU affinity and NUMA awareness

cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-optimized-app
  namespace: performance-lab
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cpu-optimized-app
  template:
    metadata:
      labels:
        app: cpu-optimized-app
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        resources:
          requests:
            cpu: 1000m
            memory: 512Mi
          limits:
            cpu: 2000m
            memory: 1Gi
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - cpu-optimized-app
              topologyKey: kubernetes.io/hostname
EOF
Step 2: Implement quality of service classes

# Guaranteed QoS class
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: guaranteed-pod
  namespace: performance-lab
spec:
  containers:
  - name: nginx
    image: nginx:latest
    resources:
      requests:
        cpu: 500m
        memory: 512Mi
      limits:
        cpu: 500m
        memory: 512Mi
EOF

# Burstable QoS class
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: burstable-pod
  namespace: performance-lab
spec:
  containers:
  - name: nginx
    image: nginx:latest
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
EOF
Step 3: Configure priority classes for critical workloads

cat << EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "High priority class for critical applications"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 100
globalDefault: false
description: "Low priority class for batch jobs"
EOF

# Deploy high-priority application
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
  namespace: performance-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: critical-app
  template:
    metadata:
      labels:
        app: critical-app
    spec:
      priorityClassName: high-priority
      containers:
      - name: nginx
        image: nginx:latest
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 1000m
            memory: 1Gi
EOF
Troubleshooting Common Issues
Issue 1: Container OOMKilled (Out of Memory)
Symptoms: Containers restart frequently with exit code 137

Solution:

# Check container logs for OOM events
kubectl logs <pod-name> -n performance-lab --previous

# Increase memory limits
kubectl patch deployment <deployment-name> -n performance-lab -p='{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"limits":{"memory":"1Gi"}}}]}}}}'
Issue 2: CPU Throttling
Symptoms: High CPU wait times, poor application performance

Solution:

# Check CPU throttling metrics
docker exec <container-id> cat /sys/fs/cgroup/cpu/cpu.stat

# Increase CPU limits
kubectl patch deployment <deployment-name> -n performance-lab -p='{"spec":{"template":{"spec":{"containers":[{"name":"<container-name>","resources":{"limits":{"cpu":"1000m"}}}]}}}}'
Issue 3: I/O Performance Issues
Symptoms: Slow disk operations, high I/O wait

Solution:

# Monitor I/O statistics
iostat -x 1

# Use faster storage classes
kubectl get storageclass

# Optimize container I/O
docker run --device-read-iops /dev/sda:1000 --device-write-iops /dev/sda:1000 <image>
Cleanup
After completing the lab, clean up the resources:

# Stop and remove Docker containers
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)

# Delete Kubernetes resources
kubectl delete namespace performance-lab

# Remove priority classes
kubectl delete priorityclass high-priority low-priority

# Stop monitoring scripts
pkill -f monitor_docker.sh
pkill -f monitor_k8s.sh
pkill -f performance_monitor.sh
Conclusion
In this comprehensive lab, you have successfully:

Monitored container performance using both Docker stats and kubectl top commands to gain real-time insights into CPU, memory, and I/O utilization
Configured resource limits and requests for containers in both Docker and Kubernetes environments, ensuring optimal resource allocation
Implemented performance optimization strategies including CPU affinity, quality of service classes, and horizontal pod autoscaling
Generated and analyzed performance data under various load conditions to identify bottlenecks and optimization opportunities
Applied advanced optimization techniques such as priority classes, anti-affinity rules, and optimized container configurations
Why This Matters: Container performance tuning is critical in production environments where resource efficiency directly impacts cost, scalability, and user experience. The skills you've developed in this lab enable you to:

Optimize resource utilization and reduce infrastructure costs
Ensure applications meet performance SLAs under varying load conditions
Implement proactive monitoring and scaling strategies
Troubleshoot performance issues in containerized environments
Apply best practices for container resource management in enterprise settings
These capabilities are essential for roles in DevOps, Site Reliability Engineering, and Cloud Architecture, particularly when working with containerized applications at scale. The monitoring and optimization techniques you've learned form the foundation for maintaining high-performance, cost-effective containerized infrastructure.
