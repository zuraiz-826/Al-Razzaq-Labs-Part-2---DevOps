Lab 7: Configuring DNS with BIND
Objectives
By the end of this lab, you will be able to:

Install and configure BIND (Berkeley Internet Name Domain) as a caching DNS server
Set up DNS forwarding to upstream DNS servers for efficient name resolution
Create and manage zone files for various DNS record types including A, CNAME, and PTR records
Understand the fundamentals of DNS hierarchy and resolution process
Troubleshoot common DNS configuration issues
Implement best practices for DNS server security and performance
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command line operations
Familiarity with text editors like nano or vim
Knowledge of networking concepts including IP addresses and domain names
Understanding of client-server architecture
Basic knowledge of system administration tasks like service management
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install any software locally.

Your lab environment includes:

CentOS/RHEL 8 or 9 based system
Root access for system configuration
Network connectivity for testing DNS resolution
Pre-installed text editors and network utilities
Task 1: Install BIND and Configure as a Caching DNS Server
Subtask 1.1: Install BIND Packages
First, we need to install BIND and its utilities on our system.

# Update the system packages
sudo dnf update -y

# Install BIND and related utilities
sudo dnf install -y bind bind-utils

# Verify installation
rpm -qa | grep bind
Subtask 1.2: Understand BIND Configuration Structure
BIND uses several configuration files located in specific directories:

Main configuration file: /etc/named.conf
Zone files directory: /var/named/
Log files: /var/log/messages or /var/named/data/named.run
# Check the default configuration structure
ls -la /etc/named.conf
ls -la /var/named/
Subtask 1.3: Configure Basic Caching DNS Server
Create a basic caching DNS server configuration:

# Backup the original configuration
sudo cp /etc/named.conf /etc/named.conf.backup

# Create a new named.conf file
sudo nano /etc/named.conf
Add the following configuration to /etc/named.conf:

//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//

options {
    listen-on port 53 { 127.0.0.1; any; };
    listen-on-v6 port 53 { ::1; };
    directory       "/var/named";
    dump-file       "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    secroots-file   "/var/named/data/named.secroots";
    recursion yes;
    allow-query     { localhost; any; };
    allow-query-cache { localhost; any; };

    /*
     - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
     - If you are building a RECURSIVE (caching) DNS server, you need to enable
       recursion.
     - If your recursive DNS server has a public IP address, you MUST enable access
       control to limit queries to your legitimate users. Failing to do so will
       cause your server to become part of large scale DNS amplification
       attacks. Implementing BCP38 within your network would greatly
       reduce such attack surface
    */

    dnssec-enable yes;
    dnssec-validation yes;

    managed-keys-directory "/var/named/dynamic";

    pid-file "/run/named/named.pid";
    session-keyfile "/run/named/session.key";

    /* https://fedoraproject.org/wiki/Changes/CryptoPolicy */
    include "/etc/crypto-policies/back-ends/bind.config";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
    type hint;
    file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
Subtask 1.4: Start and Enable BIND Service
# Start the named service
sudo systemctl start named

# Enable the service to start at boot
sudo systemctl enable named

# Check the service status
sudo systemctl status named

# Check if BIND is listening on port 53
sudo netstat -tulnp | grep :53
Subtask 1.5: Configure Firewall
# Allow DNS traffic through firewall
sudo firewall-cmd --permanent --add-service=dns
sudo firewall-cmd --reload

# Verify firewall rules
sudo firewall-cmd --list-services
Subtask 1.6: Test Basic Caching Functionality
# Test DNS resolution using the local server
dig @localhost google.com

# Test with nslookup
nslookup google.com localhost

# Check if caching is working by running the same query twice
# The second query should be faster
time dig @localhost google.com
time dig @localhost google.com
Task 2: Set Up DNS Forwarding to Upstream DNS Servers
Subtask 2.1: Configure Forwarders
Edit the BIND configuration to add upstream DNS servers:

# Edit the main configuration file
sudo nano /etc/named.conf
Modify the options section to include forwarders:

options {
    listen-on port 53 { 127.0.0.1; any; };
    listen-on-v6 port 53 { ::1; };
    directory       "/var/named";
    dump-file       "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    secroots-file   "/var/named/data/named.secroots";
    recursion yes;
    allow-query     { localhost; any; };
    allow-query-cache { localhost; any; };

    // Configure forwarders
    forwarders {
        8.8.8.8;        // Google DNS
        8.8.4.4;        // Google DNS Secondary
        1.1.1.1;        // Cloudflare DNS
        1.0.0.1;        // Cloudflare DNS Secondary
    };
    
    // Forward first, then try to resolve directly if forwarding fails
    forward first;

    dnssec-enable yes;
    dnssec-validation yes;

    managed-keys-directory "/var/named/dynamic";
    pid-file "/run/named/named.pid";
    session-keyfile "/run/named/session.key";
    include "/etc/crypto-policies/back-ends/bind.config";
};
Subtask 2.2: Configure Conditional Forwarding
For specific domains, you might want to forward to specific DNS servers:

# Add conditional forwarding zones to named.conf
sudo nano /etc/named.conf
Add these zones after the main options block:

// Conditional forwarding for internal domain
zone "internal.company.com" {
    type forward;
    forward only;
    forwarders { 192.168.1.10; 192.168.1.11; };
};

// Conditional forwarding for reverse DNS
zone "1.168.192.in-addr.arpa" {
    type forward;
    forward only;
    forwarders { 192.168.1.10; };
};
Subtask 2.3: Restart and Test Forwarding
# Check configuration syntax
sudo named-checkconf

# Restart the service
sudo systemctl restart named

# Check service status
sudo systemctl status named

# Test forwarding functionality
dig @localhost example.com
dig @localhost microsoft.com

# Check query logs to see forwarding in action
sudo tail -f /var/log/messages | grep named
Task 3: Manage Zone Files for DNS Records (A, CNAME, PTR)
Subtask 3.1: Create a Forward Zone File
We'll create a zone for a fictional domain lab.local:

# Create the zone file
sudo nano /var/named/lab.local.zone
Add the following content to create a comprehensive zone file:

$TTL 86400
@   IN  SOA     ns1.lab.local. admin.lab.local. (
        2023110801  ; Serial number (YYYYMMDDNN)
        3600        ; Refresh (1 hour)
        1800        ; Retry (30 minutes)
        604800      ; Expire (1 week)
        86400       ; Minimum TTL (1 day)
)

; Name servers
@           IN  NS      ns1.lab.local.
@           IN  NS      ns2.lab.local.

; A records (hostname to IP address)
ns1         IN  A       192.168.1.10
ns2         IN  A       192.168.1.11
web         IN  A       192.168.1.20
mail        IN  A       192.168.1.30
ftp         IN  A       192.168.1.40
db          IN  A       192.168.1.50

; CNAME records (aliases)
www         IN  CNAME   web.lab.local.
webserver   IN  CNAME   web.lab.local.
mailserver  IN  CNAME   mail.lab.local.
database    IN  CNAME   db.lab.local.

; MX record for mail
@           IN  MX  10  mail.lab.local.

; Additional A records for testing
server1     IN  A       192.168.1.100
server2     IN  A       192.168.1.101
server3     IN  A       192.168.1.102
Subtask 3.2: Create a Reverse Zone File (PTR Records)
Create a reverse zone for the 192.168.1.0/24 network:

# Create the reverse zone file
sudo nano /var/named/192.168.1.rev
Add the following content:

$TTL 86400
@   IN  SOA     ns1.lab.local. admin.lab.local. (
        2023110801  ; Serial number
        3600        ; Refresh
        1800        ; Retry
        604800      ; Expire
        86400       ; Minimum TTL
)

; Name servers
@           IN  NS      ns1.lab.local.
@           IN  NS      ns2.lab.local.

; PTR records (IP to hostname)
10          IN  PTR     ns1.lab.local.
11          IN  PTR     ns2.lab.local.
20          IN  PTR     web.lab.local.
30          IN  PTR     mail.lab.local.
40          IN  PTR     ftp.lab.local.
50          IN  PTR     db.lab.local.
100         IN  PTR     server1.lab.local.
101         IN  PTR     server2.lab.local.
102         IN  PTR     server3.lab.local.
Subtask 3.3: Configure Zone Declarations
Add the zone declarations to the main configuration file:

# Edit named.conf to add zone declarations
sudo nano /etc/named.conf
Add these zones at the end of the file:

// Forward zone for lab.local
zone "lab.local" IN {
    type master;
    file "lab.local.zone";
    allow-update { none; };
    allow-query { any; };
};

// Reverse zone for 192.168.1.0/24
zone "1.168.192.in-addr.arpa" IN {
    type master;
    file "192.168.1.rev";
    allow-update { none; };
    allow-query { any; };
};
Subtask 3.4: Set Proper File Permissions
# Set ownership and permissions for zone files
sudo chown named:named /var/named/lab.local.zone
sudo chown named:named /var/named/192.168.1.rev
sudo chmod 640 /var/named/lab.local.zone
sudo chmod 640 /var/named/192.168.1.rev

# Verify permissions
ls -la /var/named/lab.local.zone
ls -la /var/named/192.168.1.rev
Subtask 3.5: Validate Configuration and Zone Files
# Check main configuration syntax
sudo named-checkconf

# Check forward zone file syntax
sudo named-checkzone lab.local /var/named/lab.local.zone

# Check reverse zone file syntax
sudo named-checkzone 1.168.192.in-addr.arpa /var/named/192.168.1.rev

# If all checks pass, restart the service
sudo systemctl restart named

# Check service status
sudo systemctl status named
Subtask 3.6: Test DNS Records
Test all types of DNS records we configured:

# Test A records
dig @localhost web.lab.local
dig @localhost ns1.lab.local
dig @localhost server1.lab.local

# Test CNAME records
dig @localhost www.lab.local
dig @localhost webserver.lab.local
dig @localhost database.lab.local

# Test PTR records (reverse DNS)
dig @localhost -x 192.168.1.20
dig @localhost -x 192.168.1.30
dig @localhost -x 192.168.1.100

# Test NS records
dig @localhost lab.local NS

# Test MX records
dig @localhost lab.local MX

# Test SOA record
dig @localhost lab.local SOA
Subtask 3.7: Advanced Record Management
Add additional record types and test them:

# Edit the zone file to add more record types
sudo nano /var/named/lab.local.zone
Add these additional records:

; TXT records for verification and information
@           IN  TXT     "v=spf1 mx -all"
_dmarc      IN  TXT     "v=DMARC1; p=none; rua=mailto:admin@lab.local"

; SRV records for services
_http._tcp  IN  SRV     10 5 80 web.lab.local.
_https._tcp IN  SRV     10 5 443 web.lab.local.
_ftp._tcp   IN  SRV     10 5 21 ftp.lab.local.

; Additional CNAME records
intranet    IN  CNAME   web.lab.local.
portal      IN  CNAME   web.lab.local.
Update the serial number in the SOA record:

# Change the serial number to reflect the update
# From: 2023110801
# To:   2023110802
Reload the configuration:

# Reload the zone without restarting the service
sudo rndc reload

# Test the new records
dig @localhost lab.local TXT
dig @localhost _http._tcp.lab.local SRV
dig @localhost intranet.lab.local
Troubleshooting Common Issues
Issue 1: Service Won't Start
# Check configuration syntax
sudo named-checkconf

# Check system logs
sudo journalctl -u named -f

# Check if port 53 is already in use
sudo netstat -tulnp | grep :53
Issue 2: DNS Queries Not Working
# Check if BIND is listening on the correct interfaces
sudo netstat -tulnp | grep named

# Test local resolution
dig @127.0.0.1 google.com

# Check firewall settings
sudo firewall-cmd --list-services
Issue 3: Zone File Errors
# Validate zone files individually
sudo named-checkzone lab.local /var/named/lab.local.zone

# Check file permissions
ls -la /var/named/

# Verify SELinux context (if enabled)
ls -Z /var/named/
Issue 4: Forwarding Not Working
# Check if forwarders are reachable
dig @8.8.8.8 google.com

# Monitor query logs
sudo tail -f /var/log/messages | grep named

# Test with different query types
dig @localhost google.com +trace
Performance Monitoring and Optimization
Monitor DNS Performance
# Check DNS statistics
sudo rndc stats
cat /var/named/data/named_stats.txt

# Monitor query logs
sudo rndc querylog on
sudo tail -f /var/log/messages | grep named

# Check cache statistics
sudo rndc dumpdb -cache
cat /var/named/data/cache_dump.db | head -20
Optimize BIND Configuration
# Add performance tuning options to named.conf
sudo nano /etc/named.conf
Add these optimization options:

options {
    // ... existing options ...
    
    // Performance tuning
    max-cache-size 256M;
    max-cache-ttl 86400;
    max-ncache-ttl 3600;
    cleaning-interval 60;
    
    // Security enhancements
    version "DNS Server";
    hostname none;
    server-id none;
};
Security Best Practices
Implement Access Controls
# Create ACLs for better access control
sudo nano /etc/named.conf
Add ACL definitions:

// Access Control Lists
acl "trusted-clients" {
    127.0.0.1;
    192.168.1.0/24;
    10.0.0.0/8;
};

acl "internal-networks" {
    192.168.0.0/16;
    10.0.0.0/8;
    172.16.0.0/12;
};

options {
    // ... existing options ...
    
    // Restrict queries to trusted clients
    allow-query { trusted-clients; };
    allow-recursion { trusted-clients; };
    
    // Disable zone transfers by default
    allow-transfer { none; };
};
Enable Query Logging for Security Monitoring
# Configure detailed logging
sudo nano /etc/named.conf
Add comprehensive logging configuration:

logging {
    channel security_log {
        file "/var/log/named-security.log" versions 3 size 10m;
        severity info;
        print-time yes;
        print-severity yes;
        print-category yes;
    };
    
    channel query_log {
        file "/var/log/named-queries.log" versions 5 size 20m;
        severity info;
        print-time yes;
    };
    
    category security { security_log; };
    category queries { query_log; };
};
Conclusion
In this comprehensive lab, you have successfully:

Accomplished Key Objectives:

Installed and configured BIND as a robust caching DNS server
Implemented DNS forwarding to upstream servers for efficient name resolution
Created and managed comprehensive zone files with multiple DNS record types
Configured forward and reverse DNS zones for complete name resolution
Implemented security best practices and access controls
Learned troubleshooting techniques for common DNS issues
Technical Skills Developed:

DNS Server Administration: You now understand how to deploy and manage enterprise-grade DNS infrastructure using BIND
Zone File Management: You can create, modify, and maintain DNS records including A, CNAME, PTR, MX, TXT, and SRV records
Performance Optimization: You've learned how to configure caching, forwarding, and performance tuning for optimal DNS response times
Security Implementation: You understand how to implement access controls, logging, and security measures for DNS servers
Real-World Applications: This knowledge is directly applicable to:

Enterprise Network Administration: Managing internal DNS infrastructure for organizations
Cloud Infrastructure: Configuring DNS for cloud-based applications and services
DevOps Operations: Implementing DNS as part of automated infrastructure deployment
Security Operations: Monitoring and securing DNS infrastructure against attacks
Certification Relevance: The skills demonstrated in this lab directly support the Red Hat Certified Specialist in Services Management and Automation exam objectives, particularly in areas of:

Service configuration and management
Network services implementation
System security and access control
Troubleshooting and performance optimization
Next Steps: To further enhance your DNS expertise, consider:

Implementing DNS load balancing and high availability
Exploring DNSSEC for enhanced security
Integrating DNS with configuration management tools like Ansible
Setting up DNS monitoring and alerting systems
This lab provides a solid foundation for managing DNS infrastructure in production environments and prepares you for advanced networking and system administration challenges.
