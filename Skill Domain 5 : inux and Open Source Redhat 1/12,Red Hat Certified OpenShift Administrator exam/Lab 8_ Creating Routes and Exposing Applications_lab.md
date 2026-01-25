Lab 8: Creating Routes and Exposing Applications
Objectives
By the end of this lab, you will be able to:

Understand the concept of OpenShift routes and their role in exposing applications
Create external routes using the oc expose command to make services accessible from outside the cluster
Test route functionality by accessing applications through a web browser
Configure secure HTTPS routes for enhanced security
Troubleshoot common routing issues in OpenShift environments
Prerequisites
Before starting this lab, you should have:

Basic understanding of OpenShift concepts including pods, services, and deployments
Familiarity with command-line interface operations
Knowledge of HTTP and HTTPS protocols
Previous experience with oc command-line tool
Completion of previous OpenShift labs covering service creation and management
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift access. Simply click Start Lab to begin - no need to build your own virtual machine or install additional software.

Your lab environment includes:

OpenShift cluster with administrative access
Pre-installed oc command-line tool
Sample applications ready for deployment
Web browser for testing routes
Task 1: Create an OpenShift Route Using oc expose
Subtask 1.1: Verify Cluster Access and Deploy Sample Application
First, let's ensure you have proper access to the OpenShift cluster and deploy a sample application to work with.

Login to OpenShift cluster:
oc login --server=https://your-openshift-cluster-url
Create a new project for this lab:
oc new-project route-lab-project
Deploy a sample web application:
oc new-app --name=sample-web-app --image=quay.io/redhattraining/hello-world-nginx:v1.0
Verify the deployment:
oc get pods
oc get services
Wait until the pod status shows Running before proceeding to the next step.

Subtask 1.2: Understanding Services Before Creating Routes
Before creating routes, it's important to understand that routes expose services, not pods directly.

Examine the service created by the deployment:
oc describe service sample-web-app
Note the service details:
Service Name: sample-web-app
Port: Usually 8080 or 80
Target Port: The port the container listens on
Subtask 1.3: Create Your First Route
Now let's create a route to expose our application to external traffic.

Create a basic HTTP route:
oc expose service sample-web-app --name=sample-web-route
Verify the route creation:
oc get routes
Get detailed route information:
oc describe route sample-web-route
Extract the route hostname:
oc get route sample-web-route -o jsonpath='{.spec.host}'
The output will show the external URL where your application is now accessible.

Task 2: Test the Route by Accessing the Application via Browser
Subtask 2.1: Browser-Based Testing
Copy the route hostname from the previous command output.

Open your web browser and navigate to:

http://[your-route-hostname]
Verify application accessibility:
You should see the sample web application's welcome page
The page should load without SSL/TLS warnings (since we're using HTTP)
Subtask 2.2: Command-Line Testing
For additional verification, test the route using command-line tools:

Test with curl:
curl -I http://$(oc get route sample-web-route -o jsonpath='{.spec.host}')
Verify the HTTP response:

Look for HTTP/1.1 200 OK status
Check for proper content-type headers
Test full content retrieval:

curl http://$(oc get route sample-web-route -o jsonpath='{.spec.host}')
Subtask 2.3: Route Troubleshooting
If your route isn't working, try these troubleshooting steps:

Check pod status:
oc get pods -l app=sample-web-app
Verify service endpoints:
oc get endpoints sample-web-app
Check route configuration:
oc get route sample-web-route -o yaml
Task 3: Modify the Route for Secure Access (HTTPS)
Subtask 3.1: Understanding Route Security Options
OpenShift provides several TLS termination options:

Edge: TLS termination at the router (most common)
Passthrough: TLS termination at the pod
Re-encrypt: TLS termination at router, re-encrypted to pod
Subtask 3.2: Create a Secure HTTPS Route
Delete the existing HTTP route:
oc delete route sample-web-route
Create a new secure route with edge termination:
oc create route edge sample-web-secure-route \
  --service=sample-web-app \
  --port=8080
Verify the secure route creation:
oc get routes
Notice the HOST/PORT column now shows the HTTPS URL.

Subtask 3.3: Configure Route with Custom Options
For more control over the secure route, you can use additional parameters:

Create a secure route with redirect:
oc create route edge sample-web-secure-redirect \
  --service=sample-web-app \
  --port=8080 \
  --insecure-policy=Redirect
This configuration automatically redirects HTTP traffic to HTTPS.

Verify both routes exist:
oc get routes
Subtask 3.4: Test Secure Route Functionality
Test HTTPS access via browser:

Navigate to: https://[your-secure-route-hostname]
Accept any certificate warnings (expected with self-signed certificates)
Verify the application loads correctly
Test with curl (accepting self-signed certificates):

curl -k https://$(oc get route sample-web-secure-route -o jsonpath='{.spec.host}')
Test HTTP to HTTPS redirect (if configured):
curl -I http://$(oc get route sample-web-secure-redirect -o jsonpath='{.spec.host}')
Look for HTTP/1.1 302 Found with a Location header pointing to HTTPS.

Subtask 3.5: Advanced Route Configuration
Create a route using YAML for more advanced configuration:

Create a route YAML file:
cat > advanced-secure-route.yaml << EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: advanced-secure-route
  namespace: route-lab-project
spec:
  host: custom-hostname.apps.your-cluster.com
  to:
    kind: Service
    name: sample-web-app
    weight: 100
  port:
    targetPort: 8080
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
EOF
Apply the advanced route:
oc apply -f advanced-secure-route.yaml
Verify the advanced route:
oc describe route advanced-secure-route
Additional Exercises and Best Practices
Exercise 1: Route with Custom Hostname
Create a route with a specific hostname:
oc expose service sample-web-app \
  --hostname=myapp.example.com \
  --name=custom-hostname-route
Exercise 2: Route Load Balancing
Create multiple backend services:
oc new-app --name=backend-v1 --image=quay.io/redhattraining/hello-world-nginx:v1.0
oc new-app --name=backend-v2 --image=quay.io/redhattraining/hello-world-nginx:v2.0
Create a route with weighted load balancing:
cat > load-balanced-route.yaml << EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: load-balanced-route
spec:
  to:
    kind: Service
    name: backend-v1
    weight: 80
  alternateBackends:
  - kind: Service
    name: backend-v2
    weight: 20
  port:
    targetPort: 8080
EOF
Apply the load-balanced route:
oc apply -f load-balanced-route.yaml
Exercise 3: Route Monitoring and Metrics
Check route status and metrics:
oc get routes -o wide
Monitor route traffic (if metrics are available):
oc describe route sample-web-secure-route
Troubleshooting Common Issues
Issue 1: Route Not Accessible
Symptoms: Browser shows "This site can't be reached" or similar error.

Solutions:

Verify the service is running:
oc get svc sample-web-app
Check if pods are ready:
oc get pods -l app=sample-web-app
Verify route configuration:
oc get route -o yaml
Issue 2: SSL Certificate Warnings
Symptoms: Browser shows SSL certificate warnings.

Solutions:

This is expected with default OpenShift routes using self-signed certificates
For production, configure custom certificates:
oc create route edge secure-route \
  --service=sample-web-app \
  --cert=path/to/cert.crt \
  --key=path/to/cert.key \
  --ca-cert=path/to/ca.crt
Issue 3: Route Conflicts
Symptoms: Route creation fails with hostname conflicts.

Solutions:

Use unique hostnames:
oc expose service sample-web-app --hostname=unique-name.apps.cluster.com
Check existing routes:
oc get routes --all-namespaces
Lab Cleanup
After completing the lab, clean up your resources:

Delete all routes:
oc delete route --all
Delete the project:
oc delete project route-lab-project
Verify cleanup:
oc get projects | grep route-lab
Conclusion
In this lab, you have successfully:

Created OpenShift routes using the oc expose command to make internal services accessible from external networks
Tested route functionality through both browser and command-line interfaces to ensure proper application accessibility
Implemented secure HTTPS routes with TLS termination to protect data in transit
Configured advanced routing options including redirects, load balancing, and custom hostnames
Troubleshot common routing issues and learned best practices for route management
Why This Matters: Routes are essential for making OpenShift applications accessible to end users. Understanding how to properly configure and secure routes is crucial for:

Production deployments where applications must be accessible from the internet
Security compliance requiring encrypted communications
Load distribution across multiple application instances
Blue-green deployments and canary releases
Multi-tenant environments where different applications need unique access points
These skills are fundamental for the Red Hat Certified OpenShift Administrator exam and essential for managing production OpenShift environments. Routes serve as the bridge between your internal cluster services and external users, making them one of the most critical components in any OpenShift deployment strategy.
