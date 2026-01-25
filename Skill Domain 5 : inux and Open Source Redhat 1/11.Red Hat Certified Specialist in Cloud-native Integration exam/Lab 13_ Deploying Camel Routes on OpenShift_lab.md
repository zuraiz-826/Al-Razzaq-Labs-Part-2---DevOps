Lab 13: Deploying Camel Routes on OpenShift
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of Apache Camel K and its integration with OpenShift
Install and configure Camel K operator on OpenShift cluster
Create and deploy simple Camel routes as serverless functions
Monitor and verify Camel route deployments using OpenShift tools
Troubleshoot common deployment issues with Camel K
Prerequisites
Before starting this lab, you should have:

Basic understanding of Apache Camel concepts and Enterprise Integration Patterns
Familiarity with OpenShift/Kubernetes fundamentals
Knowledge of YAML configuration files
Basic command-line interface experience
Understanding of containerization concepts
Required Tools
OpenShift CLI (oc) - will be pre-installed on your lab machine
Camel K CLI (kamel) - will be installed during the lab
Text editor (vi/nano) - pre-installed on your lab machine
Lab Environment Setup
Good News! Al Nafi provides you with a ready-to-use Linux-based cloud machine with OpenShift cluster access. Simply click Start Lab and you'll have everything you need. No need to build your own VM or install OpenShift from scratch.

Your lab environment includes:

Pre-configured OpenShift cluster
Administrative access to the cluster
All necessary networking and storage configurations
Task 1: Set up Camel K on OpenShift
Subtask 1.1: Verify OpenShift Cluster Access
First, let's verify that your OpenShift cluster is accessible and you have the necessary permissions.

Open a terminal on your lab machine

Check your current OpenShift login status:

oc whoami
Verify cluster information:
oc cluster-info
Check available projects:
oc projects
Create a new project for this lab:
oc new-project camel-k-lab
Switch to the newly created project:
oc project camel-k-lab
Subtask 1.2: Install Camel K Operator
The Camel K operator manages the lifecycle of Camel integrations on OpenShift.

First, let's check if the Camel K operator is available in the OperatorHub:
oc get packagemanifests | grep camel
Create the operator subscription file:
cat > camel-k-subscription.yaml << EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: red-hat-camel-k
  namespace: camel-k-lab
spec:
  channel: latest
  name: red-hat-camel-k
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  installPlanApproval: Automatic
EOF
Apply the subscription:
oc apply -f camel-k-subscription.yaml
Wait for the operator to be installed (this may take a few minutes):
oc get csv -w
Note: Press Ctrl+C when you see the Camel K operator status shows "Succeeded"

Verify the operator installation:
oc get pods -n camel-k-lab
Subtask 1.3: Install Camel K CLI
The Camel K CLI (kamel) is essential for managing Camel integrations.

Download the latest Camel K CLI:
curl -L https://github.com/apache/camel-k/releases/latest/download/camel-k-client-linux-64bit.tar.gz -o kamel.tar.gz
Extract and install the CLI:
tar -xzf kamel.tar.gz
sudo mv kamel /usr/local/bin/
chmod +x /usr/local/bin/kamel
Verify the installation:
kamel version
Subtask 1.4: Initialize Camel K Integration Platform
Initialize the Camel K integration platform in your project:
kamel install --wait
Verify the integration platform is ready:
kamel get
Check the integration platform status:
oc get integrationplatform
The status should show "Ready" when the platform is fully initialized.

Task 2: Deploy a Simple Camel Route as a Pod in OpenShift
Subtask 2.1: Create a Simple File Processing Route
Let's create a simple Camel route that processes files and logs their content.

Create a simple Java-based Camel route:
cat > FileProcessor.java << 'EOF'
import org.apache.camel.builder.RouteBuilder;

public class FileProcessor extends RouteBuilder {
    @Override
    public void configure() throws Exception {
        from("timer:tick?period=10000")
            .setBody(constant("Hello from Camel K on OpenShift - " + System.currentTimeMillis()))
            .log("Processing message: ${body}")
            .to("log:info");
    }
}
EOF
Deploy the route using Camel K:
kamel run FileProcessor.java --name file-processor
Monitor the deployment progress:
kamel get
Watch the integration build and deployment:
oc get pods -w
Note: Press Ctrl+C when you see the pod status shows "Running"

Subtask 2.2: Create a REST API Route
Now let's create a more complex route that exposes a REST API.

Create a REST API Camel route:
cat > RestApiRoute.java << 'EOF'
import org.apache.camel.builder.RouteBuilder;

public class RestApiRoute extends RouteBuilder {
    @Override
    public void configure() throws Exception {
        
        restConfiguration()
            .component("platform-http")
            .port(8080);
            
        rest("/api")
            .get("/hello")
                .to("direct:hello")
            .get("/status")
                .to("direct:status");
                
        from("direct:hello")
            .setBody(constant("{\"message\": \"Hello from Camel K REST API\", \"timestamp\": \"" + System.currentTimeMillis() + "\"}"))
            .setHeader("Content-Type", constant("application/json"));
            
        from("direct:status")
            .setBody(constant("{\"status\": \"healthy\", \"service\": \"camel-k-rest-api\"}"))
            .setHeader("Content-Type", constant("application/json"));
    }
}
EOF
Deploy the REST API route:
kamel run RestApiRoute.java --name rest-api --trait service.enabled=true
Monitor the deployment:
kamel get rest-api -w
Subtask 2.3: Create a Message Transformation Route
Let's create a route that demonstrates message transformation capabilities.

Create a message transformation route:
cat > MessageTransformer.java << 'EOF'
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.dataformat.JsonLibrary;

public class MessageTransformer extends RouteBuilder {
    @Override
    public void configure() throws Exception {
        
        from("timer:transform?period=15000")
            .setBody(constant("{\"name\": \"John Doe\", \"age\": 30, \"city\": \"New York\"}"))
            .log("Original message: ${body}")
            .unmarshal().json(JsonLibrary.Jackson)
            .process(exchange -> {
                java.util.Map<String, Object> body = exchange.getIn().getBody(java.util.Map.class);
                body.put("processed", true);
                body.put("processedAt", System.currentTimeMillis());
                exchange.getIn().setBody(body);
            })
            .marshal().json(JsonLibrary.Jackson)
            .log("Transformed message: ${body}")
            .to("log:transformed");
    }
}
EOF
Deploy the transformation route:
kamel run MessageTransformer.java --name message-transformer
Verify all integrations are running:
kamel get
Task 3: Verify Deployment and Monitor Routes Using OpenShift Tools
Subtask 3.1: Verify Pod Deployments
List all pods in your project:
oc get pods
Check the detailed status of your Camel K integrations:
oc get integrations
Describe one of your integrations to see detailed information:
oc describe integration file-processor
Check the logs of the file processor:
oc logs -f deployment/file-processor
Note: Press Ctrl+C to stop following the logs

Subtask 3.2: Monitor Using OpenShift Web Console
Get the OpenShift web console URL:
oc whoami --show-console
Access the web console using the provided URL and your credentials

Navigate to your project: camel-k-lab

In the Topology view, you should see your Camel K integrations represented as pods

Click on each integration to view:

Pod details
Resource usage
Logs
Events
Subtask 3.3: Test the REST API Route
First, expose the REST API service:
oc expose service rest-api
Get the route URL:
oc get route rest-api
Test the hello endpoint:
ROUTE_URL=$(oc get route rest-api -o jsonpath='{.spec.host}')
curl http://$ROUTE_URL/api/hello
Test the status endpoint:
curl http://$ROUTE_URL/api/status
Subtask 3.4: Monitor Resource Usage
Check resource usage of your pods:
oc top pods
View detailed resource information:
oc describe pod -l camel.apache.org/integration=file-processor
Check events in your project:
oc get events --sort-by='.lastTimestamp'
Subtask 3.5: Scale Your Integrations
Scale the file processor integration:
kamel scale file-processor --replicas=2
Verify the scaling:
oc get pods -l camel.apache.org/integration=file-processor
Check the integration status:
kamel get file-processor
Subtask 3.6: View Integration Logs and Metrics
View logs from all replicas of file-processor:
oc logs -l camel.apache.org/integration=file-processor --tail=20
Follow logs from the message transformer:
oc logs -f -l camel.apache.org/integration=message-transformer
Check the integration platform logs:
oc logs -l name=camel-k-operator
Troubleshooting Common Issues
Issue 1: Integration Fails to Start
Symptoms: Integration shows "Error" status

Solution:

# Check integration details
oc describe integration <integration-name>

# Check pod events
oc get events --field-selector involvedObject.name=<pod-name>

# Check operator logs
oc logs -l name=camel-k-operator
Issue 2: Route Not Accessible
Symptoms: Cannot access REST API endpoints

Solution:

# Verify service exists
oc get svc

# Check if route is exposed
oc get routes

# Verify pod is running
oc get pods -l camel.apache.org/integration=rest-api
Issue 3: Build Failures
Symptoms: Integration stuck in "Building" phase

Solution:

# Check build logs
oc logs -l camel.apache.org/integration=<integration-name>

# Verify integration platform status
oc get integrationplatform

# Check available resources
oc describe nodes
Lab Cleanup
When you're finished with the lab, clean up the resources:

Delete all integrations:
kamel delete --all
Delete the project:
oc delete project camel-k-lab
Conclusion
Congratulations! You have successfully completed Lab 13: Deploying Camel Routes on OpenShift.

What You Accomplished
In this lab, you have:

Set up Camel K on OpenShift: You installed the Camel K operator and CLI, creating a foundation for serverless integration development
Deployed Multiple Camel Routes: You created and deployed three different types of integrations:
A timer-based file processing route
A REST API service route
A message transformation route
Monitored and Verified Deployments: You used both command-line tools and the OpenShift web console to monitor your integrations
Tested Functionality: You verified that your routes work correctly by testing endpoints and reviewing logs
Learned Scaling: You demonstrated how to scale Camel K integrations horizontally
Why This Matters
This lab demonstrates the power of cloud-native integration using Apache Camel K on OpenShift. The skills you've learned are directly applicable to:

Enterprise Integration: Building scalable, cloud-native integration solutions
Microservices Architecture: Creating lightweight, focused integration services
DevOps Practices: Deploying and managing integrations using modern container platforms
Serverless Computing: Leveraging Kubernetes-native serverless capabilities for integration workloads
Real-World Applications
The techniques you've practiced are used in production environments for:

API gateway implementations
Data transformation pipelines
Event-driven architectures
Hybrid cloud integrations
Microservices communication patterns
Next Steps
To further develop your skills:

Explore more complex Camel components and patterns
Implement error handling and retry mechanisms
Set up monitoring and alerting for production deployments
Practice with different data formats and protocols
Study Camel K traits for advanced configuration options
This hands-on experience with Camel K on OpenShift provides you with valuable skills for the Red Hat Certified Specialist in Cloud-native Integration exam and prepares you for real-world cloud-native integration challenges.
