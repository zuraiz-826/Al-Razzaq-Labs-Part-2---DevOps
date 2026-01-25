Lab 9: Configuring Postfix for Email Sending
Objectives
By the end of this lab, students will be able to:

Install and configure Postfix mail server for sending emails
Set up relay hosts and authentication mechanisms for secure email delivery
Implement TLS encryption to secure mail traffic
Test email functionality and troubleshoot common configuration issues
Understand the fundamentals of mail server security and best practices
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with text editors (nano, vim, or gedit)
Knowledge of network concepts including DNS and TCP/IP
Understanding of basic system administration tasks
Access to root or sudo privileges on the system
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your dedicated environment - no need to build your own virtual machine or configure initial settings.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS system
Root access for system configuration
Network connectivity for testing email functionality
Pre-installed basic utilities and text editors
Task 1: Install and Configure Postfix for Email Sending
Subtask 1.1: Install Postfix Package
First, we need to install the Postfix mail server package on our system.

For RHEL/CentOS systems:

# Update the system packages
sudo dnf update -y

# Install Postfix and mailx utilities
sudo dnf install -y postfix mailx

# Install additional utilities for testing
sudo dnf install -y telnet nc
For Ubuntu/Debian systems:

# Update package repositories
sudo apt update

# Install Postfix and mail utilities
sudo apt install -y postfix mailutils

# Install additional testing tools
sudo apt install -y telnet netcat
Subtask 1.2: Initial Postfix Configuration
Now we'll configure Postfix with basic settings for sending emails.

# Stop Postfix service if running
sudo systemctl stop postfix

# Backup the original configuration file
sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.backup

# Create a new basic configuration
sudo tee /etc/postfix/main.cf > /dev/null << 'EOF'
# Basic Postfix Configuration for Email Sending
compatibility_level = 2

# Network settings
inet_interfaces = all
inet_protocols = ipv4
mydestination = $myhostname, localhost.$mydomain, localhost
myorigin = $mydomain

# Basic mail handling
home_mailbox = Maildir/
mailbox_command = 

# Message size limits
message_size_limit = 10240000
mailbox_size_limit = 1024000000

# Queue settings
maximal_queue_lifetime = 1d
bounce_queue_lifetime = 1d

# Logging
maillog_file = /var/log/postfix.log
EOF
Subtask 1.3: Set Hostname and Domain
Configure the system hostname and domain for proper email identification.

# Set the hostname (replace 'mailserver' with your preferred name)
sudo hostnamectl set-hostname mailserver.example.com

# Update the Postfix configuration with hostname
sudo postconf -e "myhostname = $(hostname -f)"
sudo postconf -e "mydomain = example.com"

# Verify the configuration
sudo postconf -n | grep -E "(myhostname|mydomain)"
Subtask 1.4: Configure Basic Mail Directories
Set up the necessary directories for mail handling.

# Create mail spool directory if it doesn't exist
sudo mkdir -p /var/spool/mail

# Set proper permissions
sudo chmod 1777 /var/spool/mail

# Create postfix user home directory
sudo mkdir -p /var/spool/postfix

# Set ownership
sudo chown -R postfix:postfix /var/spool/postfix
Task 2: Manage Relay Hosts and Authentication Settings
Subtask 2.1: Configure SMTP Relay Host
Configure Postfix to use an external SMTP server for email delivery.

# Configure relay host (using Gmail as example)
sudo postconf -e "relayhost = [smtp.gmail.com]:587"

# Enable SASL authentication
sudo postconf -e "smtp_sasl_auth_enable = yes"
sudo postconf -e "smtp_sasl_security_options = noanonymous"
sudo postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
Subtask 2.2: Create Authentication Credentials
Set up authentication credentials for the relay host.

# Create SASL password file
sudo tee /etc/postfix/sasl_passwd > /dev/null << 'EOF'
# Format: [hostname]:port username:password
[smtp.gmail.com]:587 your-email@gmail.com:your-app-password
EOF

# Note: Replace 'your-email@gmail.com' and 'your-app-password' with actual credentials
# For Gmail, you need to generate an App Password from your Google Account settings

# Set proper permissions on the password file
sudo chmod 600 /etc/postfix/sasl_passwd

# Create the hash database
sudo postmap /etc/postfix/sasl_passwd

# Verify the database was created
ls -la /etc/postfix/sasl_passwd*
Subtask 2.3: Configure SASL Authentication
Install and configure SASL authentication components.

For RHEL/CentOS:

# Install SASL packages
sudo dnf install -y cyrus-sasl-plain cyrus-sasl-md5

# Configure SASL mechanism maps
sudo postconf -e "smtp_sasl_mechanism_filter = plain, login"
For Ubuntu/Debian:

# Install SASL packages
sudo apt install -y libsasl2-modules

# Configure SASL mechanism
sudo postconf -e "smtp_sasl_mechanism_filter = plain, login"
Subtask 2.4: Configure Network Maps and Access Control
Set up network access controls and sender restrictions.

# Configure network access
sudo postconf -e "mynetworks = 127.0.0.0/8, 10.0.0.0/8, 192.168.0.0/16, 172.16.0.0/12"

# Configure sender restrictions
sudo postconf -e "smtpd_sender_restrictions = permit_mynetworks, reject_unknown_sender_domain"

# Configure recipient restrictions
sudo postconf -e "smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination"
Task 3: Secure Mail Traffic Using TLS Encryption
Subtask 3.1: Enable TLS for SMTP Client
Configure Postfix to use TLS when connecting to relay hosts.

# Enable TLS for outgoing connections
sudo postconf -e "smtp_use_tls = yes"
sudo postconf -e "smtp_tls_security_level = encrypt"

# Configure TLS certificate verification
sudo postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-bundle.crt"

# For Ubuntu/Debian, use this path instead:
# sudo postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"

# Configure TLS session cache
sudo postconf -e "smtp_tls_session_cache_database = btree:/var/lib/postfix/smtp_scache"
Subtask 3.2: Configure TLS Logging and Debugging
Enable TLS logging for troubleshooting and monitoring.

# Enable TLS logging
sudo postconf -e "smtp_tls_loglevel = 1"

# Configure additional TLS options
sudo postconf -e "smtp_tls_note_starttls_offer = yes"

# Set TLS protocols (disable older insecure versions)
sudo postconf -e "smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1"
sudo postconf -e "smtp_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1"
Subtask 3.3: Generate Self-Signed Certificates (Optional)
For testing purposes, create self-signed certificates.

# Create directory for certificates
sudo mkdir -p /etc/postfix/certs

# Generate private key
sudo openssl genrsa -out /etc/postfix/certs/postfix.key 2048

# Generate certificate signing request
sudo openssl req -new -key /etc/postfix/certs/postfix.key -out /etc/postfix/certs/postfix.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=$(hostname -f)"

# Generate self-signed certificate
sudo openssl x509 -req -days 365 -in /etc/postfix/certs/postfix.csr -signkey /etc/postfix/certs/postfix.key -out /etc/postfix/certs/postfix.crt

# Set proper permissions
sudo chmod 600 /etc/postfix/certs/postfix.key
sudo chmod 644 /etc/postfix/certs/postfix.crt

# Configure Postfix to use the certificates
sudo postconf -e "smtpd_tls_cert_file = /etc/postfix/certs/postfix.crt"
sudo postconf -e "smtpd_tls_key_file = /etc/postfix/certs/postfix.key"
Subtask 3.4: Enable TLS for Incoming Connections
Configure TLS for SMTP server (receiving emails).

# Enable TLS for incoming connections
sudo postconf -e "smtpd_use_tls = yes"
sudo postconf -e "smtpd_tls_security_level = may"

# Configure TLS session cache for server
sudo postconf -e "smtpd_tls_session_cache_database = btree:/var/lib/postfix/smtpd_scache"

# Set server TLS logging
sudo postconf -e "smtpd_tls_loglevel = 1"

# Configure TLS authentication
sudo postconf -e "smtpd_tls_auth_only = no"
Task 4: Start Services and Test Configuration
Subtask 4.1: Start and Enable Postfix Service
# Start Postfix service
sudo systemctl start postfix

# Enable Postfix to start at boot
sudo systemctl enable postfix

# Check service status
sudo systemctl status postfix

# Verify Postfix is listening on port 25
sudo netstat -tlnp | grep :25
Subtask 4.2: Test Email Sending Functionality
Test the email configuration with various methods.

# Test 1: Send email using mail command
echo "This is a test email from Postfix configuration lab." | mail -s "Test Email from Lab 9" recipient@example.com

# Test 2: Send email using sendmail
sudo tee /tmp/test_email.txt > /dev/null << 'EOF'
To: recipient@example.com
From: sender@example.com
Subject: Postfix Test Email

This is a test email to verify Postfix configuration.
The email was sent from Lab 9: Configuring Postfix for Email Sending.

Best regards,
Lab Administrator
EOF

# Send the email
sudo sendmail recipient@example.com < /tmp/test_email.txt

# Test 3: Check mail queue
sudo postqueue -p

# Test 4: Monitor mail logs
sudo tail -f /var/log/postfix.log
Subtask 4.3: Verify TLS Configuration
Test TLS functionality and encryption.

# Test SMTP connection with TLS
echo "QUIT" | openssl s_client -connect smtp.gmail.com:587 -starttls smtp

# Check TLS configuration in Postfix
sudo postconf -n | grep tls

# Verify certificate files exist and have correct permissions
ls -la /etc/postfix/certs/
Subtask 4.4: Monitor and Troubleshoot
Set up monitoring and troubleshooting tools.

# Create a script to monitor mail queue
sudo tee /usr/local/bin/check_mail_queue.sh > /dev/null << 'EOF'
#!/bin/bash
echo "=== Mail Queue Status ==="
postqueue -p
echo ""
echo "=== Recent Mail Log Entries ==="
tail -20 /var/log/postfix.log
EOF

# Make script executable
sudo chmod +x /usr/local/bin/check_mail_queue.sh

# Run the monitoring script
sudo /usr/local/bin/check_mail_queue.sh
Task 5: Advanced Configuration and Security Hardening
Subtask 5.1: Configure Rate Limiting
Implement rate limiting to prevent abuse.

# Configure connection rate limits
sudo postconf -e "smtpd_client_connection_count_limit = 10"
sudo postconf -e "smtpd_client_connection_rate_limit = 30"

# Configure message rate limits
sudo postconf -e "smtpd_client_message_rate_limit = 100"

# Configure recipient rate limits
sudo postconf -e "smtpd_client_recipient_rate_limit = 200"
Subtask 5.2: Configure Header Checks
Set up header checks for additional security.

# Create header checks file
sudo tee /etc/postfix/header_checks > /dev/null << 'EOF'
# Remove sensitive information from headers
/^Received: from .*\[(192\.168\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.)/
    REPLACE Received: from localhost
/^X-Originating-IP:/    IGNORE
/^X-Mailer:/           IGNORE
/^User-Agent:/         IGNORE
EOF

# Configure Postfix to use header checks
sudo postconf -e "header_checks = regexp:/etc/postfix/header_checks"

# Create the database
sudo postmap /etc/postfix/header_checks
Subtask 5.3: Final Configuration Review
Review and validate the complete configuration.

# Display current Postfix configuration
sudo postconf -n > /tmp/postfix_config.txt

# Check configuration syntax
sudo postfix check

# Reload Postfix with new configuration
sudo systemctl reload postfix

# Display final configuration summary
echo "=== Postfix Configuration Summary ==="
echo "Hostname: $(postconf -h myhostname)"
echo "Domain: $(postconf -h mydomain)"
echo "Relay Host: $(postconf -h relayhost)"
echo "TLS Enabled: $(postconf -h smtp_use_tls)"
echo "SASL Auth: $(postconf -h smtp_sasl_auth_enable)"
Troubleshooting Common Issues
Issue 1: Authentication Failures
# Check SASL configuration
sudo postconf -n | grep sasl

# Verify password file exists and has correct permissions
ls -la /etc/postfix/sasl_passwd*

# Check for authentication errors in logs
sudo grep -i "authentication failed" /var/log/postfix.log
Issue 2: TLS Connection Problems
# Test TLS connectivity manually
openssl s_client -connect smtp.gmail.com:587 -starttls smtp -verify_return_error

# Check TLS configuration
sudo postconf -n | grep -i tls

# Verify CA certificate file exists
ls -la /etc/ssl/certs/ca-bundle.crt
Issue 3: Mail Queue Issues
# View detailed queue information
sudo postqueue -p

# Flush the mail queue
sudo postqueue -f

# Remove specific messages from queue (replace QUEUE_ID)
sudo postsuper -d QUEUE_ID

# Clear entire queue (use with caution)
sudo postsuper -d ALL
Testing and Validation
Comprehensive Test Script
Create a comprehensive test script to validate all configurations.

# Create test script
sudo tee /usr/local/bin/postfix_test.sh > /dev/null << 'EOF'
#!/bin/bash

echo "=== Postfix Configuration Test ==="
echo ""

# Test 1: Service Status
echo "1. Checking Postfix service status..."
systemctl is-active postfix
echo ""

# Test 2: Port Listening
echo "2. Checking if Postfix is listening on port 25..."
netstat -tlnp | grep :25
echo ""

# Test 3: Configuration Syntax
echo "3. Checking configuration syntax..."
postfix check
echo "Configuration syntax: OK"
echo ""

# Test 4: TLS Configuration
echo "4. Checking TLS configuration..."
postconf -h smtp_use_tls
postconf -h smtpd_use_tls
echo ""

# Test 5: Authentication Configuration
echo "5. Checking SASL authentication..."
postconf -h smtp_sasl_auth_enable
echo ""

# Test 6: Queue Status
echo "6. Checking mail queue..."
postqueue -p
echo ""

echo "=== Test Complete ==="
EOF

# Make script executable
sudo chmod +x /usr/local/bin/postfix_test.sh

# Run the test
sudo /usr/local/bin/postfix_test.sh
Conclusion
In this comprehensive lab, you have successfully:

Accomplished Tasks:

Installed and configured Postfix as a mail transfer agent capable of sending emails securely
Implemented relay host configuration with proper authentication mechanisms using SASL
Secured mail traffic using TLS encryption for both incoming and outgoing connections
Applied security hardening measures including rate limiting and header filtering
Tested and validated the complete email sending functionality
Key Technical Skills Developed:

Mail server administration and configuration management
SMTP protocol understanding and implementation
TLS/SSL encryption configuration for secure communications
Authentication mechanisms and credential management
System monitoring and troubleshooting techniques
Real-World Applications: This lab provides practical experience essential for system administrators managing email infrastructure in enterprise environments. The skills learned are directly applicable to:

Corporate email server management
Automated notification systems
Application-to-email integration
Secure communication infrastructure
Compliance with email security standards
Why This Matters: Email remains a critical communication infrastructure in modern organizations. Understanding how to properly configure, secure, and maintain mail servers like Postfix is essential for ensuring reliable and secure email delivery. The TLS encryption and authentication mechanisms you've implemented represent industry best practices for protecting sensitive communications and preventing email-based security threats.

Your newly acquired skills in Postfix configuration will serve as a foundation for more advanced email infrastructure management and contribute significantly to your expertise in Linux system administration and email security.
