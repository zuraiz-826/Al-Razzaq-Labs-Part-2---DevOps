Lab 6: Examining and Managing Container Images
Objectives
By the end of this lab, you will be able to:

• Locate and examine container images in OpenShift using command-line tools • Inspect image properties including size, repository information, and tags • Use oc describe to get detailed information about container images • Pull images from the OpenShift integrated registry • Manage image streams for automatic updates and version control • Understand image lifecycle management in OpenShift environments

Prerequisites
Before starting this lab, you should have:

• Basic understanding of containers and containerization concepts • Familiarity with Linux command-line interface • Knowledge of OpenShift fundamentals and basic oc commands • Understanding of container registries and image repositories • Basic knowledge of YAML configuration files

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift CLI tools already installed. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes: • OpenShift CLI (oc) pre-installed and configured • Access to an OpenShift cluster • Sample applications and images for practice • All necessary permissions for image management operations

Task 1: Using oc describe to Inspect Container Images
Subtask 1.1: List Available Images in Your Project
First, let's explore what images are available in your current OpenShift project.

Login to your OpenShift cluster (if not already logged in):
oc login --server=https://your-openshift-cluster-url
Check your current project:
oc project
List all images in the current project:
oc get images
List image streams in your project:
oc get imagestreams
Subtask 1.2: Examine Image Details with oc describe
Now let's use the oc describe command to get detailed information about container images.

Describe a specific image (replace IMAGE_NAME with an actual image name from your list):
oc describe image IMAGE_NAME
Get detailed information about an image stream:
oc describe imagestream IMAGESTREAM_NAME
View image information in JSON format for programmatic processing:
oc get image IMAGE_NAME -o json
Subtask 1.3: Analyze Image Properties
Let's examine specific properties of container images:

Check image size and layers:
oc describe image IMAGE_NAME | grep -E "(Size|Layer)"
View image tags and repository information:
oc describe imagestream IMAGESTREAM_NAME | grep -E "(Tag|Repository)"
List all tags for a specific image stream:
oc get imagestream IMAGESTREAM_NAME -o jsonpath='{.spec.tags[*].name}'
Task 2: Pulling Images from OpenShift Integrated Registry
Subtask 2.1: Access the Integrated Registry
OpenShift includes an integrated container registry for storing and managing images.

Get the registry route (if exposed externally):
oc get route docker-registry -n default
Get registry service information:
oc get svc docker-registry -n default
Login to the integrated registry:
docker login -u $(oc whoami) -p $(oc whoami -t) $(oc registry info)
Subtask 2.2: Pull Images Using oc Commands
Import an external image into your project:
oc import-image nginx:latest --from=docker.io/nginx:latest --confirm
Create a new image stream from an external registry:
oc create imagestream my-app-image
Tag an existing image with a new tag:
oc tag SOURCE_IMAGE:TAG DESTINATION_IMAGE:NEW_TAG
Subtask 2.3: Verify Image Pull Operations
Check if the image was successfully imported:
oc get imagestream nginx
Describe the newly imported image stream:
oc describe imagestream nginx
View image import status:
oc get imagestreamimport
Task 3: Managing Image Streams for Automatic Updates
Subtask 3.1: Create and Configure Image Streams
Image streams provide a stable pointer to images and can automatically update when new versions are available.

Create a new image stream from a template:
cat << EOF | oc apply -f -
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: my-application
  namespace: $(oc project -q)
spec:
  lookupPolicy:
    local: true
  tags:
  - name: latest
    from:
      kind: DockerImage
      name: docker.io/nginx:latest
    importPolicy:
      scheduled: true
    referencePolicy:
      type: Source
EOF
Verify the image stream creation:
oc get imagestream my-application
Check the image stream configuration:
oc describe imagestream my-application
Subtask 3.2: Configure Automatic Updates
Enable scheduled imports for automatic updates:
oc patch imagestream my-application -p '{"spec":{"tags":[{"name":"latest","importPolicy":{"scheduled":true}}]}}'
Set import policy for a specific tag:
oc tag docker.io/nginx:1.20 my-application:stable --scheduled=true
View import schedule status:
oc describe imagestream my-application | grep -A 5 "Import Policy"
Subtask 3.3: Manage Image Stream Tags
Add a new tag to an existing image stream:
oc tag my-application:latest my-application:v1.0
Update a tag to point to a different image:
oc tag docker.io/nginx:1.21 my-application:latest
List all tags in an image stream:
oc describe imagestream my-application | grep -E "^[[:space:]]*[a-zA-Z0-9].*:"
Delete a specific tag:
oc tag my-application:v1.0 -d
Task 4: Advanced Image Management Operations
Subtask 4.1: Image Pruning and Cleanup
View images that can be pruned:
oc adm prune images --dry-run
Prune unused images (requires cluster admin privileges):
oc adm prune images --confirm
Check image usage across the cluster:
oc get images --all-namespaces
Subtask 4.2: Image Security and Scanning
Check image vulnerabilities (if image scanning is enabled):
oc describe image IMAGE_NAME | grep -i security
View image signature information:
oc get image IMAGE_NAME -o jsonpath='{.signatures}'
Subtask 4.3: Working with Private Registries
Create a secret for private registry authentication:
oc create secret docker-registry my-registry-secret \
  --docker-server=private-registry.example.com \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=myemail@example.com
Link the secret to the default service account:
oc secrets link default my-registry-secret --for=pull
Import image from private registry:
oc import-image my-private-app:latest \
  --from=private-registry.example.com/my-private-app:latest \
  --confirm
Troubleshooting Common Issues
Issue 1: Image Import Failures
Problem: Image import fails with authentication errors.

Solution:

# Check if registry credentials are correct
oc get secrets | grep docker-registry

# Verify secret configuration
oc describe secret SECRET_NAME
Issue 2: Image Stream Not Updating
Problem: Image stream doesn't automatically update despite scheduled imports.

Solution:

# Manually trigger import
oc import-image IMAGESTREAM_NAME:TAG

# Check import policy
oc describe imagestream IMAGESTREAM_NAME | grep "Import Policy"
Issue 3: Registry Access Issues
Problem: Cannot access the integrated registry.

Solution:

# Check registry service status
oc get svc docker-registry -n default

# Verify registry route
oc get route docker-registry -n default
Verification and Testing
Verify Your Lab Completion
Check that you can list and describe images:
oc get images | head -5
oc describe image $(oc get images -o name | head -1 | cut -d'/' -f2)
Verify image stream management:
oc get imagestreams
oc describe imagestream my-application
Confirm automatic update configuration:
oc describe imagestream my-application | grep -i scheduled
Lab Summary and Key Takeaways
What You Accomplished
In this lab, you successfully:

• Mastered image inspection using oc describe and related commands to examine container images, their sizes, repositories, and tags • Learned to pull images from the OpenShift integrated registry and external registries • Configured image streams for automatic updates and version management • Implemented advanced image management including pruning, security scanning, and private registry integration • Developed troubleshooting skills for common image-related issues in OpenShift

Why This Matters
Container image management is crucial for:

• Security: Keeping images updated with latest security patches • Efficiency: Managing image sizes and reducing storage costs • Automation: Enabling automatic updates and deployments • Compliance: Tracking image sources and maintaining audit trails • Performance: Optimizing image layers and reducing pull times

Real-World Applications
These skills are essential for:

• DevOps Engineers managing CI/CD pipelines with automated image updates • System Administrators maintaining secure and efficient container environments • Security Teams scanning and managing container image vulnerabilities • Development Teams implementing proper image versioning and deployment strategies

Next Steps
To further enhance your OpenShift image management skills:

• Explore image security policies and admission controllers • Learn about multi-stage builds and image optimization techniques • Study image signing and verification processes • Practice cross-cluster image replication and disaster recovery scenarios • Investigate custom image builders and Source-to-Image (S2I) processes

This lab has provided you with fundamental skills for the Red Hat Certified OpenShift Administrator exam and real-world OpenShift image management scenarios.
