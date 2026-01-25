Lab 19: Debugging and Troubleshooting Pipelines
Objectives
By the end of this lab, you will be able to:

• Use the tkn CLI to inspect and troubleshoot failing Tekton pipelines • Analyze OpenShift logs to identify root causes of pipeline failures • Diagnose issues with failed tasks and understand retry mechanisms • Implement effective fixes for common pipeline problems • Successfully rerun pipelines after applying corrections • Apply systematic debugging approaches to CI/CD pipeline issues

Prerequisites
Before starting this lab, you should have:

• Basic understanding of Kubernetes and OpenShift concepts • Familiarity with YAML syntax and structure • Knowledge of containerization and Docker concepts • Understanding of CI/CD pipeline fundamentals • Experience with command-line interfaces • Completion of previous Tekton pipeline labs (recommended)

Ready-to-Use Cloud Machines
Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to access your environment. No need to build your own VM or install additional software - everything is ready to use!

Your lab environment includes: • OpenShift cluster with Tekton Pipelines installed • tkn CLI tool pre-configured • oc CLI tool for OpenShift operations • Sample applications and pipeline definitions • All required permissions and access configured

Lab Environment Setup
Task 1: Verify Lab Environment and Tools
Subtask 1.1: Check OpenShift Connection
First, let's verify that your OpenShift environment is ready and accessible.

# Check OpenShift connection
oc whoami

# Verify cluster information
oc cluster-info

# Check current project
oc project
Subtask 1.2: Verify Tekton Installation
Confirm that Tekton Pipelines is properly installed in your cluster.

# Check Tekton Pipelines installation
oc get pods -n openshift-pipelines

# Verify tkn CLI version
tkn version

# List available Tekton resources
tkn pipeline list
tkn task list
Subtask 1.3: Create Working Project
Create a dedicated project for this debugging lab.

# Create new project
oc new-project pipeline-debug-lab

# Verify project creation
oc project pipeline-debug-lab
Task 1: Use tkn CLI and OpenShift Logs to Troubleshoot Failing Pipelines
Subtask 1.1: Create a Deliberately Failing Pipeline
Let's create a pipeline with intentional issues to practice debugging techniques.

# Create a task with potential failure points
cat << 'EOF' > failing-task.yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: failing-build-task
spec:
  params:
    - name: image-name
      type: string
      default: "my-app"
    - name: dockerfile-path
      type: string
      default: "./Dockerfile"
  workspaces:
    - name: source
  steps:
    - name: check-dockerfile
      image: registry.redhat.io/ubi8/ubi:latest
      workingDir: $(workspaces.source.path)
      script: |
        #!/bin/bash
        echo "Checking for Dockerfile..."
        if [ ! -f "$(params.dockerfile-path)" ]; then
          echo "ERROR: Dockerfile not found at $(params.dockerfile-path)"
          exit 1
        fi
        echo "Dockerfile found successfully"
    
    - name: build-image
      image: registry.redhat.io/ubi8/buildah:latest
      workingDir: $(workspaces.source.path)
      securityContext:
        privileged: true
      script: |
        #!/bin/bash
        echo "Building container image..."
        buildah build -t $(params.image-name) -f $(params.dockerfile-path) .
        echo "Build completed successfully"
    
    - name: failing-step
      image: registry.redhat.io/ubi8/ubi:latest
      script: |
        #!/bin/bash
        echo "This step will fail intentionally..."
        nonexistent_command_that_will_fail
        echo "This line will never be reached"
EOF

# Apply the failing task
oc apply -f failing-task.yaml
Subtask 1.2: Create a Pipeline Using the Failing Task
# Create a pipeline that uses our failing task
cat << 'EOF' > failing-pipeline.yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: debug-pipeline
spec:
  params:
    - name: git-url
      type: string
      default: "https://github.com/openshift/nodejs-ex.git"
    - name: image-name
      type: string
      default: "debug-app"
  workspaces:
    - name: shared-workspace
  tasks:
    - name: git-clone
      taskRef:
        name: git-clone
        kind: ClusterTask
      params:
        - name: url
          value: $(params.git-url)
      workspaces:
        - name: output
          workspace: shared-workspace
    
    - name: failing-build
      taskRef:
        name: failing-build-task
      params:
        - name: image-name
          value: $(params.image-name)
        - name: dockerfile-path
          value: "./Dockerfile.missing"
      workspaces:
        - name: source
          workspace: shared-workspace
      runAfter:
        - git-clone
EOF

# Apply the pipeline
oc apply -f failing-pipeline.yaml
Subtask 1.3: Create Workspace and Run the Pipeline
# Create a PersistentVolumeClaim for workspace
cat << 'EOF' > workspace-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: debug-workspace-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# Apply the PVC
oc apply -f workspace-pvc.yaml

# Run the pipeline
tkn pipeline start debug-pipeline \
  --param git-url=https://github.com/openshift/nodejs-ex.git \
  --param image-name=debug-app \
  --workspace name=shared-workspace,claimName=debug-workspace-pvc \
  --showlog
Subtask 1.4: Use tkn CLI for Initial Troubleshooting
Now let's use the tkn CLI to investigate the pipeline failure.

# List recent pipeline runs
tkn pipelinerun list

# Get detailed information about the latest run
LATEST_RUN=$(tkn pipelinerun list -o name | head -1 | cut -d'/' -f2)
echo "Latest pipeline run: $LATEST_RUN"

# Describe the pipeline run
tkn pipelinerun describe $LATEST_RUN

# Check the logs of the failed pipeline run
tkn pipelinerun logs $LATEST_RUN

# List task runs for this pipeline run
tkn taskrun list --label tekton.dev/pipelineRun=$LATEST_RUN
Subtask 1.5: Analyze Task-Level Failures
# Get the failed task run name
FAILED_TASKRUN=$(tkn taskrun list --label tekton.dev/pipelineRun=$LATEST_RUN -o name | grep failing-build | cut -d'/' -f2)
echo "Failed task run: $FAILED_TASKRUN"

# Describe the failed task run
tkn taskrun describe $FAILED_TASKRUN

# Get detailed logs from the failed task
tkn taskrun logs $FAILED_TASKRUN

# Check specific step logs
tkn taskrun logs $FAILED_TASKRUN --step check-dockerfile
tkn taskrun logs $FAILED_TASKRUN --step failing-step
Subtask 1.6: Use OpenShift Logs for Deeper Analysis
# Get the pod associated with the failed task run
FAILED_POD=$(oc get pods -l tekton.dev/taskRun=$FAILED_TASKRUN -o name)
echo "Failed pod: $FAILED_POD"

# Get detailed pod information
oc describe $FAILED_POD

# Check pod logs using OpenShift CLI
oc logs $FAILED_POD --all-containers=true

# Check logs for specific containers
oc logs $FAILED_POD -c step-check-dockerfile
oc logs $FAILED_POD -c step-failing-step

# Check pod events
oc get events --field-selector involvedObject.name=${FAILED_POD#pod/}
Task 2: Diagnose Issues with Failed Tasks and Retries
Subtask 2.1: Analyze Common Failure Patterns
Let's examine different types of failures and their characteristics.

# Create a task with multiple failure scenarios
cat << 'EOF' > diagnostic-task.yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: diagnostic-task
spec:
  params:
    - name: failure-type
      type: string
      default: "none"
  steps:
    - name: resource-check
      image: registry.redhat.io/ubi8/ubi:latest
      script: |
        #!/bin/bash
        echo "Checking system resources..."
        df -h
        free -m
        echo "Resource check completed"
    
    - name: conditional-failure
      image: registry.redhat.io/ubi8/ubi:latest
      script: |
        #!/bin/bash
        case "$(params.failure-type)" in
          "command-not-found")
            echo "Simulating command not found error..."
            nonexistent_command
            ;;
          "permission-denied")
            echo "Simulating permission denied error..."
            touch /root/test-file
            chmod 000 /root/test-file
            cat /root/test-file
            ;;
          "timeout")
            echo "Simulating timeout..."
            sleep 300
            ;;
          "resource-limit")
            echo "Simulating resource exhaustion..."
            dd if=/dev/zero of=/tmp/bigfile bs=1M count=10000
            ;;
          *)
            echo "No failure simulation requested"
            ;;
        esac
        echo "Step completed successfully"
EOF

# Apply the diagnostic task
oc apply -f diagnostic-task.yaml
Subtask 2.2: Test Different Failure Scenarios
# Test command not found error
tkn task start diagnostic-task \
  --param failure-type=command-not-found \
  --showlog

# Wait for completion and analyze
sleep 30
DIAG_TASKRUN=$(tkn taskrun list -o name | head -1 | cut -d'/' -f2)
tkn taskrun describe $DIAG_TASKRUN

# Test permission denied error
tkn task start diagnostic-task \
  --param failure-type=permission-denied \
  --showlog
Subtask 2.3: Implement and Test Retry Mechanisms
# Create a task with retry configuration
cat << 'EOF' > retry-task.yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: retry-task
spec:
  params:
    - name: max-attempts
      type: string
      default: "3"
  steps:
    - name: flaky-operation
      image: registry.redhat.io/ubi8/ubi:latest
      script: |
        #!/bin/bash
        ATTEMPT_FILE="/tmp/attempt_count"
        
        # Initialize or increment attempt counter
        if [ -f "$ATTEMPT_FILE" ]; then
          ATTEMPT=$(cat $ATTEMPT_FILE)
          ATTEMPT=$((ATTEMPT + 1))
        else
          ATTEMPT=1
        fi
        echo $ATTEMPT > $ATTEMPT_FILE
        
        echo "Attempt #$ATTEMPT"
        
        # Fail on first two attempts, succeed on third
        if [ $ATTEMPT -lt 3 ]; then
          echo "Simulating transient failure on attempt $ATTEMPT"
          exit 1
        else
          echo "Success on attempt $ATTEMPT!"
          exit 0
        fi
EOF

# Apply the retry task
oc apply -f retry-task.yaml

# Create a pipeline with retry configuration
cat << 'EOF' > retry-pipeline.yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: retry-pipeline
spec:
  tasks:
    - name: retry-test
      taskRef:
        name: retry-task
      retries: 2
EOF

# Apply and run the retry pipeline
oc apply -f retry-pipeline.yaml
tkn pipeline start retry-pipeline --showlog
Subtask 2.4: Monitor Retry Behavior
# Monitor the retry pipeline execution
RETRY_RUN=$(tkn pipelinerun list -o name | head -1 | cut -d'/' -f2)

# Watch the pipeline run status
watch -n 5 "tkn pipelinerun describe $RETRY_RUN | grep -A 10 'Status'"

# After completion, analyze retry attempts
tkn pipelinerun logs $RETRY_RUN

# Check individual task run attempts
tkn taskrun list --label tekton.dev/pipelineRun=$RETRY_RUN
Task 3: Implement Fixes and Rerun Pipelines
Subtask 3.1: Fix the Original Failing Pipeline
Now let's fix the issues we identified in our original failing pipeline.

# Create a corrected version of the failing task
cat << 'EOF' > fixed-task.yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: fixed-build-task
spec:
  params:
    - name: image-name
      type: string
      default: "my-app"
    - name: dockerfile-path
      type: string
      default: "./Dockerfile"
  workspaces:
    - name: source
  steps:
    - name: check-dockerfile
      image: registry.redhat.io/ubi8/ubi:latest
      workingDir: $(workspaces.source.path)
      script: |
        #!/bin/bash
        echo "Checking for Dockerfile..."
        
        # Check multiple possible Dockerfile locations
        DOCKERFILE_PATHS=("$(params.dockerfile-path)" "./Dockerfile" "./docker/Dockerfile" "./build/Dockerfile")
        
        FOUND_DOCKERFILE=""
        for path in "${DOCKERFILE_PATHS[@]}"; do
          if [ -f "$path" ]; then
            FOUND_DOCKERFILE="$path"
            echo "Found Dockerfile at: $path"
            break
          fi
        done
        
        if [ -z "$FOUND_DOCKERFILE" ]; then
          echo "No Dockerfile found. Creating a simple one..."
          cat << 'DOCKERFILE' > ./Dockerfile
        FROM registry.redhat.io/ubi8/nodejs-14:latest
        COPY . /app
        WORKDIR /app
        RUN npm install
        EXPOSE 8080
        CMD ["npm", "start"]
        DOCKERFILE
          echo "Created default Dockerfile"
          FOUND_DOCKERFILE="./Dockerfile"
        fi
        
        # Save the found dockerfile path for next step
        echo "$FOUND_DOCKERFILE" > /tmp/dockerfile-path
    
    - name: validate-dockerfile
      image: registry.redhat.io/ubi8/ubi:latest
      workingDir: $(workspaces.source.path)
      script: |
        #!/bin/bash
        DOCKERFILE_PATH=$(cat /tmp/dockerfile-path)
        echo "Validating Dockerfile at: $DOCKERFILE_PATH"
        
        # Basic Dockerfile validation
        if grep -q "FROM" "$DOCKERFILE_PATH"; then
          echo "Dockerfile validation passed"
        else
          echo "ERROR: Invalid Dockerfile format"
          exit 1
        fi
    
    - name: success-step
      image: registry.redhat.io/ubi8/ubi:latest
      script: |
        #!/bin/bash
        echo "All checks passed successfully!"
        echo "Build task completed without errors"
EOF

# Apply the fixed task
oc apply -f fixed-task.yaml
Subtask 3.2: Create an Improved Pipeline
# Create an improved pipeline with better error handling
cat << 'EOF' > improved-pipeline.yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: improved-pipeline
spec:
  params:
    - name: git-url
      type: string
      default: "https://github.com/openshift/nodejs-ex.git"
    - name: image-name
      type: string
      default: "improved-app"
  workspaces:
    - name: shared-workspace
  tasks:
    - name: git-clone
      taskRef:
        name: git-clone
        kind: ClusterTask
      params:
        - name: url
          value: $(params.git-url)
      workspaces:
        - name: output
          workspace: shared-workspace
      retries: 1
    
    - name: fixed-build
      taskRef:
        name: fixed-build-task
      params:
        - name: image-name
          value: $(params.image-name)
        - name: dockerfile-path
          value: "./Dockerfile"
      workspaces:
        - name: source
          workspace: shared-workspace
      runAfter:
        - git-clone
      retries: 1
    
    - name: cleanup
      taskRef:
        name: cleanup-task
      workspaces:
        - name: source
          workspace: shared-workspace
      runAfter:
        - fixed-build
  finally:
    - name: notification
      taskRef:
        name: notification-task
      params:
        - name: message
          value: "Pipeline $(context.pipelineRun.name) completed with status: $(tasks.status)"
EOF

# Create supporting tasks for the improved pipeline
cat << 'EOF' > cleanup-task.yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: cleanup-task
spec:
  workspaces:
    - name: source
  steps:
    - name: cleanup
      image: registry.redhat.io/ubi8/ubi:latest
      workingDir: $(workspaces.source.path)
      script: |
        #!/bin/bash
        echo "Performing cleanup operations..."
        
        # Remove temporary files
        find . -name "*.tmp" -delete
        find . -name "*.log" -delete
        
        # Clean up build artifacts
        rm -rf ./node_modules/.cache
        
        echo "Cleanup completed successfully"
EOF

cat << 'EOF' > notification-task.yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: notification-task
spec:
  params:
    - name: message
      type: string
  steps:
    - name: notify
      image: registry.redhat.io/ubi8/ubi:latest
      script: |
        #!/bin/bash
        echo "==================================="
        echo "PIPELINE NOTIFICATION"
        echo "==================================="
        echo "Message: $(params.message)"
        echo "Timestamp: $(date)"
        echo "==================================="
EOF

# Apply all the improved components
oc apply -f improved-pipeline.yaml
oc apply -f cleanup-task.yaml
oc apply -f notification-task.yaml
Subtask 3.3: Run the Improved Pipeline
# Run the improved pipeline
tkn pipeline start improved-pipeline \
  --param git-url=https://github.com/openshift/nodejs-ex.git \
  --param image-name=improved-app \
  --workspace name=shared-workspace,claimName=debug-workspace-pvc \
  --showlog

# Monitor the pipeline execution
IMPROVED_RUN=$(tkn pipelinerun list -o name | head -1 | cut -d'/' -f2)
echo "Improved pipeline run: $IMPROVED_RUN"

# Watch the pipeline progress
watch -n 10 "tkn pipelinerun describe $IMPROVED_RUN"
Subtask 3.4: Compare Results and Analyze Improvements
# Compare the original failing run with the improved run
echo "=== ORIGINAL FAILING PIPELINE ==="
ORIGINAL_RUN=$(tkn pipelinerun list | grep debug-pipeline | head -1 | awk '{print $1}')
tkn pipelinerun describe $ORIGINAL_RUN | grep -A 5 "Status"

echo "=== IMPROVED PIPELINE ==="
tkn pipelinerun describe $IMPROVED_RUN | grep -A 5 "Status"

# Show detailed comparison
echo "=== TASK COMPARISON ==="
echo "Original pipeline tasks:"
tkn taskrun list --label tekton.dev/pipelineRun=$ORIGINAL_RUN

echo "Improved pipeline tasks:"
tkn taskrun list --label tekton.dev/pipelineRun=$IMPROVED_RUN

# Generate a debugging report
cat << 'EOF' > generate-debug-report.sh
#!/bin/bash

PIPELINE_RUN=$1
if [ -z "$PIPELINE_RUN" ]; then
  echo "Usage: $0 <pipeline-run-name>"
  exit 1
fi

echo "=========================================="
echo "PIPELINE DEBUGGING REPORT"
echo "Pipeline Run: $PIPELINE_RUN"
echo "Generated: $(date)"
echo "=========================================="

echo ""
echo "1. PIPELINE RUN OVERVIEW:"
tkn pipelinerun describe $PIPELINE_RUN

echo ""
echo "2. TASK RUNS STATUS:"
tkn taskrun list --label tekton.dev/pipelineRun=$PIPELINE_RUN

echo ""
echo "3. FAILED TASKS ANALYSIS:"
FAILED_TASKS=$(tkn taskrun list --label tekton.dev/pipelineRun=$PIPELINE_RUN -o json | jq -r '.items[] | select(.status.conditions[0].status == "False") | .metadata.name')

for task in $FAILED_TASKS; do
  echo "--- Failed Task: $task ---"
  tkn taskrun describe $task
  echo ""
  echo "Task Logs:"
  tkn taskrun logs $task
  echo ""
done

echo ""
echo "4. RESOURCE USAGE:"
oc get pods -l tekton.dev/pipelineRun=$PIPELINE_RUN -o custom-columns=NAME:.metadata.name,CPU:.spec.containers[0].resources.requests.cpu,MEMORY:.spec.containers[0].resources.requests.memory

echo ""
echo "5. EVENTS:"
oc get events --field-selector reason=Failed

echo "=========================================="
echo "END OF REPORT"
echo "=========================================="
EOF

chmod +x generate-debug-report.sh

# Generate reports for both pipeline runs
./generate-debug-report.sh $ORIGINAL_RUN > original-pipeline-report.txt
./generate-debug-report.sh $IMPROVED_RUN > improved-pipeline-report.txt

echo "Debug reports generated:"
echo "- original-pipeline-report.txt"
echo "- improved-pipeline-report.txt"
Subtask 3.5: Implement Advanced Debugging Techniques
# Create a comprehensive debugging task
cat << 'EOF' > debug-helper-task.yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: debug-helper-task
spec:
  params:
    - name: debug-level
      type: string
      default: "info"
  workspaces:
    - name: source
  steps:
    - name: environment-info
      image: registry.redhat.io/ubi8/ubi:latest
      script: |
        #!/bin/bash
        echo "=== ENVIRONMENT DEBUGGING INFO ==="
        echo "Debug Level: $(params.debug-level)"
        echo "Hostname: $(hostname)"
        echo "User: $(whoami)"
        echo "Working Directory: $(pwd)"
        echo "Environment Variables:"
        env | sort
        echo ""
        echo "=== SYSTEM RESOURCES ==="
        echo "Disk Usage:"
        df -h
        echo ""
        echo "Memory Usage:"
        free -m
        echo ""
        echo "CPU Info:"
        cat /proc/cpuinfo | grep "model name" | head -1
        echo ""
    
    - name: workspace-analysis
      image: registry.redhat.io/ubi8/ubi:latest
      workingDir: $(workspaces.source.path)
      script: |
        #!/bin/bash
        echo "=== WORKSPACE ANALYSIS ==="
        echo "Workspace Path: $(workspaces.source.path)"
        echo "Directory Contents:"
        ls -la
        echo ""
        echo "File Types:"
        find . -type f | head -20
        echo ""
        echo "Directory Structure:"
        tree -L 3 2>/dev/null || find . -type d | head -10
        echo ""
    
    - name: network-connectivity
      image: registry.redhat.io/ubi8/ubi:latest
      script: |
        #!/bin/bash
        echo "=== NETWORK CONNECTIVITY ==="
        echo "DNS Resolution:"
        nslookup google.com || echo "DNS resolution failed"
        echo ""
        echo "External Connectivity:"
        curl -s --connect-timeout 5 https://httpbin.org/ip || echo "External connectivity failed"
        echo ""
EOF

# Apply the debug helper task
oc apply -f debug-helper-task.yaml

# Create a pipeline that includes debugging
cat << 'EOF' > debug-enabled-pipeline.yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: debug-enabled-pipeline
spec:
  params:
    - name: git-url
      type: string
      default: "https://github.com/openshift/nodejs-ex.git"
    - name: debug-enabled
      type: string
      default: "true"
  workspaces:
    - name: shared-workspace
  tasks:
    - name: debug-info
      taskRef:
        name: debug-helper-task
      params:
        - name: debug-level
          value: "verbose"
      workspaces:
        - name: source
          workspace: shared-workspace
      when:
        - input: "$(params.debug-enabled)"
          operator: in
          values: ["true"]
    
    - name: git-clone
      taskRef:
        name: git-clone
        kind: ClusterTask
      params:
        - name: url
          value: $(params.git-url)
      workspaces:
        - name: output
          workspace: shared-workspace
      runAfter:
        - debug-info
    
    - name: post-clone-debug
      taskRef:
        name: debug-helper-task
      params:
        - name: debug-level
          value: "info"
      workspaces:
        - name: source
          workspace: shared-workspace
      runAfter:
        - git-clone
      when:
        - input: "$(params.debug-enabled)"
          operator: in
          values: ["true"]
EOF

# Apply and run the debug-enabled pipeline
oc apply -f debug-enabled-pipeline.yaml

tkn pipeline start debug-enabled-pipeline \
  --param git-url=https://github.com/openshift/nodejs-ex.git \
  --param debug-enabled=true \
  --workspace name=shared-workspace,claimName=debug-workspace-pvc \
  --showlog
Advanced Troubleshooting Techniques
Subtask 3.6: Create Debugging Utilities
# Create a comprehensive debugging script
cat << 'EOF' > pipeline-debugger.sh
#!/bin/bash

# Pipeline Debugger Script
# Usage: ./pipeline-debugger.sh [pipeline-run-name]

set -e

PIPELINE_RUN=${1:-$(tkn pipelinerun list -o name | head -1 | cut -d'/' -f2)}

if [ -z "$PIPELINE_RUN" ]; then
    echo "No pipeline run specified and none found"
    exit 1
fi

echo "🔍 Debugging Pipeline Run: $PIPELINE_RUN"
echo "=================================================="

# Function to print section headers
print_section() {
    echo ""
    echo "📋 $1"
    echo "----------------------------------------"
}

# 1. Basic Pipeline Run Information
print_section "PIPELINE RUN OVERVIEW"
tkn pipelinerun describe $PIPELINE_RUN

# 2. Task Run Status
print_section "TASK RUNS STATUS"
tkn taskrun list --label tekton.dev/pipelineRun=$PIPELINE_RUN

# 3. Failed Tasks Analysis
print_section "FAILED TASKS ANALYSIS"
FAILED_TASKS=$(oc get taskruns -l tekton.dev/pipelineRun=$PIPELINE_RUN -o jsonpath='{.items[?(@.status.conditions[0].status=="False")].metadata.name}')

if [ -n "$FAILED_TASKS" ]; then
    for task in $FAILED_TASKS; do
        echo "❌ Failed Task: $task"
        echo "Task Description:"
        tkn taskrun describe $task | grep -A 10 "Status"
        echo ""
        echo "Task Logs:"
        tkn taskrun logs $task 2>/dev/null || echo "No logs available"
        echo ""
        echo "Associated Pod Events:"
        POD_NAME=$(oc get taskrun $task -o jsonpath='{.status.podName}')
        if [ -n "$POD_NAME" ]; then
            oc get events --field-selector involvedObject.name=$POD_NAME
        fi
        echo "----------------------------------------"
    done
else
    echo "✅ No failed tasks found"
fi

# 4. Resource Usage Analysis
print_section "RESOURCE USAGE"
PODS=$(oc get pods -l tekton.dev/pipelineRun=$PIPELINE_RUN -o name)
for pod in $PODS; do
    POD_NAME=${pod#pod/}
    echo "Pod: $POD_NAME"
    oc describe pod $POD_NAME | grep -A 5 "Requests\|Limits" || echo "No resource limits set"
    echo ""
done

# 5. Workspace Analysis
print_section "WORKSPACE ANALYSIS"
WORKSPACE_PODS=$(oc get pods -l tekton.dev/pipelineRun=$PIPELINE_RUN -o jsonpath='{.items[*].metadata.name}')
for pod in $WORKSPACE_PODS; do
    echo "Workspace mounts for pod $pod:"
    oc describe pod $pod | grep -A 3 "Mounts:" || echo "No workspace mounts found"
    echo ""
done

# 6. Timeline Analysis
print_section "EXECUTION TIMELINE"
echo "Pipeline Run Timeline:"
oc get pipelinerun $PIPELINE_RUN -o jsonpath='{.status.startTime}' | xargs -I {} echo "Started: {}"
oc get pipelinerun $PIPELINE_RUN -o jsonpath='{.status.completionTime}' | xargs -I {} echo "Completed: {}"

echo ""
echo "Task Execution Timeline:"
oc get taskruns -l tekton.dev/pipelineRun=$PIPELINE_RUN -o custom-columns=NAME:.metadata.name,STARTED:.status.startTime,COMPLETED:.status.completionTime

# 7. Recommendations
print_section "DEBUGGING RECOMMENDATIONS"
if [ -n "$FAILED_TASKS" ]; then
    echo "🔧 Recommended Actions:"
    echo "1. Check task logs for specific error messages"
    echo "2. Verify resource requirements and limits"
    echo "3. Ensure all required parameters are provided"
    echo "4. Check workspace permissions and availability"
    echo "5. Validate container images and their availability"
    echo "6. Review network connectivity if external resources are needed"
else
    echo "✅ Pipeline completed successfully!"
    echo "💡 Performance Tips:"
    echo "1. Consider adding resource limits for better scheduling"
    echo "2. Use parallel tasks where possible"
    echo "3. Implement proper retry strategies for transient failures"
fi

echo ""
echo "=================================================="
echo "🏁 Debugging Complete for Pipeline Run: $PIPELINE_RUN"
EOF

chmod +x pipeline-debugger.sh

# Run the debugger on our improved pipeline
./pipeline-debugger.sh $IMPROVED_RUN
Conclusion
Congratulations! You have successfully completed Lab 19: Debugging and Troubleshooting Pipelines. Throughout this comprehensive lab
