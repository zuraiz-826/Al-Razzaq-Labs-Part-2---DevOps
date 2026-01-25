Lab 3: Group Management in OpenShift with LDAP
Objectives
By the end of this lab, you will be able to:

• Configure LDAP authentication in OpenShift • Map LDAP groups to OpenShift roles and permissions • Create and manage users in LDAP directory • Assign OpenShift roles based on LDAP group membership • Test and validate user access permissions • Troubleshoot common LDAP integration issues • Implement role-based access control (RBAC) using LDAP groups

Prerequisites
Before starting this lab, you should have:

• Basic understanding of OpenShift concepts and architecture • Familiarity with LDAP directory services • Knowledge of Linux command-line operations • Understanding of YAML configuration files • Basic knowledge of role-based access control (RBAC) • Experience with OpenShift CLI (oc command)

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift and OpenLDAP already installed. Simply click Start Lab to begin - no need to build your own VM or install software.

Your lab environment includes: • OpenShift 4.12+ cluster with admin access • OpenLDAP server pre-installed and configured • Required CLI tools (oc, ldapadd, ldapsearch) • Sample LDAP directory structure

Task 1: Configure LDAP Authentication in OpenShift
Subtask 1.1: Verify LDAP Server Configuration
First, let's verify that the LDAP server is running and accessible.

Check LDAP service status:
sudo systemctl status slapd
Verify LDAP connectivity:
ldapsearch -x -H ldap://localhost:389 -b "dc=example,dc=com" -s base
View existing LDAP structure:
ldapsearch -x -H ldap://localhost:389 -b "dc=example,dc=com" -s sub
Subtask 1.2: Create LDAP Directory Structure
Create organizational units for users and groups:
cat > create_ou.ldif << EOF
dn: ou=users,dc=example,dc=com
objectClass: organizationalUnit
ou: users

dn: ou=groups,dc=example,dc=com
objectClass: organizationalUnit
ou: groups
EOF
Add organizational units to LDAP:
ldapadd -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=com" -w admin -f create_ou.ldif
Subtask 1.3: Configure OpenShift LDAP Identity Provider
Create LDAP identity provider configuration:
cat > ldap-identity-provider.yaml << EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: ldap-provider
    mappingMethod: claim
    type: LDAP
    ldap:
      attributes:
        id:
        - dn
        preferredUsername:
        - uid
        name:
        - cn
        email:
        - mail
      bindDN: "cn=admin,dc=example,dc=com"
      bindPassword:
        name: ldap-secret
      ca:
        name: ldap-ca-bundle
      insecure: true
      url: "ldap://localhost:389/ou=users,dc=example,dc=com?uid"
EOF
Create LDAP bind password secret:
oc create secret generic ldap-secret --from-literal=bindPassword=admin -n openshift-config
Apply LDAP identity provider configuration:
oc apply -f ldap-identity-provider.yaml
Verify the configuration:
oc get oauth cluster -o yaml
Task 2: Create LDAP Groups and Map to OpenShift Roles
Subtask 2.1: Create LDAP Groups
Create developer group in LDAP:
cat > create_groups.ldif << EOF
dn: cn=developers,ou=groups,dc=example,dc=com
objectClass: groupOfNames
cn: developers
description: Development team members
member: cn=placeholder,ou=users,dc=example,dc=com

dn: cn=admins,ou=groups,dc=example,dc=com
objectClass: groupOfNames
cn: admins
description: System administrators
member: cn=placeholder,ou=users,dc=example,dc=com

dn: cn=viewers,ou=groups,dc=example,dc=com
objectClass: groupOfNames
cn: viewers
description: Read-only users
member: cn=placeholder,ou=users,dc=example,dc=com
EOF
Add groups to LDAP:
ldapadd -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=com" -w admin -f create_groups.ldif
Verify groups creation:
ldapsearch -x -H ldap://localhost:389 -b "ou=groups,dc=example,dc=com" -s sub
Subtask 2.2: Create OpenShift Group Sync Configuration
Create group sync configuration file:
cat > ldap-group-sync.yaml << EOF
kind: LDAPSyncConfig
apiVersion: v1
url: ldap://localhost:389
bindDN: "cn=admin,dc=example,dc=com"
bindPassword: admin
insecure: true
groupUIDNameMapping:
  "cn=developers,ou=groups,dc=example,dc=com": developers
  "cn=admins,ou=groups,dc=example,dc=com": admins
  "cn=viewers,ou=groups,dc=example,dc=com": viewers
rfc2307:
  groupsQuery:
    baseDN: "ou=groups,dc=example,dc=com"
    scope: sub
    derefAliases: never
    filter: (objectClass=groupOfNames)
    pageSize: 0
  groupUIDAttribute: dn
  groupNameAttributes: [ cn ]
  groupMembershipAttributes: [ member ]
  usersQuery:
    baseDN: "ou=users,dc=example,dc=com"
    scope: sub
    derefAliases: never
    filter: (objectClass=inetOrgPerson)
    pageSize: 0
  userUIDAttribute: dn
  userNameAttributes: [ uid ]
  tolerateMemberNotFoundErrors: true
  tolerateMemberOutOfScopeErrors: true
EOF
Subtask 2.3: Map LDAP Groups to OpenShift Roles
Create cluster role bindings for admin group:
cat > admin-role-binding.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ldap-admins
subjects:
- kind: Group
  name: admins
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
Create role binding for developers group:
cat > developer-role-binding.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ldap-developers
subjects:
- kind: Group
  name: developers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
EOF
Create role binding for viewers group:
cat > viewer-role-binding.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ldap-viewers
subjects:
- kind: Group
  name: viewers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
EOF
Apply role bindings:
oc apply -f admin-role-binding.yaml
oc apply -f developer-role-binding.yaml
oc apply -f viewer-role-binding.yaml
Task 3: Create LDAP Users and Assign Group Membership
Subtask 3.1: Create LDAP Users
Create admin user:
cat > create_users.ldif << EOF
dn: uid=admin1,ou=users,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: admin1
sn: Administrator
givenName: System
cn: System Administrator
displayName: System Administrator
uidNumber: 10001
gidNumber: 5000
userPassword: {SSHA}password123
gecos: System Administrator
loginShell: /bin/bash
homeDirectory: /home/admin1
mail: admin1@example.com

dn: uid=dev1,ou=users,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: dev1
sn: Developer
givenName: John
cn: John Developer
displayName: John Developer
uidNumber: 10002
gidNumber: 5000
userPassword: {SSHA}password123
gecos: John Developer
loginShell: /bin/bash
homeDirectory: /home/dev1
mail: dev1@example.com

dn: uid=viewer1,ou=users,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: viewer1
sn: Viewer
givenName: Jane
cn: Jane Viewer
displayName: Jane Viewer
uidNumber: 10003
gidNumber: 5000
userPassword: {SSHA}password123
gecos: Jane Viewer
loginShell: /bin/bash
homeDirectory: /home/viewer1
mail: viewer1@example.com
EOF
Add users to LDAP:
ldapadd -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=com" -w admin -f create_users.ldif
Subtask 3.2: Assign Users to Groups
Add admin1 to admins group:
cat > add_admin_to_group.ldif << EOF
dn: cn=admins,ou=groups,dc=example,dc=com
changetype: modify
delete: member
member: cn=placeholder,ou=users,dc=example,dc=com
-
add: member
member: uid=admin1,ou=users,dc=example,dc=com
EOF
Add dev1 to developers group:
cat > add_dev_to_group.ldif << EOF
dn: cn=developers,ou=groups,dc=example,dc=com
changetype: modify
delete: member
member: cn=placeholder,ou=users,dc=example,dc=com
-
add: member
member: uid=dev1,ou=users,dc=example,dc=com
EOF
Add viewer1 to viewers group:
cat > add_viewer_to_group.ldif << EOF
dn: cn=viewers,ou=groups,dc=example,dc=com
changetype: modify
delete: member
member: cn=placeholder,ou=users,dc=example,dc=com
-
add: member
member: uid=viewer1,ou=users,dc=example,dc=com
EOF
Apply group membership changes:
ldapmodify -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=com" -w admin -f add_admin_to_group.ldif
ldapmodify -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=com" -w admin -f add_dev_to_group.ldif
ldapmodify -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=com" -w admin -f add_viewer_to_group.ldif
Subtask 3.3: Sync LDAP Groups to OpenShift
Perform group synchronization:
oc adm groups sync --sync-config=ldap-group-sync.yaml --confirm
Verify groups were created in OpenShift:
oc get groups
Check group membership:
oc describe group admins
oc describe group developers
oc describe group viewers
Task 4: Test User Access and Permissions
Subtask 4.1: Test Admin User Access
Get OpenShift login URL:
oc whoami --show-server
Login as admin user:
oc login -u admin1 -p password123
Test admin privileges:
oc get nodes
oc get projects
oc new-project test-admin-project
Verify cluster-admin access:
oc auth can-i "*" "*"
oc get clusterroles
Subtask 4.2: Test Developer User Access
Login as developer user:
oc login -u dev1 -p password123
Test developer privileges:
oc new-project test-dev-project
oc create deployment nginx --image=nginx
oc get deployments
Test restricted access:
oc get nodes
oc auth can-i get nodes
oc auth can-i create projects
Subtask 4.3: Test Viewer User Access
Login as viewer user:
oc login -u viewer1 -p password123
Test read-only access:
oc get projects
oc get pods -A
Test restricted write access:
oc new-project test-viewer-project
oc auth can-i create deployments
oc auth can-i delete pods
Subtask 4.4: Verify Role-Based Access Control
Switch back to admin user:
oc login -u admin1 -p password123
Check user identities:
oc get users
oc get identities
Verify group memberships:
oc describe user admin1
oc describe user dev1
oc describe user viewer1
Check role bindings:
oc get clusterrolebindings | grep ldap
oc describe clusterrolebinding ldap-admins
oc describe clusterrolebinding ldap-developers
oc describe clusterrolebinding ldap-viewers
Troubleshooting Common Issues
LDAP Connection Issues
Check LDAP service status:
sudo systemctl status slapd
sudo netstat -tlnp | grep :389
Test LDAP connectivity:
telnet localhost 389
ldapsearch -x -H ldap://localhost:389 -b "dc=example,dc=com"
Authentication Problems
Check OAuth configuration:
oc get oauth cluster -o yaml
oc logs -n openshift-authentication deployment/oauth-openshift
Verify LDAP secret:
oc get secret ldap-secret -n openshift-config -o yaml
Group Sync Issues
Test group sync in dry-run mode:
oc adm groups sync --sync-config=ldap-group-sync.yaml
Check for sync errors:
oc adm groups sync --sync-config=ldap-group-sync.yaml --confirm -v=5
Permission Issues
Check user permissions:
oc auth can-i --list --as=system:serviceaccount:default:default
Verify role bindings:
oc get rolebindings,clusterrolebindings -o wide | grep -E "(admin1|dev1|viewer1)"
Best Practices
• Security: Always use encrypted connections (LDAPS) in production environments • Group Management: Keep LDAP groups synchronized with OpenShift groups regularly • Access Control: Follow the principle of least privilege when assigning roles • Monitoring: Regularly audit user access and group memberships • Backup: Maintain backups of LDAP directory and OpenShift configurations

Conclusion
In this lab, you have successfully:

• Configured LDAP authentication integration with OpenShift • Created and managed LDAP directory structure with users and groups • Mapped LDAP groups to OpenShift roles using RBAC • Implemented role-based access control with different permission levels • Tested user authentication and authorization across different roles • Learned troubleshooting techniques for LDAP integration issues

This knowledge is essential for enterprise OpenShift deployments where centralized user management through LDAP is required. The skills you've developed enable you to implement secure, scalable user authentication and authorization systems that integrate with existing enterprise directory services.

Key Takeaways: • LDAP integration provides centralized user management for OpenShift clusters • Group-based role assignment simplifies permission management at scale • Proper testing and validation ensure security policies are correctly implemented • Regular synchronization maintains consistency between LDAP and OpenShift

These concepts are fundamental for the Red Hat OpenShift Administration III certification and real-world enterprise OpenShift deployments.
