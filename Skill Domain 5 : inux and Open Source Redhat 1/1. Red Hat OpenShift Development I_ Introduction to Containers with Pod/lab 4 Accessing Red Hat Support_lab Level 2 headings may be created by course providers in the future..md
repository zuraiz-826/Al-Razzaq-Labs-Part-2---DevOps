Lab 4: Accessing Red Hat Support
Objectives
Learn to collect system diagnostic data using open-source tools
Understand how to submit a support case to Red Hat
Explore Red Hat's knowledge base resources
Learn the process of escalating a support case
Prerequisites
A system running RHEL 8 or 9 (or CentOS Stream as a substitute for lab purposes)
Valid Red Hat customer account (or create a free developer account)
Internet connectivity
Basic command line proficiency
Note: For this lab, we'll use CentOS Stream as an open-source alternative where RHEL-specific tools aren't available
Task 1: Collect System Diagnostic Data
Subtask 1.1: Gather Basic System Information
Open a terminal
Run the following commands to collect system information:
# System overview
sudo dnf install -y inxi  # Install system information tool
inxi -Fxz

# Kernel and OS details
uname -a
cat /etc/os-release

# Hardware information
lscpu
free -h
lsblk
Expected Outcome: You'll see detailed system configuration information displayed in your terminal.

Troubleshooting Tip: If inxi isn't available, use sudo dnf install -y epel-release first to enable the EPEL repository.

Subtask 1.2: Collect System Logs
# Create a directory for diagnostic data
mkdir ~/system_diagnostics
cd ~/system_diagnostics

# Collect journal logs
journalctl --since "1 day ago" > system_journal.log

# Collect dmesg output
dmesg > dmesg_output.log

# Collect installed package list
rpm -qa > installed_packages.list

# Create a tarball of the collected data
tar -czvf system_diagnostics_$(date +%Y%m%d).tar.gz *
Expected Outcome: A compressed archive (system_diagnostics_[date].tar.gz) containing all diagnostic data.

Task 2: Submit a Support Case to Red Hat
Subtask 2.1: Access the Red Hat Customer Portal
Open a web browser and navigate to: https://access.redhat.com
Log in with your Red Hat account credentials
If you don't have an account, create a free developer account at: https://developers.redhat.com/register
Subtask 2.2: Create a New Support Case
From the customer portal, click on "Support" → "Open a Case"
Fill in the case details:
Select appropriate product (e.g., "Red Hat Enterprise Linux")
Choose case severity (select "3 - Moderate" for this lab)
Enter a descriptive subject
Provide detailed description of your issue
Attach the diagnostic data collected in Task 1
Submit the case
Expected Outcome: You'll receive a case number and confirmation email.

Troubleshooting Tip: For lab purposes without actual issues, you can practice the case creation process without submitting.

Task 3: Explore Red Hat's Knowledge Base and Escalate a Case
Subtask 3.1: Search the Knowledge Base
In the Red Hat Customer Portal, click on "Knowledgebase"
Search for common issues like "Podman container startup failure"
Review the suggested solutions and articles
# Example of a common issue you might research
podman run --rm hello-world
Expected Outcome: You'll find relevant articles and solutions for common problems.

Subtask 3.2: Escalate a Support Case
Navigate to "Support" → "My Cases"
Open the case you created earlier
Click "Add Comment" to provide additional information
To escalate, click "Request Escalation" and provide justification
Submit the escalation request
Expected Outcome: The case status will change to reflect the escalation request.

Conclusion
In this lab, you have learned:

How to collect comprehensive system diagnostic data using open-source tools
The process of submitting a technical support case to Red Hat
How to effectively use Red Hat's knowledge base resources
The procedure for escalating a support case when needed
These skills are essential for effectively troubleshooting and resolving issues in Red Hat environments, particularly when working with container technologies like Podman in OpenShift development.

Final Task: Clean up the diagnostic files created during the lab:

rm -rf ~/system_diagnostics
Additional Resources
Red Hat Knowledgebase
Red Hat Support Guide
Podman Troubleshooting Guide
