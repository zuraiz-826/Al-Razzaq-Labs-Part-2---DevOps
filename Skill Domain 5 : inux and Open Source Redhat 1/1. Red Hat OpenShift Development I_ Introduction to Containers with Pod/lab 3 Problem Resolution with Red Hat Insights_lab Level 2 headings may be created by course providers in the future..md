Lab 3: Problem Resolution with Red Hat Insights
Objectives
By the end of this lab, you will be able to:

Set up and register a system with Red Hat Insights.
Analyze system health checks and recommendations.
Apply recommended fixes to resolve identified issues.
Prerequisites
A Red Hat Enterprise Linux (RHEL) 8 or 9 system with an active subscription.
Root or sudo privileges.
Internet connectivity.
insights-client package installed (if not pre-installed).
Lab Setup
Verify System Subscription
Ensure your system is registered with Red Hat Subscription Manager (RHSM):

sudo subscription-manager register --username <your_username> --password <your_password>
sudo subscription-manager attach --auto
Install Red Hat Insights Client
Install the insights-client package if not already present:

sudo dnf install -y insights-client
Task 1: Set Up Red Hat Insights
Step 1.1: Register the System with Red Hat Insights
Run the following command to register your system:

sudo insights-client --register
Expected Outcome:

The system is registered, and a confirmation message appears.
Troubleshooting Tip:

If registration fails, verify your RHSM credentials and network connectivity.
Step 1.2: Perform Initial System Analysis
Run a manual check to upload system data to Red Hat Insights:

sudo insights-client
Expected Outcome:

Data is collected and uploaded to the Red Hat Insights dashboard.
Task 2: Investigate Health Checks and Recommendations
Step 2.1: Access the Red Hat Insights Dashboard
Log in to the Red Hat Insights Portal.
Navigate to Systems to view your registered system.
Key Concept:

Insights categorizes issues into Availability, Performance, Security, and Stability.
Step 2.2: Review Recommendations
Click on your system to view detailed recommendations.
Note the Critical, Important, and Moderate severity issues.
Expected Outcome:

A list of actionable recommendations appears, such as missing patches or misconfigurations.
Task 3: Implement Recommended Fixes
Step 3.1: Apply a Recommended Update
If Insights suggests a package update, apply it:

sudo dnf update <package_name> -y
Expected Outcome:

The package is updated, and the issue is resolved.
Step 3.2: Resolve a Configuration Issue
If Insights flags a misconfiguration (e.g., /etc/ssh/sshd_config), edit the file:

sudo vi /etc/ssh/sshd_config
Make the recommended change (e.g., PermitRootLogin no), then restart the service:

sudo systemctl restart sshd
Expected Outcome:

The configuration change is applied, and the issue is marked as resolved in Insights.
Step 3.3: Verify Fixes in Insights
Re-run the Insights client to update the dashboard:

sudo insights-client
Expected Outcome:

The resolved issues no longer appear in the recommendations.
Conclusion
In this lab, you:

Registered a system with Red Hat Insights.
Analyzed health checks and recommendations.
Applied fixes to resolve identified issues.
Key Takeaway:
Red Hat Insights provides proactive monitoring and remediation guidance, reducing manual troubleshooting efforts.

Additional Resources
Red Hat Insights Documentation
Red Hat Customer Portal
