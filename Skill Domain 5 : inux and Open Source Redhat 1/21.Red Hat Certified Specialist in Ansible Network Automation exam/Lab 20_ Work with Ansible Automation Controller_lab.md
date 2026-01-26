Lab 20: Work with Ansible Automation Controller
Objectives
By the end of this lab, you will be able to:

Configure source control repositories and credentials in Ansible Automation Controller
Create and manage projects and workflow templates
Execute and monitor automation jobs through the web interface
Understand the relationship between inventories, credentials, and job templates
Implement workflow templates for complex automation scenarios
Monitor job execution and troubleshoot automation tasks
Prerequisites
Before starting this lab, you should have:

Basic understanding of Ansible playbooks and YAML syntax
Familiarity with Linux command line operations
Knowledge of Git version control system
Understanding of SSH key authentication
Basic networking concepts (IP addresses, ports, protocols)
Experience with web-based interfaces
Lab Environment
Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own VM or install software - everything is ready to use!

Your lab environment includes:

Ansible Automation Controller (AWX) pre-installed
Multiple target nodes for automation
Git repository access
Sample playbooks and configurations
Task 1: Configure Source Control Repositories and Credentials
Subtask 1.1: Access Ansible Automation Controller
Open your web browser and navigate to the Automation Controller interface:

http://your-lab-ip:8080
Log in using the provided credentials:

Username: admin
Password: password123
Verify the dashboard loads successfully and shows the main navigation menu with sections like Projects, Inventories, Templates, and Jobs.

Subtask 1.2: Create SSH Credentials
Navigate to Credentials by clicking on the "Credentials" option in the left sidebar.

Click the "+" button to create a new credential.

Fill in the credential details:

Name: lab-ssh-key
Description: SSH key for lab automation
Organization: Default
Credential Type: Machine
Add SSH private key:

# First, generate an SSH key pair on your control node
ssh-keygen -t rsa -b 2048 -f ~/.ssh/lab_key -N ""

# Copy the private key content
cat ~/.ssh/lab_key
Paste the private key into the "SSH Private Key" field in the web interface.

Set the username to ansible (or the appropriate user for your target nodes).

Click Save to create the credential.

Subtask 1.3: Create Git Repository Credentials
Click the "+" button again to create another credential.

Configure Git credentials:

Name: git-repo-access
Description: Access to Git repository
Organization: Default
Credential Type: Source Control
Enter Git repository details:

Username: your-git-username
Password: your-git-token (use personal access token for security)
Click Save to store the Git credentials.

Subtask 1.4: Set Up Source Control Repository
Navigate to Projects in the left sidebar.

Click the "+" button to create a new project.

Configure the project:

Name: ansible-lab-project
Description: Lab automation playbooks
Organization: Default
SCM Type: Git
Set repository details:

SCM URL: https://github.com/ansible/ansible-examples.git
SCM Branch/Tag/Commit: master
SCM Credential: git-repo-access (if repository requires authentication)
Enable SCM options:

Check "Clean" to ensure clean repository pulls
Check "Update Revision on Launch" for latest code
Click Save and wait for the project to sync successfully.

Task 2: Create Projects and Workflow Templates
Subtask 2.1: Create an Inventory
Navigate to Inventories in the left sidebar.

Click the "+" button and select "Inventory".

Configure the inventory:

Name: lab-servers
Description: Lab environment servers
Organization: Default
Click Save to create the inventory.

Add hosts to the inventory:

Click on the newly created inventory
Click the "Hosts" tab
Click the "+" button to add a host
Configure host details:

Host Name: web-server-01
Description: Web server for testing
Variables (in YAML format):
ansible_host: 192.168.1.10
ansible_user: ansible
server_role: web
Add additional hosts following the same pattern:

# Database server
Host Name: db-server-01
Variables:
ansible_host: 192.168.1.11
ansible_user: ansible
server_role: database
Subtask 2.2: Create Job Templates
Navigate to Templates in the left sidebar.

Click the "+" button and select "Job Template".

Configure the first job template:

Name: install-apache
Description: Install and configure Apache web server
Job Type: Run
Inventory: lab-servers
Project: ansible-lab-project
Playbook: lamp_simple/site.yml
Credentials: lab-ssh-key
Set additional options:

Check "Enable Privilege Escalation"
Verbosity: 1 (Verbose)
Check "Allow Simultaneous"
Click Save to create the job template.

Create a second job template:

Name: system-updates
Description: Apply system updates
Job Type: Run
Inventory: lab-servers
Project: ansible-lab-project
Playbook: system/update.yml
Credentials: lab-ssh-key
Subtask 2.3: Create Workflow Templates
Click the "+" button and select "Workflow Template".

Configure the workflow template:

Name: complete-server-setup
Description: Complete server setup workflow
Organization: Default
Inventory: lab-servers
Click Save to create the workflow template.

Design the workflow:

Click "Visualizer" to open the workflow editor
Click "Start" to add the first node
Add the first workflow node:

Node Type: Job Template
Job Template: system-updates
Click "Select"
Add a second node:

Hover over the first node and click the "+" icon
Node Type: Job Template
Job Template: install-apache
Run: On Success (default)
Click "Select"
Save the workflow by clicking "Save" in the visualizer.

Subtask 2.4: Create a Survey for User Input
Open the install-apache job template for editing.

Click the "Survey" tab.

Click "Add" to create a survey question.

Configure the survey question:

Prompt: Apache Document Root
Description: Specify the document root directory
Answer Variable Name: apache_docroot
Answer Type: Text
Default Answer: /var/www/html
Required: Yes
Add another survey question:

Prompt: Server Admin Email
Description: Administrator email for Apache
Answer Variable Name: apache_admin_email
Answer Type: Text
Default Answer: admin@example.com
Required: Yes
Enable the survey by toggling the "Survey Enabled" switch.

Click Save to apply the survey configuration.

Task 3: Run and Monitor Automation Jobs
Subtask 3.1: Execute Individual Job Templates
Navigate to Templates and locate the system-updates job template.

Click the rocket icon next to the template name to launch the job.

Monitor the job execution:

The job details page will open automatically
Watch the real-time output in the "Output" section
Note the job status in the top-right corner
Analyze job results:

Check the "Details" tab for job statistics
Review any error messages or warnings
Note the execution time and affected hosts
Launch the install-apache job template:

Click the rocket icon for the install-apache template
Fill in the survey questions when prompted:
Apache Document Root: /var/www/html
Server Admin Email: admin@lab.local
Click "Launch" to start the job
Subtask 3.2: Execute Workflow Templates
Navigate to Templates and find the complete-server-setup workflow template.

Click the rocket icon to launch the workflow.

Monitor workflow execution:

The workflow visualizer will show the current status
Green nodes indicate successful completion
Red nodes indicate failures
Yellow nodes indicate currently running jobs
View detailed job information:

Click on individual nodes to see job details
Review the output of each job in the workflow
Check the overall workflow status
Subtask 3.3: Monitor Jobs and View History
Navigate to Jobs in the left sidebar to view all job executions.

Review job history:

Sort jobs by date, status, or template name
Click on individual jobs to view detailed information
Use filters to find specific job types or statuses
Analyze job performance:

# Example job statistics you might see:
Job ID: 15
Status: Successful
Started: 2024-01-15 10:30:00
Finished: 2024-01-15 10:32:15
Elapsed: 00:02:15
Hosts: 2 successful, 0 failed
Set up job notifications (optional):

Edit a job template
Go to the "Notifications" tab
Add email or webhook notifications for job completion
Subtask 3.4: Troubleshoot Failed Jobs
Create a test job that will fail to practice troubleshooting:

Create a new job template with an invalid playbook path
Launch the job and observe the failure
Analyze the failure:

Review the job output for error messages
Check the "Details" tab for failure reasons
Look for common issues like:
Connection failures
Permission errors
Syntax errors in playbooks
Missing variables
Common troubleshooting steps:

# Check connectivity to target hosts
- name: Test connection
  ping:

# Verify credentials are working
- name: Test privilege escalation
  command: whoami
  become: yes

# Debug variable values
- name: Show variables
  debug:
    var: ansible_facts
Fix the issue and re-run the job to verify the solution.

Subtask 3.5: Schedule Automated Jobs
Edit the system-updates job template.

Click the "Schedules" tab.

Click "Add" to create a new schedule.

Configure the schedule:

Name: weekly-updates
Description: Weekly system updates
Start Date/Time: Set to next week
Local Time Zone: Select your timezone
Repeat Frequency: Weekly
On Days: Sunday
Enable the schedule and click "Save".

Verify the schedule appears in the schedules list and shows the next run time.

Troubleshooting Tips
Common Issues and Solutions
Issue: Job fails with "Permission denied" error Solution:

Verify SSH credentials are correct
Ensure the target user has appropriate permissions
Check if privilege escalation is enabled when needed
Issue: Project sync fails Solution:

Verify Git repository URL is accessible
Check Git credentials if repository requires authentication
Ensure network connectivity to the repository
Issue: Playbook not found error Solution:

Verify the playbook path is correct relative to the project root
Ensure the project has synced successfully
Check that the playbook file exists in the repository
Issue: Host unreachable errors Solution:

Verify host IP addresses in inventory
Check network connectivity between controller and targets
Ensure SSH service is running on target hosts
Conclusion
In this lab, you have successfully:

Configured source control integration by setting up Git repository access and credentials in Ansible Automation Controller
Created comprehensive automation projects including inventories, job templates, and workflow templates
Implemented user surveys to collect input parameters for job execution
Executed and monitored automation jobs through the web interface, gaining experience with real-time job tracking
Built workflow templates that chain multiple automation tasks together for complex scenarios
Learned troubleshooting techniques for common automation issues and job failures
Set up job scheduling for automated, recurring tasks
These skills are essential for managing enterprise automation at scale using Ansible Automation Controller. The web-based interface provides powerful capabilities for organizing, executing, and monitoring automation tasks while maintaining security through credential management and role-based access control.

Understanding how to work with Automation Controller is crucial for the Red Hat Certified Specialist in Ansible Network Automation exam and for real-world automation scenarios where teams need to collaborate on infrastructure management tasks. The workflow capabilities you've learned enable complex automation scenarios that can handle dependencies, error handling, and conditional execution paths.

Continue practicing with different playbook types, inventory configurations, and workflow designs to build expertise in enterprise automation management.
