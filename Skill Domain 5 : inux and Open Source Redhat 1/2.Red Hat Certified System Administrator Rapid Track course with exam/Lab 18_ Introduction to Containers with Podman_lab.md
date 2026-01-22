Lab 18: Introduction to Containers with Podman
Objectives
By the end of this lab, students will be able to:

• Understand the fundamentals of containerization and Podman • Install and configure Podman on a Linux system • Create, run, and manage containers using Podman commands • Work with container images including pulling, listing, and removing images • Manage container lifecycle operations (start, stop, restart, remove) • Run containerized services and applications • Understand basic container networking and port mapping • Implement container persistence using volumes

Prerequisites
Before starting this lab, students should have:

• Basic knowledge of Linux command line operations • Understanding of file system navigation and permissions • Familiarity with package management concepts • Basic networking concepts (ports, IP addresses) • Text editor skills (nano, vim, or similar)

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software initially.

Your lab environment includes: • CentOS/RHEL 8 or 9 based system • Root or sudo access • Internet connectivity for downloading container images • Pre-installed development tools

Task 1: Install Podman and Create Containers
Subtask 1.1: Install Podman
First, we'll install Podman on our system and verify the installation.

Step 1: Update the system packages

sudo dnf update -y
Step 2: Install Podman

sudo dnf install -y podman
Step 3: Verify Podman installation

podman --version
Expected output should show the Podman version installed.

Step 4: Check Podman system information

podman info
This command displays comprehensive information about your Podman installation and system configuration.

Subtask 1.2: Create Your First Container
Now we'll create and run our first container using a simple web server.

Step 1: Pull a basic web server image

podman pull docker.io/library/httpd:latest
Step 2: Run your first container

podman run -d --name my-web-server -p 8080:80 httpd:latest
Command breakdown: • -d: Run container in detached mode (background) • --name my-web-server: Assign a custom name to the container • -p 8080:80: Map host port 8080 to container port 80 • httpd:latest: The image to use

Step 3: Verify the container is running

podman ps
Step 4: Test the web server

curl http://localhost:8080
You should see the default Apache HTTP Server page HTML content.

Subtask 1.3: Interactive Container Creation
Let's create an interactive container to understand container environments better.

Step 1: Run an interactive CentOS container

podman run -it --name interactive-centos centos:latest /bin/bash
Command breakdown: • -it: Interactive mode with pseudo-TTY • /bin/bash: Command to run inside the container

Step 2: Explore the container environment

Inside the container, run these commands:

# Check the operating system
cat /etc/os-release

# List running processes
ps aux

# Check network configuration
ip addr show

# Create a test file
echo "Hello from container" > /tmp/test.txt
cat /tmp/test.txt
Step 3: Exit the container

exit
Task 2: Manage Container Images with Podman
Subtask 2.1: Working with Container Images
Step 1: List all images on your system

podman images
Step 2: Search for images in registries

podman search nginx
Step 3: Pull specific image versions

podman pull docker.io/library/nginx:1.21-alpine
Step 4: Inspect an image

podman inspect httpd:latest
This command provides detailed information about the image including layers, configuration, and metadata.

Subtask 2.2: Image Management Operations
Step 1: Tag an image with a custom name

podman tag httpd:latest my-custom-web:v1.0
Step 2: Verify the new tag

podman images | grep my-custom-web
Step 3: Remove an image tag

podman rmi my-custom-web:v1.0
Step 4: Clean up unused images

podman image prune
Subtask 2.3: Creating a Custom Image
Let's create a simple custom image using a Containerfile (Podman's equivalent to Dockerfile).

Step 1: Create a working directory

mkdir ~/custom-web-app
cd ~/custom-web-app
Step 2: Create a simple HTML file

cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>My Custom Web App</title>
</head>
<body>
    <h1>Welcome to My Container Lab</h1>
    <p>This is a custom web application running in Podman!</p>
    <p>Lab 18: Introduction to Containers with Podman</p>
</body>
</html>
EOF
Step 3: Create a Containerfile

cat > Containerfile << 'EOF'
FROM httpd:latest
COPY index.html /usr/local/apache2/htdocs/
EXPOSE 80
EOF
Step 4: Build the custom image

podman build -t my-web-app:latest .
Step 5: Run a container from your custom image

podman run -d --name custom-web -p 8081:80 my-web-app:latest
Step 6: Test your custom web application

curl http://localhost:8081
Task 3: Run and Manage Container Services
Subtask 3.1: Container Lifecycle Management
Step 1: List all containers (running and stopped)

podman ps -a
Step 2: Stop a running container

podman stop my-web-server
Step 3: Start a stopped container

podman start my-web-server
Step 4: Restart a container

podman restart my-web-server
Step 5: Check container logs

podman logs my-web-server
Step 6: Follow container logs in real-time

podman logs -f my-web-server
Press Ctrl+C to stop following the logs.

Subtask 3.2: Advanced Container Operations
Step 1: Execute commands in a running container

podman exec -it my-web-server /bin/bash
Inside the container, explore the file system:

# Check Apache configuration
ls -la /usr/local/apache2/conf/
# View the default web page
cat /usr/local/apache2/htdocs/index.html
# Exit the container
exit
Step 2: Copy files between host and container

# Create a test file on the host
echo "This file was copied from host" > host-file.txt

# Copy file from host to container
podman cp host-file.txt my-web-server:/usr/local/apache2/htdocs/

# Copy file from container to host
podman cp my-web-server:/usr/local/apache2/htdocs/index.html ./container-index.html
Step 3: Monitor container resource usage

podman stats my-web-server
Press Ctrl+C to stop monitoring.

Subtask 3.3: Working with Container Volumes
Step 1: Create a named volume

podman volume create web-data
Step 2: List volumes

podman volume ls
Step 3: Run a container with a mounted volume

podman run -d --name web-with-volume -p 8082:80 -v web-data:/usr/local/apache2/htdocs httpd:latest
Step 4: Add content to the volume

podman exec web-with-volume sh -c 'echo "<h1>Data from Volume</h1>" > /usr/local/apache2/htdocs/volume.html'
Step 5: Test the volume-mounted content

curl http://localhost:8082/volume.html
Step 6: Inspect volume details

podman volume inspect web-data
Subtask 3.4: Container Networking
Step 1: Create a custom network

podman network create lab-network
Step 2: List networks

podman network ls
Step 3: Run containers on the custom network

# Run a database container
podman run -d --name lab-database --network lab-network -e MYSQL_ROOT_PASSWORD=labpassword mysql:8.0

# Run a web application that can connect to the database
podman run -d --name lab-webapp --network lab-network -p 8083:80 httpd:latest
Step 4: Test network connectivity between containers

# Install network tools in the web container
podman exec lab-webapp apt-get update
podman exec lab-webapp apt-get install -y iputils-ping

# Test connectivity to database container
podman exec lab-webapp ping -c 3 lab-database
Subtask 3.5: Container Cleanup
Step 1: Stop all running containers

podman stop $(podman ps -q)
Step 2: Remove specific containers

podman rm my-web-server custom-web interactive-centos
Step 3: Remove containers with volumes

podman rm -v web-with-volume
Step 4: Clean up unused resources

# Remove unused containers
podman container prune

# Remove unused images
podman image prune

# Remove unused volumes
podman volume prune

# Remove unused networks
podman network prune
Step 5: Verify cleanup

podman ps -a
podman images
podman volume ls
podman network ls
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Permission denied when running Podman commands Solution: Ensure you have proper permissions or use sudo if needed:

sudo podman <command>
Issue 2: Port already in use error Solution: Check what's using the port and choose a different one:

ss -tulpn | grep :8080
podman run -p 8084:80 httpd:latest  # Use different port
Issue 3: Container fails to start Solution: Check container logs for error messages:

podman logs <container-name>
Issue 4: Image pull fails Solution: Check network connectivity and try different registry:

podman pull quay.io/httpd:latest  # Alternative registry
Issue 5: Container runs but service not accessible Solution: Verify port mapping and firewall settings:

podman port <container-name>
sudo firewall-cmd --list-ports
Best Practices
• Always use specific image tags instead of latest in production • Regularly clean up unused containers and images to save disk space • Use meaningful names for containers and images • Monitor container resource usage to prevent system overload • Use volumes for persistent data that should survive container restarts • Implement proper security practices by running containers as non-root users when possible

Conclusion
Congratulations! You have successfully completed Lab 18: Introduction to Containers with Podman. In this lab, you have accomplished the following:

Key Achievements: • Installed and configured Podman on a Linux system, establishing a foundation for container management • Created and managed containers using various Podman commands, learning both interactive and detached modes • Worked with container images including pulling from registries, creating custom images, and managing image lifecycle • Implemented container services with proper networking, port mapping, and volume management • Mastered container lifecycle operations including starting, stopping, monitoring, and cleaning up containers

Why This Matters: Container technology has revolutionized how applications are developed, deployed, and managed in modern IT environments. Podman, as a daemonless container engine, provides a secure and efficient alternative to traditional container platforms. The skills you've learned in this lab are essential for:

• System Administration: Managing containerized applications in enterprise environments • DevOps Practices: Implementing continuous integration and deployment pipelines • Application Development: Creating portable and scalable applications • Red Hat Certification: Building foundational knowledge for RHCSA and other Red Hat certifications • Career Advancement: Developing in-demand skills for cloud-native technologies

The hands-on experience gained through creating custom images, managing container networks, and implementing persistent storage solutions provides you with practical skills that directly apply to real-world scenarios. These containerization concepts form the foundation for more advanced topics like Kubernetes orchestration and microservices architecture.

Continue practicing these commands and concepts to build confidence in container management, as these skills are increasingly valuable in today's technology landscape.
