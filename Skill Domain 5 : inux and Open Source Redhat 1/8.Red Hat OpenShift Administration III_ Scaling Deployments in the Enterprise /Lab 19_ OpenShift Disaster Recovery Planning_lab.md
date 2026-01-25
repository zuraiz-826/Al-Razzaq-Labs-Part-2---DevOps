Lab 19: OpenShift Disaster Recovery Planning
Objectives
By the end of this lab, students will be able to:

• Understand the fundamentals of OpenShift disaster recovery planning and best practices • Perform comprehensive disaster recovery drills to test cluster resilience • Execute backup restoration procedures to secondary OpenShift clusters • Implement automated backup solutions for continuous disaster recovery readiness • Configure and validate cross-cluster data replication strategies • Develop disaster recovery runbooks and documentation • Assess recovery time objectives (RTO) and recovery point objectives (RPO) for OpenShift workloads

Prerequisites
Before starting this lab, students should have:

• Basic understanding of OpenShift/Kubernetes concepts (pods, services, deployments) • Familiarity with Linux command-line operations • Knowledge of YAML configuration files • Understanding of container orchestration principles • Experience with OpenShift CLI (oc) commands • Basic knowledge of backup and restore concepts • Familiarity with storage concepts in Kubernetes environments

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift clusters already deployed. Simply click Start Lab to access your environment. No need to build your own virtual machines or install OpenShift from scratch.

Your lab environment includes: • Primary OpenShift cluster (cluster-primary) • Secondary OpenShift cluster (cluster-secondary) • Shared storage systems • Pre-installed backup tools (Velero, OADP) • Sample applications for testing

Task 1: Perform an OpenShift Disaster Recovery Drill
Subtask 1.1: Assess Current Cluster State and Prepare Test Environment
First, let's examine our primary cluster and prepare a test application for our disaster recovery drill.

Step 1: Connect to your primary OpenShift cluster and verify cluster status.

# Login to the primary cluster
oc login --server=https://api.cluster-primary.example.com:6443 --username=admin --password=admin123

# Check cluster status
oc get nodes
oc get clusterversion
oc get clusteroperators
Step 2: Create a test namespace and deploy a sample application.

# Create a test namespace
oc new-project disaster-recovery-test

# Deploy a sample application with persistent data
cat << EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: disaster-recovery-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        ports:
        - containerPort: 80
        volumeMounts:
        - name: data-volume
          mountPath: /usr/share/nginx/html
      volumes:
      - name: data-volume
        persistentVolumeClaim:
          claimName: sample-app-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sample-app-pvc
  namespace: disaster-recovery-test
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-service
  namespace: disaster-recovery-test
spec:
  selector:
    app: sample-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
EOF
Step 3: Add test data to the application.

# Wait for pods to be ready
oc wait --for=condition=ready pod -l app=sample-app -n disaster-recovery-test --timeout=300s

# Add test data
oc exec -n disaster-recovery-test deployment/sample-app -- sh -c "echo 'Disaster Recovery Test Data - $(date)' > /usr/share/nginx/html/index.html"

# Verify data
oc exec -n disaster-recovery-test deployment/sample-app -- cat /usr/share/nginx/html/index.html
Subtask 1.2: Document Current State and Create Baseline
Step 1: Document the current cluster state for comparison after recovery.

# Create documentation directory
mkdir -p ~/disaster-recovery-docs

# Document cluster resources
oc get all -A > ~/disaster-recovery-docs/cluster-resources-before.txt
oc get pv,pvc -A > ~/disaster-recovery-docs/storage-before.txt
oc get configmaps,secrets -A > ~/disaster-recovery-docs/config-before.txt

# Document our test application specifically
oc get all -n disaster-recovery-test -o yaml > ~/disaster-recovery-docs/test-app-before.yaml
Step 2: Create a disaster recovery checklist.

cat << EOF > ~/disaster-recovery-docs/dr-checklist.md
# Disaster Recovery Checklist

## Pre-Disaster State
- [ ] Cluster nodes: $(oc get nodes --no-headers | wc -l)
- [ ] Running pods: $(oc get pods -A --field-selector=status.phase=Running --no-headers | wc -l)
- [ ] PVCs: $(oc get pvc -A --no-headers | wc -l)
- [ ] Test application status: $(oc get deployment sample-app -n disaster-recovery-test -o jsonpath='{.status.readyReplicas}')

## Recovery Validation
- [ ] All nodes operational
- [ ] All pods restored and running
- [ ] Persistent data intact
- [ ] Application functionality verified
- [ ] Network connectivity confirmed

## Recovery Time Tracking
- Disaster simulation start: $(date)
- Recovery completion: TBD
- Total downtime: TBD
EOF
Subtask 1.3: Simulate Disaster Scenarios
Step 1: Simulate a node failure scenario.

# Identify a worker node
WORKER_NODE=$(oc get nodes -l node-role.kubernetes.io/worker --no-headers | head -1 | awk '{print $1}')
echo "Simulating failure on node: $WORKER_NODE"

# Cordon and drain the node
oc cordon $WORKER_NODE
oc drain $WORKER_NODE --ignore-daemonsets --delete-emptydir-data --force

# Verify pod rescheduling
oc get pods -n disaster-recovery-test -o wide
Step 2: Simulate application data corruption.

# Corrupt application data
oc exec -n disaster-recovery-test deployment/sample-app -- sh -c "echo 'CORRUPTED DATA' > /usr/share/nginx/html/index.html"

# Verify corruption
oc exec -n disaster-recovery-test deployment/sample-app -- cat /usr/share/nginx/html/index.html
Step 3: Document disaster impact.

# Update checklist with disaster impact
cat << EOF >> ~/disaster-recovery-docs/dr-checklist.md

## Disaster Impact Assessment
- Disaster type: Node failure + Data corruption
- Affected node: $WORKER_NODE
- Affected applications: sample-app
- Data integrity: Compromised
- Service availability: $(oc get deployment sample-app -n disaster-recovery-test -o jsonpath='{.status.readyReplicas}')/{.spec.replicas}')
EOF
Task 2: Test Backup Restoration to Another Cluster
Subtask 2.1: Install and Configure Backup Tools
Step 1: Install Velero (backup tool) on the primary cluster.

# Download and install Velero CLI
wget https://github.com/vmware-tanzu/velero/releases/download/v1.12.0/velero-v1.12.0-linux-amd64.tar.gz
tar -xzf velero-v1.12.0-linux-amd64.tar.gz
sudo mv velero-v1.12.0-linux-amd64/velero /usr/local/bin/

# Verify installation
velero version --client-only
Step 2: Configure backup storage location.

# Create credentials file for backup storage (using MinIO as example)
cat << EOF > ~/minio-credentials
[default]
aws_access_key_id = minio
aws_secret_access_key = minio123
EOF

# Install Velero with MinIO backend
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.8.0 \
    --bucket velero-backups \
    --secret-file ~/minio-credentials \
    --use-volume-snapshots=false \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.velero.svc.cluster.local:9000

# Verify Velero installation
oc get pods -n velero
velero backup-location get
Subtask 2.2: Create Comprehensive Backup
Step 1: Create a full cluster backup.

# Create backup of our test namespace
velero backup create test-app-backup \
    --include-namespaces disaster-recovery-test \
    --wait

# Verify backup completion
velero backup describe test-app-backup
velero backup logs test-app-backup
Step 2: Create additional backups for different scenarios.

# Create cluster-wide backup (excluding system namespaces)
velero backup create cluster-backup \
    --exclude-namespaces velero,kube-system,openshift-*,kube-* \
    --wait

# Create backup with specific labels
velero backup create labeled-resources-backup \
    --selector app=sample-app \
    --wait

# List all backups
velero backup get
Subtask 2.3: Prepare Secondary Cluster for Restoration
Step 1: Switch to secondary cluster and install Velero.

# Login to secondary cluster
oc login --server=https://api.cluster-secondary.example.com:6443 --username=admin --password=admin123

# Verify secondary cluster status
oc get nodes
oc get namespaces

# Install Velero on secondary cluster with same configuration
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.8.0 \
    --bucket velero-backups \
    --secret-file ~/minio-credentials \
    --use-volume-snapshots=false \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.velero.svc.cluster.local:9000

# Verify Velero can access backups
velero backup get
Subtask 2.4: Perform Restoration Testing
Step 1: Restore the test application to secondary cluster.

# Create restore from backup
velero restore create test-app-restore \
    --from-backup test-app-backup \
    --wait

# Monitor restore progress
velero restore describe test-app-restore
velero restore logs test-app-restore
Step 2: Verify restoration success.

# Check if namespace was restored
oc get namespace disaster-recovery-test

# Check if resources were restored
oc get all -n disaster-recovery-test

# Verify persistent data
oc wait --for=condition=ready pod -l app=sample-app -n disaster-recovery-test --timeout=300s
oc exec -n disaster-recovery-test deployment/sample-app -- cat /usr/share/nginx/html/index.html
Step 3: Test application functionality.

# Test application accessibility
oc port-forward -n disaster-recovery-test service/sample-app-service 8080:80 &
PORT_FORWARD_PID=$!

# Test HTTP response
sleep 5
curl -s http://localhost:8080

# Clean up port forward
kill $PORT_FORWARD_PID
Subtask 2.5: Validate Cross-Cluster Restoration
Step 1: Compare restored resources with original documentation.

# Document restored state
oc get all -n disaster-recovery-test -o yaml > ~/disaster-recovery-docs/test-app-restored.yaml

# Compare with original state
diff ~/disaster-recovery-docs/test-app-before.yaml ~/disaster-recovery-docs/test-app-restored.yaml
Step 2: Perform functional testing.

# Create test script for application validation
cat << 'EOF' > ~/validate-restoration.sh
#!/bin/bash

echo "=== Disaster Recovery Validation ==="
echo "Timestamp: $(date)"

# Check namespace
if oc get namespace disaster-recovery-test &>/dev/null; then
    echo "✓ Namespace restored successfully"
else
    echo "✗ Namespace restoration failed"
    exit 1
fi

# Check deployment
READY_REPLICAS=$(oc get deployment sample-app -n disaster-recovery-test -o jsonpath='{.status.readyReplicas}')
DESIRED_REPLICAS=$(oc get deployment sample-app -n disaster-recovery-test -o jsonpath='{.spec.replicas}')

if [ "$READY_REPLICAS" = "$DESIRED_REPLICAS" ]; then
    echo "✓ Application deployment restored successfully ($READY_REPLICAS/$DESIRED_REPLICAS)"
else
    echo "✗ Application deployment incomplete ($READY_REPLICAS/$DESIRED_REPLICAS)"
fi

# Check persistent volume claim
if oc get pvc sample-app-pvc -n disaster-recovery-test &>/dev/null; then
    PVC_STATUS=$(oc get pvc sample-app-pvc -n disaster-recovery-test -o jsonpath='{.status.phase}')
    echo "✓ PVC restored with status: $PVC_STATUS"
else
    echo "✗ PVC restoration failed"
fi

# Check data integrity
DATA_CONTENT=$(oc exec -n disaster-recovery-test deployment/sample-app -- cat /usr/share/nginx/html/index.html 2>/dev/null)
if echo "$DATA_CONTENT" | grep -q "Disaster Recovery Test Data"; then
    echo "✓ Application data restored successfully"
    echo "  Data: $DATA_CONTENT"
else
    echo "✗ Application data restoration failed or corrupted"
    echo "  Found: $DATA_CONTENT"
fi

echo "=== Validation Complete ==="
EOF

chmod +x ~/validate-restoration.sh
~/validate-restoration.sh
Task 3: Automate Backups for Future Disaster Recovery Operations
Subtask 3.1: Create Automated Backup Schedules
Step 1: Create scheduled backups using Velero.

# Switch back to primary cluster
oc login --server=https://api.cluster-primary.example.com:6443 --username=admin --password=admin123

# Create daily backup schedule
velero schedule create daily-backup \
    --schedule="0 2 * * *" \
    --exclude-namespaces velero,kube-system,openshift-*,kube-* \
    --ttl 720h

# Create hourly backup for critical namespaces
velero schedule create hourly-critical-backup \
    --schedule="0 * * * *" \
    --include-namespaces disaster-recovery-test,production,staging \
    --ttl 168h

# Create weekly full backup
velero schedule create weekly-full-backup \
    --schedule="0 1 * * 0" \
    --ttl 2160h

# List all schedules
velero schedule get
Step 2: Create backup policies with different retention periods.

# Create backup policy configuration
cat << EOF > ~/backup-policies.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backup-policies
  namespace: velero
data:
  policy.yaml: |
    policies:
      critical:
        schedule: "0 */4 * * *"  # Every 4 hours
        retention: "72h"
        namespaces: ["production", "disaster-recovery-test"]
      standard:
        schedule: "0 2 * * *"    # Daily at 2 AM
        retention: "168h"        # 7 days
        exclude_namespaces: ["kube-system", "openshift-*"]
      archive:
        schedule: "0 1 * * 0"    # Weekly on Sunday
        retention: "2160h"       # 90 days
        full_cluster: true
EOF

oc apply -f ~/backup-policies.yaml
Subtask 3.2: Implement Backup Monitoring and Alerting
Step 1: Create backup monitoring script.

cat << 'EOF' > ~/backup-monitor.sh
#!/bin/bash

# Backup monitoring script
LOG_FILE="/var/log/backup-monitor.log"
ALERT_EMAIL="admin@company.com"

log_message() {
    echo "$(date): $1" | tee -a $LOG_FILE
}

check_backup_status() {
    local backup_name=$1
    local status=$(velero backup get $backup_name -o jsonpath='{.status.phase}' 2>/dev/null)
    
    case $status in
        "Completed")
            log_message "✓ Backup $backup_name completed successfully"
            return 0
            ;;
        "Failed")
            log_message "✗ Backup $backup_name failed"
            return 1
            ;;
        "InProgress")
            log_message "⏳ Backup $backup_name in progress"
            return 2
            ;;
        *)
            log_message "? Backup $backup_name status unknown: $status"
            return 3
            ;;
    esac
}

# Check recent backups
log_message "Starting backup status check"

FAILED_BACKUPS=0
for backup in $(velero backup get --output name | head -10); do
    backup_name=$(echo $backup | cut -d'/' -f2)
    if ! check_backup_status $backup_name; then
        if [ $? -eq 1 ]; then
            ((FAILED_BACKUPS++))
        fi
    fi
done

# Alert if failures detected
if [ $FAILED_BACKUPS -gt 0 ]; then
    log_message "ALERT: $FAILED_BACKUPS backup(s) failed"
    # In a real environment, send email or webhook notification
    echo "Backup failures detected. Check $LOG_FILE for details."
fi

log_message "Backup monitoring check completed"
EOF

chmod +x ~/backup-monitor.sh
Step 2: Create automated backup validation.

cat << 'EOF' > ~/backup-validator.sh
#!/bin/bash

# Backup validation script
validate_backup() {
    local backup_name=$1
    echo "Validating backup: $backup_name"
    
    # Check backup exists and is complete
    if ! velero backup describe $backup_name &>/dev/null; then
        echo "✗ Backup $backup_name not found"
        return 1
    fi
    
    local status=$(velero backup get $backup_name -o jsonpath='{.status.phase}')
    if [ "$status" != "Completed" ]; then
        echo "✗ Backup $backup_name status: $status"
        return 1
    fi
    
    # Check backup size and resource count
    local resources=$(velero backup describe $backup_name | grep "Resource List:" -A 20 | grep -E "^\s+\w+:" | wc -l)
    if [ $resources -eq 0 ]; then
        echo "✗ Backup $backup_name contains no resources"
        return 1
    fi
    
    echo "✓ Backup $backup_name validated successfully ($resources resource types)"
    return 0
}

# Validate recent backups
echo "=== Backup Validation Report ==="
echo "Generated: $(date)"
echo

VALIDATION_FAILURES=0
for backup in $(velero backup get --output name | head -5); do
    backup_name=$(echo $backup | cut -d'/' -f2)
    if ! validate_backup $backup_name; then
        ((VALIDATION_FAILURES++))
    fi
    echo
done

echo "=== Summary ==="
if [ $VALIDATION_FAILURES -eq 0 ]; then
    echo "✓ All backups validated successfully"
else
    echo "✗ $VALIDATION_FAILURES backup(s) failed validation"
fi
EOF

chmod +x ~/backup-validator.sh
~/backup-validator.sh
Subtask 3.3: Create Disaster Recovery Automation
Step 1: Create automated disaster recovery script.

cat << 'EOF' > ~/automated-dr.sh
#!/bin/bash

# Automated Disaster Recovery Script
set -e

# Configuration
PRIMARY_CLUSTER="https://api.cluster-primary.example.com:6443"
SECONDARY_CLUSTER="https://api.cluster-secondary.example.com:6443"
BACKUP_NAME=""
RESTORE_NAMESPACES=""
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --backup-name)
            BACKUP_NAME="$2"
            shift 2
            ;;
        --namespaces)
            RESTORE_NAMESPACES="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

log_step() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Validate prerequisites
validate_prerequisites() {
    log_step "Validating prerequisites..."
    
    if [ -z "$BACKUP_NAME" ]; then
        echo "Error: --backup-name is required"
        exit 1
    fi
    
    # Check if backup exists
    if ! velero backup get $BACKUP_NAME &>/dev/null; then
        echo "Error: Backup $BACKUP_NAME not found"
        exit 1
    fi
    
    log_step "Prerequisites validated"
}

# Switch to secondary cluster
switch_to_secondary() {
    log_step "Switching to secondary cluster..."
    oc login --server=$SECONDARY_CLUSTER --username=admin --password=admin123
    log_step "Connected to secondary cluster"
}

# Perform restoration
perform_restore() {
    log_step "Starting restoration process..."
    
    local restore_name="dr-restore-$(date +%Y%m%d-%H%M%S)"
    local restore_cmd="velero restore create $restore_name --from-backup $BACKUP_NAME"
    
    if [ -n "$RESTORE_NAMESPACES" ]; then
        restore_cmd="$restore_cmd --include-namespaces $RESTORE_NAMESPACES"
    fi
    
    if [ "$DRY_RUN" = true ]; then
        log_step "DRY RUN: Would execute: $restore_cmd"
        return 0
    fi
    
    $restore_cmd --wait
    
    log_step "Restoration completed: $restore_name"
    
    # Validate restoration
    velero restore describe $restore_name
    
    return 0
}

# Validate restored applications
validate_restoration() {
    log_step "Validating restored applications..."
    
    if [ "$DRY_RUN" = true ]; then
        log_step "DRY RUN: Skipping validation"
        return 0
    fi
    
    # Wait for pods to be ready
    if [ -n "$RESTORE_NAMESPACES" ]; then
        for ns in $(echo $RESTORE_NAMESPACES | tr ',' ' '); do
            log_step "Waiting for pods in namespace $ns to be ready..."
            oc wait --for=condition=ready pod --all -n $ns --timeout=300s || true
        done
    fi
    
    log_step "Validation completed"
}

# Generate recovery report
generate_report() {
    log_step "Generating disaster recovery report..."
    
    local report_file="dr-report-$(date +%Y%m%d-%H%M%S).txt"
    
    cat << EOF > $report_file
Disaster Recovery Report
========================
Date: $(date)
Backup Used: $BACKUP_NAME
Target Cluster: $SECONDARY_CLUSTER
Restored Namespaces: ${RESTORE_NAMESPACES:-"All (excluding system)"}
Dry Run: $DRY_RUN

Cluster Status:
$(oc get nodes)

Restored Resources:
$(if [ -n "$RESTORE_NAMESPACES" ]; then
    for ns in $(echo $RESTORE_NAMESPACES | tr ',' ' '); do
        echo "Namespace: $ns"
        oc get all -n $ns
        echo
    done
fi)
EOF
    
    log_step "Report generated: $report_file"
}

# Main execution
main() {
    log_step "Starting automated disaster recovery process"
    
    validate_prerequisites
    switch_to_secondary
    perform_restore
    validate_restoration
    generate_report
    
    log_step "Disaster recovery process completed successfully"
}

# Show usage if no arguments
if [ $# -eq 0 ]; then
    cat << EOF
Usage: $0 --backup-name BACKUP_NAME [OPTIONS]

Options:
  --backup-name NAME    Name of the backup to restore (required)
  --namespaces LIST     Comma-separated list of namespaces to restore
  --dry-run            Perform a dry run without actual restoration

Examples:
  $0 --backup-name daily-backup-20231201 --namespaces disaster-recovery-test
  $0 --backup-name cluster-backup --dry-run
EOF
    exit 1
fi

main "$@"
EOF

chmod +x ~/automated-dr.sh
Step 2: Test the automated disaster recovery script.

# Test with dry run first
~/automated-dr.sh --backup-name test-app-backup --namespaces disaster-recovery-test --dry-run

# If dry run looks good, perform actual restoration
~/automated-dr.sh --backup-name test-app-backup --namespaces disaster-recovery-test
Subtask 3.4: Create Disaster Recovery Documentation and Runbooks
Step 1: Create comprehensive disaster recovery runbook.

cat << 'EOF' > ~/disaster-recovery-runbook.md
# OpenShift Disaster Recovery Runbook

## Overview
This runbook provides step-by-step procedures for OpenShift disaster recovery operations.

## Emergency Contacts
- Primary Administrator: admin@company.com
- Secondary Administrator: backup-admin@company.com
- Infrastructure Team: infra@company.com

## Recovery Time Objectives (RTO)
- Critical Applications: 4 hours
- Standard Applications: 8 hours
- Development Applications: 24 hours

## Recovery Point Objectives (RPO)
- Critical Applications: 1 hour
- Standard Applications: 4 hours
- Development Applications: 24 hours

## Disaster Scenarios and Procedures

### Scenario 1: Complete Cluster Failure

**Detection:**
- Cluster API unreachable
- All nodes down
- Applications inaccessible

**Response:**
1. Verify disaster scope
2. Activate secondary cluster
3. Restore from latest backup
4. Validate application functionality
5. Update DNS/load balancer configuration

**Commands:**
```bash
# Switch to secondary cluster
oc login --server=https://api.cluster-secondary.example.com:6443

# List available backups
velero backup get

# Restore latest backup
velero restore create emergency-restore --from-backup <latest-backup> --wait

# Validate restoration
./backup-validator.sh
Scenario 2: Data Corruption
Detection:

Application data inconsistencies
Database corruption alerts
User reports of missing data
Response:

Identify affected namespaces/applications
Stop affected applications
Restore from point-in-time backup
Validate data integrity
Resume applications
Commands:

# Scale down affected applications
oc scale deployment <app-name> --replicas=0 -n <namespace>

# Restore specific namespace
velero restore create data-recovery --from-backup <backup-name> --include-namespaces <namespace>

# Validate and scale up
oc scale deployment <app-name> --replicas=<original-count> -n <namespace>
Scenario 3: Node Failure
Detection:

Node status NotReady
Pods stuck in Pending state
Resource scheduling failures
Response:

Assess node failure scope
Cordon affected nodes
Drain workloads to healthy nodes
Replace or repair failed nodes
Uncordon when ready
Commands:

# Check node status
oc get nodes

# Cordon failed node
oc cordon <node-name>

# Drain workloads
oc drain <node-name> --ignore-daemonsets --delete-emptydir-data

# After repair, uncordon
oc uncordon <node-name>
Backup Schedule
Hourly: Critical namespaces
Daily: All application namespaces
Weekly: Full cluster backup
Testing Schedule
Monthly: Backup restoration test
Quarterly: Full disaster recovery drill
Annually: Cross-site failover test
Post-Recovery Checklist
 All critical applications running
 Data integrity verified
 Performance metrics normal
 Monitoring and alerting functional
 Backup schedules resumed
 Incident documentation completed
 Lessons learned documented EOF

**Step 2**: Create backup and restore cheat sheet.

```bash
cat << 'EOF' > ~/backup-restore-cheatsheet.md
# OpenShift Backup & Restore Cheat Sheet

## Velero Commands

### Backup Operations
```bash
# Create backup
velero backup create <backup-name> [options]

# Backup specific namespace
velero backup create <name> --include-namespaces <namespace>

# Backup with labels
velero backup create <name> --selector <label-selector>

# Exclude namespaces
velero backup create <name> --exclude-namespaces <namespaces>

# List backups
velero backup get

# Describe backup
velero backup describe <backup-name>

# Get backup logs
velero backup logs <backup-name>

# Delete backup
velero backup delete <backup-name>
Restore Operations
# Create restore
velero restore create <restore-name> --from-backup <backup-name>

# Restore to different namespace
velero restore create <name> --from-backup <backup> --namespace-mappings old-ns:new-ns

# Restore specific resources
velero restore create <name> --from-backup <backup> --include-resources <resources>

# List restores
velero restore get

# Describe restore
velero restore describe <restore-name>

# Get restore logs
velero restore logs <restore-name>
Schedule Operations
# Create schedule
velero schedule create <name> --schedule="<cron-expression>"

# List schedules
velero schedule get

# Describe schedule
velero schedule describe <schedule-name>

# Delete schedule
velero schedule delete <schedule-name>
OpenShift Commands
Cluster Information
# Get cluster version
oc get clusterversion

# Get cluster operators
oc get clusteroperators

# Get nodes
oc get nodes

# Get all resources in namespace
oc get all -n <namespace>
Resource Management
# Scale deployment
oc scale deployment <name> --replicas=<count> -n <namespace>

# Get pod logs
oc logs <pod-name> -n <namespace>

# Execute command in pod
oc exec <pod-name> -n <namespace> -- <command>

# Port forward
oc port-forward <pod-name> <local-port>:<pod-port> -n <namespace>
Common Backup Scenarios
Daily Application Backup
velero backup create daily-$(date +%Y%m%d) \
  --exclude-namespaces kube-system,openshift-*,velero \
  --ttl 168h
Critical Namespace Backup
velero backup create critical-$(date +%Y%m%d-%H%M) \
  --include-namespaces production,staging \
  --ttl 72h
Full Cluster Backup
velero backup create full-$(date +%Y%m%d) \
  --ttl
