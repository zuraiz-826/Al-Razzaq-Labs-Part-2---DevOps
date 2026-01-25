Lab 9: Configuring and Managing Network Policies
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of Kubernetes Network Policies in OpenShift
Create and configure network policies to control pod-to-pod communication
Implement ingress and egress traffic rules for enhanced security
Test network policy effectiveness using practical scenarios
Modify and troubleshoot network policies based on specific use cases
Apply network segmentation best practices in containerized environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Kubernetes/OpenShift concepts (pods, services, namespaces)
Familiarity with YAML syntax and structure
Knowledge of basic networking concepts (IP addresses, ports, protocols)
Experience with command-line interface operations
Understanding of labels and selectors in Kubernetes
Completion of previous OpenShift administration labs or equivalent experience
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift cluster access. Simply click Start Lab to begin - no need to build your own virtual machine or install additional software.

Your lab environment includes:

OpenShift cluster with administrative access
Pre-installed oc command-line tool
Network policy-enabled cluster networking
Sample applications for testing
Task 1: Understanding Network Policies and Initial Setup
Subtask 1.1: Verify Cluster Network Policy Support
First, let's verify that your OpenShift cluster supports network policies and examine the current networking configuration.

Check cluster network configuration:
oc get network.config.openshift.io cluster -o yaml
Verify the network plugin supports policies:
oc get clusternetwork -o yaml
List existing network policies across all namespaces:
oc get networkpolicy --all-namespaces
Subtask 1.2: Create Test Namespaces and Applications
We'll create multiple namespaces to demonstrate network policy functionality.

Create three test namespaces:
oc new-project frontend-app
oc new-project backend-app
oc new-project database-app
Deploy test applications in each namespace:
Frontend Application:

oc project frontend-app
oc new-app --name=frontend --image=nginx:latest
oc expose svc/frontend
Backend Application:

oc project backend-app
oc new-app --name=backend --image=httpd:latest
oc expose svc/backend
Database Application:

oc project database-app
oc new-app --name=database --image=mysql:8.0 \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=testdb
Add labels to namespaces for policy targeting:
oc label namespace frontend-app tier=frontend
oc label namespace backend-app tier=backend
oc label namespace database-app tier=database
Verify deployments are running:
oc get pods --all-namespaces | grep -E "(frontend|backend|database)"
Subtask 1.3: Test Initial Connectivity
Before implementing network policies, let's test the default connectivity between applications.

Get pod and service information:
oc get pods,svc -n frontend-app
oc get pods,svc -n backend-app
oc get pods,svc -n database-app
Test connectivity from frontend to backend:
FRONTEND_POD=$(oc get pods -n frontend-app -o jsonpath='{.items[0].metadata.name}')
BACKEND_SVC_IP=$(oc get svc backend -n backend-app -o jsonpath='{.spec.clusterIP}')

oc exec -n frontend-app $FRONTEND_POD -- curl -s --connect-timeout 5 http://$BACKEND_SVC_IP:8080
Test connectivity from backend to database:
BACKEND_POD=$(oc get pods -n backend-app -o jsonpath='{.items[0].metadata.name}')
DATABASE_SVC_IP=$(oc get svc database -n database-app -o jsonpath='{.spec.clusterIP}')

oc exec -n backend-app $BACKEND_POD -- nc -zv $DATABASE_SVC_IP 3306
Task 2: Creating and Implementing Network Policies
Subtask 2.1: Create a Deny-All Default Policy
We'll start by creating a default deny-all policy to establish a secure baseline.

Create a deny-all ingress policy for the database namespace:
cat << 'EOF' > database-deny-all.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: database-app
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF
Apply the policy:
oc apply -f database-deny-all.yaml
Verify the policy was created:
oc get networkpolicy -n database-app
oc describe networkpolicy deny-all-ingress -n database-app
Subtask 2.2: Test the Deny-All Policy
Test connectivity after applying the deny-all policy:
BACKEND_POD=$(oc get pods -n backend-app -o jsonpath='{.items[0].metadata.name}')
DATABASE_SVC_IP=$(oc get svc database -n database-app -o jsonpath='{.spec.clusterIP}')

# This should now fail or timeout
oc exec -n backend-app $BACKEND_POD -- timeout 10 nc -zv $DATABASE_SVC_IP 3306
The connection should fail, demonstrating that the network policy is working.

Subtask 2.3: Create Selective Allow Policies
Now we'll create policies that allow specific traffic patterns.

Create a policy to allow backend access to database:
cat << 'EOF' > allow-backend-to-database.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: database-app
spec:
  podSelector:
    matchLabels:
      deployment: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 3306
EOF
Apply the backend-to-database policy:
oc apply -f allow-backend-to-database.yaml
Create a policy for backend namespace to control ingress:
cat << 'EOF' > backend-ingress-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: backend-app
spec:
  podSelector:
    matchLabels:
      deployment: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080
EOF
Apply the frontend-to-backend policy:
oc apply -f backend-ingress-policy.yaml
Subtask 2.4: Create Egress Policies
Implement egress policies to control outbound traffic.

Create an egress policy for the frontend namespace:
cat << 'EOF' > frontend-egress-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-egress-policy
  namespace: frontend-app
spec:
  podSelector:
    matchLabels:
      deployment: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 8080
  - to: []
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF
Apply the frontend egress policy:
oc apply -f frontend-egress-policy.yaml
Task 3: Testing Network Policies
Subtask 3.1: Comprehensive Connectivity Testing
Test allowed connections:
# Test frontend to backend (should work)
FRONTEND_POD=$(oc get pods -n frontend-app -o jsonpath='{.items[0].metadata.name}')
BACKEND_SVC_IP=$(oc get svc backend -n backend-app -o jsonpath='{.spec.clusterIP}')

echo "Testing frontend to backend connection:"
oc exec -n frontend-app $FRONTEND_POD -- curl -s --connect-timeout 5 http://$BACKEND_SVC_IP:8080 | head -5

# Test backend to database (should work)
BACKEND_POD=$(oc get pods -n backend-app -o jsonpath='{.items[0].metadata.name}')
DATABASE_SVC_IP=$(oc get svc database -n database-app -o jsonpath='{.spec.clusterIP}')

echo "Testing backend to database connection:"
oc exec -n backend-app $BACKEND_POD -- timeout 5 nc -zv $DATABASE_SVC_IP 3306
Test blocked connections:
# Test frontend to database (should fail)
echo "Testing frontend to database connection (should fail):"
oc exec -n frontend-app $FRONTEND_POD -- timeout 5 nc -zv $DATABASE_SVC_IP 3306

# Test external access to backend without going through frontend
echo "Testing direct external access to backend:"
oc get route backend -n backend-app 2>/dev/null || echo "No direct route exists (good!)"
Subtask 3.2: Create a Test Pod for Verification
Deploy a test pod in a separate namespace:
oc new-project test-namespace
oc run test-pod --image=busybox --restart=Never -- sleep 3600
Test connectivity from the test pod:
# This should fail due to network policies
DATABASE_SVC_IP=$(oc get svc database -n database-app -o jsonpath='{.spec.clusterIP}')
oc exec test-pod -n test-namespace -- timeout 5 nc -zv $DATABASE_SVC_IP 3306
Subtask 3.3: Monitor Network Policy Effects
View network policy details:
oc get networkpolicy --all-namespaces
oc describe networkpolicy -n database-app
oc describe networkpolicy -n backend-app
oc describe networkpolicy -n frontend-app
Check pod labels to understand policy matching:
oc get pods --show-labels -n frontend-app
oc get pods --show-labels -n backend-app
oc get pods --show-labels -n database-app
Task 4: Modifying Policies Based on Use Cases
Subtask 4.1: Implement Time-Based Access Scenario
Create a more complex policy that allows multiple sources with different port restrictions.

Create a multi-source database access policy:
cat << 'EOF' > database-multi-access.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-multi-access
  namespace: database-app
spec:
  podSelector:
    matchLabels:
      deployment: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 3306
  - from:
    - namespaceSelector:
        matchLabels:
          name: test-namespace
    - podSelector:
        matchLabels:
          role: admin
    ports:
    - protocol: TCP
      port: 3306
EOF
Replace the existing database policy:
oc delete networkpolicy deny-all-ingress -n database-app
oc delete networkpolicy allow-backend-to-database -n database-app
oc apply -f database-multi-access.yaml
Subtask 4.2: Create Application-Specific Policies
Label the test pod as admin:
oc label pod test-pod role=admin -n test-namespace
oc label namespace test-namespace name=test-namespace
Test the updated policy:
# Test admin access from test namespace (should now work)
DATABASE_SVC_IP=$(oc get svc database -n database-app -o jsonpath='{.spec.clusterIP}')
oc exec test-pod -n test-namespace -- timeout 5 nc -zv $DATABASE_SVC_IP 3306
Subtask 4.3: Implement Logging and Monitoring Policy
Create a policy that allows monitoring tools access:
cat << 'EOF' > allow-monitoring.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring
  namespace: backend-app
spec:
  podSelector:
    matchLabels:
      deployment: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080
  - from:
    - namespaceSelector:
        matchLabels:
          name: openshift-monitoring
    ports:
    - protocol: TCP
      port: 8080
    - protocol: TCP
      port: 8443
EOF
Apply the monitoring policy:
oc apply -f allow-monitoring.yaml
Subtask 4.4: Create Emergency Access Override
Create an emergency access policy:
cat << 'EOF' > emergency-access.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: emergency-access
  namespace: database-app
  labels:
    emergency: "true"
spec:
  podSelector:
    matchLabels:
      deployment: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: emergency-admin
    ports:
    - protocol: TCP
      port: 3306
EOF
Apply emergency access (but don't activate yet):
# Save for emergency use
echo "Emergency policy created but not applied"
echo "To activate: oc apply -f emergency-access.yaml"
Task 5: Advanced Policy Scenarios and Troubleshooting
Subtask 5.1: Implement IP Block Restrictions
Create a policy with IP block restrictions:
cat << 'EOF' > ip-block-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ip-block-policy
  namespace: frontend-app
spec:
  podSelector:
    matchLabels:
      deployment: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 10.0.0.0/8
        except:
        - 10.1.0.0/16
    ports:
    - protocol: TCP
      port: 80
EOF
Apply and test the IP block policy:
oc apply -f ip-block-policy.yaml
Subtask 5.2: Policy Troubleshooting
Common troubleshooting commands:
# Check policy syntax and status
oc get networkpolicy --all-namespaces -o wide

# Verify pod labels match policy selectors
oc get pods --show-labels -n database-app

# Check namespace labels
oc get namespaces --show-labels

# Describe policies for detailed information
oc describe networkpolicy -n database-app
Test policy conflicts:
# Create conflicting policies to demonstrate resolution
cat << 'EOF' > conflicting-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: conflicting-policy
  namespace: database-app
spec:
  podSelector:
    matchLabels:
      deployment: database
  policyTypes:
  - Ingress
  ingress: []  # This denies all ingress
EOF
oc apply -f conflicting-policy.yaml

# Test connectivity (should fail due to conflict)
BACKEND_POD=$(oc get pods -n backend-app -o jsonpath='{.items[0].metadata.name}')
DATABASE_SVC_IP=$(oc get svc database -n database-app -o jsonpath='{.spec.clusterIP}')
oc exec -n backend-app $BACKEND_POD -- timeout 5 nc -zv $DATABASE_SVC_IP 3306

# Remove conflicting policy
oc delete networkpolicy conflicting-policy -n database-app
Subtask 5.3: Policy Validation and Best Practices
Validate all current policies:
# List all policies with their specifications
for ns in frontend-app backend-app database-app; do
  echo "=== Policies in namespace: $ns ==="
  oc get networkpolicy -n $ns -o yaml
  echo ""
done
Create a comprehensive policy documentation:
# Generate policy summary
cat << 'EOF' > policy-summary.md
# Network Policy Summary

## Frontend Namespace (frontend-app)
- Egress: Can connect to backend-app on port 8080
- Egress: Can perform DNS lookups

## Backend Namespace (backend-app)  
- Ingress: Accepts connections from frontend-app on port 8080
- Ingress: Accepts monitoring connections

## Database Namespace (database-app)
- Ingress: Accepts connections from backend-app on port 3306
- Ingress: Accepts connections from admin pods in test-namespace

## Security Posture
- Default deny-all approach implemented
- Principle of least privilege enforced
- Monitoring access maintained
EOF

cat policy-summary.md
Troubleshooting Common Issues
Issue 1: Policy Not Taking Effect
Symptoms: Network traffic still flows despite policy restrictions

Solutions:

# Check if network plugin supports policies
oc get network.config.openshift.io cluster -o jsonpath='{.spec.networkType}'

# Verify policy syntax
oc get networkpolicy <policy-name> -n <namespace> -o yaml

# Check pod and namespace labels
oc get pods --show-labels -n <namespace>
oc get namespaces --show-labels
Issue 2: Legitimate Traffic Blocked
Symptoms: Expected connections are failing

Solutions:

# Review policy selectors
oc describe networkpolicy <policy-name> -n <namespace>

# Check for conflicting policies
oc get networkpolicy --all-namespaces

# Verify service endpoints
oc get endpoints -n <namespace>
Issue 3: DNS Resolution Problems
Symptoms: Pods cannot resolve service names

Solutions:

# Ensure DNS egress is allowed
# Add this to egress policies:
# - to: []
#   ports:
#   - protocol: UDP
#     port: 53
#   - protocol: TCP
#     port: 53
Lab Cleanup
Remove test applications and namespaces:
oc delete project frontend-app backend-app database-app test-namespace
Verify cleanup:
oc get networkpolicy --all-namespaces
oc get projects | grep -E "(frontend|backend|database|test)"
Conclusion
In this comprehensive lab, you have successfully:

Implemented Network Security: Created and configured network policies to control pod-to-pod communication, establishing a secure-by-default networking approach in your OpenShift cluster.

Applied Traffic Control: Developed both ingress and egress policies that allow legitimate business traffic while blocking unauthorized access, demonstrating the principle of least privilege.

Tested Policy Effectiveness: Validated network policies through practical testing scenarios, ensuring that security controls work as intended without disrupting application functionality.

Handled Complex Scenarios: Modified policies to accommodate real-world use cases including monitoring access, emergency procedures, and multi-tier application architectures.

Mastered Troubleshooting: Learned to identify and resolve common network policy issues, including policy conflicts, label mismatches, and DNS resolution problems.

Why This Matters: Network policies are crucial for implementing Zero Trust Architecture in containerized environments. They provide:

Microsegmentation: Isolate application components to limit blast radius of security incidents
Compliance: Meet regulatory requirements for network access controls
Defense in Depth: Add an additional security layer beyond application-level controls
Operational Security: Prevent lateral movement in case of container compromise
These skills are essential for the Red Hat Certified OpenShift Administrator exam and real-world OpenShift deployments where security and compliance are paramount. Network policies enable you to build secure, scalable, and maintainable containerized applications that meet enterprise security standards.

The hands-on experience gained in this lab prepares you to implement network security controls in production OpenShift environments, making you a more effective and security-conscious OpenShift administrator.
