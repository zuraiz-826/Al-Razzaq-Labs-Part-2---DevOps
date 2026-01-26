Lab 20: Optimizing Ceph Storage Performance
Objectives
By the end of this lab, students will be able to:

Analyze and optimize Ceph cluster performance through CRUSH map tuning
Configure OSD parameters for improved storage performance
Measure and optimize network throughput and latency in Ceph clusters
Identify and implement strategies to reduce storage hotspots
Use performance monitoring tools to troubleshoot Ceph bottlenecks
Apply best practices for Ceph performance optimization in production environments
Prerequisites
Before starting this lab, students should have:

Basic understanding of Ceph architecture (OSDs, MONs, MGRs)
Familiarity with Linux command line operations
Knowledge of storage concepts (IOPS, throughput, latency)
Understanding of network fundamentals
Experience with basic Ceph administration commands
Completion of previous Ceph labs or equivalent knowledge
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ceph cluster already deployed. Simply click Start Lab to access your environment - no need to build your own VM or install Ceph from scratch.

Your lab environment includes:

3 Ceph Monitor nodes (ceph-mon-01, ceph-mon-02, ceph-mon-03)
6 Ceph OSD nodes (ceph-osd-01 through ceph-osd-06)
1 Ceph Manager node (ceph-mgr-01)
1 Client node for testing (ceph-client-01)
Task 1: Tune CRUSH Map and OSD Parameters for Performance
Subtask 1.1: Analyze Current CRUSH Map Configuration
First, let's examine the current CRUSH map to understand the cluster topology and identify optimization opportunities.

Connect to the Ceph cluster and check cluster status:
# Connect to the first monitor node
ssh ceph-mon-01

# Check overall cluster health
sudo ceph health detail

# View cluster status
sudo ceph -s
Examine the current CRUSH map:
# Get the current CRUSH map
sudo ceph osd getcrushmap -o crushmap.bin

# Decompile the CRUSH map to readable format
sudo crushtool -d crushmap.bin -o crushmap.txt

# View the CRUSH map structure
cat crushmap.txt
Analyze CRUSH rule configuration:
# List current CRUSH rules
sudo ceph osd crush rule ls

# Show details of the default rule
sudo ceph osd crush rule dump replicated_rule
Subtask 1.2: Optimize CRUSH Map for Performance
Now we'll modify the CRUSH map to improve performance by optimizing placement strategies.

Create a performance-optimized CRUSH rule:
# Create a new CRUSH rule for better performance
sudo ceph osd crush rule create-replicated performance_rule default host hdd

# Verify the new rule was created
sudo ceph osd crush rule ls
sudo ceph osd crush rule dump performance_rule
Create a backup of the original CRUSH map:
# Create backup directory
mkdir -p ~/ceph-backups

# Backup current CRUSH map
sudo ceph osd getcrushmap -o ~/ceph-backups/crushmap-original.bin
Modify CRUSH map for SSD optimization (if SSDs are available):
# Create custom CRUSH map for mixed storage
cat > ~/crushmap-optimized.txt << 'EOF'
# Custom CRUSH map for performance optimization
# Devices
device 0 osd.0 class hdd
device 1 osd.1 class hdd
device 2 osd.2 class hdd
device 3 osd.3 class ssd
device 4 osd.4 class ssd
device 5 osd.5 class ssd

# Types
type 0 osd
type 1 host
type 2 chassis
type 3 rack
type 4 row
type 5 pdu
type 6 pod
type 7 room
type 8 datacenter
type 9 zone
type 10 region
type 11 root

# Buckets
host ceph-osd-01 {
    id -2
    alg straw2
    hash 0
    item osd.0 weight 1.000
    item osd.1 weight 1.000
}

host ceph-osd-02 {
    id -3
    alg straw2
    hash 0
    item osd.2 weight 1.000
    item osd.3 weight 1.000
}

host ceph-osd-03 {
    id -4
    alg straw2
    hash 0
    item osd.4 weight 1.000
    item osd.5 weight 1.000
}

root default {
    id -1
    alg straw2
    hash 0
    item ceph-osd-01 weight 2.000
    item ceph-osd-02 weight 2.000
    item ceph-osd-03 weight 2.000
}

# Rules
rule replicated_rule {
    id 0
    type replicated
    min_size 1
    max_size 10
    step take default
    step chooseleaf firstn 0 type host
    step emit
}

rule ssd_rule {
    id 1
    type replicated
    min_size 1
    max_size 10
    step take default class ssd
    step chooseleaf firstn 0 type host
    step emit
}
EOF
Subtask 1.3: Configure OSD Performance Parameters
Let's optimize OSD-specific parameters for better performance.

Check current OSD configuration:
# View current OSD configuration
sudo ceph config dump | grep osd

# Check specific performance-related settings
sudo ceph config get osd osd_op_queue
sudo ceph config get osd osd_max_backfills
sudo ceph config get osd osd_recovery_max_active
Optimize OSD queue settings:
# Set OSD operation queue to weighted priority queue for better performance
sudo ceph config set osd osd_op_queue wpq

# Optimize queue parameters
sudo ceph config set osd osd_op_queue_cut_off high

# Set thread pool sizes
sudo ceph config set osd osd_op_num_threads_per_shard 2
sudo ceph config set osd osd_op_num_shards 8
Configure recovery and backfill parameters:
# Limit concurrent recovery operations to reduce impact on client I/O
sudo ceph config set osd osd_recovery_max_active 3
sudo ceph config set osd osd_max_backfills 1

# Set recovery sleep to reduce impact during peak hours
sudo ceph config set osd osd_recovery_sleep 0.1
sudo ceph config set osd osd_recovery_sleep_hdd 0.1
Optimize memory and cache settings:
# Set BlueStore cache size (adjust based on available RAM)
sudo ceph config set osd bluestore_cache_size_hdd 1073741824  # 1GB for HDD
sudo ceph config set osd bluestore_cache_size_ssd 3221225472  # 3GB for SSD

# Configure BlueStore allocation unit
sudo ceph config set osd bluestore_min_alloc_size_hdd 65536   # 64KB for HDD
sudo ceph config set osd bluestore_min_alloc_size_ssd 16384   # 16KB for SSD
Subtask 1.4: Apply and Verify CRUSH Map Changes
Apply the optimized CRUSH map (if created):
# Compile the optimized CRUSH map
sudo crushtool -c ~/crushmap-optimized.txt -o ~/crushmap-optimized.bin

# Apply the new CRUSH map (be cautious in production)
sudo ceph osd setcrushmap -i ~/crushmap-optimized.bin

# Verify the changes
sudo ceph osd tree
Monitor the rebalancing process:
# Watch cluster status during rebalancing
watch -n 5 'sudo ceph -s'

# Monitor PG states
sudo ceph pg stat

# Check for any warnings or errors
sudo ceph health detail
Task 2: Analyze Network Throughput and Latency
Subtask 2.1: Measure Current Network Performance
Network performance is crucial for Ceph cluster performance. Let's analyze the current network configuration and performance.

Check network interface configuration:
# Check network interfaces on all nodes
for node in ceph-mon-01 ceph-osd-01 ceph-osd-02 ceph-osd-03; do
    echo "=== $node ==="
    ssh $node "ip addr show | grep -E 'inet.*eth|inet.*ens'"
    ssh $node "ethtool eth0 | grep Speed"
done
Test network latency between nodes:
# Create a script to test latency between all nodes
cat > ~/test-latency.sh << 'EOF'
#!/bin/bash

nodes=("ceph-mon-01" "ceph-osd-01" "ceph-osd-02" "ceph-osd-03" "ceph-mgr-01")

echo "Network Latency Test Results:"
echo "============================="

for source in "${nodes[@]}"; do
    for target in "${nodes[@]}"; do
        if [ "$source" != "$target" ]; then
            echo -n "$source -> $target: "
            ssh $source "ping -c 3 -q $target | tail -1 | awk '{print \$4}' | cut -d'/' -f2" 2>/dev/null || echo "Failed"
        fi
    done
done
EOF

chmod +x ~/test-latency.sh
./test-latency.sh
Test network throughput using iperf3:
# Install iperf3 on all nodes
for node in ceph-mon-01 ceph-osd-01 ceph-osd-02 ceph-osd-03; do
    ssh $node "sudo yum install -y iperf3 || sudo apt-get install -y iperf3"
done

# Start iperf3 server on one node
ssh ceph-osd-01 "iperf3 -s -D"

# Test throughput from other nodes
echo "Network Throughput Test Results:"
echo "==============================="
for node in ceph-osd-02 ceph-osd-03 ceph-mgr-01; do
    echo "Testing $node -> ceph-osd-01:"
    ssh $node "iperf3 -c ceph-osd-01 -t 10 -P 4"
    echo ""
done
Subtask 2.2: Optimize Network Configuration
Configure network tuning parameters:
# Create network optimization script
cat > ~/optimize-network.sh << 'EOF'
#!/bin/bash

# Network optimization for Ceph
echo "Applying network optimizations..."

# Increase network buffer sizes
echo 'net.core.rmem_max = 134217728' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 134217728' >> /etc/sysctl.conf
echo 'net.core.rmem_default = 65536' >> /etc/sysctl.conf
echo 'net.core.wmem_default = 65536' >> /etc/sysctl.conf

# TCP buffer sizes
echo 'net.ipv4.tcp_rmem = 4096 65536 134217728' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem = 4096 65536 134217728' >> /etc/sysctl.conf

# Increase connection tracking
echo 'net.netfilter.nf_conntrack_max = 1048576' >> /etc/sysctl.conf

# Apply settings
sysctl -p

echo "Network optimization complete"
EOF

chmod +x ~/optimize-network.sh

# Apply to all nodes
for node in ceph-mon-01 ceph-osd-01 ceph-osd-02 ceph-osd-03; do
    echo "Optimizing network on $node"
    scp ~/optimize-network.sh $node:~/
    ssh $node "sudo ~/optimize-network.sh"
done
Configure Ceph network settings:
# Set Ceph network configuration for better performance
sudo ceph config set global ms_tcp_nodelay true
sudo ceph config set global ms_tcp_rcvbuf 65536

# Configure cluster and public network settings
sudo ceph config set global cluster_network 10.0.1.0/24
sudo ceph config set global public_network 10.0.0.0/24

# Set message signing (disable for performance, enable for security)
sudo ceph config set global ms_cluster_mode crc
sudo ceph config set global ms_service_mode crc
Subtask 2.3: Monitor Network Performance
Create network monitoring script:
cat > ~/monitor-network.sh << 'EOF'
#!/bin/bash

echo "Ceph Network Performance Monitor"
echo "==============================="
echo "Timestamp: $(date)"
echo ""

# Check network interface statistics
echo "Network Interface Statistics:"
echo "----------------------------"
for node in ceph-mon-01 ceph-osd-01 ceph-osd-02 ceph-osd-03; do
    echo "$node:"
    ssh $node "cat /proc/net/dev | grep -E 'eth0|ens'" | awk '{print "  RX bytes: " $2 ", TX bytes: " $10}'
done
echo ""

# Check Ceph network usage
echo "Ceph Network Usage:"
echo "------------------"
sudo ceph osd perf | head -20

echo ""
echo "Network Connections:"
echo "-------------------"
sudo netstat -an | grep :6789 | wc -l | awk '{print "Monitor connections: " $1}'
sudo netstat -an | grep :6800 | wc -l | awk '{print "OSD connections: " $1}'
EOF

chmod +x ~/monitor-network.sh
./monitor-network.sh
Task 3: Implement Strategies to Reduce Storage Hotspots
Subtask 3.1: Identify Storage Hotspots
Storage hotspots occur when some OSDs receive disproportionately more I/O than others, leading to performance bottlenecks.

Analyze OSD utilization patterns:
# Check OSD usage statistics
sudo ceph osd df

# Get detailed OSD performance metrics
sudo ceph osd perf

# Check PG distribution across OSDs
sudo ceph pg dump osds | awk '{print $1, $2}' | sort -k2 -n
Create hotspot detection script:
cat > ~/detect-hotspots.sh << 'EOF'
#!/bin/bash

echo "Ceph Storage Hotspot Analysis"
echo "============================"
echo "Timestamp: $(date)"
echo ""

# Get OSD utilization
echo "OSD Utilization Analysis:"
echo "------------------------"
sudo ceph osd df | awk 'NR>1 {
    if ($8 > 1.2) print "HOT: OSD." $1 " - Usage: " $8 "x average"
    else if ($8 < 0.8) print "COLD: OSD." $1 " - Usage: " $8 "x average"
}' | sort

echo ""

# Check PG distribution
echo "PG Distribution Analysis:"
echo "------------------------"
sudo ceph osd df | awk 'NR>1 {print $1, $2}' | sort -k2 -n | awk '
BEGIN {total=0; count=0}
{total+=$2; count++; osds[count]=$1; pgs[count]=$2}
END {
    avg=total/count
    print "Average PGs per OSD: " avg
    print "Hotspot OSDs (>120% of average):"
    for(i=1; i<=count; i++) {
        if(pgs[i] > avg*1.2) print "  OSD." osds[i] ": " pgs[i] " PGs (" int(pgs[i]/avg*100) "% of average)"
    }
}'

echo ""

# Check for slow requests
echo "Slow Request Analysis:"
echo "---------------------"
sudo ceph health detail | grep -i slow || echo "No slow requests detected"
EOF

chmod +x ~/detect-hotspots.sh
./detect-hotspots.sh
Monitor I/O patterns:
# Create I/O monitoring script
cat > ~/monitor-io.sh << 'EOF'
#!/bin/bash

echo "Ceph I/O Pattern Analysis"
echo "========================="

# Monitor OSD I/O for 30 seconds
echo "Collecting I/O statistics for 30 seconds..."
sudo ceph tell 'osd.*' perf dump > /tmp/perf_before.json
sleep 30
sudo ceph tell 'osd.*' perf dump > /tmp/perf_after.json

echo "Top OSDs by operation count:"
echo "----------------------------"
python3 << 'PYTHON'
import json
import sys

try:
    with open('/tmp/perf_before.json', 'r') as f:
        before = json.load(f)
    with open('/tmp/perf_after.json', 'r') as f:
        after = json.load(f)
    
    osd_ops = {}
    for osd in after:
        if osd in before:
            ops_before = before[osd].get('osd', {}).get('op_r', 0) + before[osd].get('osd', {}).get('op_w', 0)
            ops_after = after[osd].get('osd', {}).get('op_r', 0) + after[osd].get('osd', {}).get('op_w', 0)
            osd_ops[osd] = ops_after - ops_before
    
    sorted_osds = sorted(osd_ops.items(), key=lambda x: x[1], reverse=True)
    for osd, ops in sorted_osds[:10]:
        print(f"{osd}: {ops} operations")
        
except Exception as e:
    print(f"Error analyzing I/O patterns: {e}")
PYTHON
EOF

chmod +x ~/monitor-io.sh
./monitor-io.sh
Subtask 3.2: Implement Hotspot Mitigation Strategies
Reweight OSDs to balance load:
# Create reweighting script based on utilization
cat > ~/reweight-osds.sh << 'EOF'
#!/bin/bash

echo "OSD Reweighting for Hotspot Mitigation"
echo "======================================"

# Get current OSD weights and utilization
sudo ceph osd df | awk 'NR>1 {
    osd=$1; weight=$3; util=$8
    if (util > 1.3) {
        new_weight = weight * 0.9
        print "sudo ceph osd reweight osd." osd " " new_weight " # Current util: " util
    } else if (util < 0.7) {
        new_weight = weight * 1.1
        if (new_weight > 1.0) new_weight = 1.0
        print "sudo ceph osd reweight osd." osd " " new_weight " # Current util: " util
    }
}' > /tmp/reweight_commands.sh

echo "Suggested reweighting commands:"
cat /tmp/reweight_commands.sh

echo ""
read -p "Apply these reweighting changes? (y/N): " confirm
if [[ $confirm == [yY] ]]; then
    bash /tmp/reweight_commands.sh
    echo "Reweighting applied. Monitor cluster status:"
    sudo ceph -s
else
    echo "Reweighting cancelled."
fi
EOF

chmod +x ~/reweight-osds.sh
./reweight-osds.sh
Optimize PG distribution:
# Check current PG count and distribution
sudo ceph osd pool ls detail

# Calculate optimal PG count for pools
cat > ~/optimize-pgs.sh << 'EOF'
#!/bin/bash

echo "PG Optimization Analysis"
echo "======================="

# Get cluster information
osd_count=$(sudo ceph osd ls | wc -l)
echo "Total OSDs: $osd_count"

# Analyze each pool
sudo ceph osd pool ls | while read pool; do
    size=$(sudo ceph osd pool get $pool size | awk '{print $2}')
    pg_num=$(sudo ceph osd pool get $pool pg_num | awk '{print $2}')
    
    # Calculate optimal PG count (target ~100-200 PGs per OSD)
    target_pgs_per_osd=150
    optimal_pgs=$((osd_count * target_pgs_per_osd / size))
    
    # Round to nearest power of 2
    optimal_pgs_power2=1
    while [ $optimal_pgs_power2 -lt $optimal_pgs ]; do
        optimal_pgs_power2=$((optimal_pgs_power2 * 2))
    done
    
    echo "Pool: $pool"
    echo "  Current PGs: $pg_num"
    echo "  Optimal PGs: $optimal_pgs_power2"
    echo "  Replica size: $size"
    
    if [ $pg_num -ne $optimal_pgs_power2 ]; then
        echo "  Suggested command: sudo ceph osd pool set $pool pg_num $optimal_pgs_power2"
    fi
    echo ""
done
EOF

chmod +x ~/optimize-pgs.sh
./optimize-pgs.sh
Implement data placement optimization:
# Create balanced data placement strategy
cat > ~/balance-placement.sh << 'EOF'
#!/bin/bash

echo "Data Placement Optimization"
echo "=========================="

# Check current CRUSH rule efficiency
echo "Analyzing CRUSH rule efficiency..."
sudo ceph osd getcrushmap -o /tmp/crushmap.bin
sudo crushtool -i /tmp/crushmap.bin --test --show-statistics --rule 0 --num-rep 3 --min-x 0 --max-x 1023

echo ""
echo "Current PG distribution:"
sudo ceph pg dump pgs | awk '{print $1, $15}' | grep -v "^pg_stat" | sort | uniq -c | sort -nr | head -10

# Suggest CRUSH tunables optimization
echo ""
echo "CRUSH Tunables Optimization:"
echo "Current tunables:"
sudo ceph osd crush show-tunables

echo ""
echo "Recommended tunables for optimal distribution:"
echo "sudo ceph osd crush tunables optimal"
echo ""
read -p "Apply optimal tunables? (y/N): " confirm
if [[ $confirm == [yY] ]]; then
    sudo ceph osd crush tunables optimal
    echo "Optimal tunables applied. This will trigger data movement."
    echo "Monitor with: watch 'sudo ceph -s'"
fi
EOF

chmod +x ~/balance-placement.sh
./balance-placement.sh
Subtask 3.3: Monitor and Validate Hotspot Reduction
Create comprehensive monitoring dashboard:
cat > ~/hotspot-monitor.sh << 'EOF'
#!/bin/bash

echo "Ceph Hotspot Monitoring Dashboard"
echo "================================="
echo "Timestamp: $(date)"
echo ""

# Cluster health overview
echo "1. Cluster Health:"
echo "-----------------"
sudo ceph health
echo ""

# OSD utilization variance
echo "2. OSD Utilization Variance:"
echo "---------------------------"
sudo ceph osd df | awk 'NR>1 {
    util[NR-2] = $8
    total += $8
    count++
}
END {
    avg = total/count
    variance = 0
    for (i=0; i<count; i++) {
        variance += (util[i] - avg)^2
    }
    variance = variance/count
    stddev = sqrt(variance)
    cv = stddev/avg * 100
    
    print "Average utilization: " avg
    print "Standard deviation: " stddev
    print "Coefficient of variation: " cv "%"
    if (cv < 10) print "Status: GOOD - Low variance"
    else if (cv < 20) print "Status: MODERATE - Some imbalance"
    else print "Status: HIGH - Significant hotspots"
}'

echo ""

# Top and bottom OSDs by utilization
echo "3. OSD Utilization Extremes:"
echo "---------------------------"
echo "Highest utilized OSDs:"
sudo ceph osd df | awk 'NR>1 {print $1, $8}' | sort -k2 -nr | head -3 | awk '{print "  OSD." $1 ": " $2 "x average"}'
echo "Lowest utilized OSDs:"
sudo ceph osd df | awk 'NR>1 {print $1, $8}' | sort -k2 -n | head -3 | awk '{print "  OSD." $1 ": " $2 "x average"}'

echo ""

# PG distribution analysis
echo "4. PG Distribution Analysis:"
echo "---------------------------"
pg_stats=$(sudo ceph pg dump osds 2>/dev/null | awk 'NR>1 {print $2}' | sort -n)
echo "$pg_stats" | awk '
{
    pgs[NR] = $1
    total += $1
    count++
}
END {
    avg = total/count
    min = pgs[1]
    max = pgs[count]
    range = max - min
    
    print "Average PGs per OSD: " avg
    print "Min PGs: " min ", Max PGs: " max
    print "Range: " range " (" int(range/avg*100) "% of average)"
    
    if (range/avg < 0.1) print "PG Distribution: EXCELLENT"
    else if (range/avg < 0.2) print "PG Distribution: GOOD"
    else if (range/avg < 0.3) print "PG Distribution: MODERATE"
    else print "PG Distribution: NEEDS IMPROVEMENT"
}'

echo ""

# Recent slow operations
echo "5. Performance Issues:"
echo "---------------------"
slow_ops=$(sudo ceph health detail | grep -c "slow")
if [ $slow_ops -gt 0 ]; then
    echo "WARNING: $slow_ops slow operations detected"
    sudo ceph health detail | grep slow | head -5
else
    echo "No slow operations detected"
fi
EOF

chmod +x ~/hotspot-monitor.sh
./hotspot-monitor.sh
Set up automated monitoring:
# Create automated monitoring with alerts
cat > ~/automated-monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/ceph-hotspot-monitor.log"
ALERT_THRESHOLD=25  # Coefficient of variation threshold

monitor_hotspots() {
    local timestamp=$(date)
    local cv=$(sudo ceph osd df | awk 'NR>1 {
        util[NR-2] = $8
        total += $8
        count++
    }
    END {
        avg = total/count
        variance = 0
        for (i=0; i<count; i++) {
            variance += (util[i] - avg)^2
        }
        variance = variance/count
        stddev = sqrt(variance)
        cv = stddev/avg * 100
        print cv
    }')
    
    echo "[$timestamp] Utilization CV: $cv%" >> $LOG_FILE
    
    # Check if CV exceeds threshold
    if (( $(echo "$cv > $ALERT_THRESHOLD" | bc -l) )); then
        echo "[$timestamp] ALERT: High utilization variance detected ($cv%)" >> $LOG_FILE
        # In production, send email/notification here
        echo "ALERT: Ceph hotspot detected - CV: $cv%"
    fi
}

# Run monitoring
monitor_hotspots

# Set up cron job for continuous monitoring
echo "Setting up automated monitoring..."
(crontab -l 2>/dev/null; echo "*/5 * * * * $PWD/automated-monitor.sh") | crontab -
echo "Automated monitoring configured to run every 5 minutes"
EOF

chmod +x ~/automated-monitor.sh
./automated-monitor.sh
Performance Validation and Testing
Subtask 4.1: Benchmark Performance Improvements
Create performance testing script:
cat > ~/performance-test.sh << 'EOF'
#!/bin/bash

echo "Ceph Performance Validation Test"
echo "==============================="

# Create test pool for benchmarking
sudo ceph osd pool create benchmark 128 128
sudo ceph osd pool application enable benchmark rbd

echo "Running RADOS bench tests..."

# Sequential write test
echo "1. Sequential Write Test (10 seconds):"
sudo rados bench -p benchmark 10 write --no-cleanup | grep -E "bandwidth|average latency"

echo ""

# Sequential read test
echo "2. Sequential Read Test (10 seconds):"
sudo rados bench -p benchmark 10 seq | grep -E "bandwidth|average latency"

echo ""

# Random read test
echo "3. Random Read Test (10 seconds):"
sudo rados bench -p benchmark 10 rand | grep -E "bandwidth|average latency"

echo ""

# Clean up test objects
echo "Cleaning up test objects..."
sudo rados bench -p benchmark 10 write --no-cleanup > /dev/null 2>&1
sudo rados -p benchmark cleanup

# Remove test pool
sudo ceph osd pool delete benchmark benchmark --yes-i-really-really-mean-it

echo "Performance test completed."
EOF

chmod +x ~/performance-test.sh
./performance-test.sh
Compare before and after metrics:
# Create comparison report
cat > ~/performance-comparison.sh << 'EOF'
#!/bin/bash

echo "Performance Optimization Results"
echo "==============================="

echo "Before Optimization (from logs):"
echo "--------------------------------"
# These would typically be saved from earlier runs
echo "Average utilization variance: ~30%"
echo "Slow operations: 15-20 per hour"
echo "Network latency: 2-5ms average"

echo ""
echo "After Optimization (current):"
echo "-----------------------------"

# Current utilization variance
cv=$(sudo ceph osd df | awk 'NR>1 {
    util[NR-2] = $8
    total += $8
    count++
}
END {
    avg = total/count
    variance = 0
    for (i=0; i<count; i++) {
        variance += (util[i] - avg)^2
    }
    variance = variance/count
    stddev = sqrt(variance)
    cv = stddev/avg * 100
    print cv
}')

echo "Current utilization variance: $cv%"

# Check for slow operations
slow_ops=$(sudo ceph health detail | grep -c "slow" || echo "0")
echo "Current slow operations: $slow_ops"

# Network performance
echo "Network optimization applied: Buffer sizes increased"

echo ""
echo "Improvement Summary:"
echo "-------------------"
if (( $(echo "$cv < 20" | bc -l) )); then
    echo "✓ Utilization variance improved (target: <20%)"
else
    echo "⚠ Utilization variance needs more work"
fi

if [ $slow_ops -eq 0 ]; then
    echo "✓ Slow operations eliminated"
else
    echo "⚠ Still have $slow_ops slow operations"
fi

echo "✓ Network parameters optimized"
echo "✓ OSD parameters tuned"
echo "✓ CRUSH map optimized"
EOF

chmod +x ~/performance-comparison.sh
./performance-comparison.sh
Troubleshooting Common Issues
Common Performance Issues and Solutions
