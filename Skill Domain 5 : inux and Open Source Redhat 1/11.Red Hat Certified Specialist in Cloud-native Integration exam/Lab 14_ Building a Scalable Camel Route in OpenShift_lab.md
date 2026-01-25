Lab 14: Building a Scalable Camel Route in OpenShift
Objectives
By the end of this lab, you will be able to:

Build and deploy a scalable Apache Camel route on OpenShift
Configure Kubernetes Horizontal Pod Autoscaler (HPA) for dynamic scaling
Implement monitoring and observability for Camel applications
Test and validate scaling behavior under load
Understand best practices for cloud-native integration patterns
Prerequisites
Before starting this lab, you should have:

Basic understanding of Apache Camel concepts and routing
Familiarity with OpenShift/Kubernetes fundamentals
Knowledge of containerization concepts
Understanding of REST APIs and HTTP protocols
Basic Linux command-line experience
Required Tools and Technologies
OpenShift 4.x cluster access
Apache Camel K operator
Prometheus and Grafana for monitoring
curl or similar HTTP client for testing
Ready-to-Use Cloud Machines
Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to access your environment. No need to build your own VM or install software - everything is ready to use!

Your lab environment includes:

OpenShift cluster with admin access
Pre-installed Camel K operator
Monitoring stack (Prometheus/Grafana)
Development tools and utilities
Task 1: Create a Scalable Camel Route
Subtask 1.1: Set Up the Project Environment
First, let's create a new OpenShift project and verify our environment.

Log into OpenShift CLI
# Login to your OpenShift cluster
oc login --server=https://api.your-cluster.com:6443 --username=admin

# Create a new project for our Camel application
oc new-project camel-scaling-lab

# Verify the project is created
oc project camel-scaling-lab
Verify Camel K Operator Installation
# Check if Camel K operator is installed
oc get csv -n openshift-operators | grep camel

# If not installed, install the Camel K operator
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: red-hat-camel-k
  namespace: openshift-operators
spec:
  channel: stable
  name: red-hat-camel-k
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
Initialize Camel K Integration Platform
# Create the integration platform
kamel install --wait

# Verify the platform is ready
kamel get platform
Subtask 1.2: Create the Scalable Camel Route
Now we'll create a Camel route that can handle HTTP requests and is designed for horizontal scaling.

Create the Main Camel Integration File
Create a file named scalable-route.java:

cat > scalable-route.java << 'EOF'
// camel-k: language=java
// camel-k: dependency=camel-jackson
// camel-k: dependency=camel-undertow
// camel-k: property=server.port=8080

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.rest.RestBindingMode;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

public class ScalableRoute extends RouteBuilder {
    
    private static final AtomicLong requestCounter = new AtomicLong(0);
    
    @Override
    public void configure() throws Exception {
        
        // Configure REST endpoint
        restConfiguration()
            .component("undertow")
            .host("0.0.0.0")
            .port(8080)
            .bindingMode(RestBindingMode.json);
        
        // Health check endpoint for Kubernetes probes
        rest("/health")
            .get()
            .to("direct:health");
        
        // Main API endpoint
        rest("/api/v1")
            .get("/process/{id}")
            .to("direct:processRequest")
            .post("/data")
            .to("direct:processData");
        
        // Metrics endpoint for monitoring
        rest("/metrics")
            .get()
            .to("direct:metrics");
        
        // Health check route
        from("direct:health")
            .setBody(constant("{\"status\":\"UP\",\"service\":\"camel-scaling-service\"}"))
            .setHeader("Content-Type", constant("application/json"));
        
        // Process GET request route
        from("direct:processRequest")
            .log("Processing request for ID: ${header.id} on pod: ${env:HOSTNAME}")
            .process(exchange -> {
                String id = exchange.getIn().getHeader("id", String.class);
                long count = requestCounter.incrementAndGet();
                
                // Simulate some processing time
                Thread.sleep(100 + (long)(Math.random() * 200));
                
                Map<String, Object> response = new HashMap<>();
                response.put("id", id);
                response.put("processed_by", System.getenv("HOSTNAME"));
                response.put("request_count", count);
                response.put("timestamp", System.currentTimeMillis());
                response.put("status", "processed");
                
                exchange.getIn().setBody(response);
            })
            .setHeader("Content-Type", constant("application/json"));
        
        // Process POST data route
        from("direct:processData")
            .log("Processing POST data on pod: ${env:HOSTNAME}")
            .process(exchange -> {
                long count = requestCounter.incrementAndGet();
                
                // Simulate heavier processing for POST requests
                Thread.sleep(200 + (long)(Math.random() * 300));
                
                Map<String, Object> response = new HashMap<>();
                response.put("processed_by", System.getenv("HOSTNAME"));
                response.put("request_count", count);
                response.put("timestamp", System.currentTimeMillis());
                response.put("status", "data_processed");
                response.put("message", "Data processing completed successfully");
                
                exchange.getIn().setBody(response);
            })
            .setHeader("Content-Type", constant("application/json"));
        
        // Metrics route for monitoring
        from("direct:metrics")
            .process(exchange -> {
                Map<String, Object> metrics = new HashMap<>();
                metrics.put("total_requests", requestCounter.get());
                metrics.put("pod_name", System.getenv("HOSTNAME"));
                metrics.put("uptime", System.currentTimeMillis());
                
                exchange.getIn().setBody(metrics);
            })
            .setHeader("Content-Type", constant("application/json"));
    }
}
EOF
Deploy the Camel Integration
# Deploy the integration with resource limits
kamel run scalable-route.java \
  --resource-limit cpu=500m \
  --resource-limit memory=512Mi \
  --resource-request cpu=100m \
  --resource-request memory=128Mi \
  --trait container.port=8080 \
  --trait service.enabled=true \
  --trait service.port=8080 \
  --name scalable-camel-service

# Wait for the integration to be ready
kamel get integrations -w
Verify the Deployment
# Check the integration status
oc get integrations

# Check the pods
oc get pods -l camel.apache.org/integration=scalable-camel-service

# Check the service
oc get svc scalable-camel-service
Subtask 1.3: Create OpenShift Route for External Access
Expose the Service
# Create a route to expose the service externally
oc expose service scalable-camel-service --name=camel-api-route

# Get the route URL
ROUTE_URL=$(oc get route camel-api-route -o jsonpath='{.spec.host}')
echo "Service URL: http://$ROUTE_URL"
Test the Basic Functionality
# Test health endpoint
curl -X GET http://$ROUTE_URL/health

# Test the API endpoint
curl -X GET http://$ROUTE_URL/api/v1/process/12345

# Test POST endpoint
curl -X POST http://$ROUTE_URL/api/v1/data \
  -H "Content-Type: application/json" \
  -d '{"test": "data", "value": 123}'

# Check metrics
curl -X GET http://$ROUTE_URL/metrics
Task 2: Set Up OpenShift Autoscaling
Subtask 2.1: Configure Resource Monitoring
Enable Metrics Collection
First, we need to ensure our pods expose metrics that the HPA can use.

# Create a ServiceMonitor for Prometheus scraping
cat > service-monitor.yaml << 'EOF'
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: camel-service-monitor
  namespace: camel-scaling-lab
  labels:
    app: scalable-camel-service
spec:
  selector:
    matchLabels:
      camel.apache.org/integration: scalable-camel-service
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
EOF

# Apply the ServiceMonitor
oc apply -f service-monitor.yaml
Verify Metrics Server
# Check if metrics server is running
oc get pods -n openshift-monitoring | grep metrics-server

# Test metrics collection
oc top pods
Subtask 2.2: Create Horizontal Pod Autoscaler
Create HPA Configuration
# Create HPA based on CPU utilization
cat > hpa-config.yaml << 'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: camel-service-hpa
  namespace: camel-scaling-lab
spec:
  scaleTargetRef:
    apiVersion: camel.apache.org/v1
    kind: Integration
    name: scalable-camel-service
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
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
EOF

# Apply the HPA configuration
oc apply -f hpa-config.yaml
Verify HPA Setup
# Check HPA status
oc get hpa camel-service-hpa

# Get detailed HPA information
oc describe hpa camel-service-hpa

# Monitor current resource usage
oc top pods -l camel.apache.org/integration=scalable-camel-service
Subtask 2.3: Configure Pod Disruption Budget
To ensure availability during scaling operations, let's create a Pod Disruption Budget.

# Create PDB configuration
cat > pdb-config.yaml << 'EOF'
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: camel-service-pdb
  namespace: camel-scaling-lab
spec:
  minAvailable: 1
  selector:
    matchLabels:
      camel.apache.org/integration: scalable-camel-service
EOF

# Apply the PDB
oc apply -f pdb-config.yaml

# Verify PDB
oc get pdb camel-service-pdb
Task 3: Monitor and Test Scaling Behavior
Subtask 3.1: Set Up Monitoring Dashboard
Create Custom Metrics for Camel Application
# Create a ConfigMap with custom Grafana dashboard
cat > grafana-dashboard.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: camel-scaling-dashboard
  namespace: camel-scaling-lab
  labels:
    grafana_dashboard: "1"
data:
  camel-scaling.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Camel Scaling Dashboard",
        "tags": ["camel", "scaling"],
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Pod Count",
            "type": "stat",
            "targets": [
              {
                "expr": "count(up{job=\"scalable-camel-service\"})",
                "legendFormat": "Active Pods"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "CPU Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(container_cpu_usage_seconds_total{pod=~\"scalable-camel-service.*\"}[5m]) * 100",
                "legendFormat": "{{pod}}"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
          }
        ],
        "time": {"from": "now-1h", "to": "now"},
        "refresh": "5s"
      }
    }
EOF

# Apply the dashboard
oc apply -f grafana-dashboard.yaml
Create Load Testing Script
# Create a load testing script
cat > load-test.sh << 'EOF'
#!/bin/bash

ROUTE_URL=$(oc get route camel-api-route -o jsonpath='{.spec.host}')
DURATION=${1:-300}  # Default 5 minutes
CONCURRENT=${2:-10}  # Default 10 concurrent requests

echo "Starting load test against: http://$ROUTE_URL"
echo "Duration: ${DURATION} seconds"
echo "Concurrent requests: ${CONCURRENT}"

# Function to make requests
make_requests() {
    local id=$1
    local end_time=$(($(date +%s) + DURATION))
    
    while [ $(date +%s) -lt $end_time ]; do
        # Mix of GET and POST requests
        if [ $((RANDOM % 2)) -eq 0 ]; then
            curl -s -X GET "http://$ROUTE_URL/api/v1/process/$id-$(date +%s)" > /dev/null
        else
            curl -s -X POST "http://$ROUTE_URL/api/v1/data" \
                -H "Content-Type: application/json" \
                -d "{\"worker\":\"$id\",\"timestamp\":$(date +%s)}" > /dev/null
        fi
        
        # Small delay to avoid overwhelming
        sleep 0.1
    done
}

# Start concurrent workers
for i in $(seq 1 $CONCURRENT); do
    make_requests $i &
done

echo "Load test started with $CONCURRENT workers"
echo "Monitor scaling with: watch 'oc get pods -l camel.apache.org/integration=scalable-camel-service'"
echo "Monitor HPA with: watch 'oc get hpa camel-service-hpa'"

# Wait for all background jobs to complete
wait

echo "Load test completed"
EOF

# Make the script executable
chmod +x load-test.sh
Subtask 3.2: Execute Load Testing and Monitor Scaling
Start Monitoring in Separate Terminals
Open multiple terminal sessions to monitor different aspects:

Terminal 1 - Monitor Pods:

# Watch pod scaling in real-time
watch 'oc get pods -l camel.apache.org/integration=scalable-camel-service'
Terminal 2 - Monitor HPA:

# Watch HPA metrics and decisions
watch 'oc get hpa camel-service-hpa'
Terminal 3 - Monitor Resource Usage:

# Watch resource consumption
watch 'oc top pods -l camel.apache.org/integration=scalable-camel-service'
Execute Load Test
In your main terminal:

# Start the load test (5 minutes with 15 concurrent workers)
./load-test.sh 300 15
Monitor Scaling Events
# Check HPA events
oc describe hpa camel-service-hpa

# Check integration events
oc describe integration scalable-camel-service

# View scaling events
oc get events --sort-by=.metadata.creationTimestamp | grep -i scale
Subtask 3.3: Analyze Scaling Behavior
Collect Scaling Metrics
# Create a script to collect metrics during the test
cat > collect-metrics.sh << 'EOF'
#!/bin/bash

LOGFILE="scaling-metrics-$(date +%Y%m%d-%H%M%S).log"
echo "Collecting metrics to: $LOGFILE"

# Collect metrics every 30 seconds
while true; do
    echo "=== $(date) ===" >> $LOGFILE
    echo "Pod Count:" >> $LOGFILE
    oc get pods -l camel.apache.org/integration=scalable-camel-service --no-headers | wc -l >> $LOGFILE
    
    echo "HPA Status:" >> $LOGFILE
    oc get hpa camel-service-hpa --no-headers >> $LOGFILE
    
    echo "Resource Usage:" >> $LOGFILE
    oc top pods -l camel.apache.org/integration=scalable-camel-service --no-headers >> $LOGFILE
    
    echo "" >> $LOGFILE
    sleep 30
done
EOF

chmod +x collect-metrics.sh

# Run metrics collection in background
./collect-metrics.sh &
METRICS_PID=$!
Test Different Load Patterns
# Test 1: Gradual load increase
echo "Test 1: Gradual load increase"
./load-test.sh 180 5
sleep 60
./load-test.sh 180 10
sleep 60
./load-test.sh 180 20

# Test 2: Spike load
echo "Test 2: Spike load test"
./load-test.sh 120 25

# Test 3: Sustained high load
echo "Test 3: Sustained high load"
./load-test.sh 600 15
Verify Scale-Down Behavior
# After load tests, monitor scale-down
echo "Monitoring scale-down behavior..."
watch 'echo "Pods: $(oc get pods -l camel.apache.org/integration=scalable-camel-service --no-headers | wc -l)"; oc get hpa camel-service-hpa'

# Stop metrics collection
kill $METRICS_PID
Subtask 3.4: Performance Analysis and Optimization
Analyze Response Times Under Load
# Create a response time testing script
cat > response-time-test.sh << 'EOF'
#!/bin/bash

ROUTE_URL=$(oc get route camel-api-route -o jsonpath='{.spec.host}')
REQUESTS=${1:-100}

echo "Testing response times with $REQUESTS requests"
echo "URL: http://$ROUTE_URL"

# Test GET endpoint response times
echo "Testing GET endpoint..."
for i in $(seq 1 $REQUESTS); do
    response_time=$(curl -w "%{time_total}" -s -o /dev/null "http://$ROUTE_URL/api/v1/process/test-$i")
    echo "Request $i: ${response_time}s"
done | awk '{sum+=$3; count++} END {print "Average response time:", sum/count "s"}'

# Test POST endpoint response times
echo "Testing POST endpoint..."
for i in $(seq 1 $REQUESTS); do
    response_time=$(curl -w "%{time_total}" -s -o /dev/null \
        -X POST "http://$ROUTE_URL/api/v1/data" \
        -H "Content-Type: application/json" \
        -d "{\"test\":\"data-$i\"}")
    echo "Request $i: ${response_time}s"
done | awk '{sum+=$3; count++} END {print "Average response time:", sum/count "s"}'
EOF

chmod +x response-time-test.sh

# Run response time tests
./response-time-test.sh 50
Check Application Logs for Performance Issues
# View logs from all pods
oc logs -l camel.apache.org/integration=scalable-camel-service --tail=100

# Check for any errors or warnings
oc logs -l camel.apache.org/integration=scalable-camel-service | grep -i error

# Monitor real-time logs during load
oc logs -f -l camel.apache.org/integration=scalable-camel-service
Troubleshooting Common Issues
Issue 1: HPA Not Scaling
Symptoms: Pods not scaling despite high CPU usage

Solutions:

# Check metrics server
oc get apiservice v1beta1.metrics.k8s.io -o yaml

# Verify resource requests are set
oc describe integration scalable-camel-service | grep -A 10 "Resource Requests"

# Check HPA conditions
oc describe hpa camel-service-hpa | grep -A 10 Conditions
Issue 2: Slow Scaling Response
Symptoms: Scaling takes too long to respond to load changes

Solutions:

# Adjust HPA behavior settings
oc patch hpa camel-service-hpa --type='merge' -p='
{
  "spec": {
    "behavior": {
      "scaleUp": {
        "stabilizationWindowSeconds": 30
      }
    }
  }
}'
Issue 3: Integration Fails to Start
Symptoms: Camel integration pods failing to start

Solutions:

# Check integration status
kamel describe integration scalable-camel-service

# Check pod events
oc describe pod -l camel.apache.org/integration=scalable-camel-service

# Verify Camel K platform
kamel get platform -o yaml
Conclusion
In this lab, you have successfully:

Built a Scalable Camel Route: Created a cloud-native Apache Camel integration that can handle HTTP requests efficiently and is designed for horizontal scaling in OpenShift.

Implemented Autoscaling: Configured Kubernetes Horizontal Pod Autoscaler (HPA) to automatically scale your Camel application based on CPU and memory utilization, ensuring optimal resource usage and performance.

Monitored Scaling Behavior: Set up comprehensive monitoring and testing procedures to validate that your application scales correctly under various load conditions, including gradual increases, spike loads, and sustained high traffic.

Key Takeaways
Cloud-Native Integration: Modern integration solutions must be designed with scalability, observability, and resilience in mind from the ground up.

Resource Management: Proper resource requests and limits are crucial for effective autoscaling and cluster resource management.

Monitoring and Observability: Comprehensive monitoring enables proactive scaling decisions and helps identify performance bottlenecks before they impact users.

Load Testing: Regular load testing validates that your scaling configuration works correctly and helps identify optimal scaling parameters.

Real-World Applications
The skills you've learned in this lab are directly applicable to:

Enterprise Integration: Building scalable integration solutions that can handle varying loads in production environments
Microservices Architecture: Creating resilient, auto-scaling microservices that adapt to demand
Cloud Migration: Modernizing legacy integration solutions for cloud-native platforms
DevOps Practices: Implementing infrastructure-as-code and automated scaling policies
This lab demonstrates the power of combining Apache Camel's integration capabilities with OpenShift's container orchestration features to create robust, scalable integration solutions that can adapt to changing business demands automatically.
