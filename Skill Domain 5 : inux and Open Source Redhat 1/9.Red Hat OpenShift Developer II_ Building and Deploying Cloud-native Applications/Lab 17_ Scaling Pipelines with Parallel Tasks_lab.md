Lab 17: Scaling Pipelines with Parallel Tasks
Objectives
By the end of this lab, students will be able to:

• Understand the concepts of parallel task execution in CI/CD pipelines • Configure Tekton pipelines to run multiple tasks simultaneously • Implement conditional logic to control when parallel tasks execute • Validate and monitor parallel task execution • Optimize pipeline performance through parallelization strategies • Troubleshoot common issues with parallel pipeline execution

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Kubernetes concepts (pods, services, deployments) • Familiarity with YAML syntax and structure • Previous experience with Tekton Pipelines (Labs 15-16 recommended) • Knowledge of Git version control basics • Understanding of CI/CD pipeline concepts • Basic command-line interface skills

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes: • OpenShift cluster with Tekton Pipelines installed • kubectl and oc CLI tools configured • Git client and text editors • Sample application code repository

Task 1: Understanding Parallel Task Execution
Subtask 1.1: Review Current Pipeline Structure
First, let's examine a basic sequential pipeline to understand how we can improve it with parallelization.

Access your lab environment by clicking the Start Lab button

Verify your cluster connection:

oc whoami
oc project
Create a new project for this lab:
oc new-project pipeline-parallel-lab
Create a basic sequential pipeline to serve as our starting point:
cat > sequential-pipeline.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: sequential-build-pipeline
  namespace: pipeline-parallel-lab
spec:
  params:
    - name: git-url
      type: string
      description: Git repository URL
    - name: git-revision
      type: string
      default: main
      description: Git revision to build
  workspaces:
    - name: shared-data
      description: Shared workspace for pipeline tasks
  tasks:
    - name: fetch-source
      taskRef:
        name: git-clone
        kind: ClusterTask
      workspaces:
        - name: output
          workspace: shared-data
      params:
        - name: url
          value: $(params.git-url)
        - name: revision
          value: $(params.git-revision)
    
    - name: code-analysis
      taskRef:
        name: code-quality-check
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - fetch-source
    
    - name: security-scan
      taskRef:
        name: security-scanner
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - code-analysis
    
    - name: unit-tests
      taskRef:
        name: run-tests
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - security-scan
    
    - name: build-image
      taskRef:
        name: buildah
        kind: ClusterTask
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - unit-tests
      params:
        - name: IMAGE
          value: "image-registry.openshift-image-registry.svc:5000/$(context.pipelineRun.namespace)/sample-app:latest"
EOF
Create the required custom tasks for our pipeline:
cat > code-quality-task.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: code-quality-check
  namespace: pipeline-parallel-lab
spec:
  workspaces:
    - name: source
      description: Source code workspace
  steps:
    - name: quality-check
      image: alpine:latest
      workingDir: $(workspaces.source.path)
      script: |
        #!/bin/sh
        echo "Running code quality analysis..."
        sleep 10  # Simulate analysis time
        echo "Code quality check completed successfully"
        echo "Quality Score: 85/100"
EOF
cat > security-scanner-task.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: security-scanner
  namespace: pipeline-parallel-lab
spec:
  workspaces:
    - name: source
      description: Source code workspace
  steps:
    - name: security-scan
      image: alpine:latest
      workingDir: $(workspaces.source.path)
      script: |
        #!/bin/sh
        echo "Running security vulnerability scan..."
        sleep 15  # Simulate scan time
        echo "Security scan completed"
        echo "No critical vulnerabilities found"
EOF
cat > test-runner-task.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: run-tests
  namespace: pipeline-parallel-lab
spec:
  workspaces:
    - name: source
      description: Source code workspace
  steps:
    - name: unit-tests
      image: alpine:latest
      workingDir: $(workspaces.source.path)
      script: |
        #!/bin/sh
        echo "Running unit tests..."
        sleep 12  # Simulate test execution time
        echo "All tests passed successfully"
        echo "Test Coverage: 92%"
EOF
Apply all task definitions:
oc apply -f code-quality-task.yaml
oc apply -f security-scanner-task.yaml
oc apply -f test-runner-task.yaml
Subtask 1.2: Analyze Sequential Execution Time
Apply the sequential pipeline:
oc apply -f sequential-pipeline.yaml
Create a PipelineRun to test the sequential execution:
cat > sequential-pipelinerun.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: sequential-run-1
  namespace: pipeline-parallel-lab
spec:
  pipelineRef:
    name: sequential-build-pipeline
  params:
    - name: git-url
      value: "https://github.com/openshift/ruby-hello-world.git"
    - name: git-revision
      value: "main"
  workspaces:
    - name: shared-data
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 1Gi
EOF
Execute the sequential pipeline:
oc apply -f sequential-pipelinerun.yaml
Monitor the execution time:
# Watch the pipeline execution
oc get pipelinerun sequential-run-1 -w

# Check detailed status
tkn pipelinerun describe sequential-run-1
Key Observation: Notice how each task waits for the previous one to complete, leading to longer total execution time.

Task 2: Implementing Parallel Task Execution
Subtask 2.1: Create a Parallel Pipeline
Now let's modify our pipeline to run compatible tasks in parallel, significantly reducing execution time.

Create the parallel pipeline configuration:
cat > parallel-pipeline.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: parallel-build-pipeline
  namespace: pipeline-parallel-lab
spec:
  params:
    - name: git-url
      type: string
      description: Git repository URL
    - name: git-revision
      type: string
      default: main
      description: Git revision to build
    - name: enable-security-scan
      type: string
      default: "true"
      description: Enable or disable security scanning
    - name: enable-quality-check
      type: string
      default: "true"
      description: Enable or disable code quality check
  workspaces:
    - name: shared-data
      description: Shared workspace for pipeline tasks
  tasks:
    # First task - must complete before parallel tasks
    - name: fetch-source
      taskRef:
        name: git-clone
        kind: ClusterTask
      workspaces:
        - name: output
          workspace: shared-data
      params:
        - name: url
          value: $(params.git-url)
        - name: revision
          value: $(params.git-revision)
    
    # Parallel tasks - can run simultaneously after source fetch
    - name: code-analysis
      taskRef:
        name: code-quality-check
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - fetch-source
      when:
        - input: "$(params.enable-quality-check)"
          operator: in
          values: ["true"]
    
    - name: security-scan
      taskRef:
        name: security-scanner
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - fetch-source
      when:
        - input: "$(params.enable-security-scan)"
          operator: in
          values: ["true"]
    
    - name: unit-tests
      taskRef:
        name: run-tests
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - fetch-source
    
    # Final task - waits for all parallel tasks to complete
    - name: build-image
      taskRef:
        name: buildah
        kind: ClusterTask
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - code-analysis
        - security-scan
        - unit-tests
      params:
        - name: IMAGE
          value: "image-registry.openshift-image-registry.svc:5000/$(context.pipelineRun.namespace)/sample-app:latest"
        - name: DOCKERFILE
          value: "./Dockerfile"
EOF
Apply the parallel pipeline:
oc apply -f parallel-pipeline.yaml
Subtask 2.2: Execute and Compare Parallel Performance
Create a PipelineRun for the parallel pipeline:
cat > parallel-pipelinerun.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: parallel-run-1
  namespace: pipeline-parallel-lab
spec:
  pipelineRef:
    name: parallel-build-pipeline
  params:
    - name: git-url
      value: "https://github.com/openshift/ruby-hello-world.git"
    - name: git-revision
      value: "main"
    - name: enable-security-scan
      value: "true"
    - name: enable-quality-check
      value: "true"
  workspaces:
    - name: shared-data
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 1Gi
EOF
Execute the parallel pipeline:
oc apply -f parallel-pipelinerun.yaml
Monitor parallel execution:
# Watch the pipeline execution
oc get pipelinerun parallel-run-1 -w

# Get detailed execution information
tkn pipelinerun describe parallel-run-1

# View logs from parallel tasks
tkn pipelinerun logs parallel-run-1 -f
Compare execution times:
# Check completion times
echo "Sequential Pipeline:"
oc get pipelinerun sequential-run-1 -o jsonpath='{.status.completionTime}' && echo
oc get pipelinerun sequential-run-1 -o jsonpath='{.status.startTime}' && echo

echo "Parallel Pipeline:"
oc get pipelinerun parallel-run-1 -o jsonpath='{.status.completionTime}' && echo
oc get pipelinerun parallel-run-1 -o jsonpath='{.status.startTime}' && echo
Task 3: Implementing Conditional Logic for Parallel Tasks
Subtask 3.1: Create Advanced Conditional Pipeline
Let's enhance our pipeline with more sophisticated conditional logic that controls parallel task execution based on various parameters.

Create an advanced conditional parallel pipeline:
cat > conditional-parallel-pipeline.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: conditional-parallel-pipeline
  namespace: pipeline-parallel-lab
spec:
  params:
    - name: git-url
      type: string
      description: Git repository URL
    - name: git-revision
      type: string
      default: main
      description: Git revision to build
    - name: environment
      type: string
      default: "development"
      description: Target environment (development, staging, production)
    - name: skip-tests
      type: string
      default: "false"
      description: Skip test execution
    - name: security-level
      type: string
      default: "standard"
      description: Security scan level (basic, standard, comprehensive)
  workspaces:
    - name: shared-data
      description: Shared workspace for pipeline tasks
  tasks:
    # Source fetch - always required
    - name: fetch-source
      taskRef:
        name: git-clone
        kind: ClusterTask
      workspaces:
        - name: output
          workspace: shared-data
      params:
        - name: url
          value: $(params.git-url)
        - name: revision
          value: $(params.git-revision)
    
    # Parallel analysis tasks with conditions
    - name: basic-code-analysis
      taskRef:
        name: code-quality-check
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - fetch-source
      when:
        - input: "$(params.environment)"
          operator: in
          values: ["development", "staging", "production"]
    
    - name: security-scan-basic
      taskRef:
        name: security-scanner
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - fetch-source
      when:
        - input: "$(params.security-level)"
          operator: in
          values: ["basic", "standard", "comprehensive"]
    
    - name: security-scan-comprehensive
      taskRef:
        name: comprehensive-security-scan
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - fetch-source
      when:
        - input: "$(params.security-level)"
          operator: in
          values: ["comprehensive"]
        - input: "$(params.environment)"
          operator: in
          values: ["staging", "production"]
    
    - name: unit-tests
      taskRef:
        name: run-tests
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - fetch-source
      when:
        - input: "$(params.skip-tests)"
          operator: in
          values: ["false"]
    
    - name: integration-tests
      taskRef:
        name: integration-tests
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - fetch-source
      when:
        - input: "$(params.environment)"
          operator: in
          values: ["staging", "production"]
        - input: "$(params.skip-tests)"
          operator: in
          values: ["false"]
    
    # Build task - conditional on environment
    - name: build-development
      taskRef:
        name: buildah
        kind: ClusterTask
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - basic-code-analysis
        - security-scan-basic
        - unit-tests
      when:
        - input: "$(params.environment)"
          operator: in
          values: ["development"]
      params:
        - name: IMAGE
          value: "image-registry.openshift-image-registry.svc:5000/$(context.pipelineRun.namespace)/sample-app:dev-latest"
    
    - name: build-production
      taskRef:
        name: buildah
        kind: ClusterTask
      workspaces:
        - name: source
          workspace: shared-data
      runAfter:
        - basic-code-analysis
        - security-scan-comprehensive
        - unit-tests
        - integration-tests
      when:
        - input: "$(params.environment)"
          operator: in
          values: ["production"]
      params:
        - name: IMAGE
          value: "image-registry.openshift-image-registry.svc:5000/$(context.pipelineRun.namespace)/sample-app:prod-$(params.git-revision)"
EOF
Create additional tasks for comprehensive testing:
cat > comprehensive-security-task.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: comprehensive-security-scan
  namespace: pipeline-parallel-lab
spec:
  workspaces:
    - name: source
      description: Source code workspace
  steps:
    - name: comprehensive-scan
      image: alpine:latest
      workingDir: $(workspaces.source.path)
      script: |
        #!/bin/sh
        echo "Running comprehensive security vulnerability scan..."
        echo "Scanning for OWASP Top 10 vulnerabilities..."
        sleep 20  # Simulate comprehensive scan time
        echo "Checking dependency vulnerabilities..."
        sleep 10
        echo "Comprehensive security scan completed"
        echo "Security report generated"
EOF
cat > integration-tests-task.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: integration-tests
  namespace: pipeline-parallel-lab
spec:
  workspaces:
    - name: source
      description: Source code workspace
  steps:
    - name: integration-tests
      image: alpine:latest
      workingDir: $(workspaces.source.path)
      script: |
        #!/bin/sh
        echo "Running integration tests..."
        echo "Testing API endpoints..."
        sleep 8
        echo "Testing database connections..."
        sleep 5
        echo "Integration tests completed successfully"
        echo "All integration tests passed"
EOF
Apply the new tasks and pipeline:
oc apply -f comprehensive-security-task.yaml
oc apply -f integration-tests-task.yaml
oc apply -f conditional-parallel-pipeline.yaml
Subtask 3.2: Test Different Conditional Scenarios
Test development environment scenario:
cat > dev-pipelinerun.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: dev-conditional-run
  namespace: pipeline-parallel-lab
spec:
  pipelineRef:
    name: conditional-parallel-pipeline
  params:
    - name: git-url
      value: "https://github.com/openshift/ruby-hello-world.git"
    - name: git-revision
      value: "main"
    - name: environment
      value: "development"
    - name: skip-tests
      value: "false"
    - name: security-level
      value: "basic"
  workspaces:
    - name: shared-data
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 1Gi
EOF
Execute development pipeline:
oc apply -f dev-pipelinerun.yaml
Test production environment scenario:
cat > prod-pipelinerun.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: prod-conditional-run
  namespace: pipeline-parallel-lab
spec:
  pipelineRef:
    name: conditional-parallel-pipeline
  params:
    - name: git-url
      value: "https://github.com/openshift/ruby-hello-world.git"
    - name: git-revision
      value: "v1.0.0"
    - name: environment
      value: "production"
    - name: skip-tests
      value: "false"
    - name: security-level
      value: "comprehensive"
  workspaces:
    - name: shared-data
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 1Gi
EOF
Execute production pipeline:
oc apply -f prod-pipelinerun.yaml
Monitor both executions:
# Check which tasks are running/skipped in development
tkn pipelinerun describe dev-conditional-run

# Check which tasks are running/skipped in production
tkn pipelinerun describe prod-conditional-run

# Compare the task execution patterns
echo "Development Pipeline Tasks:"
oc get pipelinerun dev-conditional-run -o jsonpath='{.status.taskRuns}' | jq 'keys[]'

echo "Production Pipeline Tasks:"
oc get pipelinerun prod-conditional-run -o jsonpath='{.status.taskRuns}' | jq 'keys[]'
Task 4: Validating Parallel Execution
Subtask 4.1: Create Monitoring and Validation Tools
Create a pipeline execution analyzer script:
cat > pipeline-analyzer.sh << 'EOF'
#!/bin/bash

PIPELINERUN_NAME=$1
NAMESPACE=${2:-pipeline-parallel-lab}

if [ -z "$PIPELINERUN_NAME" ]; then
    echo "Usage: $0 <pipelinerun-name> [namespace]"
    exit 1
fi

echo "=== Pipeline Execution Analysis for $PIPELINERUN_NAME ==="
echo

# Get pipeline run status
echo "Pipeline Status:"
oc get pipelinerun $PIPELINERUN_NAME -n $NAMESPACE -o jsonpath='{.status.conditions[0].reason}: {.status.conditions[0].message}' && echo
echo

# Get start and completion times
START_TIME=$(oc get pipelinerun $PIPELINERUN_NAME -n $NAMESPACE -o jsonpath='{.status.startTime}')
COMPLETION_TIME=$(oc get pipelinerun $PIPELINERUN_NAME -n $NAMESPACE -o jsonpath='{.status.completionTime}')

echo "Execution Times:"
echo "Started: $START_TIME"
echo "Completed: $COMPLETION_TIME"
echo

# Calculate duration if both times are available
if [ ! -z "$START_TIME" ] && [ ! -z "$COMPLETION_TIME" ]; then
    START_EPOCH=$(date -d "$START_TIME" +%s)
    END_EPOCH=$(date -d "$COMPLETION_TIME" +%s)
    DURATION=$((END_EPOCH - START_EPOCH))
    echo "Total Duration: ${DURATION} seconds"
    echo
fi

# Get task execution details
echo "Task Execution Details:"
echo "========================"

# Get all task runs
TASK_RUNS=$(oc get pipelinerun $PIPELINERUN_NAME -n $NAMESPACE -o jsonpath='{.status.taskRuns}' | jq -r 'keys[]')

for task_run in $TASK_RUNS; do
    TASK_NAME=$(oc get taskrun $task_run -n $NAMESPACE -o jsonpath='{.metadata.labels.tekton\.dev/pipelineTask}')
    TASK_STATUS=$(oc get taskrun $task_run -n $NAMESPACE -o jsonpath='{.status.conditions[0].reason}')
    TASK_START=$(oc get taskrun $task_run -n $NAMESPACE -o jsonpath='{.status.startTime}')
    TASK_END=$(oc get taskrun $task_run -n $NAMESPACE -o jsonpath='{.status.completionTime}')
    
    echo "Task: $TASK_NAME"
    echo "  Status: $TASK_STATUS"
    echo "  Started: $TASK_START"
    echo "  Completed: $TASK_END"
    
    if [ ! -z "$TASK_START" ] && [ ! -z "$TASK_END" ]; then
        TASK_START_EPOCH=$(date -d "$TASK_START" +%s)
        TASK_END_EPOCH=$(date -d "$TASK_END" +%s)
        TASK_DURATION=$((TASK_END_EPOCH - TASK_START_EPOCH))
        echo "  Duration: ${TASK_DURATION} seconds"
    fi
    echo
done

# Identify parallel tasks
echo "Parallel Execution Analysis:"
echo "============================="

# Find tasks that started around the same time (within 5 seconds)
declare -A task_start_times
for task_run in $TASK_RUNS; do
    TASK_NAME=$(oc get taskrun $task_run -n $NAMESPACE -o jsonpath='{.metadata.labels.tekton\.dev/pipelineTask}')
    TASK_START=$(oc get taskrun $task_run -n $NAMESPACE -o jsonpath='{.status.startTime}')
    if [ ! -z "$TASK_START" ]; then
        TASK_START_EPOCH=$(date -d "$TASK_START" +%s)
        task_start_times[$TASK_NAME]=$TASK_START_EPOCH
    fi
done

# Group tasks by similar start times
declare -A parallel_groups
for task in "${!task_start_times[@]}"; do
    start_time=${task_start_times[$task]}
    group_found=false
    
    for group in "${!parallel_groups[@]}"; do
        group_time=$(echo $group | cut -d'_' -f1)
        if [ $((start_time - group_time)) -le 5 ] && [ $((start_time - group_time)) -ge -5 ]; then
            parallel_groups[$group]="${parallel_groups[$group]} $task"
            group_found=true
            break
        fi
    done
    
    if [ "$group_found" = false ]; then
        parallel_groups[${start_time}_group]="$task"
    fi
done

group_num=1
for group in "${!parallel_groups[@]}"; do
    tasks=${parallel_groups[$group]}
    task_count=$(echo $tasks | wc -w)
    if [ $task_count -gt 1 ]; then
        echo "Parallel Group $group_num: $tasks"
        group_num=$((group_num + 1))
    fi
done

EOF

chmod +x pipeline-analyzer.sh
Create a parallel execution validator:
cat > validate-parallel.sh << 'EOF'
#!/bin/bash

PIPELINERUN_NAME=$1
NAMESPACE=${2:-pipeline-parallel-lab}

if [ -z "$PIPELINERUN_NAME" ]; then
    echo "Usage: $0 <pipelinerun-name> [namespace]"
    exit 1
fi

echo "=== Parallel Execution Validation ==="
echo

# Check if pipeline completed successfully
STATUS=$(oc get pipelinerun $PIPELINERUN_NAME -n $NAMESPACE -o jsonpath='{.status.conditions[0].reason}')
if [ "$STATUS" != "Succeeded" ]; then
    echo "❌ Pipeline did not complete successfully. Status: $STATUS"
    exit 1
fi

echo "✅ Pipeline completed successfully"

# Get task execution timeline
echo
echo "Task Execution Timeline:"
echo "========================"

TASK_RUNS=$(oc get pipelinerun $PIPELINERUN_NAME -n $NAMESPACE -o jsonpath='{.status.taskRuns}' | jq -r 'keys[]')

declare -A task_times
for task_run in $TASK_RUNS; do
    TASK_NAME=$(oc get taskrun $task_run -n $NAMESPACE -o jsonpath='{.metadata.labels.tekton\.dev/pipelineTask}')
    TASK_START=$(oc get taskrun $task_run -n $NAMESPACE -o jsonpath='{.status.startTime}')
    TASK_END=$(oc get taskrun $task_run -n $NAMESPACE -o jsonpath='{.status.completionTime}')
    
    if [ ! -z "$TASK_START" ] && [ ! -z "$TASK_END" ]; then
        TASK_START_EPOCH=$(date -d "$TASK_START" +%s)
        TASK_END_EPOCH=$(date -d "$TASK_END" +%s)
        task_times[$TASK_NAME]="$TASK_START_EPOCH:$TASK_END_EPOCH"
    fi
done

# Sort tasks by start time and display
for task in $(for t in "${!task_times[@]}"; do echo "$t:${task_times[$t]}"; done | sort -t: -k2 -n); do
    TASK_NAME=$(echo $task | cut -d: -f1)
    START_TIME=$(echo $task | cut -d: -f2)
    END_TIME=$(echo $task | cut -d: -f3)
    DURATION=$((END_TIME - START_TIME))
    
    START_READABLE=$(date -d "@$START_TIME" +"%H:%M:%S")
    END_READABLE=$(date -d "@$END_TIME" +"%H:%M:%S")
    
    echo "$TASK_NAME: $START_READABLE - $END_READABLE (${DURATION}s)"
done

# Validate parallel execution
echo
echo "Parallel Execution Validation:"
echo "==============================="

# Check for overlapping execution times
parallel_detected=false
task_array=()
for task in "${!task_times[@]}"; do
    task_array+=("$task:${task_times[$task]}")
done

for ((i=0; i<${#task_array[@]}; i++)); do
    for ((j=i+1; j<${#task_array[@]}; j++)); do
        task1=$(echo ${task_array[$i]} | cut -d: -f1)
        start1=$(echo ${task_array[$i]} | cut -d: -f2)
        end1=$(echo ${task_array[$i]} | cut -d: -f3)
        
        task2=$(echo ${task_array[$j]} | cut -d: -f1)
        start2=$(echo ${task_array[$j]} | cut -d: -f2)
        end2=$(echo ${task_array[$j]} | cut -d: -f3)
        
        # Check if tasks overlap (excluding fetch-source which should run first)
        if [ "$task1" != "fetch-source" ] && [ "$task2" != "fetch-source" ]; then
            if [ $start1 -lt $end2 ] && [ $start2 -lt $end1 ]; then
                echo "✅ Parallel execution detected: $task1 and $task2"
                parallel_detected=true
            fi
        fi
    done
done

if [ "$parallel_detected" = false ]; then
    echo "⚠️  No parallel execution detected"
else
    echo "✅ Parallel execution successfully validated"
fi

EOF

chmod +x validate-parallel.sh
Subtask 4.2: Analyze Pipeline Executions
Analyze the sequential pipeline execution:
./pipeline-analyzer.sh sequential-run-1
Analyze the parallel pipeline execution:
./pipeline-analyzer.sh parallel-run-1
Validate parallel execution:
./validate-parallel.sh parallel-run-1
Compare conditional pipeline executions:
echo "=== Development Environment Analysis ==="
./pipeline-analyzer.sh dev-conditional-run

echo
echo "=== Production Environment Analysis ==="
./pipeline-analyzer.sh prod-conditional-run
Subtask 4.3: Performance Metrics Collection
