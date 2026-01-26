Lab 15: Setting Up Redundant Satellite Servers
Objectives
By the end of this lab, students will be able to:

Understand the importance of high availability in satellite server infrastructure
Set up a secondary Satellite server for redundancy using open-source tools
Configure replication between primary and secondary servers
Implement and test failover functionality
Troubleshoot common issues in redundant satellite server configurations
Validate the effectiveness of load balancing and failover mechanisms
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with network configuration concepts
Knowledge of database replication principles
Experience with command-line interface operations
Understanding of DNS configuration
Basic knowledge of PostgreSQL database management
Completion of previous Red Hat Satellite administration labs
Required Knowledge Areas
Linux file system permissions and ownership
Network troubleshooting fundamentals
Service management using systemctl
Basic scripting concepts
Understanding of high availability concepts
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machines or configure base systems.

Provided Infrastructure
Primary Satellite Server: CentOS 8 Stream with 8GB RAM, 4 vCPUs
Secondary Satellite Server: CentOS 8 Stream with 8GB RAM, 4 vCPUs
Load Balancer Server: CentOS 8 Stream with 4GB RAM, 2 vCPUs
Client Test Machines: 2x CentOS 8 Stream with 2GB RAM, 1 vCPU each
All machines are pre-networked and have internet connectivity established.

Task 1: Set Up Secondary Satellite Server for Redundancy
Subtask 1.1: Prepare the Secondary Server Environment
First, we'll prepare the secondary server to mirror the primary satellite server configuration.

Step 1: Access the Secondary Server
# SSH into the secondary satellite server
ssh root@satellite-secondary.lab.local

# Update the system packages
dnf update -y

# Set the hostname
hostnamectl set-hostname satellite-secondary.lab.local
Step 2: Install Required Dependencies
# Install essential packages
dnf install -y wget curl vim net-tools bind-utils

# Install PostgreSQL client tools
dnf install -y postgresql postgresql-contrib

# Install rsync for file synchronization
dnf install -y rsync

# Install HAProxy for load balancing
dnf install -y haproxy
Step 3: Configure Network Settings
# Configure static IP address
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
NAME=eth0
DEVICE=eth0
ONBOOT=yes
IPADDR=192.168.1.102
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=8.8.8.8
DNS2=8.8.4.4
EOF

# Restart network service
systemctl restart NetworkManager
Subtask 1.2: Install Satellite Server Software
Step 1: Download and Install Foreman (Open Source Satellite Alternative)
# Add Foreman repository
dnf install -y https://yum.theforeman.org/releases/3.8/el8/x86_64/foreman-release.rpm

# Install Foreman and Katello
dnf install -y foreman-installer katello

# Install additional components
dnf install -y foreman-proxy tfm-rubygem-foreman_bootdisk
Step 2: Configure Firewall Rules
# Configure firewall for Satellite services
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=5647/tcp
firewall-cmd --permanent --add-port=8140/tcp
firewall-cmd --permanent --add-port=9090/tcp
firewall-cmd --permanent --add-port=5432/tcp

# Reload firewall configuration
firewall-cmd --reload
Subtask 1.3: Initial Foreman Configuration
Step 1: Run Foreman Installer
# Create installation script
cat > /root/foreman-install.sh << 'EOF'
#!/bin/bash

foreman-installer \
  --scenario katello \
  --foreman-initial-admin-username admin \
  --foreman-initial-admin-password "SecurePass123!" \
  --foreman-proxy-puppetca true \
  --foreman-proxy-tftp true \
  --enable-foreman-plugin-bootdisk \
  --enable-foreman-plugin-setup \
  --katello-candlepin-manage-db true \
  --katello-pulp-manage-db true

EOF

# Make script executable and run
chmod +x /root/foreman-install.sh
/root/foreman-install.sh
Step 2: Verify Installation
# Check service status
systemctl status foreman
systemctl status postgresql
systemctl status httpd

# Test web interface connectivity
curl -k https://localhost/users/login
Task 2: Configure Replication Between Primary and Secondary Servers
Subtask 2.1: Set Up Database Replication
Step 1: Configure Primary Server for Replication
Access the primary satellite server and configure PostgreSQL for replication:

# SSH to primary server
ssh root@satellite-primary.lab.local

# Edit PostgreSQL configuration
cat >> /var/lib/pgsql/data/postgresql.conf << EOF

# Replication settings
wal_level = replica
max_wal_senders = 3
max_replication_slots = 3
synchronous_commit = on
synchronous_standby_names = 'standby1'
EOF
Step 2: Configure Authentication for Replication
# Add replication user authentication
cat >> /var/lib/pgsql/data/pg_hba.conf << EOF

# Replication connections
host replication replicator 192.168.1.102/32 md5
host all foreman 192.168.1.102/32 md5
host all candlepin 192.168.1.102/32 md5
EOF

# Restart PostgreSQL
systemctl restart postgresql
Step 3: Create Replication User
# Connect to PostgreSQL and create replication user
sudo -u postgres psql << EOF
CREATE USER replicator REPLICATION LOGIN ENCRYPTED PASSWORD 'ReplicaPass123!';
GRANT CONNECT ON DATABASE foreman TO replicator;
GRANT CONNECT ON DATABASE candlepin TO replicator;
\q
EOF
Subtask 2.2: Configure Secondary Server as Standby
Step 1: Stop PostgreSQL on Secondary Server
# SSH to secondary server
ssh root@satellite-secondary.lab.local

# Stop PostgreSQL service
systemctl stop postgresql

# Backup existing data directory
mv /var/lib/pgsql/data /var/lib/pgsql/data.backup
Step 2: Create Base Backup from Primary
# Create base backup from primary server
sudo -u postgres pg_basebackup -h 192.168.1.101 -D /var/lib/pgsql/data -U replicator -W -v -P -R

# Set proper ownership
chown -R postgres:postgres /var/lib/pgsql/data
Step 3: Configure Standby Settings
# Create standby configuration
cat > /var/lib/pgsql/data/standby.signal << EOF
# This file indicates that this server is in standby mode
EOF

# Configure recovery settings
cat >> /var/lib/pgsql/data/postgresql.conf << EOF

# Standby server settings
hot_standby = on
primary_conninfo = 'host=192.168.1.101 port=5432 user=replicator password=ReplicaPass123! application_name=standby1'
primary_slot_name = 'standby1'
EOF
Subtask 2.3: Set Up File Synchronization
Step 1: Configure Rsync for Content Synchronization
# Create synchronization script on primary server
ssh root@satellite-primary.lab.local

cat > /root/sync-to-secondary.sh << 'EOF'
#!/bin/bash

# Synchronize Pulp content
rsync -avz --delete /var/lib/pulp/ root@192.168.1.102:/var/lib/pulp/

# Synchronize Foreman configuration
rsync -avz --delete /etc/foreman/ root@192.168.1.102:/etc/foreman/

# Synchronize SSL certificates
rsync -avz --delete /etc/pki/katello/ root@192.168.1.102:/etc/pki/katello/

# Log synchronization
echo "$(date): Synchronization completed" >> /var/log/satellite-sync.log
EOF

chmod +x /root/sync-to-secondary.sh
Step 2: Set Up SSH Key Authentication
# Generate SSH key on primary server
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""

# Copy public key to secondary server
ssh-copy-id root@192.168.1.102

# Test SSH connectivity
ssh root@192.168.1.102 "echo 'SSH connection successful'"
Step 3: Create Automated Synchronization
# Add cron job for regular synchronization
cat > /etc/cron.d/satellite-sync << EOF
# Synchronize satellite data every 15 minutes
*/15 * * * * root /root/sync-to-secondary.sh
EOF

# Run initial synchronization
/root/sync-to-secondary.sh
Task 3: Test Failover Functionality
Subtask 3.1: Set Up Load Balancer
Step 1: Configure HAProxy on Load Balancer Server
# SSH to load balancer server
ssh root@loadbalancer.lab.local

# Install HAProxy
dnf install -y haproxy

# Create HAProxy configuration
cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    log         127.0.0.1:514 local0
    chroot      /var/lib/haproxy
    stats       socket /var/lib/haproxy/stats
    user        haproxy
    group       haproxy
    daemon

defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option                  http-server-close
    option                  forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

frontend satellite_frontend
    bind *:443 ssl crt /etc/ssl/certs/satellite.pem
    bind *:80
    redirect scheme https if !{ ssl_fc }
    default_backend satellite_servers

backend satellite_servers
    balance roundrobin
    option httpchk GET /users/login
    server satellite-primary 192.168.1.101:443 check ssl verify none
    server satellite-secondary 192.168.1.102:443 check ssl verify none backup

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
EOF
Step 2: Generate SSL Certificate
# Create self-signed certificate for testing
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/satellite.key \
    -out /etc/ssl/certs/satellite.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=satellite.lab.local"

# Combine certificate and key for HAProxy
cat /etc/ssl/certs/satellite.crt /etc/ssl/private/satellite.key > /etc/ssl/certs/satellite.pem
Step 3: Start and Enable HAProxy
# Configure firewall
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=8404/tcp
firewall-cmd --reload

# Start HAProxy service
systemctl enable haproxy
systemctl start haproxy

# Verify service status
systemctl status haproxy
Subtask 3.2: Create Failover Testing Scripts
Step 1: Create Health Check Script
# Create health monitoring script
cat > /root/health-check.sh << 'EOF'
#!/bin/bash

PRIMARY_SERVER="192.168.1.101"
SECONDARY_SERVER="192.168.1.102"
LOGFILE="/var/log/satellite-health.log"

check_server() {
    local server=$1
    local name=$2
    
    if curl -k -s --connect-timeout 5 https://$server/users/login > /dev/null; then
        echo "$(date): $name server is healthy" >> $LOGFILE
        return 0
    else
        echo "$(date): $name server is DOWN" >> $LOGFILE
        return 1
    fi
}

# Check both servers
check_server $PRIMARY_SERVER "Primary"
check_server $SECONDARY_SERVER "Secondary"

# Check load balancer
if curl -k -s --connect-timeout 5 https://satellite.lab.local/users/login > /dev/null; then
    echo "$(date): Load balancer is working" >> $LOGFILE
else
    echo "$(date): Load balancer is DOWN" >> $LOGFILE
fi
EOF

chmod +x /root/health-check.sh
Step 2: Create Failover Simulation Script
# Create failover test script
cat > /root/test-failover.sh << 'EOF'
#!/bin/bash

echo "Starting failover test..."

# Function to check service availability
check_service() {
    if curl -k -s --connect-timeout 5 https://satellite.lab.local/users/login > /dev/null; then
        echo "Service is available"
        return 0
    else
        echo "Service is unavailable"
        return 1
    fi
}

# Initial health check
echo "Initial service check:"
check_service

# Simulate primary server failure
echo "Simulating primary server failure..."
ssh root@192.168.1.101 "systemctl stop httpd"

# Wait for failover
echo "Waiting 30 seconds for failover..."
sleep 30

# Check service availability after failover
echo "Service check after primary failure:"
check_service

# Restore primary server
echo "Restoring primary server..."
ssh root@192.168.1.101 "systemctl start httpd"

# Wait for recovery
echo "Waiting 30 seconds for recovery..."
sleep 30

# Final health check
echo "Final service check:"
check_service

echo "Failover test completed"
EOF

chmod +x /root/test-failover.sh
Subtask 3.3: Execute Failover Tests
Step 1: Test Database Replication
# On primary server, create test data
ssh root@satellite-primary.lab.local

sudo -u postgres psql foreman << EOF
CREATE TABLE IF NOT EXISTS failover_test (
    id SERIAL PRIMARY KEY,
    test_data VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO failover_test (test_data) VALUES ('Replication test data');
\q
EOF

# On secondary server, verify replication
ssh root@satellite-secondary.lab.local

sudo -u postgres psql foreman << EOF
SELECT * FROM failover_test;
\q
EOF
Step 2: Test Load Balancer Functionality
# Test load balancer from client machine
ssh root@client1.lab.local

# Test multiple requests to see load balancing
for i in {1..10}; do
    echo "Request $i:"
    curl -k -s -I https://satellite.lab.local/users/login | grep "Server:"
    sleep 1
done
Step 3: Execute Complete Failover Test
# Run the comprehensive failover test
/root/test-failover.sh

# Monitor the results
tail -f /var/log/satellite-health.log
Subtask 3.4: Validate Failover Results
Step 1: Check HAProxy Statistics
# Access HAProxy statistics page
curl http://loadbalancer.lab.local:8404/stats

# Or view in browser at http://loadbalancer.lab.local:8404/stats
Step 2: Verify Database Consistency
# Compare database states between servers
ssh root@satellite-primary.lab.local "sudo -u postgres psql foreman -c 'SELECT COUNT(*) FROM users;'"
ssh root@satellite-secondary.lab.local "sudo -u postgres psql foreman -c 'SELECT COUNT(*) FROM users;'"
Step 3: Test Client Connectivity During Failover
# Create continuous connectivity test
cat > /root/continuous-test.sh << 'EOF'
#!/bin/bash

COUNTER=0
SUCCESS=0
FAILED=0

while [ $COUNTER -lt 60 ]; do
    if curl -k -s --connect-timeout 3 https://satellite.lab.local/users/login > /dev/null; then
        echo "$(date): Connection successful"
        SUCCESS=$((SUCCESS + 1))
    else
        echo "$(date): Connection failed"
        FAILED=$((FAILED + 1))
    fi
    
    COUNTER=$((COUNTER + 1))
    sleep 5
done

echo "Test completed: $SUCCESS successful, $FAILED failed connections"
EOF

chmod +x /root/continuous-test.sh
Troubleshooting Common Issues
Database Replication Issues
Problem: Replication lag or failure

Solution:

# Check replication status on primary
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"

# Check replication status on secondary
sudo -u postgres psql -c "SELECT * FROM pg_stat_wal_receiver;"

# Restart replication if needed
systemctl restart postgresql
Load Balancer Issues
Problem: HAProxy not detecting server failures

Solution:

# Check HAProxy logs
journalctl -u haproxy -f

# Verify health check configuration
haproxy -c -f /etc/haproxy/haproxy.cfg

# Restart HAProxy
systemctl restart haproxy
SSL Certificate Issues
Problem: SSL certificate validation errors

Solution:

# Regenerate certificates
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/satellite.key \
    -out /etc/ssl/certs/satellite.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=satellite.lab.local"

# Update HAProxy certificate
cat /etc/ssl/certs/satellite.crt /etc/ssl/private/satellite.key > /etc/ssl/certs/satellite.pem
systemctl restart haproxy
Network Connectivity Issues
Problem: Servers cannot communicate

Solution:

# Check firewall rules
firewall-cmd --list-all

# Test network connectivity
ping 192.168.1.101
ping 192.168.1.102

# Check DNS resolution
nslookup satellite-primary.lab.local
nslookup satellite-secondary.lab.local
Performance Optimization Tips
Database Optimization
# Optimize PostgreSQL for replication
cat >> /var/lib/pgsql/data/postgresql.conf << EOF
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
EOF
Load Balancer Optimization
# Optimize HAProxy configuration
cat >> /etc/haproxy/haproxy.cfg << EOF
    option tcp-check
    tcp-check connect
    tcp-check send "GET /users/login HTTP/1.0\r\n\r\n"
    tcp-check expect string "200 OK"
EOF
Conclusion
In this comprehensive lab, you have successfully:

Set up a redundant satellite server infrastructure using open-source tools including Foreman and Katello as alternatives to Red Hat Satellite
Implemented database replication between primary and secondary servers using PostgreSQL streaming replication
Configured automated file synchronization to ensure content consistency across servers
Deployed a load balancer using HAProxy to distribute traffic and provide automatic failover
Created comprehensive testing scripts to validate failover functionality and monitor system health
Learned troubleshooting techniques for common high availability issues
Why This Matters
High availability satellite server configurations are crucial for:

Business Continuity: Ensuring patch management and system updates continue even during server failures
Reduced Downtime: Minimizing service interruptions that could affect thousands of managed systems
Scalability: Distributing load across multiple servers to handle growing infrastructure demands
Disaster Recovery: Providing rapid recovery capabilities in case of hardware or software failures
Key Takeaways
Redundancy is Essential: Having multiple satellite servers prevents single points of failure
Replication Must Be Monitored: Regular monitoring ensures data consistency between servers
Load Balancing Improves Performance: Distributing requests across servers enhances response times
Testing is Critical: Regular failover testing validates that your high availability setup works when needed
Automation Reduces Errors: Automated synchronization and monitoring reduce manual intervention and human errors
This lab provides the foundation for implementing enterprise-grade high availability satellite server infrastructure using entirely open-source technologies, making it accessible for organizations of all sizes while maintaining professional-level reliability and performance.
