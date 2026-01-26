Lab 8: Deploying Capsule Servers
Objectives
By the end of this lab, you will be able to:

Understand the purpose and architecture of Red Hat Satellite Capsule Servers
Install and configure a Capsule Server using satellite-installer
Establish secure communication between Capsule and main Satellite server
Configure Capsule Server services including DNS, DHCP, and TFTP
Test Capsule Server functionality and verify proper operation
Troubleshoot common Capsule Server deployment issues
Prerequisites
Before starting this lab, you should have:

Basic understanding of Red Hat Satellite 6 architecture
Knowledge of Linux system administration
Familiarity with command-line interface
Understanding of network services (DNS, DHCP, TFTP)
Experience with SSL certificates and security concepts
A working Red Hat Satellite 6 server (covered in previous labs)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure basic networking.

Your lab environment includes:

satellite.example.com: Main Satellite server (already configured)
capsule.example.com: Target machine for Capsule installation
client.example.com: Test client for verification
Task 1: Install a Capsule Server using satellite-installer
Subtask 1.1: Prepare the Capsule Server System
First, we need to prepare the target system for Capsule installation.

Connect to the Capsule server:
ssh root@capsule.example.com
Update the system:
dnf update -y
Set the hostname properly:
hostnamectl set-hostname capsule.example.com
Verify hostname resolution:
hostname -f
nslookup capsule.example.com
Configure firewall rules:
# Open required ports for Capsule services
firewall-cmd --permanent --add-port=53/udp
firewall-cmd --permanent --add-port=53/tcp
firewall-cmd --permanent --add-port=67/udp
firewall-cmd --permanent --add-port=69/udp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=5647/tcp
firewall-cmd --permanent --add-port=8000/tcp
firewall-cmd --permanent --add-port=8140/tcp
firewall-cmd --permanent --add-port=9090/tcp
firewall-cmd --reload
Subtask 1.2: Register Capsule Server with Satellite
Download the consumer RPM from Satellite server:
curl -k https://satellite.example.com/pub/katello-ca-consumer-latest.noarch.rpm -o katello-ca-consumer-latest.noarch.rpm
Install the consumer RPM:
dnf install -y katello-ca-consumer-latest.noarch.rpm
Register the Capsule server:
subscription-manager register --org="Default_Organization" --activationkey="capsule-key"
Enable required repositories:
subscription-manager repos --enable=rhel-8-for-x86_64-baseos-rpms
subscription-manager repos --enable=rhel-8-for-x86_64-appstream-rpms
subscription-manager repos --enable=satellite-capsule-6.12-for-rhel-8-x86_64-rpms
subscription-manager repos --enable=satellite-maintenance-6.12-for-rhel-8-x86_64-rpms
Subtask 1.3: Install Capsule Server Packages
Install satellite-capsule package:
dnf install -y satellite-capsule
Verify installation:
rpm -qa | grep satellite-capsule
Task 2: Configure Capsule to Connect to the Main Satellite Server
Subtask 2.1: Generate Certificates on Satellite Server
Switch to the main Satellite server to generate certificates for the Capsule.

Connect to Satellite server:
ssh root@satellite.example.com
Generate Capsule certificates:
capsule-certs-generate --foreman-proxy-fqdn capsule.example.com \
  --certs-tar /root/capsule.example.com-certs.tar
Copy the certificate bundle to Capsule server:
scp /root/capsule.example.com-certs.tar root@capsule.example.com:/root/
Subtask 2.2: Configure Capsule Server Installation
Return to the Capsule server to complete the installation.

Switch back to Capsule server:
ssh root@capsule.example.com
Extract and verify certificates:
cd /root
tar -tf capsule.example.com-certs.tar
Run satellite-installer for Capsule configuration:
satellite-installer --scenario capsule \
  --certs-tar-file /root/capsule.example.com-certs.tar \
  --foreman-proxy-register-in-foreman true \
  --foreman-proxy-foreman-base-url https://satellite.example.com \
  --foreman-proxy-trusted-hosts satellite.example.com \
  --foreman-proxy-trusted-hosts capsule.example.com \
  --foreman-proxy-oauth-consumer-key $(grep oauth_consumer_key /etc/foreman-proxy/settings.yml | cut -d' ' -f2) \
  --foreman-proxy-oauth-consumer-secret $(grep oauth_consumer_secret /etc/foreman-proxy/settings.yml | cut -d' ' -f2) \
  --foreman-proxy-content-parent-fqdn satellite.example.com \
  --puppet-server-foreman-url https://satellite.example.com
Subtask 2.3: Configure Additional Capsule Services
Enable DNS service on Capsule:
satellite-installer --scenario capsule \
  --foreman-proxy-dns true \
  --foreman-proxy-dns-interface eth0 \
  --foreman-proxy-dns-zone example.com \
  --foreman-proxy-dns-forwarders 8.8.8.8 \
  --foreman-proxy-dns-reverse 168.192.in-addr.arpa
Enable DHCP service on Capsule:
satellite-installer --scenario capsule \
  --foreman-proxy-dhcp true \
  --foreman-proxy-dhcp-interface eth0 \
  --foreman-proxy-dhcp-range "192.168.1.100 192.168.1.200" \
  --foreman-proxy-dhcp-gateway 192.168.1.1 \
  --foreman-proxy-dhcp-nameservers 192.168.1.10
Enable TFTP service for PXE boot:
satellite-installer --scenario capsule \
  --foreman-proxy-tftp true \
  --foreman-proxy-tftp-servername capsule.example.com
Subtask 2.4: Verify Capsule Services
Check service status:
systemctl status foreman-proxy
systemctl status httpd
systemctl status named
systemctl status dhcpd
systemctl status xinetd
Verify Capsule proxy features:
curl -k https://capsule.example.com:9090/features
Check log files for errors:
tail -f /var/log/foreman-proxy/proxy.log
Task 3: Test the Capsule Server Functionality
Subtask 3.1: Verify Capsule Registration in Satellite
Connect to Satellite server web interface:

Open browser and navigate to https://satellite.example.com
Login with admin credentials
Check Capsule registration:

Navigate to Infrastructure → Capsules
Verify that capsule.example.com appears in the list
Check the status shows as "Active"
Verify Capsule features via CLI:

hammer capsule list
hammer capsule info --name capsule.example.com
Subtask 3.2: Test Content Synchronization
Create a lifecycle environment for Capsule testing:
hammer lifecycle-environment create \
  --name "Capsule-Test" \
  --prior "Library" \
  --organization "Default Organization"
Enable Capsule for content synchronization:
hammer capsule content add-lifecycle-environment \
  --name capsule.example.com \
  --lifecycle-environment "Capsule-Test"
Synchronize content to Capsule:
hammer capsule content synchronize \
  --name capsule.example.com
Monitor synchronization progress:
hammer task list --search "label = Actions::Katello::ContentView::CapsuleSync"
Subtask 3.3: Test Client Registration through Capsule
Connect to test client machine:
ssh root@client.example.com
Download consumer RPM from Capsule:
curl -k https://capsule.example.com/pub/katello-ca-consumer-latest.noarch.rpm -o katello-ca-consumer-latest.noarch.rpm
Install and register through Capsule:
dnf install -y katello-ca-consumer-latest.noarch.rpm
subscription-manager register --org="Default_Organization" \
  --activationkey="test-key" \
  --serverurl=https://capsule.example.com:8443/rhsm \
  --baseurl=https://capsule.example.com/pulp/repos
Verify client registration:
subscription-manager status
subscription-manager list --installed
Subtask 3.4: Test Network Services
Test DNS resolution through Capsule:
# From client machine
nslookup satellite.example.com capsule.example.com
dig @capsule.example.com satellite.example.com
Test DHCP functionality:
# Release and renew IP address
dhclient -r eth0
dhclient eth0
Verify TFTP service:
# Test TFTP connectivity
tftp capsule.example.com
tftp> get pxelinux.0
tftp> quit
Subtask 3.5: Performance and Load Testing
Monitor Capsule performance:
# Check system resources
top
free -h
df -h
Test concurrent client connections:
# Create script to simulate multiple client registrations
cat > /tmp/test_capsule_load.sh << 'EOF'
#!/bin/bash
for i in {1..10}; do
  (
    curl -k https://capsule.example.com:9090/features
    echo "Test $i completed"
  ) &
done
wait
EOF

chmod +x /tmp/test_capsule_load.sh
/tmp/test_capsule_load.sh
Check Capsule logs during load test:
tail -f /var/log/foreman-proxy/proxy.log
Troubleshooting Common Issues
Certificate Issues
If you encounter certificate problems:

# Regenerate certificates on Satellite server
capsule-certs-generate --foreman-proxy-fqdn capsule.example.com \
  --certs-tar /root/capsule.example.com-certs-new.tar --certs-update-all

# Copy new certificates to Capsule
scp /root/capsule.example.com-certs-new.tar root@capsule.example.com:/root/

# Update Capsule with new certificates
satellite-installer --scenario capsule \
  --certs-tar-file /root/capsule.example.com-certs-new.tar \
  --certs-update-all
Service Startup Issues
If services fail to start:

# Check service logs
journalctl -u foreman-proxy -f
journalctl -u httpd -f

# Restart services in correct order
systemctl restart foreman-proxy
systemctl restart httpd
Network Connectivity Problems
If clients cannot connect to Capsule:

# Verify firewall rules
firewall-cmd --list-all

# Test port connectivity
telnet capsule.example.com 443
telnet capsule.example.com 9090
Verification Checklist
Before completing the lab, verify the following:

 Capsule server is properly registered with Satellite
 All required services are running and enabled
 Certificates are valid and properly configured
 Content synchronization is working
 Client registration through Capsule is successful
 DNS, DHCP, and TFTP services are functional
 Firewall rules allow required traffic
 Log files show no critical errors
Conclusion
In this lab, you have successfully deployed and configured a Red Hat Satellite Capsule Server. You learned how to:

Install Capsule Server software using satellite-installer
Generate and configure SSL certificates for secure communication
Configure essential network services (DNS, DHCP, TFTP) on the Capsule
Establish content synchronization between Satellite and Capsule servers
Test client registration and content delivery through the Capsule
Troubleshoot common deployment issues
Why This Matters: Capsule Servers are crucial for organizations with distributed infrastructure. They provide local content delivery, reduce bandwidth usage, and improve performance for remote locations. By extending Satellite's capabilities to branch offices or data centers, Capsule Servers enable centralized management while maintaining local service delivery.

The skills you've developed in this lab are essential for Red Hat Satellite 6 Administration certification and real-world enterprise deployments. Capsule Servers form the backbone of scalable Red Hat infrastructure management, allowing organizations to maintain consistent configuration and security policies across geographically distributed environments.
