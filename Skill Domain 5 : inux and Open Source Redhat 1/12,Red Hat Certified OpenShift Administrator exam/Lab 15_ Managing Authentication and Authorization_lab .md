Lab 15: Managing Authentication and Authorization
Objectives
By the end of this lab, you will be able to:

Configure authentication and authorization for OpenShift resources using Role-Based Access Control (RBAC)
Set up HTPasswd as an Identity Provider (IdP) for user authentication
Create users and assign appropriate roles using OpenShift administrative commands
Test user access based on role-based policies
Understand the relationship between users, groups, roles, and role bindings in OpenShift
Implement security best practices for user management in OpenShift clusters
Prerequisites
Before starting this lab, you should have:

Basic understanding of OpenShift concepts and architecture
Familiarity with command-line interface operations
Knowledge of YAML file structure and syntax
Understanding of basic security concepts like authentication and authorization
Experience with Linux file permissions and user management concepts
Ready-to-Use Cloud Machines
Al Nafi provides pre-configured Linux-based cloud machines with OpenShift cluster access. Simply click Start Lab to begin - no need to build your own virtual machine or install OpenShift from scratch. Your lab environment includes:

OpenShift cluster with administrative access
Pre-installed oc command-line tool
All necessary utilities for user and authentication management
Network connectivity configured for external identity providers
Lab Tasks
Task 1: Create Users and Assign Roles with oc adm
Subtask 1.1: Understand OpenShift RBAC Components
Before creating users, let's examine the existing RBAC structure in your OpenShift cluster.

List existing cluster roles:
oc get clusterroles | head -20
Examine a specific cluster role (view role):
oc describe clusterrole view
List existing role bindings:
oc get rolebindings -A | head -10
Check current user context:
oc whoami
oc auth can-i create pods
oc auth can-i create projects
Subtask 1.2: Create Service Accounts and Users
Create a new project for testing:
oc new-project rbac-demo
Create service accounts for different roles:
# Create a service account for developers
oc create serviceaccount developer-sa -n rbac-demo

# Create a service account for viewers
oc create serviceaccount viewer-sa -n rbac-demo

# Verify service accounts were created
oc get serviceaccounts -n rbac-demo
Create custom roles for specific permissions:
# Create a custom role for pod management
cat << EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: rbac-demo
  name: pod-manager
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "pods/status"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
EOF
Create role bindings to assign roles:
# Bind the pod-manager role to developer-sa
oc create rolebinding developer-binding \
  --role=pod-manager \
  --serviceaccount=rbac-demo:developer-sa \
  -n rbac-demo

# Bind the view cluster role to viewer-sa
oc create rolebinding viewer-binding \
  --clusterrole=view \
  --serviceaccount=rbac-demo:viewer-sa \
  -n rbac-demo
Verify role bindings:
oc get rolebindings -n rbac-demo
oc describe rolebinding developer-binding -n rbac-demo
Subtask 1.3: Test Service Account Permissions
Get service account tokens:
# Get developer service account token
DEV_TOKEN=$(oc serviceaccounts get-token developer-sa -n rbac-demo)

# Get viewer service account token
VIEWER_TOKEN=$(oc serviceaccounts get-token viewer-sa -n rbac-demo)

# Display tokens (first 20 characters for verification)
echo "Developer token: ${DEV_TOKEN:0:20}..."
echo "Viewer token: ${VIEWER_TOKEN:0:20}..."
Test developer permissions:
# Test pod creation permission
oc auth can-i create pods -n rbac-demo --token=$DEV_TOKEN
oc auth can-i delete pods -n rbac-demo --token=$DEV_TOKEN
oc auth can-i create deployments -n rbac-demo --token=$DEV_TOKEN
Test viewer permissions:
# Test viewer permissions
oc auth can-i get pods -n rbac-demo --token=$VIEWER_TOKEN
oc auth can-i create pods -n rbac-demo --token=$VIEWER_TOKEN
oc auth can-i delete pods -n rbac-demo --token=$VIEWER_TOKEN
Task 2: Set up HTPasswd as an Identity Provider (IdP)
Subtask 2.1: Create HTPasswd File
Install htpasswd utility (if not available):
# Check if htpasswd is available
which htpasswd || echo "htpasswd not found"

# If needed, install httpd-tools package
# Note: This may already be available in your lab environment
Create users with htpasswd:
# Create htpasswd file with first user
htpasswd -c -B -b users.htpasswd alice password123

# Add additional users
htpasswd -B -b users.htpasswd bob password456
htpasswd -B -b users.htpasswd charlie password789
htpasswd -B -b users.htpasswd diana adminpass

# Verify the file contents
cat users.htpasswd
Create a secret from the htpasswd file:
oc create secret generic htpass-secret \
  --from-file=htpasswd=users.htpasswd \
  -n openshift-config
Subtask 2.2: Configure HTPasswd Identity Provider
Backup current OAuth configuration:
oc get oauth cluster -o yaml > oauth-backup.yaml
Create HTPasswd identity provider configuration:
cat << EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: my_htpasswd_provider
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
EOF
Monitor the OAuth pods restart:
# Watch OAuth pods restart
oc get pods -n openshift-authentication -w
Wait for the configuration to take effect:
# Wait for OAuth pods to be ready
oc wait --for=condition=ready pod -l app=oauth-openshift -n openshift-authentication --timeout=300s
Subtask 2.3: Verify Identity Provider Configuration
Check OAuth configuration:
oc get oauth cluster -o yaml
Verify the secret was created:
oc get secret htpass-secret -n openshift-config -o yaml
Check authentication operator status:
oc get clusteroperator authentication
Task 3: Test User Access Based on Role-Based Policies
Subtask 3.1: Assign Roles to HTPasswd Users
Create cluster role bindings for different users:
# Give alice cluster-admin privileges
oc adm policy add-cluster-role-to-user cluster-admin alice

# Give bob edit privileges in rbac-demo project
oc adm policy add-role-to-user edit bob -n rbac-demo

# Give charlie view privileges in rbac-demo project
oc adm policy add-role-to-user view charlie -n rbac-demo

# Diana will have no special privileges (basic authenticated user)
Create a group and assign users:
# Create a group for developers
oc adm groups new developers alice bob

# Assign edit role to the developers group in a new project
oc new-project team-project
oc adm policy add-role-to-group edit developers -n team-project
Verify role assignments:
oc get rolebindings -n rbac-demo
oc get clusterrolebindings | grep alice
oc describe group developers
Subtask 3.2: Test User Authentication and Authorization
Test alice (cluster-admin) access:
# Login as alice
oc login -u alice -p password123

# Test cluster-admin capabilities
oc whoami
oc auth can-i create projects
oc auth can-i delete nodes
oc get nodes

# Create a test project
oc new-project alice-test
oc get projects | grep alice
Test bob (edit in rbac-demo) access:
# Login as bob
oc login -u bob -p password456

# Test project access
oc whoami
oc project rbac-demo
oc auth can-i create pods -n rbac-demo
oc auth can-i delete pods -n rbac-demo
oc auth can-i create projects

# Try to create a pod
cat << EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: rbac-demo
spec:
  containers:
  - name: test-container
    image: registry.redhat.io/ubi8/ubi:latest
    command: ["sleep", "3600"]
EOF

# Verify pod creation
oc get pods -n rbac-demo
Test charlie (view only) access:
# Login as charlie
oc login -u charlie -p password789

# Test view permissions
oc whoami
oc project rbac-demo
oc get pods -n rbac-demo
oc auth can-i create pods -n rbac-demo
oc auth can-i delete pods -n rbac-demo

# Try to create a pod (should fail)
oc run test-pod-charlie --image=registry.redhat.io/ubi8/ubi:latest -n rbac-demo
Test diana (basic user) access:
# Login as diana
oc login -u diana -p adminpass

# Test basic user permissions
oc whoami
oc auth can-i create projects
oc get projects

# Try to access rbac-demo project (should fail)
oc project rbac-demo
Subtask 3.3: Advanced RBAC Testing
Create custom cluster role:
# Login back as admin
oc login -u system:admin

# Create a custom cluster role for project management
cat << EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: project-manager
rules:
- apiGroups: ["project.openshift.io"]
  resources: ["projects"]
  verbs: ["get", "list", "create", "delete"]
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "list", "create", "delete"]
EOF
Assign custom role to a user:
# Assign project-manager role to bob
oc adm policy add-cluster-role-to-user project-manager bob
Test custom role permissions:
# Login as bob and test project creation
oc login -u bob -p password456
oc auth can-i create projects
oc new-project bob-custom-project
oc get projects | grep bob
Subtask 3.4: Audit and Monitor User Activities
Check user and group information:
# Login as admin
oc login -u system:admin

# List all users
oc get users

# List all groups
oc get groups

# Get detailed user information
oc get user alice -o yaml
Review role bindings across the cluster:
# List all cluster role bindings
oc get clusterrolebindings | grep -E "(alice|bob|charlie|diana)"

# List role bindings in specific namespaces
oc get rolebindings -n rbac-demo
oc get rolebindings -n team-project
Generate access review reports:
# Check what alice can do
oc auth can-i --list --as=alice

# Check what bob can do in rbac-demo namespace
oc auth can-i --list --as=bob -n rbac-demo

# Check what charlie can do
oc auth can-i --list --as=charlie -n rbac-demo
Troubleshooting Tips
Common Issues and Solutions
OAuth pods not restarting after configuration:

Check if the htpass-secret exists in openshift-config namespace
Verify the OAuth configuration syntax
Wait longer for the authentication operator to process changes
Users cannot login:

Verify htpasswd file format and encoding
Check if the secret contains the correct data
Ensure OAuth configuration references the correct secret name
Permission denied errors:

Verify role bindings are created in the correct namespace
Check if the user is assigned to the correct groups
Ensure cluster roles vs. roles are used appropriately
Service account token issues:

Tokens may expire; regenerate if needed
Ensure service accounts exist in the correct namespace
Verify role bindings reference the correct service account
Verification Commands
# Check authentication operator status
oc get clusteroperator authentication

# Verify OAuth configuration
oc get oauth cluster -o yaml

# List all identity providers
oc get oauth cluster -o jsonpath='{.spec.identityProviders[*].name}'

# Check user authentication
oc get users
oc get identities
Conclusion
In this lab, you have successfully:

Configured Role-Based Access Control (RBAC) in OpenShift by creating custom roles and role bindings
Set up HTPasswd as an Identity Provider to enable user authentication with username and password
Created and managed users with different permission levels using OpenShift administrative commands
Tested user access policies to ensure proper authorization based on assigned roles
Implemented security best practices for user management in an OpenShift environment
Key Takeaways
Authentication vs. Authorization: You learned the difference between authentication (verifying who you are) and authorization (determining what you can do). OpenShift uses identity providers for authentication and RBAC for authorization.

Flexible User Management: HTPasswd provides a simple way to manage users for development and testing environments, while enterprise environments typically use LDAP or other external identity providers.

Granular Permission Control: OpenShift's RBAC system allows for very specific permission assignments, from cluster-wide administrative access to namespace-specific resource management.

Security Best Practices: By implementing least-privilege access and testing user permissions, you've established a foundation for secure OpenShift cluster management.

Why This Matters
Proper authentication and authorization are critical for:

Security: Preventing unauthorized access to cluster resources
Compliance: Meeting organizational and regulatory requirements
Operational Efficiency: Enabling teams to work independently within their authorized scope
Audit Trail: Maintaining accountability for cluster changes and access
This knowledge is essential for the Red Hat Certified OpenShift Administrator exam and real-world OpenShift cluster management, where security and user management are fundamental operational requirements.
