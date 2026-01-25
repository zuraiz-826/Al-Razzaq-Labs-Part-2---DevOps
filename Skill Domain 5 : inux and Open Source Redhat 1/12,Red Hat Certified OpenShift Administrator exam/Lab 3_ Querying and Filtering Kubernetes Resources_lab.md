Lab 3: Querying and Filtering Kubernetes Resources
Objectives
By the end of this lab, you will be able to:

Use oc CLI commands to query Kubernetes resources effectively
Apply label selectors to filter resources based on metadata labels
Utilize field selectors to filter resources based on specific field values
Filter resources by namespaces to organize and isolate workloads
Format command output in JSON and YAML formats for different use cases
Combine multiple filtering techniques for advanced resource queries
Understand the practical applications of resource filtering in OpenShift administration
Prerequisites
Before starting this lab, you should have:

Basic understanding of Kubernetes/OpenShift concepts (pods, services, deployments)
Familiarity with command-line interface operations
Knowledge of YAML and JSON data formats
Understanding of Linux basic commands
Completed previous OpenShift labs or equivalent experience
Lab Environment Setup
Good News! Al Nafi provides ready-to-use Linux-based cloud machines with OpenShift CLI pre-installed. Simply click Start Lab and you'll have access to a fully configured environment. No need to build your own VM or install additional software.

Your lab environment includes:

OpenShift CLI (oc) tool pre-installed
Access to an OpenShift cluster
Sample applications and resources for practice
All necessary permissions configured
Task 1: Using oc get with Label Selectors
Subtask 1.1: Understanding Labels and Label Selectors
Labels are key-value pairs attached to Kubernetes objects that help organize and select resources. Label selectors allow you to query resources based on these labels.

Step 1: First, let's examine existing resources and their labels

# List all pods with their labels
oc get pods --show-labels

# List all services with their labels
oc get services --show-labels
Step 2: Create sample resources with specific labels for practice

# Create a new project for our lab
oc new-project lab3-filtering

# Create sample pods with different labels
oc run web-app-1 --image=nginx --labels="app=web,tier=frontend,version=v1"
oc run web-app-2 --image=nginx --labels="app=web,tier=frontend,version=v2"
oc run api-app-1 --image=nginx --labels="app=api,tier=backend,version=v1"
oc run db-app-1 --image=nginx --labels="app=database,tier=backend,version=v1"
Subtask 1.2: Basic Label Selector Queries
Step 3: Use equality-based label selectors

# Get all pods with app=web label
oc get pods -l app=web

# Get all pods with tier=frontend label
oc get pods -l tier=frontend

# Get all pods with version=v1 label
oc get pods -l version=v1
Step 4: Use inequality-based label selectors

# Get all pods where app is NOT web
oc get pods -l app!=web

# Get all pods where version is NOT v1
oc get pods -l version!=v1
Subtask 1.3: Advanced Label Selector Queries
Step 5: Use set-based label selectors

# Get pods where app is either web or api
oc get pods -l 'app in (web,api)'

# Get pods where tier is not in the specified set
oc get pods -l 'tier notin (middleware,cache)'

# Get pods that have the app label (regardless of value)
oc get pods -l app

# Get pods that do NOT have a specific label
oc get pods -l '!environment'
Step 6: Combine multiple label selectors

# Get pods with both app=web AND tier=frontend
oc get pods -l app=web,tier=frontend

# Get pods with app=web AND version=v1
oc get pods -l app=web,version=v1

# Complex query: app is web OR api, AND tier is frontend
oc get pods -l 'app in (web,api),tier=frontend'
Task 2: Filter Output Using Field Selectors
Subtask 2.1: Understanding Field Selectors
Field selectors allow you to filter resources based on the values of resource fields, such as metadata.name, status.phase, or spec.nodeName.

Step 7: Create additional resources to demonstrate field selectors

# Create some services
oc expose pod web-app-1 --port=80 --name=web-service-1
oc expose pod api-app-1 --port=8080 --name=api-service-1

# Create a deployment
oc create deployment sample-deployment --image=nginx --replicas=3
Subtask 2.2: Basic Field Selector Queries
Step 8: Use field selectors to filter by metadata fields

# Get pods by name
oc get pods --field-selector metadata.name=web-app-1

# Get pods by namespace
oc get pods --field-selector metadata.namespace=lab3-filtering

# Get all pods in default namespace (if any exist)
oc get pods --field-selector metadata.namespace=default
Step 9: Use field selectors to filter by status fields

# Get pods that are running
oc get pods --field-selector status.phase=Running

# Get pods that are pending
oc get pods --field-selector status.phase=Pending

# Get pods that have failed
oc get pods --field-selector status.phase=Failed
Subtask 2.3: Advanced Field Selector Usage
Step 10: Combine field selectors with other options

# Get running pods with specific labels
oc get pods --field-selector status.phase=Running -l app=web

# Get services by type
oc get services --field-selector spec.type=ClusterIP

# Get events sorted by time
oc get events --field-selector type=Warning --sort-by='.lastTimestamp'
Step 11: Use field selectors with different resource types

# Get nodes by specific criteria (if accessible)
oc get nodes --field-selector spec.unschedulable=false

# Get persistent volumes by status
oc get pv --field-selector status.phase=Available

# Get namespaces by status
oc get namespaces --field-selector status.phase=Active
Task 3: Format Output in JSON or YAML
Subtask 3.1: JSON Output Formatting
Step 12: Generate JSON output for different resources

# Get pod information in JSON format
oc get pod web-app-1 -o json

# Get all pods in JSON format
oc get pods -o json

# Get specific fields from JSON output using JSONPath
oc get pods -o jsonpath='{.items[*].metadata.name}'

# Get pod names and status in a custom format
oc get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'
Step 13: Use JSON output with filtering

# Get pods with specific labels in JSON format
oc get pods -l app=web -o json

# Get running pods in JSON format
oc get pods --field-selector status.phase=Running -o json

# Extract specific information using jq (if available)
oc get pods -o json | jq '.items[].metadata.name'
Subtask 3.2: YAML Output Formatting
Step 14: Generate YAML output for resources

# Get pod information in YAML format
oc get pod web-app-1 -o yaml

# Get service information in YAML format
oc get service web-service-1 -o yaml

# Get deployment information in YAML format
oc get deployment sample-deployment -o yaml
Step 15: Use YAML output for configuration management

# Export pod configuration to a file
oc get pod web-app-1 -o yaml > web-app-1-config.yaml

# Export service configuration
oc get service web-service-1 -o yaml > web-service-1-config.yaml

# Export multiple resources
oc get pods,services -l app=web -o yaml > web-resources.yaml
Subtask 3.3: Custom Output Formats
Step 16: Use custom output formats and templates

# Use wide output format for more details
oc get pods -o wide

# Use custom columns
oc get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName

# Use go-template for custom formatting
oc get pods -o go-template='{{range .items}}{{.metadata.name}} {{.status.phase}}{{"\n"}}{{end}}'

# Create a table with specific information
oc get pods -o custom-columns="POD NAME:.metadata.name,APP LABEL:.metadata.labels.app,STATUS:.status.phase"
Advanced Filtering Combinations
Subtask 3.4: Combining All Filtering Techniques
Step 17: Create complex queries combining labels, fields, and output formatting

# Get running web pods in JSON format
oc get pods -l app=web --field-selector status.phase=Running -o json

# Get frontend tier pods with custom output
oc get pods -l tier=frontend -o custom-columns=NAME:.metadata.name,VERSION:.metadata.labels.version,STATUS:.status.phase

# Get all resources with specific labels in YAML
oc get pods,services -l app=web -o yaml

# Monitor resources with watch flag
oc get pods -l app=web --field-selector status.phase=Running -w
Step 18: Practice namespace-specific filtering

# List all namespaces
oc get namespaces

# Get resources from specific namespace
oc get pods -n lab3-filtering

# Get resources from all namespaces
oc get pods --all-namespaces -l app=web

# Get resources with namespace information
oc get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase
Practical Scenarios and Use Cases
Subtask 3.5: Real-World Application Scenarios
Step 19: Troubleshooting scenarios

# Find all failed pods across all namespaces
oc get pods --all-namespaces --field-selector status.phase=Failed

# Find pods consuming high resources (if metrics available)
oc top pods -l app=web

# Get events related to specific pods
oc get events --field-selector involvedObject.name=web-app-1

# Find all services without endpoints
oc get endpoints -o json | jq '.items[] | select(.subsets == null) | .metadata.name'
Step 20: Monitoring and maintenance scenarios

# Get all pods older than a specific time
oc get pods -o json | jq '.items[] | select(.metadata.creationTimestamp < "2024-01-01T00:00:00Z") | .metadata.name'

# Find pods with specific resource requests
oc get pods -o json | jq '.items[] | select(.spec.containers[].resources.requests.memory) | .metadata.name'

# Export configuration for backup
oc get all -l app=web -o yaml > web-app-backup.yaml
Verification and Testing
Subtask 3.6: Verify Your Learning
Step 21: Test your understanding with these verification commands

# Verify label-based filtering works
echo "Testing label selectors..."
oc get pods -l app=web --no-headers | wc -l

# Verify field-based filtering works
echo "Testing field selectors..."
oc get pods --field-selector status.phase=Running --no-headers | wc -l

# Verify output formatting works
echo "Testing JSON output..."
oc get pod web-app-1 -o json | jq '.metadata.name'

# Verify YAML output works
echo "Testing YAML output..."
oc get pod web-app-1 -o yaml | grep "name:"
Cleanup
Step 22: Clean up the lab environment

# Delete the lab project and all resources
oc delete project lab3-filtering

# Verify cleanup
oc get projects | grep lab3-filtering
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Command not found errors

Solution: Ensure you're logged into the OpenShift cluster: oc whoami
Solution: Check if oc CLI is properly installed: oc version
Issue 2: No resources found

Solution: Verify you're in the correct project: oc project
Solution: Check if resources exist: oc get all
Issue 3: Permission denied errors

Solution: Verify your user permissions: oc auth can-i get pods
Solution: Contact your cluster administrator if permissions are insufficient
Issue 4: Invalid label selector syntax

Solution: Use single quotes around complex selectors: oc get pods -l 'app in (web,api)'
Solution: Check label syntax documentation: oc get --help
Issue 5: JSONPath or jq errors

Solution: Verify JSON structure first: oc get pods -o json | head -20
Solution: Test JSONPath expressions: oc get pods -o jsonpath='{.items[0].metadata.name}'
Conclusion
Congratulations! You have successfully completed Lab 3: Querying and Filtering Kubernetes Resources. In this lab, you have accomplished the following:

Key Achievements
Mastered Label Selectors: You learned how to use equality-based, inequality-based, and set-based label selectors to filter Kubernetes resources effectively.

Applied Field Selectors: You practiced filtering resources based on field values such as status, metadata, and specifications.

Formatted Output: You gained experience in formatting command output in JSON, YAML, and custom formats for different use cases.

Combined Filtering Techniques: You learned to combine multiple filtering methods to create powerful and precise queries.

Real-World Applications: You explored practical scenarios for troubleshooting, monitoring, and maintenance tasks.

Why This Matters
These skills are essential for OpenShift administrators because they enable you to:

Efficiently manage large-scale deployments by quickly finding specific resources
Troubleshoot issues faster by filtering relevant resources and information
Automate administrative tasks using precise queries and formatted output
Monitor application health by filtering resources based on status and labels
Maintain organized environments through effective resource categorization and selection
Next Steps
With these querying and filtering skills, you're well-prepared for:

Advanced OpenShift administration tasks
Red Hat Certified OpenShift Administrator exam scenarios
Real-world production environment management
Automation and scripting tasks using OpenShift CLI
The ability to efficiently query and filter Kubernetes resources is a fundamental skill that will serve you throughout your OpenShift administration journey. Practice these techniques regularly to build muscle memory and confidence in your administrative capabilities.
