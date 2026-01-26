Lab 17: Performance Tuning for Databases
Objectives
By the end of this lab, students will be able to:

Optimize database performance by tuning system parameters related to disk, memory, and CPU
Configure I/O scheduling and network buffers specifically for database workloads
Implement performance monitoring and measurement techniques for database systems
Apply best practices for database performance optimization in Linux environments
Understand the relationship between system-level tuning and database performance
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux system administration
Familiarity with command-line interface and text editors
Knowledge of database concepts and SQL basics
Understanding of system resources (CPU, memory, disk I/O)
Experience with performance monitoring tools
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install additional software.

Your lab environment includes:

CentOS/RHEL 8 or 9 system with root access
PostgreSQL database server pre-installed
Performance monitoring tools (htop, iotop, iostat, etc.)
Sample database with test data
Task 1: Tune Disk and Memory Settings for Database Workloads
Subtask 1.1: Analyze Current System Configuration
First, let's examine the current system configuration and identify areas for optimization.

Check current memory configuration:
# Display total memory and current usage
free -h

# Check swap configuration
swapon --show

# View memory-related kernel parameters
sysctl vm.swappiness
sysctl vm.dirty_ratio
sysctl vm.dirty_background_ratio
Examine disk configuration:
# List all block devices
lsblk

# Check current I/O scheduler for database disk
cat /sys/block/sda/queue/scheduler

# View current disk usage
df -h

# Check mount options
mount | grep -E "(ext4|xfs)"
Analyze current database configuration:
# Connect to PostgreSQL and check current settings
sudo -u postgres psql -c "SHOW shared_buffers;"
sudo -u postgres psql -c "SHOW effective_cache_size;"
sudo -u postgres psql -c "SHOW work_mem;"
sudo -u postgres psql -c "SHOW maintenance_work_mem;"
Subtask 1.2: Configure Memory Settings for Database Performance
Optimize kernel memory parameters:
# Create backup of current sysctl configuration
sudo cp /etc/sysctl.conf /etc/sysctl.conf.backup

# Add database-optimized memory settings
sudo tee -a /etc/sysctl.conf << 'EOF'

# Database Performance Tuning Settings
# Reduce swappiness for database workloads
vm.swappiness = 1

# Optimize dirty page handling
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Increase shared memory limits
kernel.shmmax = 68719476736
kernel.shmall = 4294967296

# Optimize memory overcommit
vm.overcommit_memory = 2
vm.overcommit_ratio = 80
EOF

# Apply the new settings
sudo sysctl -p
Configure PostgreSQL memory settings:
# Calculate optimal settings based on available memory
TOTAL_MEM=$(free -b | awk 'NR==2{print $2}')
SHARED_BUFFERS=$((TOTAL_MEM / 4))
EFFECTIVE_CACHE=$((TOTAL_MEM * 3 / 4))

# Backup PostgreSQL configuration
sudo cp /var/lib/pgsql/data/postgresql.conf /var/lib/pgsql/data/postgresql.conf.backup

# Update PostgreSQL memory settings
sudo tee -a /var/lib/pgsql/data/postgresql.conf << EOF

# Memory Configuration for Performance
shared_buffers = $(($SHARED_BUFFERS / 1024 / 1024))MB
effective_cache_size = $(($EFFECTIVE_CACHE / 1024 / 1024))MB
work_mem = 16MB
maintenance_work_mem = 256MB
wal_buffers = 16MB
EOF
Subtask 1.3: Optimize Disk Settings for Database I/O
Configure I/O scheduler for database workloads:
# Set deadline scheduler for better database performance
echo deadline | sudo tee /sys/block/sda/queue/scheduler

# Make the change persistent
echo 'ACTION=="add|change", KERNEL=="sda", ATTR{queue/scheduler}="deadline"' | sudo tee /etc/udev/rules.d/60-scheduler.rules
Optimize filesystem mount options:
# Check current mount options
mount | grep "on / "

# Create optimized fstab entry for database partition
# (This example assumes /var/lib/pgsql is on a separate partition)
sudo cp /etc/fstab /etc/fstab.backup

# Add noatime and other performance options
# Note: Modify according to your actual partition setup
sudo sed -i 's/defaults/defaults,noatime,nodiratime/' /etc/fstab
Configure readahead settings:
# Check current readahead setting
sudo blockdev --getra /dev/sda

# Set optimal readahead for database workloads (8192 sectors = 4MB)
sudo blockdev --setra 8192 /dev/sda

# Make persistent by creating a systemd service
sudo tee /etc/systemd/system/database-tuning.service << 'EOF'
[Unit]
Description=Database Performance Tuning
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/sbin/blockdev --setra 8192 /dev/sda
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable database-tuning.service
Task 2: Adjust I/O Scheduling and Network Buffers for Database Traffic
Subtask 2.1: Fine-tune I/O Scheduling Parameters
Configure deadline scheduler parameters:
# Optimize deadline scheduler for database workloads
echo 1 | sudo tee /sys/block/sda/queue/iosched/front_merges
echo 150 | sudo tee /sys/block/sda/queue/iosched/read_expire
echo 1500 | sudo tee /sys/block/sda/queue/iosched/write_expire
echo 6 | sudo tee /sys/block/sda/queue/iosched/writes_starved

# Create script to apply I/O settings at boot
sudo tee /usr/local/bin/database-io-tuning.sh << 'EOF'
#!/bin/bash
# Database I/O Tuning Script

# Set I/O scheduler to deadline
echo deadline > /sys/block/sda/queue/scheduler

# Configure deadline scheduler parameters
echo 1 > /sys/block/sda/queue/iosched/front_merges
echo 150 > /sys/block/sda/queue/iosched/read_expire
echo 1500 > /sys/block/sda/queue/iosched/write_expire
echo 6 > /sys/block/sda/queue/iosched/writes_starved

# Set queue depth
echo 32 > /sys/block/sda/queue/nr_requests
EOF

sudo chmod +x /usr/local/bin/database-io-tuning.sh

# Add to rc.local for persistence
echo '/usr/local/bin/database-io-tuning.sh' | sudo tee -a /etc/rc.local
sudo chmod +x /etc/rc.local
Configure filesystem-level I/O optimization:
# Tune ext4 filesystem parameters (if using ext4)
sudo tune2fs -o journal_data_writeback /dev/sda1

# For XFS filesystems, optimize allocation groups
# (This is typically done during filesystem creation)
# xfs_info /var/lib/pgsql
Subtask 2.2: Optimize Network Buffers for Database Connections
Configure TCP buffer sizes for database connections:
# Add network optimization settings to sysctl.conf
sudo tee -a /etc/sysctl.conf << 'EOF'

# Network Buffer Optimization for Database
# Increase TCP buffer sizes
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216

# TCP window scaling
net.ipv4.tcp_window_scaling = 1

# TCP buffer auto-tuning
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Increase connection tracking
net.netfilter.nf_conntrack_max = 1048576

# Optimize TCP connection handling
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog = 5000
EOF

# Apply network settings
sudo sysctl -p
Configure PostgreSQL connection settings:
# Update PostgreSQL connection parameters
sudo tee -a /var/lib/pgsql/data/postgresql.conf << 'EOF'

# Connection and Network Settings
max_connections = 200
listen_addresses = '*'
port = 5432

# TCP settings
tcp_keepalives_idle = 600
tcp_keepalives_interval = 30
tcp_keepalives_count = 3
EOF
Subtask 2.3: Implement Connection Pooling
Install and configure PgBouncer for connection pooling:
# Install PgBouncer
sudo dnf install -y pgbouncer

# Create PgBouncer configuration
sudo tee /etc/pgbouncer/pgbouncer.ini << 'EOF'
[databases]
testdb = host=localhost port=5432 dbname=testdb

[pgbouncer]
listen_port = 6432
listen_addr = *
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
logfile = /var/log/pgbouncer/pgbouncer.log
pidfile = /var/run/pgbouncer/pgbouncer.pid
admin_users = postgres
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25
reserve_pool_size = 5
EOF

# Create user authentication file
sudo tee /etc/pgbouncer/userlist.txt << 'EOF'
"postgres" "md5d41d8cd98f00b204e9800998ecf8427e"
EOF

# Set proper permissions
sudo chown postgres:postgres /etc/pgbouncer/pgbouncer.ini
sudo chown postgres:postgres /etc/pgbouncer/userlist.txt
sudo chmod 640 /etc/pgbouncer/pgbouncer.ini
sudo chmod 640 /etc/pgbouncer/userlist.txt

# Start and enable PgBouncer
sudo systemctl start pgbouncer
sudo systemctl enable pgbouncer
Task 3: Measure Database Performance
Subtask 3.1: Set Up Performance Monitoring Tools
Install additional monitoring tools:
# Install performance monitoring tools
sudo dnf install -y htop iotop sysstat postgresql-contrib

# Enable and start system statistics collection
sudo systemctl enable sysstat
sudo systemctl start sysstat
Configure PostgreSQL for performance monitoring:
# Enable query statistics in PostgreSQL
sudo tee -a /var/lib/pgsql/data/postgresql.conf << 'EOF'

# Performance Monitoring Settings
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all
pg_stat_statements.max = 10000
log_statement = 'all'
log_duration = on
log_min_duration_statement = 1000
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
EOF

# Restart PostgreSQL to apply changes
sudo systemctl restart postgresql
Create performance monitoring database and extension:
# Create test database and enable extensions
sudo -u postgres createdb testdb
sudo -u postgres psql testdb -c "CREATE EXTENSION pg_stat_statements;"
sudo -u postgres psql testdb -c "CREATE EXTENSION pgstattuple;"
Subtask 3.2: Create Sample Data and Workload
Generate sample data for testing:
# Create sample tables and data
sudo -u postgres psql testdb << 'EOF'
-- Create sample tables
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    amount DECIMAL(10,2),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO customers (name, email)
SELECT 
    'Customer ' || generate_series,
    'customer' || generate_series || '@example.com'
FROM generate_series(1, 100000);

INSERT INTO orders (customer_id, amount)
SELECT 
    (random() * 100000)::integer + 1,
    (random() * 1000)::decimal(10,2)
FROM generate_series(1, 500000);

-- Create indexes
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);

-- Update statistics
ANALYZE customers;
ANALYZE orders;
EOF
Create performance test script:
# Create workload simulation script
sudo tee /home/student/db_workload_test.sh << 'EOF'
#!/bin/bash

# Database Performance Test Script
DB_NAME="testdb"
DB_USER="postgres"
DURATION=300  # 5 minutes
CONNECTIONS=20

echo "Starting database performance test..."
echo "Duration: ${DURATION} seconds"
echo "Concurrent connections: ${CONNECTIONS}"

# Function to run concurrent queries
run_queries() {
    local conn_id=$1
    local end_time=$(($(date +%s) + DURATION))
    
    while [ $(date +%s) -lt $end_time ]; do
        # Mix of different query types
        psql -U $DB_USER -d $DB_NAME -c "
            SELECT c.name, COUNT(o.id) as order_count, SUM(o.amount) as total_amount
            FROM customers c
            LEFT JOIN orders o ON c.id = o.customer_id
            WHERE c.created_at > NOW() - INTERVAL '30 days'
            GROUP BY c.id, c.name
            ORDER BY total_amount DESC
            LIMIT 100;
        " > /dev/null 2>&1
        
        psql -U $DB_USER -d $DB_NAME -c "
            SELECT * FROM orders 
            WHERE order_date BETWEEN NOW() - INTERVAL '7 days' AND NOW()
            ORDER BY amount DESC
            LIMIT 50;
        " > /dev/null 2>&1
        
        # Small delay between queries
        sleep 0.1
    done
}

# Start concurrent connections
for i in $(seq 1 $CONNECTIONS); do
    run_queries $i &
done

# Wait for all background jobs to complete
wait

echo "Performance test completed!"
EOF

chmod +x /home/student/db_workload_test.sh
Subtask 3.3: Baseline Performance Measurement
Restart services and collect baseline metrics:
# Restart PostgreSQL with new configuration
sudo systemctl restart postgresql

# Clear system caches for clean baseline
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches

# Reset PostgreSQL statistics
sudo -u postgres psql testdb -c "SELECT pg_stat_reset();"
sudo -u postgres psql testdb -c "SELECT pg_stat_statements_reset();"
Start monitoring and run baseline test:
# Start system monitoring in background
iostat -x 1 > /tmp/iostat_baseline.log &
IOSTAT_PID=$!

vmstat 1 > /tmp/vmstat_baseline.log &
VMSTAT_PID=$!

# Monitor PostgreSQL activity
sudo -u postgres psql testdb -c "
    SELECT now() as start_time;
    \timing on
" > /tmp/pg_baseline_start.log

# Run the performance test
echo "Running baseline performance test..."
/home/student/db_workload_test.sh

# Stop monitoring
kill $IOSTAT_PID $VMSTAT_PID

# Collect final statistics
sudo -u postgres psql testdb -c "
    SELECT now() as end_time;
    SELECT * FROM pg_stat_database WHERE datname = 'testdb';
" > /tmp/pg_baseline_end.log
Subtask 3.4: Performance Analysis and Optimization Verification
Analyze query performance:
# Check top queries by execution time
sudo -u postgres psql testdb -c "
    SELECT 
        query,
        calls,
        total_time,
        mean_time,
        rows
    FROM pg_stat_statements 
    ORDER BY total_time DESC 
    LIMIT 10;
"

# Check database statistics
sudo -u postgres psql testdb -c "
    SELECT 
        datname,
        numbackends,
        xact_commit,
        xact_rollback,
        blks_read,
        blks_hit,
        tup_returned,
        tup_fetched,
        tup_inserted,
        tup_updated,
        tup_deleted
    FROM pg_stat_database 
    WHERE datname = 'testdb';
"
Create performance analysis script:
# Create comprehensive performance analysis script
sudo tee /home/student/analyze_performance.sh << 'EOF'
#!/bin/bash

echo "=== Database Performance Analysis ==="
echo "Date: $(date)"
echo

echo "=== System Resource Usage ==="
echo "Memory Usage:"
free -h
echo

echo "Disk Usage:"
df -h
echo

echo "CPU Load:"
uptime
echo

echo "=== Database Statistics ==="
sudo -u postgres psql testdb -c "
    SELECT 
        'Cache Hit Ratio' as metric,
        ROUND(
            (blks_hit::float / (blks_hit + blks_read)) * 100, 2
        ) as percentage
    FROM pg_stat_database 
    WHERE datname = 'testdb' AND blks_read > 0;
"

echo
sudo -u postgres psql testdb -c "
    SELECT 
        schemaname,
        tablename,
        seq_scan,
        seq_tup_read,
        idx_scan,
        idx_tup_fetch,
        n_tup_ins,
        n_tup_upd,
        n_tup_del
    FROM pg_stat_user_tables 
    ORDER BY seq_scan DESC;
"

echo
echo "=== Top Slow Queries ==="
sudo -u postgres psql testdb -c "
    SELECT 
        LEFT(query, 80) as query_snippet,
        calls,
        ROUND(total_time::numeric, 2) as total_time_ms,
        ROUND(mean_time::numeric, 2) as avg_time_ms,
        ROUND((100.0 * total_time / sum(total_time) OVER())::numeric, 2) as percentage
    FROM pg_stat_statements 
    WHERE calls > 10
    ORDER BY total_time DESC 
    LIMIT 10;
"

echo
echo "=== Index Usage Analysis ==="
sudo -u postgres psql testdb -c "
    SELECT 
        schemaname,
        tablename,
        indexname,
        idx_scan,
        idx_tup_read,
        idx_tup_fetch
    FROM pg_stat_user_indexes 
    ORDER BY idx_scan DESC;
"
EOF

chmod +x /home/student/analyze_performance.sh
Run performance analysis:
# Execute performance analysis
/home/student/analyze_performance.sh > /tmp/performance_analysis.txt

# Display results
cat /tmp/performance_analysis.txt
Subtask 3.5: Compare Before and After Performance
Create comparison script:
# Create before/after comparison script
sudo tee /home/student/performance_comparison.sh << 'EOF'
#!/bin/bash

echo "=== Performance Tuning Results Comparison ==="
echo "Date: $(date)"
echo

echo "=== System Configuration Changes ==="
echo "Memory Settings:"
echo "  vm.swappiness: $(sysctl -n vm.swappiness)"
echo "  vm.dirty_ratio: $(sysctl -n vm.dirty_ratio)"
echo "  vm.dirty_background_ratio: $(sysctl -n vm.dirty_background_ratio)"
echo

echo "I/O Scheduler:"
cat /sys/block/sda/queue/scheduler
echo

echo "Network Buffers:"
echo "  net.core.rmem_max: $(sysctl -n net.core.rmem_max)"
echo "  net.core.wmem_max: $(sysctl -n net.core.wmem_max)"
echo

echo "=== PostgreSQL Configuration ==="
sudo -u postgres psql testdb -c "
    SELECT name, setting, unit 
    FROM pg_settings 
    WHERE name IN (
        'shared_buffers',
        'effective_cache_size',
        'work_mem',
        'maintenance_work_mem',
        'max_connections'
    );
"

echo
echo "=== Performance Metrics ==="
echo "Current Cache Hit Ratio:"
sudo -u postgres psql testdb -c "
    SELECT 
        ROUND(
            (blks_hit::float / (blks_hit + blks_read)) * 100, 2
        ) as cache_hit_ratio_percent
    FROM pg_stat_database 
    WHERE datname = 'testdb' AND blks_read > 0;
"

echo
echo "=== Recommendations ==="
echo "1. Monitor cache hit ratio - should be > 95%"
echo "2. Watch for excessive sequential scans"
echo "3. Monitor I/O wait times during peak loads"
echo "4. Consider additional indexes for frequently queried columns"
echo "5. Regular VACUUM and ANALYZE operations"
EOF

chmod +x /home/student/performance_comparison.sh

# Run comparison
/home/student/performance_comparison.sh
Troubleshooting Tips
Common Issues and Solutions
PostgreSQL fails to start after configuration changes:

# Check PostgreSQL logs
sudo tail -f /var/lib/pgsql/data/log/postgresql-*.log

# Validate configuration syntax
sudo -u postgres /usr/pgsql-*/bin/postgres --check-config -D /var/lib/pgsql/data/
High I/O wait times:

# Check for I/O bottlenecks
iostat -x 1 5
iotop -o

# Verify disk scheduler settings
cat /sys/block/sda/queue/scheduler
Memory allocation errors:

# Check available memory
free -h

# Verify shared memory limits
ipcs -l

# Check PostgreSQL memory settings
sudo -u postgres psql -c "SHOW shared_buffers;"
Connection issues with PgBouncer:

# Check PgBouncer status
sudo systemctl status pgbouncer

# View PgBouncer logs
sudo tail -f /var/log/pgbouncer/pgbouncer.log

# Test connection through PgBouncer
psql -h localhost -p 6432 -U postgres testdb
Conclusion
In this comprehensive lab, you have successfully implemented advanced database performance tuning techniques by:

Key Accomplishments:

System-Level Optimization: Configured kernel parameters for memory management, I/O scheduling, and network buffers specifically optimized for database workloads
Database Configuration: Tuned PostgreSQL settings including shared buffers, cache sizes, and connection parameters for optimal performance
I/O Optimization: Implemented deadline I/O scheduler, optimized filesystem mount options, and configured readahead settings for database storage
Connection Management: Set up PgBouncer for connection pooling to improve resource utilization and scalability
Performance Monitoring: Established comprehensive monitoring using pg_stat_statements and system tools to measure and analyze database performance
Workload Testing: Created realistic test scenarios to validate performance improvements and identify bottlenecks
Why This Matters:

Database performance tuning is critical for enterprise applications where even small improvements can result in significant cost savings and better user experience. The techniques learned in this lab are directly applicable to production environments and are essential skills for database administrators and system engineers working with high-performance database systems.

The systematic approach of measuring baseline performance, implementing optimizations, and validating improvements ensures that changes provide measurable benefits. These skills are particularly valuable for Red Hat Performance Tuning certification and real-world database optimization scenarios.

Next Steps:

Practice these techniques with different database engines (MySQL, MariaDB)
Explore advanced monitoring tools like Prometheus and Grafana for database metrics
Learn about database-specific tuning for different workload patterns (OLTP vs OLAP)
Study advanced topics like partitioning, replication, and clustering for scalability
