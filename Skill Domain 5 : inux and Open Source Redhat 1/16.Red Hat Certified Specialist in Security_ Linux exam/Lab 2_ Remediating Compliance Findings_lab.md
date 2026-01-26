Lab 2: Remediating Compliance Findings
Objectives
By the end of this lab, students will be able to:

Apply automated remediation using OpenSCAP commands to fix compliance violations
Manually remediate security findings that require custom configuration
Re-scan systems after remediation to verify compliance improvements
Generate updated security reports showing remediation progress
Understand the difference between automated and manual remediation approaches
Interpret remediation results and identify remaining compliance gaps
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with text editors (nano, vim, or gedit)
Completion of Lab 1 or equivalent knowledge of OpenSCAP scanning
Understanding of basic security concepts and compliance frameworks
Knowledge of system configuration files and services management
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with OpenSCAP tools pre-installed
Sample compliance violations from previous scans
Administrative privileges for system remediation
All necessary SCAP content and profiles
Task 1: Apply Automated Remediation Using OpenSCAP Commands
Subtask 1.1: Review Previous Scan Results
First, let's examine the compliance violations from our previous scan to understand what needs remediation.

Navigate to your scan results directory:
cd /home/student/compliance_scans
ls -la
Review the previous HTML report to identify violations:
firefox initial_scan_report.html &
Examine the XCCDF results file for detailed findings:
oscap xccdf eval --results-arf initial_results.xml --report detailed_findings.html /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml
Subtask 1.2: Generate Remediation Script
OpenSCAP can automatically generate remediation scripts based on scan results.

Create a remediation script from your previous scan results:
oscap xccdf generate fix --template urn:xccdf:fix:script:sh --profile xccdf_org.ssgproject.content_profile_pci-dss --results initial_results.xml /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml > remediation_script.sh
Review the generated remediation script:
cat remediation_script.sh | head -50
Make the script executable:
chmod +x remediation_script.sh
Subtask 1.3: Execute Automated Remediation
Important: Always backup your system before applying remediation.

Create a system backup point:
sudo cp /etc/passwd /etc/passwd.backup
sudo cp /etc/shadow /etc/shadow.backup
sudo cp /etc/group /etc/group.backup
Execute the remediation script with logging:
sudo ./remediation_script.sh 2>&1 | tee remediation_log.txt
Review the remediation log for any errors:
grep -i error remediation_log.txt
grep -i failed remediation_log.txt
Subtask 1.4: Verify Automated Remediation Results
Perform a quick verification scan:
sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_pci-dss --results post_auto_remediation.xml --report post_auto_report.html /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml
Compare results with the initial scan:
firefox post_auto_report.html &
Task 2: Manually Fix Compliance Violations and Re-scan
Subtask 2.1: Identify Manual Remediation Requirements
Some compliance violations require manual intervention because they involve business decisions or complex configurations.

Review the post-remediation report to identify remaining violations:
oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_pci-dss --results current_results.xml /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml | grep -E "(fail|error)"
Extract specific failed rules for manual review:
oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_pci-dss --results current_results.xml /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml 2>&1 | grep "Rule.*fail" > manual_fixes_needed.txt
Subtask 2.2: Manual Password Policy Remediation
Let's manually fix password policy violations that commonly require custom configuration.

Check current password policy settings:
sudo cat /etc/login.defs | grep -E "(PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_MIN_LEN|PASS_WARN_AGE)"
Edit the login.defs file to meet compliance requirements:
sudo cp /etc/login.defs /etc/login.defs.backup
sudo nano /etc/login.defs
Update the following parameters in the file:
PASS_MAX_DAYS   90
PASS_MIN_DAYS   1
PASS_MIN_LEN    14
PASS_WARN_AGE   7
Configure PAM password complexity requirements:
sudo cp /etc/pam.d/system-auth /etc/pam.d/system-auth.backup
sudo nano /etc/pam.d/system-auth
Add or modify the password quality line:
password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 minlen=14 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1
Subtask 2.3: Manual SSH Configuration Remediation
SSH configuration often requires manual tuning for compliance.

Backup and edit SSH configuration:
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo nano /etc/ssh/sshd_config
Apply these security settings:
Protocol 2
PermitRootLogin no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 0
PermitEmptyPasswords no
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
Banner /etc/issue
Restart SSH service to apply changes:
sudo systemctl restart sshd
sudo systemctl status sshd
Subtask 2.4: Manual Audit Configuration
Configure system auditing for compliance requirements.

Check current audit service status:
sudo systemctl status auditd
Configure audit rules for file system monitoring:
sudo cp /etc/audit/rules.d/audit.rules /etc/audit/rules.d/audit.rules.backup
sudo nano /etc/audit/rules.d/audit.rules
Add compliance-required audit rules:
# Monitor file deletions
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete

# Monitor privilege escalation
-w /usr/bin/sudo -p x -k privilege_escalation
-w /etc/sudoers -p wa -k privilege_escalation

# Monitor authentication events
-w /var/log/lastlog -p wa -k authentication
-w /var/run/faillock -p wa -k authentication
Restart audit service:
sudo systemctl restart auditd
Subtask 2.5: Perform Post-Manual Remediation Scan
Run a comprehensive scan after manual remediation:
sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_pci-dss --results post_manual_remediation.xml --report post_manual_report.html /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml
Check the scan completion status:
echo "Scan completed with exit code: $?"
Task 3: Generate Updated Security Reports
Subtask 3.1: Create Comprehensive Compliance Report
Generate a detailed HTML report with all findings:
oscap xccdf generate report post_manual_remediation.xml > final_compliance_report.html
Create a summary report showing only failed items:
oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_pci-dss --results final_results.xml /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml 2>&1 | grep -E "(Title|Result)" > compliance_summary.txt
Subtask 3.2: Generate Executive Summary
Create a high-level summary for management reporting.

Extract compliance statistics:
# Count total rules
TOTAL_RULES=$(oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_pci-dss /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml 2>&1 | grep -c "Rule")

# Count passed rules
PASSED_RULES=$(grep -c "pass" final_results.xml)

# Count failed rules
FAILED_RULES=$(grep -c "fail" final_results.xml)

# Calculate compliance percentage
COMPLIANCE_PERCENT=$(echo "scale=2; ($PASSED_RULES * 100) / $TOTAL_RULES" | bc)

echo "=== COMPLIANCE EXECUTIVE SUMMARY ===" > executive_summary.txt
echo "Total Rules Evaluated: $TOTAL_RULES" >> executive_summary.txt
echo "Rules Passed: $PASSED_RULES" >> executive_summary.txt
echo "Rules Failed: $FAILED_RULES" >> executive_summary.txt
echo "Compliance Percentage: $COMPLIANCE_PERCENT%" >> executive_summary.txt
echo "Scan Date: $(date)" >> executive_summary.txt
View the executive summary:
cat executive_summary.txt
Subtask 3.3: Create Remediation Progress Report
Compare before and after remediation results.

Create a progress comparison script:
cat > remediation_progress.sh << 'EOF'
#!/bin/bash

echo "=== REMEDIATION PROGRESS REPORT ==="
echo "Generated on: $(date)"
echo ""

# Initial scan results
INITIAL_FAILED=$(grep -c "fail" initial_results.xml 2>/dev/null || echo "0")
echo "Initial Failed Rules: $INITIAL_FAILED"

# Post-auto remediation results
AUTO_FAILED=$(grep -c "fail" post_auto_remediation.xml 2>/dev/null || echo "0")
echo "Failed After Auto Remediation: $AUTO_FAILED"

# Final results after manual remediation
FINAL_FAILED=$(grep -c "fail" final_results.xml 2>/dev/null || echo "0")
echo "Final Failed Rules: $FINAL_FAILED"

# Calculate improvements
AUTO_IMPROVEMENT=$((INITIAL_FAILED - AUTO_FAILED))
MANUAL_IMPROVEMENT=$((AUTO_FAILED - FINAL_FAILED))
TOTAL_IMPROVEMENT=$((INITIAL_FAILED - FINAL_FAILED))

echo ""
echo "=== IMPROVEMENTS ==="
echo "Rules Fixed by Auto Remediation: $AUTO_IMPROVEMENT"
echo "Rules Fixed by Manual Remediation: $MANUAL_IMPROVEMENT"
echo "Total Rules Fixed: $TOTAL_IMPROVEMENT"

if [ $INITIAL_FAILED -gt 0 ]; then
    IMPROVEMENT_PERCENT=$(echo "scale=2; ($TOTAL_IMPROVEMENT * 100) / $INITIAL_FAILED" | bc)
    echo "Overall Improvement: $IMPROVEMENT_PERCENT%"
fi
EOF
Make the script executable and run it:
chmod +x remediation_progress.sh
./remediation_progress.sh > remediation_progress_report.txt
cat remediation_progress_report.txt
Subtask 3.4: Generate Detailed Findings Report
Create a detailed report of remaining violations:
oscap xccdf generate report --format html final_results.xml > detailed_final_report.html
Extract specific failed rules with descriptions:
cat > extract_failures.sh << 'EOF'
#!/bin/bash

echo "=== REMAINING COMPLIANCE VIOLATIONS ===" > remaining_violations.txt
echo "Generated on: $(date)" >> remaining_violations.txt
echo "" >> remaining_violations.txt

# Extract failed rules with titles
oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_pci-dss /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml 2>&1 | \
grep -A1 -B1 "fail" | \
grep -E "(Title|fail)" >> remaining_violations.txt

echo "" >> remaining_violations.txt
echo "=== REMEDIATION RECOMMENDATIONS ===" >> remaining_violations.txt
echo "1. Review failed rules in the detailed HTML report" >> remaining_violations.txt
echo "2. Consult organization security policies for manual fixes" >> remaining_violations.txt
echo "3. Consider risk acceptance for non-critical violations" >> remaining_violations.txt
echo "4. Schedule regular compliance scans" >> remaining_violations.txt
EOF
Execute the script:
chmod +x extract_failures.sh
./extract_failures.sh
cat remaining_violations.txt
Subtask 3.5: Archive Reports and Documentation
Create a comprehensive archive of all reports:
mkdir -p compliance_archive/$(date +%Y%m%d)
cp *.html compliance_archive/$(date +%Y%m%d)/
cp *.xml compliance_archive/$(date +%Y%m%d)/
cp *.txt compliance_archive/$(date +%Y%m%d)/
cp *.sh compliance_archive/$(date +%Y%m%d)/
Create a README file for the archive:
cat > compliance_archive/$(date +%Y%m%d)/README.txt << EOF
COMPLIANCE REMEDIATION ARCHIVE
==============================
Date: $(date)
Profile: PCI-DSS
System: $(hostname)

FILES INCLUDED:
- initial_results.xml: Original scan results
- post_auto_remediation.xml: Results after automated fixes
- final_results.xml: Results after manual remediation
- final_compliance_report.html: Detailed compliance report
- executive_summary.txt: High-level summary
- remediation_progress_report.txt: Before/after comparison
- remaining_violations.txt: Outstanding issues
- remediation_script.sh: Auto-generated remediation script
- remediation_log.txt: Remediation execution log

NEXT STEPS:
1. Review remaining violations
2. Plan additional remediation activities
3. Schedule follow-up compliance scans
4. Update security documentation
EOF
View the final archive structure:
ls -la compliance_archive/$(date +%Y%m%d)/
Troubleshooting Common Issues
Issue 1: Remediation Script Fails to Execute
Problem: Permission denied or script execution errors

Solution:

# Check script permissions
ls -la remediation_script.sh

# Fix permissions if needed
chmod +x remediation_script.sh

# Check for syntax errors
bash -n remediation_script.sh
Issue 2: Service Restart Failures
Problem: Services fail to restart after configuration changes

Solution:

# Check service status
sudo systemctl status service_name

# View detailed error logs
sudo journalctl -u service_name -n 50

# Validate configuration files
sudo service_name -t  # For services that support test mode
Issue 3: Scan Results Show No Improvement
Problem: Compliance scores don't improve after remediation

Solution:

# Verify remediation was applied
sudo grep -r "remediation_applied" /var/log/

# Check if correct profile was used
oscap info /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml

# Ensure system reboot if required
sudo systemctl reboot
Conclusion
In this lab, you have successfully:

Applied automated remediation using OpenSCAP-generated scripts to fix multiple compliance violations efficiently
Performed manual remediation for complex security configurations that require human judgment and customization
Generated comprehensive security reports that demonstrate compliance improvement and remaining gaps
Created executive summaries suitable for management reporting and compliance documentation
Established a systematic approach to compliance remediation that combines automation with manual oversight
Why This Matters: Compliance remediation is a critical skill in cybersecurity because it bridges the gap between identifying security issues and actually fixing them. Organizations must demonstrate not just awareness of security problems, but active remediation efforts. The combination of automated and manual remediation techniques you've learned provides a comprehensive approach to maintaining security compliance in enterprise environments.

Key Takeaways:

Automated remediation handles routine fixes efficiently but requires careful testing
Manual remediation is essential for complex configurations and business-specific requirements
Progress tracking and documentation are crucial for compliance audits
Regular re-scanning validates remediation effectiveness and identifies new issues
This systematic approach to compliance remediation will serve you well in real-world security operations and compliance management roles.
