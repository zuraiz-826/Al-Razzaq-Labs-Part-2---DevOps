Lab 18: Implementing CI/CD for Multiple Environments
Objectives
By the end of this lab, students will be able to:

• Configure CI/CD pipelines to deploy applications across multiple environments (development, staging, production) • Implement parameterized configurations for environment-specific deployments • Create environment-specific configuration files and secrets management • Set up automated testing and validation for each deployment environment • Understand best practices for multi-environment CI/CD workflows • Troubleshoot common issues in multi-environment deployments

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Git version control • Familiarity with containerization concepts (Docker) • Knowledge of YAML syntax and configuration files • Understanding of basic CI/CD concepts • Experience with command-line interface operations • Completion of previous OpenShift labs or equivalent knowledge

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes: • OpenShift CLI (oc) tools • Git client • Text editors (nano, vim) • Docker runtime • Access to OpenShift cluster

Task 1: Setting Up the Multi-Environment Pipeline Structure
Subtask 1.1: Create Project Structure
First, let's create a comprehensive project structure that supports multiple environments.

Create the main project directory:
mkdir multi-env-cicd
cd multi-env-cicd
Initialize Git repository:
git init
git config user.name "Your Name"
git config user.email "your.email@example.com"
Create the directory structure:
mkdir -p {src,config/{dev,staging,prod},pipelines,manifests/{dev,staging,prod}}
mkdir -p scripts tests
Verify the structure:
tree
Expected output:

.
├── config
│   ├── dev
│   ├── prod
│   └── staging
├── manifests
│   ├── dev
│   ├── prod
│   └── staging
├── pipelines
├── scripts
├── src
└── tests
Subtask 1.2: Create Sample Application
Create a simple Node.js application:
cat > src/app.js << 'EOF'
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;
const environment = process.env.NODE_ENV || 'development';
const version = process.env.APP_VERSION || '1.0.0';

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Multi-Environment CI/CD!',
    environment: environment,
    version: version,
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    environment: environment,
    uptime: process.uptime()
  });
});

app.listen(port, () => {
  console.log(`App running on port ${port} in ${environment} environment`);
});
EOF
Create package.json:
cat > src/package.json << 'EOF'
{
  "name": "multi-env-app",
  "version": "1.0.0",
  "description": "Sample app for multi-environment CI/CD",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "test": "echo \"Running tests...\" && exit 0"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF
Create Dockerfile:
cat > src/Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --only=production

COPY . .

EXPOSE 3000

USER node

CMD ["npm", "start"]
EOF
Task 2: Creating Environment-Specific Configurations
Subtask 2.1: Development Environment Configuration
Create development configuration:
cat > config/dev/app-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: multi-env-dev
data:
  NODE_ENV: "development"
  APP_VERSION: "dev-latest"
  LOG_LEVEL: "debug"
  DATABASE_URL: "postgresql://dev-db:5432/appdb"
  REDIS_URL: "redis://dev-redis:6379"
EOF
Create development deployment manifest:
cat > manifests/dev/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-env-app
  namespace: multi-env-dev
  labels:
    app: multi-env-app
    environment: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: multi-env-app
  template:
    metadata:
      labels:
        app: multi-env-app
        environment: dev
    spec:
      containers:
      - name: app
        image: multi-env-app:dev-latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: NODE_ENV
        - name: APP_VERSION
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_VERSION
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
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
EOF
Create development service:
cat > manifests/dev/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: multi-env-app-service
  namespace: multi-env-dev
spec:
  selector:
    app: multi-env-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: ClusterIP
EOF
Subtask 2.2: Staging Environment Configuration
Create staging configuration:
cat > config/staging/app-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: multi-env-staging
data:
  NODE_ENV: "staging"
  APP_VERSION: "staging-latest"
  LOG_LEVEL: "info"
  DATABASE_URL: "postgresql://staging-db:5432/appdb"
  REDIS_URL: "redis://staging-redis:6379"
EOF
Create staging deployment manifest:
cat > manifests/staging/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-env-app
  namespace: multi-env-staging
  labels:
    app: multi-env-app
    environment: staging
spec:
  replicas: 2
  selector:
    matchLabels:
      app: multi-env-app
  template:
    metadata:
      labels:
        app: multi-env-app
        environment: staging
    spec:
      containers:
      - name: app
        image: multi-env-app:staging-latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: NODE_ENV
        - name: APP_VERSION
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_VERSION
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "400m"
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
EOF
Create staging service:
cat > manifests/staging/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: multi-env-app-service
  namespace: multi-env-staging
spec:
  selector:
    app: multi-env-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: ClusterIP
EOF
Subtask 2.3: Production Environment Configuration
Create production configuration:
cat > config/prod/app-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: multi-env-prod
data:
  NODE_ENV: "production"
  APP_VERSION: "prod-latest"
  LOG_LEVEL: "warn"
  DATABASE_URL: "postgresql://prod-db:5432/appdb"
  REDIS_URL: "redis://prod-redis:6379"
EOF
Create production deployment manifest:
cat > manifests/prod/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-env-app
  namespace: multi-env-prod
  labels:
    app: multi-env-app
    environment: prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: multi-env-app
  template:
    metadata:
      labels:
        app: multi-env-app
        environment: prod
    spec:
      containers:
      - name: app
        image: multi-env-app:prod-latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: NODE_ENV
        - name: APP_VERSION
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_VERSION
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
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
EOF
Create production service:
cat > manifests/prod/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: multi-env-app-service
  namespace: multi-env-prod
spec:
  selector:
    app: multi-env-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: LoadBalancer
EOF
Task 3: Creating the Multi-Environment CI/CD Pipeline
Subtask 3.1: Create Pipeline Scripts
Create build script:
cat > scripts/build.sh << 'EOF'
#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
IMAGE_TAG=${2:-latest}
IMAGE_NAME="multi-env-app"

echo "Building application for environment: $ENVIRONMENT"
echo "Image tag: $IMAGE_TAG"

# Build the Docker image
cd src
docker build -t ${IMAGE_NAME}:${ENVIRONMENT}-${IMAGE_TAG} .

echo "Build completed successfully!"
echo "Image: ${IMAGE_NAME}:${ENVIRONMENT}-${IMAGE_TAG}"
EOF

chmod +x scripts/build.sh
Create deployment script:
cat > scripts/deploy.sh << 'EOF'
#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
IMAGE_TAG=${2:-latest}
NAMESPACE="multi-env-${ENVIRONMENT}"

echo "Deploying to environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"

# Create namespace if it doesn't exist
oc create namespace $NAMESPACE --dry-run=client -o yaml | oc apply -f -

# Apply configuration
echo "Applying configuration..."
oc apply -f config/${ENVIRONMENT}/app-config.yaml

# Update image tag in deployment
sed "s/:${ENVIRONMENT}-latest/:${ENVIRONMENT}-${IMAGE_TAG}/g" manifests/${ENVIRONMENT}/deployment.yaml > /tmp/deployment-${ENVIRONMENT}.yaml

# Apply manifests
echo "Applying manifests..."
oc apply -f /tmp/deployment-${ENVIRONMENT}.yaml
oc apply -f manifests/${ENVIRONMENT}/service.yaml

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
oc rollout status deployment/multi-env-app -n $NAMESPACE --timeout=300s

echo "Deployment completed successfully!"
EOF

chmod +x scripts/deploy.sh
Create test script:
cat > scripts/test.sh << 'EOF'
#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
NAMESPACE="multi-env-${ENVIRONMENT}"

echo "Running tests for environment: $ENVIRONMENT"

# Wait for service to be available
echo "Waiting for service to be available..."
sleep 30

# Get service URL
SERVICE_URL=$(oc get service multi-env-app-service -n $NAMESPACE -o jsonpath='{.spec.clusterIP}')

if [ -z "$SERVICE_URL" ]; then
    echo "Error: Could not get service URL"
    exit 1
fi

echo "Testing service at: http://$SERVICE_URL"

# Test health endpoint
echo "Testing health endpoint..."
if oc exec -n $NAMESPACE deployment/multi-env-app -- curl -f http://localhost:3000/health; then
    echo "Health check passed!"
else
    echo "Health check failed!"
    exit 1
fi

# Test main endpoint
echo "Testing main endpoint..."
if oc exec -n $NAMESPACE deployment/multi-env-app -- curl -f http://localhost:3000/; then
    echo "Main endpoint test passed!"
else
    echo "Main endpoint test failed!"
    exit 1
fi

echo "All tests passed for environment: $ENVIRONMENT"
EOF

chmod +x scripts/test.sh
Subtask 3.2: Create GitHub Actions Pipeline
Create GitHub Actions directory:
mkdir -p .github/workflows
Create multi-environment pipeline:
cat > .github/workflows/multi-env-cicd.yml << 'EOF'
name: Multi-Environment CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  IMAGE_NAME: multi-env-app

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
      
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
      
    - name: Generate image metadata
      id: meta
      run: |
        if [[ $GITHUB_REF == refs/heads/main ]]; then
          echo "tags=prod-${{ github.sha }}" >> $GITHUB_OUTPUT
        elif [[ $GITHUB_REF == refs/heads/develop ]]; then
          echo "tags=staging-${{ github.sha }}" >> $GITHUB_OUTPUT
        else
          echo "tags=dev-${{ github.sha }}" >> $GITHUB_OUTPUT
        fi
        
    - name: Build Docker image
      run: |
        cd src
        docker build -t ${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.tags }} .
        
    - name: Run unit tests
      run: |
        cd src
        npm test

  deploy-dev:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop' || github.event_name == 'pull_request'
    environment: development
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Deploy to Development
      run: |
        echo "Deploying to development environment"
        # Add your OpenShift deployment commands here
        
    - name: Run integration tests
      run: |
        ./scripts/test.sh dev

  deploy-staging:
    needs: [build, deploy-dev]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment: staging
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Deploy to Staging
      run: |
        echo "Deploying to staging environment"
        # Add your OpenShift deployment commands here
        
    - name: Run staging tests
      run: |
        ./scripts/test.sh staging

  deploy-production:
    needs: [build, deploy-staging]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Deploy to Production
      run: |
        echo "Deploying to production environment"
        # Add your OpenShift deployment commands here
        
    - name: Run production smoke tests
      run: |
        ./scripts/test.sh prod
EOF
Subtask 3.3: Create Jenkins Pipeline (Alternative)
Create Jenkinsfile:
cat > Jenkinsfile << 'EOF'
pipeline {
    agent any
    
    environment {
        IMAGE_NAME = 'multi-env-app'
        REGISTRY = 'your-registry.com'
    }
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Target environment for deployment'
        )
        string(
            name: 'IMAGE_TAG',
            defaultValue: 'latest',
            description: 'Docker image tag'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                script {
                    sh "./scripts/build.sh ${params.ENVIRONMENT} ${params.IMAGE_TAG}"
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    sh "cd src && npm test"
                }
            }
        }
        
        stage('Deploy to Dev') {
            when {
                anyOf {
                    branch 'develop'
                    expression { params.ENVIRONMENT == 'dev' }
                }
            }
            steps {
                script {
                    sh "./scripts/deploy.sh dev ${params.IMAGE_TAG}"
                    sh "./scripts/test.sh dev"
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                anyOf {
                    branch 'develop'
                    expression { params.ENVIRONMENT == 'staging' }
                }
            }
            steps {
                script {
                    sh "./scripts/deploy.sh staging ${params.IMAGE_TAG}"
                    sh "./scripts/test.sh staging"
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                anyOf {
                    branch 'main'
                    expression { params.ENVIRONMENT == 'prod' }
                }
            }
            steps {
                script {
                    input message: 'Deploy to production?', ok: 'Deploy'
                    sh "./scripts/deploy.sh prod ${params.IMAGE_TAG}"
                    sh "./scripts/test.sh prod"
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
EOF
Task 4: Testing Multi-Environment Deployments
Subtask 4.1: Manual Testing of Each Environment
Test Development Environment:
# Build and deploy to development
./scripts/build.sh dev v1.0.0
./scripts/deploy.sh dev v1.0.0

# Verify deployment
oc get pods -n multi-env-dev
oc get services -n multi-env-dev

# Test the application
./scripts/test.sh dev
Test Staging Environment:
# Build and deploy to staging
./scripts/build.sh staging v1.0.0
./scripts/deploy.sh staging v1.0.0

# Verify deployment
oc get pods -n multi-env-staging
oc get services -n multi-env-staging

# Test the application
./scripts/test.sh staging
Test Production Environment:
# Build and deploy to production
./scripts/build.sh prod v1.0.0
./scripts/deploy.sh prod v1.0.0

# Verify deployment
oc get pods -n multi-env-prod
oc get services -n multi-env-prod

# Test the application
./scripts/test.sh prod
Subtask 4.2: Verify Environment-Specific Configurations
Check development configuration:
oc exec -n multi-env-dev deployment/multi-env-app -- curl http://localhost:3000/
Expected output should show:

{
  "message": "Hello from Multi-Environment CI/CD!",
  "environment": "development",
  "version": "dev-v1.0.0",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
Check staging configuration:
oc exec -n multi-env-staging deployment/multi-env-app -- curl http://localhost:3000/
Check production configuration:
oc exec -n multi-env-prod deployment/multi-env-app -- curl http://localhost:3000/
Subtask 4.3: Test Configuration Updates
Create configuration update script:
cat > scripts/update-config.sh << 'EOF'
#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
KEY=${2}
VALUE=${3}

if [ -z "$KEY" ] || [ -z "$VALUE" ]; then
    echo "Usage: $0 <environment> <key> <value>"
    exit 1
fi

echo "Updating configuration for environment: $ENVIRONMENT"
echo "Setting $KEY=$VALUE"

# Update the ConfigMap
oc patch configmap app-config -n multi-env-${ENVIRONMENT} -p "{\"data\":{\"$KEY\":\"$VALUE\"}}"

# Restart deployment to pick up new config
oc rollout restart deployment/multi-env-app -n multi-env-${ENVIRONMENT}

# Wait for rollout to complete
oc rollout status deployment/multi-env-app -n multi-env-${ENVIRONMENT}

echo "Configuration updated successfully!"
EOF

chmod +x scripts/update-config.sh
Test configuration update:
# Update development environment
./scripts/update-config.sh dev APP_VERSION "dev-v1.1.0"

# Verify the update
oc exec -n multi-env-dev deployment/multi-env-app -- curl http://localhost:3000/
Task 5: Implementing Advanced Pipeline Features
Subtask 5.1: Add Environment Promotion
Create promotion script:
cat > scripts/promote.sh << 'EOF'
#!/bin/bash

set -e

SOURCE_ENV=${1}
TARGET_ENV=${2}

if [ -z "$SOURCE_ENV" ] || [ -z "$TARGET_ENV" ]; then
    echo "Usage: $0 <source-environment> <target-environment>"
    echo "Example: $0 dev staging"
    exit 1
fi

echo "Promoting from $SOURCE_ENV to $TARGET_ENV"

# Get the current image from source environment
SOURCE_IMAGE=$(oc get deployment multi-env-app -n multi-env-${SOURCE_ENV} -o jsonpath='{.spec.template.spec.containers[0].image}')

if [ -z "$SOURCE_IMAGE" ]; then
    echo "Error: Could not get image from source environment"
    exit 1
fi

echo "Source image: $SOURCE_IMAGE"

# Extract tag and create new tag for target environment
SOURCE_TAG=$(echo $SOURCE_IMAGE | cut -d':' -f2)
BASE_TAG=$(echo $SOURCE_TAG | sed "s/${SOURCE_ENV}-//")
TARGET_TAG="${TARGET_ENV}-${BASE_TAG}"

echo "Promoting with tag: $TARGET_TAG"

# Tag the image for target environment
docker tag $SOURCE_IMAGE multi-env-app:$TARGET_TAG

# Deploy to target environment
./scripts/deploy.sh $TARGET_ENV $BASE_TAG

echo "Promotion completed successfully!"
EOF

chmod +x scripts/promote.sh
Test promotion:
# Promote from dev to staging
./scripts/promote.sh dev staging

# Verify the promotion
oc get deployment multi-env-app -n multi-env-staging -o jsonpath='{.spec.template.spec.containers[0].image}'
Subtask 5.2: Add Rollback Capability
Create rollback script:
cat > scripts/rollback.sh << 'EOF'
#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
REVISION=${2}

echo "Rolling back environment: $ENVIRONMENT"

if [ -n "$REVISION" ]; then
    echo "Rolling back to revision: $REVISION"
    oc rollout undo deployment/multi-env-app -n multi-env-${ENVIRONMENT} --to-revision=$REVISION
else
    echo "Rolling back to previous revision"
    oc rollout undo deployment/multi-env-app -n multi-env-${ENVIRONMENT}
fi

# Wait for rollback to complete
oc rollout status deployment/multi-env-app -n multi-env-${ENVIRONMENT}

echo "Rollback completed successfully!"
EOF

chmod +x scripts/rollback.sh
Test rollback:
# Check rollout history
oc rollout history deployment/multi-env-app -n multi-env-dev

# Perform rollback
./scripts/rollback.sh dev

# Verify rollback
oc get deployment multi-env-app -n multi-env-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
Subtask 5.3: Add Monitoring and Alerting
Create monitoring script:
cat > scripts/monitor.sh << 'EOF'
#!/bin/bash

ENVIRONMENT=${1:-dev}
NAMESPACE="multi-env-${ENVIRONMENT}"

echo "Monitoring environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"

while true; do
    echo "=== $(date) ==="
    
    # Check pod status
    echo "Pod Status:"
    oc get pods -n $NAMESPACE -l app=multi-env-app
    
    # Check service endpoints
    echo "Service Endpoints:"
    oc get endpoints -n $NAMESPACE
    
    # Check resource usage
    echo "Resource Usage:"
    oc top pods -n $NAMESPACE --no-headers 2>/dev/null || echo "Metrics not available"
    
    echo "---"
    sleep 30
done
EOF

chmod +x scripts/monitor.sh
Run monitoring (in a separate terminal):
./scripts/monitor.sh dev
Troubleshooting Common Issues
Issue 1: Deployment Fails Due to Resource Constraints
Problem: Pods fail to start due to insufficient resources.

Solution:

# Check resource usage
oc describe nodes

# Reduce resource requests in deployment manifests
# Edit manifests/*/deployment.yaml and reduce memory/CPU requests
Issue 2: Configuration Not Applied
Problem: ConfigMap changes don't take effect.

Solution:

# Restart deployment to pick up new configuration
oc rollout restart deployment/multi-env-app -n multi-env-dev

# Or delete pods to force recreation
oc delete pods -l app=multi-env-app -n multi-env-dev
Issue 3: Image Pull Errors
Problem: Cannot pull Docker images.

Solution:

# Check if image exists locally
docker images | grep multi-env-app

# Rebuild if necessary
./scripts/build.sh dev latest

# Check image registry configuration
oc describe pod <pod-name> -n <namespace>
Issue 4: Service Not Accessible
Problem: Cannot access the application service.

Solution:

# Check service configuration
oc get service multi-env-app-service -n multi-env-dev -o yaml

# Check if pods are ready
oc get pods -n multi-env-dev -l app=multi-env-app

# Test from within the cluster
oc exec -n multi-env-dev deployment/multi-env-app -- curl http://localhost:3000/health
Best Practices for Multi-Environment CI/CD
Security Considerations
Use separate service accounts for each environment:
# Create environment-specific service accounts
oc create serviceaccount multi-env-dev -n multi-env-dev
oc create serviceaccount multi-env-staging -n multi-env-staging
oc create serviceaccount multi-env-prod -n multi-env-prod
Implement proper RBAC:
cat > rbac-dev.yaml << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: multi-env-dev
  name: multi-env-dev-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: multi-env-dev-binding
  namespace: multi-env-dev
subjects:
- kind: ServiceAccount
  name: multi-env-dev
  namespace: multi-env-dev
roleRef:
  kind: Role
  name: multi-env-dev-role
  apiGroup: rbac.authorization.k8s.io
EOF

oc apply -f rbac-dev.yaml
Performance Optimization
Use resource limits and requests appropriately
Implement horizontal pod autoscaling:
cat > hpa.yaml << 'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: multi-env-app-hpa
  namespace: multi-env-prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: multi-env-app
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF

oc apply -f hpa.yaml
Conclusion
In this comprehensive lab, you have successfully implemented a multi-environment CI/CD pipeline that demonstrates enterprise-grade deployment practices. Here's what you accomplished:

Key Achievements
• Multi-Environment Setup: Created separate development, staging, and production environments with environment-specific configurations • **Parameterize
