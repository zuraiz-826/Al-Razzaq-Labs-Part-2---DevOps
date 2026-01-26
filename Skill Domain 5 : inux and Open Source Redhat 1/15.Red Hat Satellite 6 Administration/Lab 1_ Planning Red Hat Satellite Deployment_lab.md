Lab 1: Planning Red Hat Satellite Deployment
Lab Objectives
By the end of this lab, students will be able to:

Understand the infrastructure requirements and architecture design for deploying Red Hat Satellite
Plan appropriate hardware specifications for Satellite Server deployment
Define the roles and responsibilities of Capsule Servers and Content Hosts
Design a comprehensive architecture for a Red Hat Satellite system
Create documentation for a Satellite deployment plan
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with Red Hat Enterprise Linux (RHEL) concepts
Knowledge of network fundamentals (IP addressing, DNS, DHCP)
Understanding of virtualization concepts
Basic knowledge of system monitoring and performance metrics
Lab Environment
Al Nafi provides ready-to-use Linux-based cloud machines for this lab. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machines or install additional software.

Your lab environment includes:

RHEL 8/9 based system with administrative access
Network connectivity for planning exercises
Documentation tools and templates
Sample configuration files
Task 1: Plan Hardware Requirements for Satellite Deployment
Subtask 1.1: Analyze System Requirements
First, let's examine the minimum and recommended hardware specifications for Red Hat Satellite.

Access your lab environment and open a terminal session.

Create a working directory for your planning documents:

mkdir -p ~/satellite-planning/hardware
cd ~/satellite-planning/hardware
Create a hardware requirements document:
cat > hardware-requirements.txt << 'EOF'
RED HAT SATELLITE 6 HARDWARE REQUIREMENTS ANALYSIS
==================================================

MINIMUM REQUIREMENTS:
- CPU: 4 cores (2.0 GHz)
- RAM: 20 GB
- Storage: 300 GB (for base installation)
- Network: 1 Gbps connection

RECOMMENDED REQUIREMENTS:
- CPU: 8+ cores (2.4 GHz or higher)
- RAM: 32 GB or more
- Storage: 500 GB+ (SSD preferred)
- Network: 1 Gbps connection with redundancy

STORAGE BREAKDOWN:
- Root filesystem (/): 20 GB minimum
- /var/lib/pulp: 200+ GB (content storage)
- /var/lib/mongodb: 50+ GB (database)
- /var/log: 10+ GB (logging)
- Swap: Equal to RAM size

EOF
Calculate storage requirements based on content volume:
cat > storage-calculator.sh << 'EOF'
#!/bin/bash

echo "SATELLITE STORAGE CALCULATOR"
echo "============================"

# Base system requirements
BASE_STORAGE=50
MONGODB_BASE=20
LOGS=10

echo "Enter the number of RHEL repositories you plan to sync:"
read RHEL_REPOS

echo "Enter the number of third-party repositories:"
read THIRD_PARTY_REPOS

echo "Enter estimated number of managed hosts:"
read MANAGED_HOSTS

# Calculate storage needs
RHEL_STORAGE=$((RHEL_REPOS * 15))  # ~15GB per RHEL repo
THIRD_PARTY_STORAGE=$((THIRD_PARTY_REPOS * 5))  # ~5GB per third-party repo
HOST_OVERHEAD=$((MANAGED_HOSTS / 100))  # 1GB per 100 hosts for metadata

TOTAL_CONTENT=$((RHEL_STORAGE + THIRD_PARTY_STORAGE))
TOTAL_STORAGE=$((BASE_STORAGE + TOTAL_CONTENT + MONGODB_BASE + LOGS + HOST_OVERHEAD))

echo ""
echo "STORAGE CALCULATION RESULTS:"
echo "Base system storage: ${BASE_STORAGE} GB"
echo "RHEL repositories: ${RHEL_STORAGE} GB"
echo "Third-party repositories: ${THIRD_PARTY_STORAGE} GB"
echo "MongoDB storage: ${MONGODB_BASE} GB"
echo "Log storage: ${LOGS} GB"
echo "Host metadata overhead: ${HOST_OVERHEAD} GB"
echo "--------------------------------"
echo "TOTAL ESTIMATED STORAGE: ${TOTAL_STORAGE} GB"
echo "RECOMMENDED STORAGE: $((TOTAL_STORAGE + TOTAL_STORAGE/2)) GB (with 50% buffer)"
EOF

chmod +x storage-calculator.sh
Run the storage calculator:
./storage-calculator.sh
Subtask 1.2: Network Requirements Planning
Create a network requirements document:
cat > network-requirements.txt << 'EOF'
SATELLITE NETWORK REQUIREMENTS
==============================

BANDWIDTH REQUIREMENTS:
- Initial sync: High bandwidth (100+ Mbps recommended)
- Ongoing operations: 10-50 Mbps depending on client count
- Content delivery: Scale with number of concurrent clients

PORT REQUIREMENTS:
Inbound:
- 443/tcp: HTTPS (Satellite web UI, API, content delivery)
- 80/tcp: HTTP (redirects to HTTPS)
- 5647/tcp: Katello agent communication
- 8140/tcp: Puppet agent communication
- 9090/tcp: Cockpit web console (optional)

Outbound:
- 443/tcp: HTTPS to Red Hat CDN
- 80/tcp: HTTP for repository synchronization
- 53/tcp,udp: DNS queries

NETWORK SERVICES:
- DNS: Forward and reverse lookup capability
- NTP: Time synchronization
- DHCP: For provisioning (if using Satellite for bare-metal)

FIREWALL CONFIGURATION:
- Allow required ports through corporate firewall
- Configure SELinux policies appropriately
- Consider load balancer requirements for HA setup
EOF
Create a firewall configuration script:
cat > firewall-config.sh << 'EOF'
#!/bin/bash

echo "SATELLITE FIREWALL CONFIGURATION"
echo "================================"

# This script shows the firewall rules needed for Satellite
# DO NOT RUN in production without review

echo "Required firewall rules for Satellite Server:"
echo ""

echo "# Allow HTTPS traffic"
echo "firewall-cmd --permanent --add-port=443/tcp"
echo ""

echo "# Allow HTTP traffic (redirects to HTTPS)"
echo "firewall-cmd --permanent --add-port=80/tcp"
echo ""

echo "# Allow Katello agent communication"
echo "firewall-cmd --permanent --add-port=5647/tcp"
echo ""

echo "# Allow Puppet agent communication"
echo "firewall-cmd --permanent --add-port=8140/tcp"
echo ""

echo "# Reload firewall configuration"
echo "firewall-cmd --reload"
echo ""

echo "For Capsule Servers, additional ports may be required:"
echo "# TFTP for PXE boot"
echo "firewall-cmd --permanent --add-port=69/udp"
echo ""

echo "# DNS service"
echo "firewall-cmd --permanent --add-port=53/tcp"
echo "firewall-cmd --permanent --add-port=53/udp"
echo ""

echo "# DHCP service"
echo "firewall-cmd --permanent --add-port=67/udp"
echo "firewall-cmd --permanent --add-port=68/udp"
EOF

chmod +x firewall-config.sh
./firewall-config.sh
Task 2: Define Roles of Capsule Servers and Content Hosts
Subtask 2.1: Understanding Satellite Architecture Components
Create a comprehensive architecture document:
cd ~/satellite-planning
mkdir -p architecture
cd architecture

cat > satellite-components.txt << 'EOF'
RED HAT SATELLITE ARCHITECTURE COMPONENTS
=========================================

1. SATELLITE SERVER (Central Management)
   Role: Primary management and content distribution hub
   
   Key Functions:
   - Content management and synchronization
   - Configuration management
   - Patch management
   - Provisioning and deployment
   - Reporting and compliance
   - User authentication and authorization
   
   Components:
   - Katello: Content management
   - Foreman: Host lifecycle management
   - Candlepin: Subscription management
   - Pulp: Content repository management
   - MongoDB: Database for content metadata
   - PostgreSQL: Database for configuration data

2. CAPSULE SERVERS (Distributed Services)
   Role: Extend Satellite services to remote locations
   
   Key Functions:
   - Local content caching and delivery
   - Provisioning services (DHCP, DNS, TFTP, PXE)
   - Configuration management proxy
   - Local logging and monitoring
   
   Benefits:
   - Reduced WAN bandwidth usage
   - Improved performance for remote sites
   - Continued operations during WAN outages
   - Localized provisioning services

3. CONTENT HOSTS (Managed Systems)
   Role: Systems managed by Satellite
   
   Types:
   - Physical servers
   - Virtual machines
   - Cloud instances
   - Containers (with appropriate tooling)
   
   Management Capabilities:
   - Package management
   - Configuration management
   - Patch compliance
   - Security scanning
   - Performance monitoring
EOF
Subtask 2.2: Capsule Server Planning
Create a Capsule Server planning worksheet:
cat > capsule-planning.txt << 'EOF'
CAPSULE SERVER DEPLOYMENT PLANNING
==================================

WHEN TO DEPLOY CAPSULE SERVERS:
- Remote locations with 50+ managed hosts
- Sites with limited WAN bandwidth
- Locations requiring local provisioning
- Geographic distribution requirements
- Compliance or data sovereignty needs

CAPSULE SERVER SIZING:
Small Site (50-200 hosts):
- CPU: 4 cores
- RAM: 12 GB
- Storage: 100 GB

Medium Site (200-1000 hosts):
- CPU: 8 cores
- RAM: 16 GB
- Storage: 200 GB

Large Site (1000+ hosts):
- CPU: 12+ cores
- RAM: 24+ GB
- Storage: 300+ GB

SERVICES PROVIDED BY CAPSULE:
□ Content Delivery (Pulp)
□ Configuration Management (Puppet/Ansible)
□ DHCP Service
□ DNS Service
□ TFTP Service (for PXE boot)
□ Discovery Service
□ Remote Execution
EOF
Create a site assessment template:
cat > site-assessment.sh << 'EOF'
#!/bin/bash

echo "SATELLITE CAPSULE SITE ASSESSMENT"
echo "================================="

create_assessment() {
    local site_name=$1
    
    cat > "assessment-${site_name}.txt" << EOF
SITE ASSESSMENT: ${site_name}
============================

BASIC INFORMATION:
Site Name: ${site_name}
Location: [Enter location]
Contact Person: [Enter contact]
Assessment Date: $(date)

INFRASTRUCTURE ASSESSMENT:
Number of managed hosts: [Enter count]
Operating Systems in use: [List OS versions]
Current patch management: [Describe current process]
Network bandwidth to main site: [Enter bandwidth]
Local IT staff availability: [Yes/No and skill level]

TECHNICAL REQUIREMENTS:
□ Content synchronization needed
□ Local provisioning required
□ DHCP service needed
□ DNS service needed
□ Isolated network segments
□ Compliance requirements
□ Backup/DR considerations

RECOMMENDED CAPSULE CONFIGURATION:
Based on assessment, recommend:
- Capsule Server: [Yes/No]
- Hardware specifications: [List specs]
- Services to enable: [List services]
- Implementation timeline: [Provide timeline]

NOTES:
[Additional considerations and notes]
EOF

    echo "Assessment template created: assessment-${site_name}.txt"
}

echo "Enter site name for assessment:"
read SITE_NAME

if [ -n "$SITE_NAME" ]; then
    create_assessment "$SITE_NAME"
else
    echo "Please provide a site name"
fi
EOF

chmod +x site-assessment.sh
Subtask 2.3: Content Host Management Strategy
Create a content host categorization document:
cat > content-host-strategy.txt << 'EOF'
CONTENT HOST MANAGEMENT STRATEGY
===============================

HOST CATEGORIZATION:

1. BY FUNCTION:
   - Web Servers
   - Database Servers
   - Application Servers
   - Development Systems
   - Testing Systems
   - Production Systems

2. BY CRITICALITY:
   - Critical (24/7 uptime required)
   - Important (business hours uptime)
   - Standard (scheduled maintenance acceptable)
   - Development (flexible maintenance)

3. BY PATCH SCHEDULE:
   - Immediate (security patches within 24 hours)
   - Weekly (standard patch cycle)
   - Monthly (stable systems)
   - Quarterly (legacy systems)

LIFECYCLE ENVIRONMENTS:
Development → Testing → Staging → Production

CONTENT VIEWS:
- Base RHEL Content View
- Application-specific Content Views
- Security-only Content Views
- Custom package Content Views

HOST COLLECTIONS:
- Group hosts by function, location, or patch schedule
- Apply bulk operations efficiently
- Manage compliance reporting

ACTIVATION KEYS:
- Automate host registration
- Apply appropriate subscriptions
- Assign to correct lifecycle environment
- Configure host collections automatically
EOF
Task 3: Design Basic Architecture for Satellite System
Subtask 3.1: Create Architecture Diagrams
Create a text-based architecture diagram:
cd ~/satellite-planning/architecture

cat > architecture-diagram.txt << 'EOF'
RED HAT SATELLITE ARCHITECTURE DESIGN
=====================================

HIGH-LEVEL ARCHITECTURE:

                    [Internet/Red Hat CDN]
                            |
                    [Corporate Firewall]
                            |
                    [Satellite Server]
                     /      |      \
                    /       |       \
            [Capsule 1] [Capsule 2] [Capsule 3]
               |           |           |
         [Content Hosts] [Content Hosts] [Content Hosts]

DETAILED COMPONENT LAYOUT:

SATELLITE SERVER (Primary Site):
┌─────────────────────────────────────┐
│ Red Hat Satellite Server            │
│ ┌─────────────────────────────────┐ │
│ │ Web UI / API (Port 443)         │ │
│ ├─────────────────────────────────┤ │
│ │ Katello (Content Management)    │ │
│ ├─────────────────────────────────┤ │
│ │ Foreman (Host Management)       │ │
│ ├─────────────────────────────────┤ │
│ │ Pulp (Repository Management)    │ │
│ ├─────────────────────────────────┤ │
│ │ Candlepin (Subscription Mgmt)   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Databases:                          │
│ - PostgreSQL (Configuration)        │
│ - MongoDB (Content Metadata)        │
└─────────────────────────────────────┘

CAPSULE SERVER (Remote Sites):
┌─────────────────────────────────────┐
│ Red Hat Satellite Capsule           │
│ ┌─────────────────────────────────┐ │
│ │ Pulp Node (Content Cache)       │ │
│ ├─────────────────────────────────┤ │
│ │ Smart Proxy Services:           │ │
│ │ - DHCP                          │ │
│ │ - DNS                           │ │
│ │ - TFTP                          │ │
│ │ - Puppet/Ansible Proxy          │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘

CONTENT HOSTS:
┌─────────────────────────────────────┐
│ Managed RHEL Systems                │
│ ┌─────────────────────────────────┐ │
│ │ Katello Agent                   │ │
│ ├─────────────────────────────────┤ │
│ │ Puppet/Ansible Agent            │ │
│ ├─────────────────────────────────┤ │
│ │ Subscription Manager            │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
EOF
Subtask 3.2: Network Architecture Design
Create a network topology document:
cat > network-topology.txt << 'EOF'
SATELLITE NETWORK TOPOLOGY DESIGN
=================================

NETWORK SEGMENTS:

1. MANAGEMENT NETWORK (Primary Site):
   - Satellite Server: 10.0.1.10/24
   - Management interfaces
   - Administrative access
   - Backup network connections

2. CONTENT DELIVERY NETWORK:
   - Content synchronization traffic
   - Client update traffic
   - Repository access

3. PROVISIONING NETWORK (per site):
   - PXE boot network
   - DHCP scope management
   - TFTP services
   - Discovery services

SITE CONNECTIVITY:

Headquarters (Primary):
├── Satellite Server (10.0.1.10)
├── Internal DNS (10.0.1.5)
├── NTP Server (10.0.1.6)
└── Backup Infrastructure

Remote Site A:
├── Capsule Server (10.1.1.10)
├── Local DNS (10.1.1.5)
├── DHCP Range: 10.1.1.100-200
└── Content Hosts (10.1.1.x)

Remote Site B:
├── Capsule Server (10.2.1.10)
├── Local DNS (10.2.1.5)
├── DHCP Range: 10.2.1.100-200
└── Content Hosts (10.2.1.x)

BANDWIDTH PLANNING:
- Initial sync: Plan for high bandwidth usage
- Ongoing sync: 10-50 Mbps per site
- Client updates: Scale with concurrent clients
- Provisioning: Local network speeds sufficient

SECURITY CONSIDERATIONS:
- SSL/TLS encryption for all communications
- Certificate-based authentication
- Network segmentation
- Firewall rules and access controls
- VPN connectivity for remote sites
EOF
Subtask 3.3: Deployment Timeline and Phases
Create a deployment plan:
cat > deployment-plan.txt << 'EOF'
SATELLITE DEPLOYMENT PLAN
=========================

PHASE 1: INFRASTRUCTURE PREPARATION (Week 1-2)
□ Hardware procurement and setup
□ Network configuration and testing
□ DNS and NTP configuration
□ SSL certificate preparation
□ Firewall rule implementation
□ Backup strategy implementation

PHASE 2: SATELLITE SERVER INSTALLATION (Week 3)
□ RHEL installation and configuration
□ Satellite software installation
□ Initial configuration and testing
□ Content synchronization setup
□ User account and role configuration
□ Integration testing

PHASE 3: CONTENT MANAGEMENT SETUP (Week 4)
□ Repository synchronization
□ Content view creation
□ Lifecycle environment setup
□ Activation key configuration
□ Host collection definition
□ Compliance policy setup

PHASE 4: CAPSULE DEPLOYMENT (Week 5-6)
□ Capsule server hardware setup
□ Capsule software installation
□ Service configuration (DHCP, DNS, TFTP)
□ Content synchronization testing
□ Network connectivity verification
□ Failover testing

PHASE 5: HOST MIGRATION (Week 7-10)
□ Pilot group registration
□ Content host migration
□ Configuration management deployment
□ Patch management testing
□ Monitoring and alerting setup
□ User training and documentation

PHASE 6: PRODUCTION ROLLOUT (Week 11-12)
□ Full production deployment
□ Performance monitoring
□ Issue resolution
□ Process documentation
□ Knowledge transfer
□ Go-live support

ROLLBACK PLAN:
- Maintain existing patch management during transition
- Document rollback procedures for each phase
- Test rollback procedures in lab environment
- Maintain emergency contact procedures
EOF
Subtask 3.4: Create Implementation Checklist
Generate a comprehensive implementation checklist:
cat > implementation-checklist.sh << 'EOF'
#!/bin/bash

cat > implementation-checklist.txt << 'CHECKLIST'
SATELLITE IMPLEMENTATION CHECKLIST
==================================

PRE-INSTALLATION CHECKLIST:
□ Hardware meets minimum requirements
□ RHEL subscription available
□ Satellite subscription available
□ Network connectivity verified
□ DNS forward/reverse lookup configured
□ NTP synchronization working
□ Firewall rules implemented
□ SSL certificates obtained
□ Backup strategy defined

SATELLITE SERVER INSTALLATION:
□ RHEL 8/9 installed and updated
□ Hostname and FQDN configured
□ Satellite installer downloaded
□ Installation command prepared
□ Installation completed successfully
□ Web UI accessible
□ Initial admin user created
□ Subscription manifest uploaded

CONTENT MANAGEMENT CONFIGURATION:
□ Red Hat repositories enabled
□ Custom repositories added
□ Content synchronization completed
□ Lifecycle environments created
□ Content views published
□ Activation keys configured
□ Host collections defined

CAPSULE SERVER DEPLOYMENT:
□ Capsule server hardware ready
□ Network connectivity to Satellite
□ Capsule certificates generated
□ Capsule installation completed
□ Services configured (DHCP, DNS, TFTP)
□ Content synchronization verified
□ Smart proxy services tested

HOST REGISTRATION AND MANAGEMENT:
□ Pilot hosts registered successfully
□ Content views assigned correctly
□ Configuration management working
□ Patch management tested
□ Reporting functionality verified
□ Compliance policies applied

MONITORING AND MAINTENANCE:
□ System monitoring configured
□ Log rotation configured
□ Backup procedures tested
□ Performance baselines established
□ Alerting thresholds set
□ Documentation completed
□ Staff training completed

POST-DEPLOYMENT VERIFICATION:
□ All services running correctly
□ Content synchronization automated
□ Host management operations tested
□ Reporting and compliance verified
□ Performance within acceptable limits
□ Backup and recovery tested
□ User access and permissions verified
□ Documentation updated and accessible
CHECKLIST

echo "Implementation checklist created: implementation-checklist.txt"
echo "Use this checklist to track your Satellite deployment progress."
CHECKLIST

chmod +x implementation-checklist.sh
./implementation-checklist.sh
Troubleshooting Common Planning Issues
Common Planning Mistakes to Avoid
Insufficient Storage Planning

Always plan for 2-3x growth in content storage
Consider snapshot and backup storage requirements
Plan for log file growth over time
Network Bandwidth Underestimation

Initial synchronization requires significant bandwidth
Plan for peak usage during patch cycles
Consider impact on other network services
Inadequate Hardware Specifications

Don't use minimum requirements for production
Plan for growth in managed host count
Consider high availability requirements
Validation Commands
Use these commands to validate your planning:

# Check available disk space
df -h

# Check memory availability
free -h

# Check CPU information
lscpu

# Test network connectivity
ping -c 4 cdn.redhat.com

# Check DNS resolution
nslookup satellite.example.com

# Verify NTP synchronization
chrony sources -v
Conclusion
In this lab, you have successfully completed the planning phase for a Red Hat Satellite deployment. You have:

Analyzed hardware requirements and created tools to calculate appropriate specifications based on your environment size and needs

Defined the roles and responsibilities of Satellite Servers, Capsule Servers, and Content Hosts, understanding how they work together in a distributed architecture

Designed a comprehensive architecture including network topology, component relationships, and deployment phases

Created planning documentation that will serve as a foundation for your actual Satellite implementation

This planning phase is crucial for a successful Satellite deployment. The documents and tools you've created will help ensure that your implementation meets your organization's requirements for performance, scalability, and reliability.

Key Takeaways:

Proper planning prevents performance issues and costly redesigns
Understanding component roles helps optimize your architecture
Documentation created during planning serves as a reference throughout the deployment lifecycle
Scalability considerations should be built into the initial design
Next Steps: With your planning complete, you're ready to proceed to the actual installation and configuration of Red Hat Satellite in subsequent labs. The foundation you've built here will guide you through the implementation process and help ensure a successful deployment.
