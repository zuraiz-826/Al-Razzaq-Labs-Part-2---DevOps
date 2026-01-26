Lab 1: Introduction to OpenSCAP
Objectives
By the end of this lab, students will be able to:

Install and configure OpenSCAP tools on a Linux system
Understand the fundamentals of security compliance scanning
Execute compliance scans using DISA STIG and PCI-DSS security profiles
Generate comprehensive compliance reports in multiple formats
Analyze scan results and identify security vulnerabilities
Interpret compliance scores and remediation recommendations
Prerequisites
Before starting this lab, students should have:

Basic Linux command-line knowledge
Understanding of file permissions and directory navigation
Familiarity with package management (yum/dnf or apt)
Basic knowledge of system administration concepts
Understanding of security compliance frameworks (helpful but not required)
Lab Environment
Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own virtual machine or install additional software initially.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS system
Root access for installation and configuration
Internet connectivity for downloading security profiles
Pre-installed text editors (vim, nano)
Task 1: Install and Configure OpenSCAP
Subtask 1.1: Update System and Install OpenSCAP
First, let's ensure our system is up-to-date and install the necessary OpenSCAP packages.

For RHEL/CentOS systems:

# Update the system
sudo dnf update -y

# Install OpenSCAP scanner and utilities
sudo dnf install -y openscap-scanner scap-security-guide

# Install additional tools for report generation
sudo dnf install -y openscap-utils
For Ubuntu systems:

# Update package lists
sudo apt update

# Install OpenSCAP tools
sudo apt install -y libopenscap8 ssg-debderived ssg-debian ssg-nondebian

# Install scanner utilities
sudo apt install -y openscap-scanner
Subtask 1.2: Verify Installation
Let's verify that OpenSCAP is properly installed and check the available tools.

# Check OpenSCAP version
oscap --version

# List available OpenSCAP modules
oscap --help

# Verify security guide installation
ls -la /usr/share/xml/scap/ssg/content/
Expected output should show OpenSCAP version information and available security content.

Subtask 1.3: Explore Available Security Profiles
Now let's examine what security profiles are available on our system.

# List all available security profiles
oscap info /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml

# For Ubuntu systems, use:
# oscap info /usr/share/xml/scap/ssg/content/ssg-ubuntu2004-ds.xml
This command will display available profiles including:

DISA STIG (Defense Information Systems Agency Security Technical Implementation Guide)
PCI-DSS (Payment Card Industry Data Security Standard)
CIS Benchmarks (Center for Internet Security)
NIST profiles
Task 2: Run Compliance Scans Using DISA STIG and PCI-DSS Profiles
Subtask 2.1: Prepare Scan Environment
Create a dedicated directory for storing scan results and reports.

# Create directory for scan results
mkdir -p ~/openscap-lab/results
cd ~/openscap-lab

# Create subdirectories for different scan types
mkdir -p results/disa-stig results/pci-dss results/reports
Subtask 2.2: Run DISA STIG Compliance Scan
Execute a comprehensive DISA STIG compliance scan on the system.

# Run DISA STIG scan with detailed reporting
sudo oscap xccdf eval \
    --profile xccdf_org.ssgproject.content_profile_stig \
    --results results/disa-stig/stig-results.xml \
    --report results/disa-stig/stig-report.html \
    --oval-results \
    /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml

# For Ubuntu systems, replace the last line with:
# /usr/share/xml/scap/ssg/content/ssg-ubuntu2004-ds.xml
Note: This scan may take 5-10 minutes to complete depending on system specifications.

Subtask 2.3: Run PCI-DSS Compliance Scan
Now let's perform a PCI-DSS compliance scan for payment card industry standards.

# Run PCI-DSS compliance scan
sudo oscap xccdf eval \
    --profile xccdf_org.ssgproject.content_profile_pci-dss \
    --results results/pci-dss/pci-results.xml \
    --report results/pci-dss/pci-report.html \
    --oval-results \
    /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml
Subtask 2.4: Monitor Scan Progress
While scans are running, you can monitor system resources and scan progress.

# Monitor system resources during scan
top

# Check scan processes
ps aux | grep oscap

# Monitor disk space usage
df -h ~/openscap-lab/results/
Task 3: Generate and Analyze Compliance Reports
Subtask 3.1: Verify Scan Results
First, let's verify that our scans completed successfully and examine the generated files.

# Check generated files
ls -la results/disa-stig/
ls -la results/pci-dss/

# Check file sizes to ensure scans completed
du -sh results/*/
Subtask 3.2: Generate Additional Report Formats
OpenSCAP can generate reports in multiple formats. Let's create additional report types.

# Generate ARF (Asset Reporting Format) report from DISA STIG results
oscap xccdf generate report \
    results/disa-stig/stig-results.xml > results/reports/stig-detailed-report.html

# Generate summary report for PCI-DSS
oscap xccdf generate report \
    results/pci-dss/pci-results.xml > results/reports/pci-detailed-report.html

# Create a custom report with specific formatting
oscap xccdf generate report \
    --output results/reports/stig-summary.html \
    results/disa-stig/stig-results.xml
Subtask 3.3: Extract Key Compliance Metrics
Let's extract important compliance information from our scan results.

# Extract compliance score from DISA STIG scan
oscap xccdf eval \
    --profile xccdf_org.ssgproject.content_profile_stig \
    --results-arf results/disa-stig/stig-arf.xml \
    /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml 2>&1 | \
    grep -E "(pass|fail|error|unknown|notapplicable)"

# Generate compliance summary
echo "=== COMPLIANCE SCAN SUMMARY ===" > results/reports/compliance-summary.txt
echo "Scan Date: $(date)" >> results/reports/compliance-summary.txt
echo "" >> results/reports/compliance-summary.txt

# Extract DISA STIG results summary
echo "DISA STIG Compliance Results:" >> results/reports/compliance-summary.txt
grep -o "Result: [a-z]*" results/disa-stig/stig-report.html | \
    sort | uniq -c >> results/reports/compliance-summary.txt

echo "" >> results/reports/compliance-summary.txt

# Extract PCI-DSS results summary
echo "PCI-DSS Compliance Results:" >> results/reports/compliance-summary.txt
grep -o "Result: [a-z]*" results/pci-dss/pci-report.html | \
    sort | uniq -c >> results/reports/compliance-summary.txt
Subtask 3.4: Analyze Critical Findings
Let's identify and analyze the most critical security findings from our scans.

# Create analysis script for critical findings
cat > analyze_findings.sh << 'EOF'
#!/bin/bash

echo "=== CRITICAL SECURITY FINDINGS ANALYSIS ==="
echo "Generated on: $(date)"
echo ""

# Analyze DISA STIG critical failures
echo "DISA STIG Critical Failures:"
echo "----------------------------"
if [ -f "results/disa-stig/stig-results.xml" ]; then
    grep -A 5 -B 5 'result="fail"' results/disa-stig/stig-results.xml | \
    grep -E "(rule id|title)" | head -20
else
    echo "DISA STIG results file not found"
fi

echo ""
echo "PCI-DSS Critical Failures:"
echo "---------------------------"
if [ -f "results/pci-dss/pci-results.xml" ]; then
    grep -A 5 -B 5 'result="fail"' results/pci-dss/pci-results.xml | \
    grep -E "(rule id|title)" | head -20
else
    echo "PCI-DSS results file not found"
fi

echo ""
echo "=== REMEDIATION PRIORITY ==="
echo "1. Review failed rules in HTML reports"
echo "2. Focus on high-severity findings first"
echo "3. Implement fixes systematically"
echo "4. Re-scan to verify remediation"
EOF

# Make script executable and run it
chmod +x analyze_findings.sh
./analyze_findings.sh > results/reports/critical-findings.txt

# Display the analysis
cat results/reports/critical-findings.txt
Subtask 3.5: View HTML Reports
Since we're working in a command-line environment, let's extract key information from the HTML reports.

# Extract compliance scores from HTML reports
echo "=== COMPLIANCE SCORES ===" > results/reports/scores.txt

# Extract overall compliance percentage (if available)
grep -i "compliance\|score\|percentage" results/disa-stig/stig-report.html | \
    head -5 >> results/reports/scores.txt

echo "" >> results/reports/scores.txt

grep -i "compliance\|score\|percentage" results/pci-dss/pci-report.html | \
    head -5 >> results/reports/scores.txt

# Display the scores
cat results/reports/scores.txt
Subtask 3.6: Generate Remediation Script Template
Create a template script for addressing common compliance issues.

# Create remediation template
cat > remediation_template.sh << 'EOF'
#!/bin/bash

# OpenSCAP Compliance Remediation Template
# Generated from Lab 1 scan results

echo "Starting compliance remediation..."
echo "Date: $(date)"

# Common DISA STIG remediations
echo "Applying common DISA STIG fixes..."

# Set proper file permissions
chmod 644 /etc/passwd
chmod 600 /etc/shadow
chmod 644 /etc/group

# Configure password policies (example)
# Note: Modify /etc/login.defs and /etc/security/pwquality.conf as needed

# Enable firewall
systemctl enable firewalld
systemctl start firewalld

# Update system packages
dnf update -y

# Configure audit logging
systemctl enable auditd
systemctl start auditd

echo "Basic remediation steps completed."
echo "Review scan reports for specific additional requirements."
echo "Re-run scans to verify improvements."
EOF

chmod +x remediation_template.sh
echo "Remediation template created: remediation_template.sh"
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Permission Denied Errors

# Solution: Ensure you're running scans with sudo
sudo oscap xccdf eval [options]
Issue 2: Missing Security Content

# Solution: Reinstall security guide
sudo dnf reinstall scap-security-guide
# or for Ubuntu:
sudo apt reinstall ssg-debderived
Issue 3: Scan Takes Too Long

# Solution: Run scan on specific rules only
oscap xccdf eval --profile [profile] --rule [specific-rule-id] [datastream]
Issue 4: Cannot Find Profile

# Solution: List available profiles first
oscap info /usr/share/xml/scap/ssg/content/ssg-*.xml
Lab Verification
To verify your lab completion, ensure you have:

Successfully installed OpenSCAP tools
Generated DISA STIG compliance report
Generated PCI-DSS compliance report
Created analysis summaries
All files present in the results directory structure
# Final verification command
find ~/openscap-lab -name "*.xml" -o -name "*.html" -o -name "*.txt" | wc -l
You should have at least 8-10 files generated from your scans and analysis.

Conclusion
In this lab, you have successfully:

Installed and configured OpenSCAP, a powerful open-source security compliance scanning tool
Executed comprehensive security scans using industry-standard profiles (DISA STIG and PCI-DSS)
Generated detailed compliance reports in multiple formats for analysis and documentation
Analyzed scan results to identify critical security findings and compliance gaps
Created remediation templates to address common security vulnerabilities
Why This Matters:

OpenSCAP is a critical tool for maintaining security compliance in enterprise environments. The skills you've developed in this lab are directly applicable to:

Red Hat Certified Specialist in Security certification requirements
Enterprise security compliance initiatives
Automated security scanning in DevSecOps pipelines
Regulatory compliance reporting (PCI-DSS, FISMA, etc.)
Continuous security monitoring and improvement
The compliance scanning and reporting capabilities you've learned are essential for security professionals working with Linux systems in regulated industries, government environments, and security-conscious organizations.

Next Steps:

Practice running scans with different security profiles
Explore automated remediation using OpenSCAP
Integrate OpenSCAP into CI/CD pipelines
Study specific compliance requirements for your industry
