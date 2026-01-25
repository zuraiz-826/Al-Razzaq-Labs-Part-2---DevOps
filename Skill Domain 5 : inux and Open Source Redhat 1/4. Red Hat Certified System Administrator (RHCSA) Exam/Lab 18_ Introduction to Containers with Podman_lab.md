Lab 18: Introduction to Containers with Podman
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of containerization technology
Install and configure Podman on a Linux system
Create and manage container images using Podman
Start, stop, and inspect containers effectively
Perform basic container lifecycle management operations
Understand the differences between Podman and other container runtimes
Prerequisites
Before starting this lab, students should have:

Basic knowledge of Linux command-line operations
Understanding of file systems and directory structures
Familiarity with package management concepts
Basic networking concepts
Access to a terminal or command-line interface
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install additional software.

Your lab environment includes:

CentOS Stream 9 or RHEL 9 compatible system
Root access for package installation
Internet connectivity for downloading container images
Pre-configured repositories for Podman installation
Task 1: Install Podman and Create Containers
Subtask 1.1: Install Podman
First, we need to install Podman on our system. Podman is a daemonless container engine that provides a Docker-compatible command-line interface.

Update the system packages:
sudo dnf update -y
Install Podman:
sudo dnf install -y podman
Verify the installation:
podman --version
Expected output should show the Podman version (e.g., podman version 4.6.1).

Check Podman system information:
podman system info
This command displays detailed information about your Podman installation and system configuration.

Subtask 1.2: Create Your First Container
Now let's create and run our first container using a simple web server image.

Pull and run an NGINX container:
podman run -d --name my-nginx -p 8080:80 docker.io/nginx:latest
Command breakdown:

run: Creates and starts a new container
-d: Runs the container in detached mode (background)
--name my-nginx: Assigns a custom name to the container
-p 8080:80: Maps host port 8080 to container port 80
docker.io/nginx:latest: Specifies the image to use
Verify the container is running:
podman ps
You should see your NGINX container listed with status "Up".

Test the web server:
curl http://localhost:8080
You should see the default NGINX welcome page HTML content.

Subtask 1.3: Create a Custom Container
Let's create a simple container running a Python web server.

Run a Python container with a simple HTTP server:
podman run -d --name python-server -p 8081:8000 docker.io/python:3.9-slim sh -c "python -m http.server 8000"
Verify both containers are running:
podman ps
You should now see two containers running.

Task 2: Manage Container Images
Subtask 2.1: List and Inspect Images
Container images are the templates used to create containers. Let's explore image management.

List all downloaded images:
podman images
This shows all images currently stored on your system.

Get detailed information about an image:
podman inspect docker.io/nginx:latest
This command provides comprehensive metadata about the image, including layers, environment variables, and configuration.

View image history:
podman history docker.io/nginx:latest
This shows the layers that make up the image and how it was built.

Subtask 2.2: Search and Pull Images
Search for images in registries:
podman search httpd
This searches for Apache HTTP server images across configured registries.

Pull a specific image:
podman pull docker.io/httpd:2.4
Pull an image with a specific tag:
podman pull docker.io/alpine:3.18
Verify the new images are downloaded:
podman images
Subtask 2.3: Remove Images
Remove an unused image:
podman rmi docker.io/httpd:2.4
Remove multiple images at once:
podman rmi docker.io/alpine:3.18 docker.io/python:3.9-slim
Note: You cannot remove images that are currently being used by running containers.

Task 3: Start, Stop, and Inspect Containers
Subtask 3.1: Container Lifecycle Management
Let's practice starting, stopping, and managing container states.

List all containers (including stopped ones):
podman ps -a
The -a flag shows all containers, not just running ones.

Stop a running container:
podman stop my-nginx
Start a stopped container:
podman start my-nginx
Restart a container:
podman restart my-nginx
Pause and unpause a container:
podman pause my-nginx
podman unpause my-nginx
Subtask 3.2: Inspect Container Details
Get detailed container information:
podman inspect my-nginx
This provides comprehensive information about the container's configuration, network settings, and current state.

View container logs:
podman logs my-nginx
Follow container logs in real-time:
podman logs -f my-nginx
Press Ctrl+C to stop following the logs.

View container resource usage:
podman stats my-nginx
This shows real-time CPU, memory, and network usage. Press Ctrl+C to exit.

Subtask 3.3: Execute Commands in Running Containers
Execute a command in a running container:
podman exec my-nginx ls -la /usr/share/nginx/html
Start an interactive shell session:
podman exec -it my-nginx /bin/bash
Inside the container, you can run commands like:

cat /etc/nginx/nginx.conf
exit
Copy files to/from containers:
echo "Hello from host" > test.txt
podman cp test.txt my-nginx:/usr/share/nginx/html/
Verify the file was copied:
curl http://localhost:8080/test.txt
Subtask 3.4: Container Cleanup
Stop all running containers:
podman stop $(podman ps -q)
Remove specific containers:
podman rm my-nginx python-server
Remove all stopped containers:
podman container prune
Remove unused images:
podman image prune
Advanced Container Operations
Working with Volumes
Create a named volume:
podman volume create my-data
Run a container with a volume:
podman run -d --name data-container -v my-data:/data docker.io/alpine:latest sleep 3600
List volumes:
podman volume ls
Container Networking
Create a custom network:
podman network create my-network
Run containers on the custom network:
podman run -d --name web1 --network my-network docker.io/nginx:latest
podman run -d --name web2 --network my-network docker.io/nginx:latest
Test network connectivity between containers:
podman exec web1 ping web2
Troubleshooting Tips
Common Issues and Solutions
Permission denied errors:

Ensure you have proper permissions or use sudo when necessary
Check SELinux contexts if enabled
Port already in use:

Use podman ps to check for conflicting containers
Choose different host ports for mapping
Image pull failures:

Check internet connectivity
Verify registry URLs are correct
Try pulling from different registries
Container won't start:

Check container logs: podman logs <container-name>
Verify image compatibility with your system architecture
Useful Commands for Troubleshooting
# Check Podman system events
podman system events

# View system-wide information
podman system info

# Check disk usage
podman system df

# Reset Podman to clean state (use with caution)
podman system reset
Lab Verification
To verify you've completed the lab successfully, run these commands:

Check Podman installation:
podman --version
Verify you can pull and run a container:
podman run --rm docker.io/hello-world
List any remaining containers and images:
podman ps -a
podman images
Conclusion
Congratulations! You have successfully completed the Introduction to Containers with Podman lab. In this lab, you have accomplished the following:

Key Achievements:

Installed and configured Podman on a Linux system, understanding its role as a daemonless container runtime
Created and managed containers using various Podman commands and options
Worked with container images including pulling, inspecting, and removing images from registries
Mastered container lifecycle management by starting, stopping, pausing, and restarting containers
Learned container inspection techniques to monitor logs, resource usage, and configuration details
Performed advanced operations such as executing commands in containers, copying files, and managing volumes
Why This Matters: Containerization has become a fundamental technology in modern IT infrastructure and DevOps practices. The skills you've learned in this lab are essential for:

Cloud-native application development and deployment
Microservices architecture implementation
DevOps and CI/CD pipelines automation
System administration in containerized environments
Red Hat Certified System Administrator (RHCSA) certification preparation
Next Steps:

Practice creating custom container images using Containerfiles (Dockerfiles)
Explore container orchestration with Kubernetes
Learn about container security best practices
Investigate advanced networking and storage options
Study container monitoring and logging solutions
The containerization skills you've developed will serve as a foundation for advanced topics in cloud computing, DevOps, and modern application architecture. Keep practicing these commands and exploring different container use cases to build your expertise further.
