Lab 20: Final Exam Preparation and Full Stack Deployment
Objectives
By the end of this lab, students will be able to:

Design and implement a complete OpenShift application workflow from development to production deployment
Integrate CI/CD pipelines using OpenShift Pipelines (Tekton)
Containerize applications using best practices with Podman and Docker
Implement horizontal pod autoscaling and resource management
Configure persistent storage and database connectivity
Set up monitoring and logging for production applications
Troubleshoot common deployment issues in OpenShift environments
Demonstrate proficiency in all key concepts required for the Red Hat Certified OpenShift Application Developer exam
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with containerization concepts (Docker/Podman)
Knowledge of Kubernetes/OpenShift fundamentals
Understanding of Git version control
Basic programming knowledge (Python, Node.js, or Java)
Completion of previous OpenShift labs or equivalent experience
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to access your environment. No need to build your own VM or install additional software.

Your lab environment includes:

OpenShift cluster access
Podman and Docker tools
Git client
OpenShift CLI (oc)
Tekton CLI (tkn)
Sample application code repositories
Task 1: Design Complete Application Architecture
Subtask 1.1: Plan the Full Stack Application
In this subtask, you'll design a three-tier web application architecture that demonstrates all OpenShift capabilities.

Step 1: Access your lab environment and open the terminal

# Verify your OpenShift cluster access
oc whoami
oc cluster-info
Step 2: Create the project structure for your full stack application

# Create a new project for the final deployment
oc new-project fullstack-final --display-name="Full Stack Final Project"

# Switch to the project
oc project fullstack-final
Step 3: Design the application components

Create a directory structure for your application:

# Create application directory structure
mkdir -p ~/fullstack-app/{frontend,backend,database,pipeline,monitoring}
cd ~/fullstack-app
Subtask 1.2: Set Up Application Code Base
Step 1: Clone the sample application repository

# Clone the sample full stack application
git clone https://github.com/openshift-examples/fullstack-demo.git
cd fullstack-demo

# Or create your own application structure
mkdir -p frontend backend database
Step 2: Create the backend API application

# Navigate to backend directory
cd backend

# Create a simple Node.js API
cat > package.json << 'EOF'
{
  "name": "fullstack-backend",
  "version": "1.0.0",
  "description": "Backend API for full stack demo",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "pg": "^8.8.0",
    "dotenv": "^16.0.3"
  }
}
EOF

# Create the main server file
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'postgresql',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'fullstack_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'password'
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// API endpoints
app.get('/api/users', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users ORDER BY id');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

app.post('/api/users', async (req, res) => {
  try {
    const { name, email } = req.body;
    const result = await pool.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
      [name, email]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

app.listen(port, () => {
  console.log(`Backend server running on port ${port}`);
});
EOF

# Create Dockerfile for backend
cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 3000

USER node

CMD ["npm", "start"]
EOF
Step 3: Create the frontend application

# Navigate to frontend directory
cd ../frontend

# Create a simple HTML frontend
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Full Stack OpenShift Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .form-group { margin: 20px 0; }
        input, button { padding: 10px; margin: 5px; }
        .user-list { margin-top: 30px; }
        .user-item { padding: 10px; border: 1px solid #ddd; margin: 5px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Full Stack OpenShift Application</h1>
        
        <div class="form-group">
            <h2>Add New User</h2>
            <input type="text" id="userName" placeholder="Name" />
            <input type="email" id="userEmail" placeholder="Email" />
            <button onclick="addUser()">Add User</button>
        </div>
        
        <div class="user-list">
            <h2>Users</h2>
            <div id="usersList"></div>
        </div>
    </div>

    <script>
        const API_BASE = window.location.protocol + '//' + window.location.hostname + ':3000/api';
        
        async function loadUsers() {
            try {
                const response = await fetch(`${API_BASE}/users`);
                const users = await response.json();
                const usersList = document.getElementById('usersList');
                usersList.innerHTML = users.map(user => 
                    `<div class="user-item">
                        <strong>${user.name}</strong> - ${user.email}
                    </div>`
                ).join('');
            } catch (error) {
                console.error('Error loading users:', error);
            }
        }
        
        async function addUser() {
            const name = document.getElementById('userName').value;
            const email = document.getElementById('userEmail').value;
            
            if (!name || !email) {
                alert('Please fill in both fields');
                return;
            }
            
            try {
                const response = await fetch(`${API_BASE}/users`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ name, email })
                });
                
                if (response.ok) {
                    document.getElementById('userName').value = '';
                    document.getElementById('userEmail').value = '';
                    loadUsers();
                }
            } catch (error) {
                console.error('Error adding user:', error);
            }
        }
        
        // Load users on page load
        loadUsers();
    </script>
</body>
</html>
EOF

# Create Dockerfile for frontend
cat > Dockerfile << 'EOF'
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF

# Create nginx configuration
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    server {
        listen 80;
        server_name localhost;

        location / {
            root /usr/share/nginx/html;
            index index.html;
        }

        location /api/ {
            proxy_pass http://backend-service:3000/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
EOF
Task 2: Implement Containerization Strategy
Subtask 2.1: Build Container Images
Step 1: Build the backend container image

# Navigate to backend directory
cd ~/fullstack-demo/backend

# Build the backend image using Podman
podman build -t fullstack-backend:latest .

# Tag the image for OpenShift registry
podman tag fullstack-backend:latest image-registry.openshift-image-registry.svc:5000/fullstack-final/backend:latest
Step 2: Build the frontend container image

# Navigate to frontend directory
cd ../frontend

# Build the frontend image
podman build -t fullstack-frontend:latest .

# Tag for OpenShift registry
podman tag fullstack-frontend:latest image-registry.openshift-image-registry.svc:5000/fullstack-final/frontend:latest
Step 3: Push images to OpenShift internal registry

# Login to OpenShift registry
oc registry login

# Push backend image
podman push image-registry.openshift-image-registry.svc:5000/fullstack-final/backend:latest

# Push frontend image
podman push image-registry.openshift-image-registry.svc:5000/fullstack-final/frontend:latest
Subtask 2.2: Create OpenShift Deployment Configurations
Step 1: Create database deployment

# Create PostgreSQL database deployment
cat > database-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgresql
  labels:
    app: postgresql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgresql
  template:
    metadata:
      labels:
        app: postgresql
    spec:
      containers:
      - name: postgresql
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: "fullstack_db"
        - name: POSTGRES_USER
          value: "postgres"
        - name: POSTGRES_PASSWORD
          value: "password"
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgresql
spec:
  selector:
    app: postgresql
  ports:
  - port: 5432
    targetPort: 5432
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# Apply database configuration
oc apply -f database-deployment.yaml
Step 2: Create backend deployment

# Create backend deployment configuration
cat > backend-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  labels:
    app: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: image-registry.openshift-image-registry.svc:5000/fullstack-final/backend:latest
        env:
        - name: DB_HOST
          value: "postgresql"
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: "fullstack_db"
        - name: DB_USER
          value: "postgres"
        - name: DB_PASSWORD
          value: "password"
        - name: PORT
          value: "3000"
        ports:
        - containerPort: 3000
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 3000
    targetPort: 3000
EOF

# Apply backend configuration
oc apply -f backend-deployment.yaml
Step 3: Create frontend deployment

# Create frontend deployment configuration
cat > frontend-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: image-registry.openshift-image-registry.svc:5000/fullstack-final/frontend:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: frontend-route
spec:
  to:
    kind: Service
    name: frontend-service
  port:
    targetPort: 80
EOF

# Apply frontend configuration
oc apply -f frontend-deployment.yaml
Task 3: Integrate CI/CD Pipelines
Subtask 3.1: Install OpenShift Pipelines
Step 1: Install Tekton Pipelines Operator

# Check if OpenShift Pipelines is already installed
oc get pods -n openshift-pipelines

# If not installed, create the subscription
cat > pipelines-subscription.yaml << 'EOF'
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-pipelines-operator
  namespace: openshift-operators
spec:
  channel: latest
  name: openshift-pipelines-operator-rh
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

# Apply the subscription (if needed)
oc apply -f pipelines-subscription.yaml
Step 2: Verify Tekton installation

# Wait for the operator to be ready
oc get pods -n openshift-pipelines

# Check Tekton CLI
tkn version
Subtask 3.2: Create CI/CD Pipeline
Step 1: Create pipeline tasks

# Create a comprehensive pipeline for the full stack application
cat > fullstack-pipeline.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: fullstack-pipeline
spec:
  params:
  - name: git-url
    type: string
    description: Git repository URL
  - name: git-revision
    type: string
    description: Git revision
    default: main
  - name: image-registry
    type: string
    description: Image registry URL
    default: image-registry.openshift-image-registry.svc:5000
  - name: project-name
    type: string
    description: OpenShift project name
    default: fullstack-final

  workspaces:
  - name: shared-workspace
  - name: docker-config

  tasks:
  - name: fetch-source
    taskRef:
      name: git-clone
      kind: ClusterTask
    workspaces:
    - name: output
      workspace: shared-workspace
    params:
    - name: url
      value: $(params.git-url)
    - name: revision
      value: $(params.git-revision)

  - name: build-backend
    taskRef:
      name: buildah
      kind: ClusterTask
    runAfter:
    - fetch-source
    workspaces:
    - name: source
      workspace: shared-workspace
    - name: dockerconfig
      workspace: docker-config
    params:
    - name: IMAGE
      value: $(params.image-registry)/$(params.project-name)/backend:$(params.git-revision)
    - name: CONTEXT
      value: ./backend
    - name: DOCKERFILE
      value: ./backend/Dockerfile

  - name: build-frontend
    taskRef:
      name: buildah
      kind: ClusterTask
    runAfter:
    - fetch-source
    workspaces:
    - name: source
      workspace: shared-workspace
    - name: dockerconfig
      workspace: docker-config
    params:
    - name: IMAGE
      value: $(params.image-registry)/$(params.project-name)/frontend:$(params.git-revision)
    - name: CONTEXT
      value: ./frontend
    - name: DOCKERFILE
      value: ./frontend/Dockerfile

  - name: deploy-application
    taskRef:
      name: openshift-client
      kind: ClusterTask
    runAfter:
    - build-backend
    - build-frontend
    workspaces:
    - name: manifest-dir
      workspace: shared-workspace
    params:
    - name: SCRIPT
      value: |
        # Update image tags in deployment files
        sed -i 's|backend:latest|backend:$(params.git-revision)|g' backend-deployment.yaml
        sed -i 's|frontend:latest|frontend:$(params.git-revision)|g' frontend-deployment.yaml
        
        # Apply updated deployments
        oc apply -f backend-deployment.yaml
        oc apply -f frontend-deployment.yaml
        
        # Wait for rollout
        oc rollout status deployment/backend
        oc rollout status deployment/frontend

  - name: run-tests
    taskRef:
      name: openshift-client
      kind: ClusterTask
    runAfter:
    - deploy-application
    workspaces:
    - name: manifest-dir
      workspace: shared-workspace
    params:
    - name: SCRIPT
      value: |
        # Wait for pods to be ready
        oc wait --for=condition=ready pod -l app=backend --timeout=300s
        oc wait --for=condition=ready pod -l app=frontend --timeout=300s
        
        # Test backend health endpoint
        BACKEND_POD=$(oc get pods -l app=backend -o jsonpath='{.items[0].metadata.name}')
        oc exec $BACKEND_POD -- curl -f http://localhost:3000/health
        
        echo "Application deployment and tests completed successfully!"
EOF

# Apply the pipeline
oc apply -f fullstack-pipeline.yaml
Step 2: Create pipeline resources

# Create workspace PVC for pipeline
cat > pipeline-pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pipeline-workspace-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
EOF

# Apply PVC
oc apply -f pipeline-pvc.yaml

# Create service account for pipeline
cat > pipeline-sa.yaml << 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pipeline-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pipeline-sa-binding
subjects:
- kind: ServiceAccount
  name: pipeline-sa
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
EOF

# Apply service account
oc apply -f pipeline-sa.yaml
Subtask 3.3: Execute the Pipeline
Step 1: Create a PipelineRun

# Create pipeline run configuration
cat > pipeline-run.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: fullstack-pipeline-run-$(date +%s)
spec:
  serviceAccountName: pipeline-sa
  pipelineRef:
    name: fullstack-pipeline
  params:
  - name: git-url
    value: https://github.com/your-username/fullstack-demo.git
  - name: git-revision
    value: main
  workspaces:
  - name: shared-workspace
    persistentVolumeClaim:
      claimName: pipeline-workspace-pvc
  - name: docker-config
    emptyDir: {}
EOF

# Start the pipeline
oc apply -f pipeline-run.yaml
Step 2: Monitor pipeline execution

# Watch pipeline runs
tkn pipelinerun list

# Get detailed logs
PIPELINE_RUN=$(tkn pipelinerun list -o name | head -1)
tkn pipelinerun logs $PIPELINE_RUN -f

# Check pipeline status
oc get pipelineruns
Task 4: Implement Scaling and Resource Management
Subtask 4.1: Configure Horizontal Pod Autoscaling
Step 1: Create HPA for backend service

# Create HPA configuration for backend
cat > backend-hpa.yaml << 'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
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
        periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
EOF

# Apply HPA
oc apply -f backend-hpa.yaml
Step 2: Create HPA for frontend service

# Create HPA configuration for frontend
cat > frontend-hpa.yaml << 'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: frontend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend
  minReplicas: 2
  maxReplicas: 8
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
EOF

# Apply HPA
oc apply -f frontend-hpa.yaml
Step 3: Test autoscaling

# Check HPA status
oc get hpa

# Generate load to test scaling
oc run load-generator --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://frontend-service/; done"

# Monitor scaling
watch oc get hpa
watch oc get pods
Subtask 4.2: Configure Resource Quotas and Limits
Step 1: Create resource quota for the project

# Create resource quota
cat > resource-quota.yaml << 'EOF'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: fullstack-quota
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    persistentvolumeclaims: "5"
    pods: "20"
    services: "10"
EOF

# Apply resource quota
oc apply -f resource-quota.yaml
Step 2: Create limit ranges

# Create limit range
cat > limit-range.yaml << 'EOF'
apiVersion: v1
kind: LimitRange
metadata:
  name: fullstack-limits
spec:
  limits:
  - default:
      cpu: "200m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    type: Container
  - max:
      cpu: "1"
      memory: "1Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
    type: Container
EOF

# Apply limit range
oc apply -f limit-range.yaml
Step 3: Verify resource management

# Check resource usage
oc describe quota fullstack-quota
oc describe limitrange fullstack-limits

# Monitor resource consumption
oc adm top pods
oc adm top nodes
Task 5: Set Up Monitoring and Logging
Subtask 5.1: Configure Application Monitoring
Step 1: Create ServiceMonitor for Prometheus

# Create ServiceMonitor for backend metrics
cat > backend-servicemonitor.yaml << 'EOF'
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: backend-monitor
  labels:
    app: backend
spec:
  selector:
    matchLabels:
      app: backend
  endpoints:
  - port: "3000"
    path: /metrics
    interval: 30s
EOF

# Apply ServiceMonitor
oc apply -f backend-servicemonitor.yaml
Step 2: Add health check endpoints

# Update backend server.js to include metrics endpoint
cat >> ~/fullstack-demo/backend/server.js << 'EOF'

// Metrics endpoint for monitoring
app.get('/metrics', (req, res) => {
  res.set('Content-Type', 'text/plain');
  res.send(`
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",endpoint="/api/users"} 42
http_requests_total{method="POST",endpoint="/api/users"} 12

# HELP app_uptime_seconds Application uptime in seconds
# TYPE app_uptime_seconds gauge
app_uptime_seconds ${process.uptime()}
  `);
});
EOF
Step 3: Create custom dashboard

# Create ConfigMap for Grafana dashboard
cat > grafana-dashboard.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: fullstack-dashboard
  labels:
    grafana_dashboard: "1"
data:
  fullstack-dashboard.json: |
    {
      "dashboard": {
        "title": "Full Stack Application Dashboard",
        "panels": [
          {
            "title": "Pod CPU Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(container_cpu_usage_seconds_total{pod=~\"backend-.*|frontend-.*\"}[5m])"
              }
            ]
          },
          {
            "title": "Pod Memory Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "container_memory_usage_bytes{pod=~\"backend-.*|frontend-.*\"}"
              }
            ]
          }
        ]
      }
    }
EOF

# Apply dashboard
oc apply -f grafana-dashboard.yaml
Subtask 5.2: Configure Centralized Logging
Step 1: Install OpenShift Logging Operator

# Create logging namespace
oc create namespace openshift-logging

# Create operator group
cat > logging-operatorgroup.yaml << 'EOF'
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: cluster-logging
  namespace: openshift-logging
spec:
  targetNamespaces:
  - openshift-logging
EOF

# Apply operator group
oc apply -f logging-operatorgroup.yaml
Step 2: Configure log forwarding

# Create ClusterLogForwarder
cat > log-forwarder.yaml << 'EOF'
apiVersion: logging.coreos.com/v1
kind: ClusterLogForwarder
metadata:
  name: instance
  namespace: openshift-logging
spec:
  outputs:
  - name: application-logs
    type: elasticsearch
    url: http://elasticsearch.openshift-logging.svc:9200
  pipelines:
  - name: application-pipeline
    inputRefs:
    - application
    filterRefs:
    - json-filter
    outputRefs:
    - application-logs
  filters:
  - name: json-filter
    type: json
    json:
      javascript: |
        const log = record.log;
        if (log) {
          try {
            const parsed = JSON.parse(log);
            record = Object.assign(record, parsed);
          } catch (e) {
            // Keep original log if not JSON
          }
        }
EOF

# Apply log forwarder
oc apply -f log-forwarder.yaml
Step 3: Verify logging configuration

# Check logging pods
oc get pods -n openshift-logging

# View application logs
oc logs -l app=backend -f
oc logs -l app=frontend -f

# Check log forwarding
oc get clusterlogforwarder -n openshift-logging
Task 6: Final Testing and Troubleshooting
Subtask 6.1: Comprehensive Application Testing
Step 1: Test application functionality

# Get application route
FRONTEND_URL=$(oc get route frontend-route -o jsonpath='{.spec.host}')
echo "Application URL: http://$FRONTEND_URL"

# Test backend API directly
BACKEND_POD=$(oc get pods -l app=backend -o jsonpath='{.items[0].metadata.name}')
oc exec $BACKEND_POD -- curl -f http://localhost:3000/health

# Test database connectivity
oc exec $BACKEND_POD -- curl -f http://localhost:3000/api/users
Step 2: Perform load testing

# Create load test script
cat > load-test.sh << 'EOF'
#!/bin/bash
FRONTEND_URL=$1
CONCURRENT_USERS
