Lab 17: Role-Based Access Control (RBAC)
Objectives
By the end of this lab, students will be able to:

• Understand the fundamental concepts of Role-Based Access Control (RBAC) in Kubernetes/OpenShift • Create custom roles with specific permissions for different resources • Create custom cluster roles for cluster-wide permissions • Bind roles to users and service accounts using RoleBindings and ClusterRoleBindings • Test and validate access control by attempting to access restricted resources • Troubleshoot common RBAC permission issues • Implement security best practices using the principle of least privilege

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Kubernetes/OpenShift concepts (pods, services, deployments) • Familiarity with command-line interface operations • Basic knowledge of YAML file structure • Understanding of Linux user and group concepts • Access to kubectl or oc command-line tools

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines with OpenShift/Kubernetes pre-installed. Simply click Start Lab to begin - no need to build your own VM or install additional software.

Your lab environment includes: • Pre-configured Kubernetes cluster • kubectl command-line tool • Text editor (nano/vim) • All necessary permissions to complete the lab

Task 1: Understanding RBAC Components and Creating Custom Roles
Subtask 1.1: Explore Existing RBAC Components
First, let's examine the current RBAC setup in your cluster to understand the existing roles and permissions.

List existing cluster roles:
kubectl get clusterroles
Examine a specific cluster role (like view):
kubectl describe clusterrole view
List existing roles in the default namespace:
kubectl get roles -n default
Check current role bindings:
kubectl get rolebindings -n default
kubectl get clusterrolebindings
Subtask 1.2: Create a Custom Role for Pod Management
Now we'll create a custom role that allows specific operations on pods.

Create a role definition file:
cat > pod-reader-role.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
EOF
Apply the role:
kubectl apply -f pod-reader-role.yaml
Verify the role was created:
kubectl get role pod-reader -n default
kubectl describe role pod-reader -n default
Subtask 1.3: Create a Custom Role for Deployment Management
Create a more comprehensive role for managing deployments.

Create a deployment manager role:
cat > deployment-manager-role.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: deployment-manager
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
EOF
Apply the deployment manager role:
kubectl apply -f deployment-manager-role.yaml
Verify the role creation:
kubectl describe role deployment-manager -n default
Subtask 1.4: Create a Custom ClusterRole
Create a cluster-wide role for node monitoring.

Create a cluster role for node monitoring:
cat > node-monitor-clusterrole.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-monitor
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["nodes", "pods"]
  verbs: ["get", "list"]
EOF
Apply the cluster role:
kubectl apply -f node-monitor-clusterrole.yaml
Verify the cluster role:
kubectl describe clusterrole node-monitor
Task 2: Bind Roles to Users and Service Accounts
Subtask 2.1: Create Service Accounts for Testing
We'll create service accounts to test our RBAC configuration.

Create service accounts:
kubectl create serviceaccount pod-reader-sa -n default
kubectl create serviceaccount deployment-manager-sa -n default
kubectl create serviceaccount node-monitor-sa -n default
Verify service account creation:
kubectl get serviceaccounts -n default
Subtask 2.2: Create RoleBindings
Bind the roles to service accounts using RoleBindings.

Create a RoleBinding for pod-reader:
cat > pod-reader-binding.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: pod-reader-sa
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF
Apply the RoleBinding:
kubectl apply -f pod-reader-binding.yaml
Create a RoleBinding for deployment-manager:
cat > deployment-manager-binding.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployment-manager-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: deployment-manager-sa
  namespace: default
roleRef:
  kind: Role
  name: deployment-manager
  apiGroup: rbac.authorization.k8s.io
EOF
Apply the deployment manager binding:
kubectl apply -f deployment-manager-binding.yaml
Subtask 2.3: Create ClusterRoleBinding
Create a ClusterRoleBinding for the node monitor role.

Create a ClusterRoleBinding:
cat > node-monitor-binding.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-monitor-binding
subjects:
- kind: ServiceAccount
  name: node-monitor-sa
  namespace: default
roleRef:
  kind: ClusterRole
  name: node-monitor
  apiGroup: rbac.authorization.k8s.io
EOF
Apply the ClusterRoleBinding:
kubectl apply -f node-monitor-binding.yaml
Verify all bindings:
kubectl get rolebindings -n default
kubectl get clusterrolebindings | grep node-monitor
Subtask 2.4: Create User-Based RoleBinding
Create a RoleBinding for a hypothetical user.

Create a RoleBinding for a user:
cat > user-pod-reader-binding.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: user-pod-reader-binding
  namespace: default
subjects:
- kind: User
  name: alice
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF
Apply the user binding:
kubectl apply -f user-pod-reader-binding.yaml
Task 3: Test Access Control and Validate Permissions
Subtask 3.1: Create Test Resources
First, create some resources to test access against.

Create a test deployment:
cat > test-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-nginx
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-nginx
  template:
    metadata:
      labels:
        app: test-nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
EOF
Apply the test deployment:
kubectl apply -f test-deployment.yaml
Wait for pods to be ready:
kubectl wait --for=condition=ready pod -l app=test-nginx --timeout=60s
Subtask 3.2: Test Pod Reader Permissions
Test the pod-reader service account permissions.

Get the pod-reader service account token:
# Create a token for the service account
kubectl create token pod-reader-sa -n default --duration=3600s > pod-reader-token.txt
Test allowed operations (list pods):
# Use the token to test permissions
TOKEN=$(cat pod-reader-token.txt)
kubectl --token=$TOKEN get pods -n default
Test forbidden operations (try to delete a pod):
# This should fail with a forbidden error
kubectl --token=$TOKEN delete pod -l app=test-nginx -n default
Test log access (should be allowed):
# Get a pod name first
POD_NAME=$(kubectl get pods -l app=test-nginx -o jsonpath='{.items[0].metadata.name}')
kubectl --token=$TOKEN logs $POD_NAME -n default
Subtask 3.3: Test Deployment Manager Permissions
Test the deployment-manager service account permissions.

Get the deployment manager token:
kubectl create token deployment-manager-sa -n default --duration=3600s > deployment-manager-token.txt
Test deployment operations:
TOKEN=$(cat deployment-manager-token.txt)

# Should work - list deployments
kubectl --token=$TOKEN get deployments -n default

# Should work - scale deployment
kubectl --token=$TOKEN scale deployment test-nginx --replicas=3 -n default

# Should work - get pods
kubectl --token=$TOKEN get pods -n default
Test forbidden operations (try to access nodes):
# This should fail
kubectl --token=$TOKEN get nodes
Subtask 3.4: Test Node Monitor Permissions
Test the cluster-wide node monitor permissions.

Get the node monitor token:
kubectl create token node-monitor-sa -n default --duration=3600s > node-monitor-token.txt
Test node access:
TOKEN=$(cat node-monitor-token.txt)

# Should work - list nodes
kubectl --token=$TOKEN get nodes

# Should work - describe nodes
kubectl --token=$TOKEN describe nodes
Test forbidden operations:
# Should fail - try to create a pod
kubectl --token=$TOKEN run test-pod --image=nginx -n default
Subtask 3.5: Test Permission Boundaries
Verify that permissions are properly restricted.

Create a script to test multiple operations:
cat > test-permissions.sh << 'EOF'
#!/bin/bash

echo "=== Testing Pod Reader Permissions ==="
TOKEN=$(cat pod-reader-token.txt)
echo "✓ Testing pod list (should work):"
kubectl --token=$TOKEN get pods -n default

echo "✗ Testing pod deletion (should fail):"
kubectl --token=$TOKEN delete pod -l app=test-nginx -n default --dry-run=client

echo -e "\n=== Testing Deployment Manager Permissions ==="
TOKEN=$(cat deployment-manager-token.txt)
echo "✓ Testing deployment list (should work):"
kubectl --token=$TOKEN get deployments -n default

echo "✗ Testing node access (should fail):"
kubectl --token=$TOKEN get nodes

echo -e "\n=== Testing Node Monitor Permissions ==="
TOKEN=$(cat node-monitor-token.txt)
echo "✓ Testing node list (should work):"
kubectl --token=$TOKEN get nodes

echo "✗ Testing pod creation (should fail):"
kubectl --token=$TOKEN run test --image=nginx -n default --dry-run=client
EOF
Make the script executable and run it:
chmod +x test-permissions.sh
./test-permissions.sh
Subtask 3.6: Verify RBAC with kubectl auth can-i
Use the built-in authorization checking feature.

Check permissions for pod-reader service account:
# Check if pod-reader can list pods
kubectl auth can-i get pods --as=system:serviceaccount:default:pod-reader-sa -n default

# Check if pod-reader can delete pods
kubectl auth can-i delete pods --as=system:serviceaccount:default:pod-reader-sa -n default

# Check if pod-reader can access logs
kubectl auth can-i get pods/log --as=system:serviceaccount:default:pod-reader-sa -n default
Check permissions for deployment-manager service account:
# Check deployment permissions
kubectl auth can-i create deployments --as=system:serviceaccount:default:deployment-manager-sa -n default
kubectl auth can-i delete deployments --as=system:serviceaccount:default:deployment-manager-sa -n default

# Check node permissions (should be false)
kubectl auth can-i get nodes --as=system:serviceaccount:default:deployment-manager-sa
Check permissions for node-monitor service account:
# Check node permissions
kubectl auth can-i get nodes --as=system:serviceaccount:default:node-monitor-sa

# Check pod creation permissions (should be false)
kubectl auth can-i create pods --as=system:serviceaccount:default:node-monitor-sa -n default
Advanced RBAC Scenarios
Subtask 3.7: Create a Read-Only Role for Specific Resources
Create a more granular role for specific resource types.

Create a configmap reader role:
cat > configmap-reader-role.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: configmap-reader
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
  resourceNames: ["public-secret"]  # Only specific secret
EOF
Apply and test the role:
kubectl apply -f configmap-reader-role.yaml

# Create a service account and binding
kubectl create serviceaccount configmap-reader-sa -n default

cat > configmap-reader-binding.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: configmap-reader-binding
  namespace: default
subjects:
- kind: ServiceAccount
  name: configmap-reader-sa
  namespace: default
roleRef:
  kind: Role
  name: configmap-reader
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f configmap-reader-binding.yaml
Troubleshooting Common RBAC Issues
Common Issues and Solutions
Permission Denied Errors:

Check if the role has the correct verbs for the operation
Verify the RoleBinding is correctly configured
Ensure the service account exists in the correct namespace
ClusterRole vs Role Confusion:

Use ClusterRole for cluster-wide resources (nodes, namespaces)
Use Role for namespaced resources (pods, services, deployments)
Token Expiration:

Service account tokens have expiration times
Recreate tokens if they expire during testing
Debugging RBAC:

# Check what a service account can do
kubectl auth can-i --list --as=system:serviceaccount:default:pod-reader-sa -n default

# Get detailed information about roles
kubectl describe role pod-reader -n default
kubectl describe rolebinding pod-reader-binding -n default
Lab Cleanup
Clean up the resources created during this lab:

# Delete deployments
kubectl delete deployment test-nginx -n default

# Delete roles
kubectl delete role pod-reader deployment-manager configmap-reader -n default
kubectl delete clusterrole node-monitor

# Delete role bindings
kubectl delete rolebinding pod-reader-binding deployment-manager-binding user-pod-reader-binding configmap-reader-binding -n default
kubectl delete clusterrolebinding node-monitor-binding

# Delete service accounts
kubectl delete serviceaccount pod-reader-sa deployment-manager-sa node-monitor-sa configmap-reader-sa -n default

# Clean up files
rm -f *.yaml *.txt test-permissions.sh
Conclusion
In this comprehensive lab, you have successfully:

• Mastered RBAC Fundamentals: You learned the core components of Kubernetes RBAC including Roles, ClusterRoles, RoleBindings, and ClusterRoleBindings, understanding how they work together to control access to cluster resources.

• Created Custom Security Policies: You built custom roles with specific permissions, implementing the principle of least privilege by granting only the minimum permissions necessary for each role.

• Implemented Access Control: You successfully bound roles to service accounts and users, creating a secure access control system that restricts unauthorized operations while allowing legitimate access.

• Validated Security Controls: You thoroughly tested your RBAC configuration by attempting both allowed and forbidden operations, confirming that your security policies work as intended.

• Gained Troubleshooting Skills: You learned how to debug RBAC issues using tools like kubectl auth can-i and how to identify and resolve common permission problems.

Why This Matters: RBAC is a critical security feature in production Kubernetes environments. It ensures that users, applications, and services can only access the resources they need, reducing the risk of security breaches and accidental damage. The skills you've developed in this lab are essential for:

Enterprise Security: Implementing proper access controls in multi-tenant environments
Compliance Requirements: Meeting security standards and audit requirements
Operational Safety: Preventing accidental deletion or modification of critical resources
DevOps Best Practices: Enabling secure CI/CD pipelines with appropriate service account permissions
The hands-on experience you've gained with creating roles, testing permissions, and troubleshooting access issues will be invaluable as you work with Kubernetes in production environments. Remember to always follow the principle of least privilege and regularly audit your RBAC configurations to maintain a secure cluster.
