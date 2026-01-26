Lab 1: Introduction to Red Hat Ceph Storage
Lab Objectives
By the end of this lab, students will be able to:

Understand Ceph's distributed storage architecture and its core principles
Identify and explain the roles of key Ceph components: MONs, OSDs, MGRs, and MDS
Comprehend the CRUSH algorithm and its role in data placement
Understand Placement Groups (PGs) and their importance in Ceph clusters
Explore RADOS (Reliable Autonomic Distributed Object Store) fundamentals
Navigate and utilize official Ceph documentation effectively
Set up a basic Ceph cluster for hands-on exploration
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with distributed systems concepts
Knowledge of storage fundamentals (block, file, and object storage)
Understanding of networking basics (IP addressing, ports)
Experience with SSH and remote system administration
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own VM or install software - everything is ready to use.

Your lab environment includes:

4 CentOS/RHEL 8 virtual machines
Pre-installed Ceph packages
Network connectivity configured
Root access to all systems
Task 1: Understanding Ceph's Architecture
Subtask 1.1: Explore Ceph's Core Philosophy
Ceph is a unified, distributed storage system designed for excellent performance, reliability, and scalability. Let's start by understanding its fundamental principles.

Connect to your lab environment:
ssh root@ceph-admin
Check the Ceph version and basic information:
ceph --version
Understand Ceph's key principles:
Self-healing: Automatically detects and repairs failures
Self-managing: Minimal administrative overhead
No single point of failure: Distributed architecture
Scalable: Can grow from a few nodes to thousands
Subtask 1.2: Examine Ceph Cluster Components
Let's explore each component that makes up a Ceph cluster:

View the cluster status:
ceph status
List all Ceph services:
ceph orch ls
Task 2: Deep Dive into Ceph Components
Subtask 2.1: Understanding MONs (Monitors)
Monitors maintain the cluster map and provide consensus for distributed decision-making.

Check monitor status:
ceph mon stat
View detailed monitor information:
ceph mon dump
Examine monitor configuration:
ceph config show mon
Key MON Functions:

Maintain cluster membership and state
Provide authentication and authorization
Store cluster maps (monitor, OSD, PG, CRUSH, MDS maps)
Require odd number for quorum (typically 3 or 5)
Subtask 2.2: Understanding OSDs (Object Storage Daemons)
OSDs store data, handle replication, recovery, and rebalancing.

List all OSDs in the cluster:
ceph osd ls
Check OSD status and utilization:
ceph osd stat
ceph osd df
View detailed OSD information:
ceph osd dump
Examine a specific OSD:
ceph osd metadata 0
Key OSD Functions:

Store actual data objects
Handle data replication to other OSDs
Perform recovery operations
Report status to monitors
Participate in peer-to-peer operations
Subtask 2.3: Understanding MGRs (Managers)
Managers provide additional monitoring and management interfaces.

Check manager status:
ceph mgr stat
List available manager modules:
ceph mgr module ls
Enable the dashboard module:
ceph mgr module enable dashboard
View manager services:
ceph mgr services
Key MGR Functions:

Provide monitoring and metrics collection
Host web-based dashboard
Expose REST APIs
Run additional management modules
Subtask 2.4: Understanding MDS (Metadata Servers)
MDS manages metadata for CephFS (Ceph File System).

Check if MDS is running:
ceph mds stat
View MDS information (if CephFS is configured):
ceph fs ls
ceph mds dump
Key MDS Functions:

Manage file system metadata
Handle directory operations
Provide POSIX semantics for CephFS
Scale dynamically based on workload
Task 3: Exploring CRUSH, PGs, and RADOS
Subtask 3.1: Understanding the CRUSH Algorithm
CRUSH (Controlled Replication Under Scalable Hashing) determines where data is stored.

View the CRUSH map:
ceph osd crush dump
Display CRUSH hierarchy:
ceph osd tree
Examine CRUSH rules:
ceph osd crush rule ls
ceph osd crush rule dump replicated_rule
Test CRUSH placement:
ceph osd map rbd test-object
CRUSH Key Concepts:

Deterministic: Same input always produces same output
Distributed: No central lookup table
Hierarchical: Understands physical topology
Configurable: Rules can be customized for different requirements
Subtask 3.2: Understanding Placement Groups (PGs)
Placement Groups are logical collections of objects that are stored together.

View PG statistics:
ceph pg stat
List all placement groups:
ceph pg ls
Examine a specific PG:
ceph pg dump | head -20
Check PG distribution:
ceph osd pool ls detail
Calculate optimal PG count:
# Formula: (OSDs * 100) / replica_size
# For 12 OSDs with 3 replicas: (12 * 100) / 3 = 400 PGs
echo "For optimal performance, consider PG count based on your OSD count"
PG Key Concepts:

Abstraction layer: Between objects and OSDs
Load balancing: Distributes objects across OSDs
Parallel operations: Enable concurrent recovery and scrubbing
Scalability: Allow cluster to grow without reshuffling all data
Subtask 3.3: Exploring RADOS (Reliable Autonomic Distributed Object Store)
RADOS is the foundation object store that powers all Ceph services.

Create a test pool:
ceph osd pool create test-pool 32 32
List pools:
ceph osd pool ls
Put an object into RADOS:
echo "Hello Ceph RADOS!" > test-file.txt
rados -p test-pool put test-object test-file.txt
List objects in the pool:
rados -p test-pool ls
Get the object back:
rados -p test-pool get test-object retrieved-file.txt
cat retrieved-file.txt
Check object location:
ceph osd map test-pool test-object
View pool statistics:
rados -p test-pool df
RADOS Key Features:

Self-healing: Automatic detection and repair of inconsistencies
Self-managing: Dynamic rebalancing and recovery
Atomic operations: Ensures data consistency
Scalable: Linear performance scaling
Task 4: Reviewing Ceph Documentation
Subtask 4.1: Navigate Official Documentation
Access local documentation (if available):
rpm -ql ceph-common | grep doc
Key documentation sections to explore:

Architecture Guide: Understanding Ceph's design principles
Installation Guide: Deployment methods and requirements
Operations Guide: Day-to-day cluster management
Developer Guide: APIs and integration methods
Important online resources:

Official Ceph Documentation: https://docs.ceph.com/
Red Hat Ceph Storage Documentation
Ceph Community Wiki and Forums
Subtask 4.2: Explore Configuration Options
View current cluster configuration:
ceph config dump
Check specific component configurations:
ceph config show osd.0
ceph config show mon
Understand configuration hierarchy:
ceph config help
Subtask 4.3: Practice Using Help Commands
General Ceph help:
ceph --help
Specific command help:
ceph osd --help
ceph pg --help
ceph mon --help
Get detailed command syntax:
ceph osd pool create --help
Task 5: Hands-On Cluster Exploration
Subtask 5.1: Monitor Cluster Health
Continuous health monitoring:
ceph -w
Press Ctrl+C to stop monitoring.

Check for any health warnings:
ceph health detail
View cluster usage:
ceph df
Subtask 5.2: Simulate Basic Operations
Create additional test data:
for i in {1..10}; do
    echo "Test data $i" > test-data-$i.txt
    rados -p test-pool put test-object-$i test-data-$i.txt
done
Verify data distribution:
rados -p test-pool ls | wc -l
Check PG distribution after adding objects:
ceph pg dump_stuck
Subtask 5.3: Clean Up Test Environment
Remove test objects:
rados -p test-pool rm test-object
for i in {1..10}; do
    rados -p test-pool rm test-object-$i
done
Remove test pool:
ceph osd pool delete test-pool test-pool --yes-i-really-really-mean-it
Clean up local files:
rm -f test-file.txt retrieved-file.txt test-data-*.txt
Troubleshooting Tips
Common Issues and Solutions
Cluster not healthy:
# Check what's wrong
ceph health detail
# Often resolved by waiting for operations to complete
OSDs down:
# Check OSD status
ceph osd stat
# Restart OSD service if needed
systemctl restart ceph-osd@<osd-id>
PGs not active+clean:
# Check PG status
ceph pg stat
# Usually resolves automatically, but check for underlying issues
Permission issues:
# Ensure proper Ceph authentication
ceph auth list
Key Concepts Summary
Architecture Components
MONs: Cluster state and consensus
OSDs: Data storage and operations
MGRs: Monitoring and management
MDS: File system metadata (CephFS only)
Data Management
CRUSH: Deterministic data placement algorithm
PGs: Logical grouping for scalability and performance
RADOS: Foundation object store with self-healing capabilities
Important Commands Reference
# Cluster status
ceph status
ceph health
ceph df

# Component information
ceph mon stat
ceph osd stat
ceph mgr stat

# Data operations
rados -p <pool> put <object> <file>
rados -p <pool> get <object> <file>
rados -p <pool> ls

# Configuration
ceph config dump
ceph config show <daemon>
Conclusion
In this introductory lab, you have successfully:

Explored Ceph's distributed architecture and understood how its components work together to provide reliable, scalable storage
Identified the roles of key components (MONs, OSDs, MGRs, MDS) and their specific functions in the cluster
Learned about CRUSH algorithm and how it enables deterministic, distributed data placement without central coordination
Understood Placement Groups (PGs) as the abstraction layer that enables scalability and parallel operations
Hands-on experience with RADOS operations, demonstrating the foundation object store capabilities
Navigated Ceph documentation and learned how to find help and configuration information
This foundational knowledge is crucial for the Red Hat Certified Specialist in Ceph Cloud Storage exam and provides the groundwork for more advanced Ceph administration tasks. Understanding these core concepts will help you design, deploy, and manage Ceph storage clusters effectively in production environments.

The self-healing and self-managing capabilities of Ceph, combined with its scalable architecture, make it an excellent choice for modern cloud storage requirements. As you continue your Ceph journey, remember that the distributed nature of Ceph means that understanding these fundamentals is essential for troubleshooting and optimizing cluster performance.
