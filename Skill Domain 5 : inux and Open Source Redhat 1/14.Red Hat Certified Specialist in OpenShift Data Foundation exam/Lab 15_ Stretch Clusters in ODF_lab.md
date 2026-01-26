Lab 15: Stretch Clusters in ODF
Objectives
By the end of this lab, students will be able to:

Understand the concept and benefits of OpenShift Data Foundation (ODF) stretch clusters
Configure ODF stretch clusters across multiple availability zones
Validate multi-zone redundancy and data replication
Perform disaster recovery testing and failover scenarios
Monitor and troubleshoot stretch cluster operations
Implement best practices for multi-zone storage resilience
Prerequisites
Before starting this lab, students should have:

Basic understanding of OpenShift Container Platform concepts
Familiarity with Kubernetes storage concepts (PVs, PVCs, StorageClasses)
Knowledge of ODF fundamentals and Ceph storage
Experience with command-line interface (CLI) operations
Understanding of availability zones and disaster recovery concepts
Completed previous ODF labs or equivalent experience
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift clusters already deployed across multiple availability zones. Simply click Start Lab to access your environment - no need to build your own VMs or configure the base infrastructure.

Your lab environment includes:

Multi-zone OpenShift cluster (3 availability zones)
Pre-installed OpenShift CLI (oc)
Administrative access to the cluster
Network connectivity between zones
Task 1: Set up ODF Stretch Clusters Across Availability Zones
Subtask 1.1: Verify Multi-Zone Cluster Setup
First, let's examine the existing cluster topology and verify that nodes are distributed across multiple availability zones.

Connect to your lab environment and open a terminal.

Verify cluster nodes and their zones:

# Check all nodes and their zone labels
oc get nodes -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.topology\.kubernetes\.io/zone,REGION:.metadata.labels.topology\.kubernetes\.io/region

# Get detailed node information
oc get nodes --show-labels | grep topology
Examine the cluster infrastructure:
# Check cluster version and status
oc get clusterversion

# Verify cluster operators
oc get co | grep -E "(storage|odf)"
Subtask 1.2: Install ODF Operator
Now we'll install the OpenShift Data Foundation operator if it's not already present.

Create the ODF namespace:
# Create openshift-storage namespace
cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-storage
  labels:
    openshift.io/cluster-monitoring: "true"
EOF
Create the OperatorGroup:
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-storage-operatorgroup
  namespace: openshift-storage
spec:
  targetNamespaces:
  - openshift-storage
EOF
Install the ODF Operator:
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: odf-operator
  namespace: openshift-storage
spec:
  channel: stable-4.14
  installPlanApproval: Automatic
  name: odf-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
Wait for the operator to be ready:
# Monitor operator installation
oc get csv -n openshift-storage

# Wait for the operator to be in Succeeded phase
oc wait --for=condition=Succeeded csv -l operators.coreos.com/odf-operator.openshift-storage -n openshift-storage --timeout=600s
Subtask 1.3: Prepare Storage Devices
For this lab, we'll create local storage devices on each zone to simulate the storage infrastructure.

Label worker nodes for storage:
# Get worker nodes in each zone
ZONE1_NODES=$(oc get nodes -l node-role.kubernetes.io/worker -o jsonpath='{.items[?(@.metadata.labels.topology\.kubernetes\.io/zone=="zone-1")].metadata.name}')
ZONE2_NODES=$(oc get nodes -l node-role.kubernetes.io/worker -o jsonpath='{.items[?(@.metadata.labels.topology\.kubernetes\.io/zone=="zone-2")].metadata.name}')
ZONE3_NODES=$(oc get nodes -l node-role.kubernetes.io/worker -o jsonpath='{.items[?(@.metadata.labels.topology\.kubernetes\.io/zone=="zone-3")].metadata.name}')

# Label nodes for ODF storage
for node in $ZONE1_NODES $ZONE2_NODES $ZONE3_NODES; do
  oc label node $node cluster.ocs.openshift.io/openshift-storage=""
done
Create Local Storage Operator subscription (if using local storage):
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: local-storage-operator
  namespace: openshift-local-storage
spec:
  channel: stable
  installPlanApproval: Automatic
  name: local-storage-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
Subtask 1.4: Configure ODF Stretch Cluster
Now we'll create the StorageSystem with stretch cluster configuration.

Create the StorageSystem for stretch cluster:
cat << EOF | oc apply -f -
apiVersion: odf.openshift.io/v1alpha1
kind: StorageSystem
metadata:
  name: ocs-storagecluster-storagesystem
  namespace: openshift-storage
spec:
  kind: storagecluster.ocs.openshift.io/v1
  name: ocs-storagecluster
  namespace: openshift-storage
EOF
Create the StorageCluster with stretch configuration:
cat << EOF | oc apply -f -
apiVersion: ocs.openshift.io/v1
kind: StorageCluster
metadata:
  name: ocs-storagecluster
  namespace: openshift-storage
spec:
  arbiter:
    enable: true
  nodeTopologies:
    arbiterLocation: zone-3
  storageDeviceSets:
  - count: 1
    dataPVCTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 100Gi
        storageClassName: gp3-csi
        volumeMode: Block
    name: ocs-deviceset-gp3-csi
    placement:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: cluster.ocs.openshift.io/openshift-storage
              operator: Exists
      tolerations:
      - effect: NoSchedule
        key: node.ocs.openshift.io/storage
        operator: Equal
        value: "true"
    portable: true
    replica: 2
  version: 4.14.0
  flexibleScaling: true
  storageClassName: ocs-storagecluster-ceph-rbd
  managedResources:
    cephBlockPools:
      reconcileStrategy: manage
    cephFilesystems:
      reconcileStrategy: manage
    cephObjectStoreUsers:
      reconcileStrategy: manage
    cephObjectStores:
      reconcileStrategy: manage
EOF
Monitor the StorageCluster deployment:
# Watch the StorageCluster status
oc get storagecluster -n openshift-storage -w

# Check pod deployment across zones
oc get pods -n openshift-storage -o wide
Task 2: Validate Multi-Zone Redundancy and Failover
Subtask 2.1: Verify Stretch Cluster Configuration
Let's validate that our stretch cluster is properly configured and data is replicated across zones.

Check Ceph cluster status:
# Get into the Ceph toolbox
TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc rsh -n openshift-storage $TOOLS_POD

# Inside the toolbox, check cluster status
ceph status
ceph osd tree
ceph osd crush tree
Verify stretch mode configuration:
# Still inside the toolbox
ceph mon dump
ceph osd pool ls detail
ceph pg dump | head -20
Exit the toolbox and check ODF components:
# Exit the toolbox
exit

# Check StorageCluster status
oc describe storagecluster ocs-storagecluster -n openshift-storage

# Verify storage classes
oc get storageclass | grep ocs
Subtask 2.2: Test Data Replication
Now we'll create test workloads to verify data replication across zones.

Create a test namespace and application:
# Create test namespace
oc create namespace stretch-test

# Create a PVC using ODF storage
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc-zone1
  namespace: stretch-test
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Deploy a test pod in zone 1:
cat << EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-writer-zone1
  namespace: stretch-test
spec:
  nodeSelector:
    topology.kubernetes.io/zone: zone-1
  containers:
  - name: writer
    image: registry.redhat.io/ubi8/ubi:latest
    command:
    - /bin/bash
    - -c
    - |
      while true; do
        echo "Data written at $(date) from zone-1" >> /data/test-file.txt
        sleep 30
      done
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: test-pvc-zone1
  restartPolicy: Always
EOF
Create a reader pod in zone 2:
cat << EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-reader-zone2
  namespace: stretch-test
spec:
  nodeSelector:
    topology.kubernetes.io/zone: zone-2
  containers:
  - name: reader
    image: registry.redhat.io/ubi8/ubi:latest
    command:
    - /bin/bash
    - -c
    - |
      while true; do
        if [ -f /data/test-file.txt ]; then
          echo "Reading from zone-2:"
          tail -5 /data/test-file.txt
        else
          echo "File not found, waiting..."
        fi
        sleep 60
      done
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: test-pvc-zone1
  restartPolicy: Always
EOF
Monitor data replication:
# Check if pods are running
oc get pods -n stretch-test -o wide

# Check logs from writer
oc logs -f test-writer-zone1 -n stretch-test

# In another terminal, check logs from reader
oc logs -f test-reader-zone2 -n stretch-test
Subtask 2.3: Validate Zone Affinity and Anti-Affinity
Let's verify that ODF components are properly distributed across zones.

Check OSD distribution:
# Check where OSDs are running
oc get pods -n openshift-storage -l app=rook-ceph-osd -o wide

# Verify mon distribution
oc get pods -n openshift-storage -l app=rook-ceph-mon -o wide

# Check MGR distribution
oc get pods -n openshift-storage -l app=rook-ceph-mgr -o wide
Verify Ceph placement groups:
# Get back into the toolbox
TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc rsh -n openshift-storage $TOOLS_POD

# Check PG distribution
ceph pg ls-by-pool ocs-storagecluster-cephblockpool
ceph osd df tree
Task 3: Perform Disaster Recovery Tests
Subtask 3.1: Simulate Zone Failure
Now we'll test the disaster recovery capabilities by simulating a zone failure.

Identify nodes in zone 1:
# Get nodes in zone 1
ZONE1_NODES=$(oc get nodes -l topology.kubernetes.io/zone=zone-1 -o jsonpath='{.items[*].metadata.name}')
echo "Zone 1 nodes: $ZONE1_NODES"
Simulate zone 1 failure by cordoning nodes:
# Cordon all nodes in zone 1
for node in $ZONE1_NODES; do
  oc adm cordon $node
  echo "Cordoned node: $node"
done

# Verify nodes are cordoned
oc get nodes -l topology.kubernetes.io/zone=zone-1
Force pod eviction from zone 1:
# Drain nodes in zone 1 (this will move pods to other zones)
for node in $ZONE1_NODES; do
  oc adm drain $node --ignore-daemonsets --delete-emptydir-data --force --timeout=300s
done
Subtask 3.2: Monitor Failover Process
Let's monitor how the system responds to the zone failure.

Watch pod redistribution:
# Monitor ODF pods during failover
watch "oc get pods -n openshift-storage -o wide | grep -E '(osd|mon|mgr)'"
Check Ceph cluster health during failover:
# Get into toolbox (may need to wait for it to reschedule)
TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc rsh -n openshift-storage $TOOLS_POD

# Monitor cluster health
ceph status
ceph health detail
Verify application continuity:
# Check if our test application is still working
oc get pods -n stretch-test -o wide

# Check if data is still accessible
oc logs test-reader-zone2 -n stretch-test --tail=10
Subtask 3.3: Test Data Accessibility During Outage
Let's verify that applications can still access data even with one zone down.

Create a new application in zone 2:
cat << EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: emergency-reader
  namespace: stretch-test
spec:
  nodeSelector:
    topology.kubernetes.io/zone: zone-2
  containers:
  - name: reader
    image: registry.redhat.io/ubi8/ubi:latest
    command:
    - /bin/bash
    - -c
    - |
      echo "Emergency reader started at $(date)"
      if [ -f /data/test-file.txt ]; then
        echo "Data is accessible during zone failure:"
        cat /data/test-file.txt
      else
        echo "Data not accessible!"
      fi
      sleep 3600
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: test-pvc-zone1
  restartPolicy: Never
EOF
Verify data accessibility:
# Check emergency reader logs
oc logs emergency-reader -n stretch-test

# Try to create a new PVC during the outage
cat << EOF | oc apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc-during-outage
  namespace: stretch-test
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: ocs-storagecluster-ceph-rbd
EOF
Subtask 3.4: Perform Zone Recovery
Now let's simulate the recovery of the failed zone.

Uncordon zone 1 nodes:
# Uncordon all nodes in zone 1
for node in $ZONE1_NODES; do
  oc adm uncordon $node
  echo "Uncordoned node: $node"
done

# Verify nodes are ready
oc get nodes -l topology.kubernetes.io/zone=zone-1
Monitor cluster rebalancing:
# Watch as pods redistribute
oc get pods -n openshift-storage -o wide

# Monitor Ceph rebalancing
TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc rsh -n openshift-storage $TOOLS_POD

# Inside toolbox
ceph status
ceph pg stat
Verify full recovery:
# Check cluster health
ceph health
ceph osd tree

# Verify all OSDs are up
ceph osd stat
Subtask 3.5: Performance Impact Analysis
Let's analyze the performance impact during the disaster recovery test.

Create a performance test:
cat << EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: performance-test
  namespace: stretch-test
spec:
  containers:
  - name: fio
    image: quay.io/openshift/origin-tests:latest
    command:
    - /bin/bash
    - -c
    - |
      echo "Starting performance test..."
      fio --name=test --ioengine=libaio --rw=randrw --bs=4k --numjobs=4 \
          --size=1G --runtime=300 --group_reporting --filename=/data/testfile \
          --direct=1 --time_based --output-format=json > /tmp/results.json
      cat /tmp/results.json
      sleep 3600
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: test-pvc-during-outage
  restartPolicy: Never
EOF
Monitor performance results:
# Check performance test results
oc logs performance-test -n stretch-test
Monitoring and Troubleshooting
Common Issues and Solutions
StorageCluster not reaching Ready state:
# Check events
oc get events -n openshift-storage --sort-by='.lastTimestamp'

# Check operator logs
oc logs -n openshift-storage deployment/ocs-operator

# Verify node labels
oc get nodes --show-labels | grep storage
Pods stuck in Pending state:
# Check pod events
oc describe pod <pod-name> -n openshift-storage

# Verify resource availability
oc describe nodes | grep -A 5 "Allocated resources"
Ceph cluster warnings:
# Get detailed health information
TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc rsh -n openshift-storage $TOOLS_POD
ceph health detail
ceph log last 20
Monitoring Commands
# Monitor StorageCluster status
oc get storagecluster -n openshift-storage -w

# Check all ODF-related pods
oc get pods -n openshift-storage

# Monitor PVC status
oc get pvc -A

# Check storage utilization
oc get cephcluster -n openshift-storage -o yaml
Cleanup
To clean up the lab environment:

Remove test applications:
oc delete namespace stretch-test
Remove StorageCluster (optional, if you want to completely clean up):
oc delete storagecluster ocs-storagecluster -n openshift-storage
Remove node labels:
oc label nodes -l cluster.ocs.openshift.io/openshift-storage cluster.ocs.openshift.io/openshift-storage-
Conclusion
In this lab, you have successfully:

Configured ODF stretch clusters across multiple availability zones, providing enhanced data resilience and availability
Validated multi-zone redundancy by verifying data replication and component distribution across zones
Performed comprehensive disaster recovery tests including zone failure simulation and recovery procedures
Analyzed performance impact during failure scenarios and recovery operations
Gained hands-on experience with enterprise-grade storage disaster recovery practices
Why This Matters: Stretch clusters are critical for enterprise environments that require high availability and disaster recovery capabilities. By distributing storage across multiple availability zones, organizations can:

Maintain service availability even during complete zone failures
Ensure data durability through automatic cross-zone replication
Meet compliance requirements for disaster recovery and business continuity
Reduce recovery time objectives (RTO) through automated failover mechanisms
The skills you've developed in this lab are essential for managing production OpenShift environments where data availability and disaster recovery are business-critical requirements. Understanding stretch cluster configuration and management is a key competency for the Red Hat Certified Specialist in OpenShift Data Foundation certification and real-world enterprise storage operations.
