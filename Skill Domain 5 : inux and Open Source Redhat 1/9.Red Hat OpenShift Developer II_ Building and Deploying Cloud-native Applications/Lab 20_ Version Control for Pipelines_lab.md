Lab 20: Version Control for Pipelines
Objectives
By the end of this lab, students will be able to:

• Store pipeline YAML files in Git repositories for version control • Set up proper versioning strategies for pipeline definitions • Integrate pipeline execution with Git version control systems • Implement best practices for managing pipeline configurations • Track changes and rollback pipeline definitions when needed • Collaborate effectively on pipeline development using Git workflows

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Git version control concepts • Familiarity with YAML file structure and syntax • Knowledge of CI/CD pipeline fundamentals • Experience with command-line interface operations • Understanding of containerization concepts • Basic knowledge of OpenShift or Kubernetes environments

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines with all necessary tools pre-installed. Simply click Start Lab to begin - no need to build your own VM or install additional software.

Your lab environment includes: • Git client pre-configured • OpenShift CLI (oc) tools • Tekton CLI (tkn) tools • Text editors (vim, nano) • Sample applications and pipeline templates

Task 1: Store Pipeline YAML Files in Git
Subtask 1.1: Initialize Git Repository for Pipeline Management
First, let's create a dedicated Git repository to store our pipeline definitions.

Create a new directory for pipeline management:
mkdir pipeline-version-control
cd pipeline-version-control
Initialize Git repository:
git init
git config user.name "Pipeline Developer"
git config user.email "developer@example.com"
Create directory structure for organized pipeline storage:
mkdir -p pipelines/{build,deploy,test}
mkdir -p tasks
mkdir -p resources
mkdir -p environments/{dev,staging,prod}
Create a README file to document the repository structure:
cat > README.md << 'EOF'
# Pipeline Version Control Repository

This repository contains all pipeline definitions and related resources.

## Directory Structure

- `pipelines/`: Contains pipeline definitions organized by type
  - `build/`: Build pipeline definitions
  - `deploy/`: Deployment pipeline definitions  
  - `test/`: Testing pipeline definitions
- `tasks/`: Reusable task definitions
- `resources/`: Pipeline resource definitions
- `environments/`: Environment-specific configurations

## Usage

All pipeline changes should be committed to this repository with descriptive commit messages.
Use semantic versioning for releases.
EOF
Subtask 1.2: Create Sample Pipeline YAML Files
Create a basic build pipeline:
cat > pipelines/build/nodejs-build-pipeline.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: nodejs-build-pipeline
  labels:
    version: "1.0.0"
    type: "build"
spec:
  params:
    - name: git-url
      type: string
      description: Git repository URL
    - name: git-revision
      type: string
      default: main
      description: Git revision to build
    - name: image-name
      type: string
      description: Name of the image to build
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
    - name: build-image
      taskRef:
        name: buildah
        kind: ClusterTask
      runAfter:
        - fetch-source
      workspaces:
        - name: source
          workspace: shared-data
      params:
        - name: IMAGE
          value: $(params.image-name)
        - name: DOCKERFILE
          value: ./Dockerfile
EOF
Create a deployment pipeline:
cat > pipelines/deploy/nodejs-deploy-pipeline.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: nodejs-deploy-pipeline
  labels:
    version: "1.0.0"
    type: "deploy"
spec:
  params:
    - name: image-name
      type: string
      description: Container image to deploy
    - name: deployment-name
      type: string
      description: Name of the deployment
    - name: namespace
      type: string
      default: default
      description: Target namespace
  tasks:
    - name: deploy-app
      taskRef:
        name: openshift-client
        kind: ClusterTask
      params:
        - name: SCRIPT
          value: |
            oc create deployment $(params.deployment-name) \
              --image=$(params.image-name) \
              --namespace=$(params.namespace) \
              --dry-run=client -o yaml | oc apply -f -
            oc expose deployment $(params.deployment-name) \
              --port=8080 \
              --namespace=$(params.namespace)
EOF
Create a reusable task definition:
cat > tasks/code-quality-check.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: code-quality-check
  labels:
    version: "1.0.0"
spec:
  description: Performs code quality checks using ESLint
  params:
    - name: source-path
      type: string
      default: "."
      description: Path to source code
  workspaces:
    - name: source
      description: Workspace containing source code
  steps:
    - name: install-dependencies
      image: node:16-alpine
      workingDir: $(workspaces.source.path)/$(params.source-path)
      script: |
        #!/bin/sh
        if [ -f package.json ]; then
          npm install
        else
          echo "No package.json found, skipping dependency installation"
        fi
    - name: run-eslint
      image: node:16-alpine
      workingDir: $(workspaces.source.path)/$(params.source-path)
      script: |
        #!/bin/sh
        if [ -f .eslintrc.js ] || [ -f .eslintrc.json ]; then
          npx eslint . --ext .js,.jsx,.ts,.tsx
        else
          echo "No ESLint configuration found, skipping linting"
        fi
EOF
Subtask 1.3: Commit Pipeline Files to Git
Add all files to Git staging area:
git add .
Create initial commit:
git commit -m "Initial commit: Add basic pipeline definitions

- Added Node.js build pipeline
- Added deployment pipeline  
- Added code quality check task
- Created organized directory structure"
Create and push to remote repository (simulate remote):
# Create a bare repository to simulate remote
git init --bare ../pipeline-repo-remote.git

# Add remote origin
git remote add origin ../pipeline-repo-remote.git

# Push to remote
git push -u origin main
Task 2: Set Up Versioning for Pipeline Definitions
Subtask 2.1: Implement Semantic Versioning Strategy
Create a versioning script:
cat > scripts/version-manager.sh << 'EOF'
#!/bin/bash

# Pipeline Version Manager
# Usage: ./version-manager.sh [major|minor|patch] [pipeline-file]

VERSION_TYPE=${1:-patch}
PIPELINE_FILE=${2}

if [ -z "$PIPELINE_FILE" ]; then
    echo "Usage: $0 [major|minor|patch] [pipeline-file]"
    exit 1
fi

if [ ! -f "$PIPELINE_FILE" ]; then
    echo "Pipeline file not found: $PIPELINE_FILE"
    exit 1
fi

# Extract current version from pipeline file
CURRENT_VERSION=$(grep -o 'version: "[0-9]*\.[0-9]*\.[0-9]*"' "$PIPELINE_FILE" | grep -o '[0-9]*\.[0-9]*\.[0-9]*')

if [ -z "$CURRENT_VERSION" ]; then
    echo "No version found in pipeline file. Adding initial version 1.0.0"
    CURRENT_VERSION="1.0.0"
fi

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Increment version based on type
case $VERSION_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Invalid version type. Use: major, minor, or patch"
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# Update version in pipeline file
sed -i "s/version: \"[0-9]*\.[0-9]*\.[0-9]*\"/version: \"$NEW_VERSION\"/" "$PIPELINE_FILE"

echo "Updated $PIPELINE_FILE from version $CURRENT_VERSION to $NEW_VERSION"
EOF

chmod +x scripts/version-manager.sh
Create version tags for current pipelines:
# Tag the initial version
git tag -a v1.0.0 -m "Initial release of pipeline definitions

Features:
- Node.js build pipeline
- Basic deployment pipeline
- Code quality check task"

# Push tags to remote
git push origin --tags
Subtask 2.2: Create Pipeline Variants for Different Environments
Create environment-specific pipeline configurations:
# Development environment pipeline
cat > environments/dev/nodejs-build-dev.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: nodejs-build-dev
  labels:
    version: "1.0.0"
    environment: "dev"
    type: "build"
spec:
  params:
    - name: git-url
      type: string
      description: Git repository URL
    - name: git-revision
      type: string
      default: develop
      description: Git revision to build
    - name: image-name
      type: string
      description: Name of the image to build
    - name: skip-tests
      type: string
      default: "false"
      description: Skip test execution for faster builds
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
    - name: code-quality
      taskRef:
        name: code-quality-check
      runAfter:
        - fetch-source
      workspaces:
        - name: source
          workspace: shared-data
      when:
        - input: $(params.skip-tests)
          operator: in
          values: ["false"]
    - name: build-image
      taskRef:
        name: buildah
        kind: ClusterTask
      runAfter:
        - code-quality
      workspaces:
        - name: source
          workspace: shared-data
      params:
        - name: IMAGE
          value: $(params.image-name):dev-$(params.git-revision)
        - name: DOCKERFILE
          value: ./Dockerfile
EOF

# Production environment pipeline
cat > environments/prod/nodejs-build-prod.yaml << 'EOF'
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: nodejs-build-prod
  labels:
    version: "1.0.0"
    environment: "prod"
    type: "build"
spec:
  params:
    - name: git-url
      type: string
      description: Git repository URL
    - name: git-revision
      type: string
      default: main
      description: Git revision to build
    - name: image-name
      type: string
      description: Name of the image to build
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
    - name: code-quality
      taskRef:
        name: code-quality-check
      runAfter:
        - fetch-source
      workspaces:
        - name: source
          workspace: shared-data
    - name: security-scan
      taskRef:
        name: trivy-scanner
        kind: ClusterTask
      runAfter:
        - fetch-source
      workspaces:
        - name: manifest-dir
          workspace: shared-data
    - name: build-image
      taskRef:
        name: buildah
        kind: ClusterTask
      runAfter:
        - code-quality
        - security-scan
      workspaces:
        - name: source
          workspace: shared-data
      params:
        - name: IMAGE
          value: $(params.image-name):$(params.git-revision)
        - name: DOCKERFILE
          value: ./Dockerfile
EOF
Subtask 2.3: Create Pipeline Configuration Management
Create a pipeline configuration file:
cat > pipeline-config.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: pipeline-config
  labels:
    version: "1.0.0"
data:
  environments: |
    dev:
      git-branch: develop
      image-tag-prefix: dev
      skip-security-scan: true
      parallel-builds: true
    staging:
      git-branch: release
      image-tag-prefix: staging
      skip-security-scan: false
      parallel-builds: false
    prod:
      git-branch: main
      image-tag-prefix: prod
      skip-security-scan: false
      parallel-builds: false
  global-settings: |
    default-timeout: 60m
    retry-count: 3
    workspace-size: 1Gi
    log-level: info
EOF
Commit the versioning changes:
git add .
git commit -m "feat: Add versioning strategy and environment-specific pipelines

- Added version manager script for semantic versioning
- Created dev and prod environment pipeline variants
- Added pipeline configuration management
- Implemented environment-specific build parameters"

# Update version and create new tag
./scripts/version-manager.sh minor pipelines/build/nodejs-build-pipeline.yaml
git add pipelines/build/nodejs-build-pipeline.yaml
git commit -m "chore: Bump pipeline version to 1.1.0"
git tag -a v1.1.0 -m "Version 1.1.0: Environment-specific pipelines"
git push origin main --tags
Task 3: Integrate Pipeline Execution with Git Version Control
Subtask 3.1: Create Git-Triggered Pipeline Execution
Create a webhook handler script:
mkdir -p automation
cat > automation/git-webhook-handler.sh << 'EOF'
#!/bin/bash

# Git Webhook Handler for Pipeline Execution
# This script processes Git webhook events and triggers appropriate pipelines

WEBHOOK_EVENT=${1:-push}
GIT_REF=${2:-refs/heads/main}
GIT_REPO_URL=${3}

# Extract branch name from Git reference
BRANCH_NAME=$(echo "$GIT_REF" | sed 's|refs/heads/||')

echo "Processing webhook event: $WEBHOOK_EVENT"
echo "Branch: $BRANCH_NAME"
echo "Repository: $GIT_REPO_URL"

# Determine which pipeline to run based on branch
case $BRANCH_NAME in
    main|master)
        PIPELINE_NAME="nodejs-build-prod"
        ENVIRONMENT="prod"
        ;;
    develop|development)
        PIPELINE_NAME="nodejs-build-dev"
        ENVIRONMENT="dev"
        ;;
    release/*)
        PIPELINE_NAME="nodejs-build-staging"
        ENVIRONMENT="staging"
        ;;
    feature/*)
        PIPELINE_NAME="nodejs-build-dev"
        ENVIRONMENT="dev"
        ;;
    *)
        echo "No pipeline configured for branch: $BRANCH_NAME"
        exit 0
        ;;
esac

# Create PipelineRun with Git information
PIPELINE_RUN_NAME="${PIPELINE_NAME}-$(date +%Y%m%d-%H%M%S)"

cat > /tmp/pipeline-run.yaml << EOF
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: $PIPELINE_RUN_NAME
  labels:
    environment: $ENVIRONMENT
    branch: $BRANCH_NAME
    triggered-by: git-webhook
spec:
  pipelineRef:
    name: $PIPELINE_NAME
  params:
    - name: git-url
      value: $GIT_REPO_URL
    - name: git-revision
      value: $BRANCH_NAME
    - name: image-name
      value: myapp:$BRANCH_NAME-\$(context.pipelineRun.uid)
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

echo "Created PipelineRun configuration: $PIPELINE_RUN_NAME"
echo "Pipeline: $PIPELINE_NAME"
echo "Environment: $ENVIRONMENT"

# Apply the PipelineRun (in a real environment, this would use oc apply)
echo "Would execute: oc apply -f /tmp/pipeline-run.yaml"
cat /tmp/pipeline-run.yaml
EOF

chmod +x automation/git-webhook-handler.sh
Create a pipeline execution tracker:
cat > automation/pipeline-tracker.sh << 'EOF'
#!/bin/bash

# Pipeline Execution Tracker
# Tracks pipeline runs and their Git associations

NAMESPACE=${1:-default}

echo "=== Pipeline Execution Tracker ==="
echo "Namespace: $NAMESPACE"
echo "Timestamp: $(date)"
echo

# Function to get pipeline runs with Git information
get_pipeline_runs() {
    echo "Recent Pipeline Runs:"
    echo "NAME                           STATUS    BRANCH      TRIGGERED-BY    AGE"
    echo "----                           ------    ------      ------------    ---"
    
    # Simulate pipeline run listing (in real environment, use oc get pipelineruns)
    cat << 'RUNS'
nodejs-build-prod-20231201-143022    Running   main        git-webhook     2m
nodejs-build-dev-20231201-142015     Succeeded develop     git-webhook     15m
nodejs-build-dev-20231201-141230     Failed    feature/ui  git-webhook     25m
RUNS
}

# Function to show pipeline run details
show_pipeline_details() {
    local pipeline_run=$1
    echo
    echo "=== Pipeline Run Details: $pipeline_run ==="
    
    # Simulate pipeline run details
    cat << DETAILS
Git Information:
  Repository: https://github.com/example/nodejs-app.git
  Branch: main
  Commit: abc123def456
  Author: developer@example.com
  Message: "Add new feature for user authentication"

Pipeline Configuration:
  Pipeline: nodejs-build-prod
  Version: 1.1.0
  Environment: prod
  
Execution Status:
  Started: 2023-12-01 14:30:22
  Duration: 2m 15s
  Status: Running
  
Tasks:
  ✓ fetch-source      (30s)
  ✓ code-quality      (45s)
  ⏳ security-scan    (running)
  ⏸ build-image      (pending)
DETAILS
}

# Main execution
get_pipeline_runs

# Show details for the most recent run
echo
read -p "Enter pipeline run name for details (or press Enter to skip): " pipeline_name
if [ -n "$pipeline_name" ]; then
    show_pipeline_details "$pipeline_name"
fi
EOF

chmod +x automation/pipeline-tracker.sh
Subtask 3.2: Implement Pipeline Rollback Mechanism
Create a pipeline rollback script:
cat > automation/pipeline-rollback.sh << 'EOF'
#!/bin/bash

# Pipeline Rollback Mechanism
# Allows rolling back to previous pipeline versions

PIPELINE_NAME=${1}
TARGET_VERSION=${2}

if [ -z "$PIPELINE_NAME" ] || [ -z "$TARGET_VERSION" ]; then
    echo "Usage: $0 <pipeline-name> <target-version>"
    echo "Example: $0 nodejs-build-pipeline v1.0.0"
    exit 1
fi

echo "=== Pipeline Rollback Tool ==="
echo "Pipeline: $PIPELINE_NAME"
echo "Target Version: $TARGET_VERSION"
echo

# Function to list available versions
list_versions() {
    echo "Available versions for $PIPELINE_NAME:"
    git tag --list "v*" --sort=-version:refname | head -10
}

# Function to show version differences
show_version_diff() {
    local current_version=$1
    local target_version=$2
    
    echo "Changes between $current_version and $target_version:"
    git log --oneline "$target_version..$current_version" -- "pipelines/"
}

# Function to perform rollback
perform_rollback() {
    local target_version=$1
    
    echo "Performing rollback to $target_version..."
    
    # Create rollback branch
    ROLLBACK_BRANCH="rollback-to-$target_version-$(date +%Y%m%d-%H%M%S)"
    git checkout -b "$ROLLBACK_BRANCH"
    
    # Get pipeline files from target version
    git checkout "$target_version" -- pipelines/
    
    # Update version labels in pipeline files
    find pipelines/ -name "*.yaml" -exec sed -i "s/version: \"[^\"]*\"/version: \"$target_version-rollback\"/" {} \;
    
    echo "Rollback prepared in branch: $ROLLBACK_BRANCH"
    echo "Pipeline files updated to version: $target_version"
    
    # Show what changed
    git diff --name-only HEAD~1
    
    echo
    echo "To complete rollback:"
    echo "1. Review changes: git diff"
    echo "2. Commit changes: git commit -m 'Rollback to $target_version'"
    echo "3. Merge to main: git checkout main && git merge $ROLLBACK_BRANCH"
    echo "4. Apply to cluster: oc apply -f pipelines/"
}

# Main execution
echo "Current branch: $(git branch --show-current)"
echo

list_versions
echo

# Verify target version exists
if ! git tag --list | grep -q "^$TARGET_VERSION$"; then
    echo "Error: Version $TARGET_VERSION not found"
    exit 1
fi

# Show current version
CURRENT_VERSION=$(git describe --tags --abbrev=0)
echo "Current version: $CURRENT_VERSION"

if [ "$CURRENT_VERSION" = "$TARGET_VERSION" ]; then
    echo "Already at target version $TARGET_VERSION"
    exit 0
fi

echo
show_version_diff "$CURRENT_VERSION" "$TARGET_VERSION"

echo
read -p "Proceed with rollback to $TARGET_VERSION? (y/N): " confirm
if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    perform_rollback "$TARGET_VERSION"
else
    echo "Rollback cancelled"
fi
EOF

chmod +x automation/pipeline-rollback.sh
Subtask 3.3: Create Pipeline Deployment Automation
Create deployment automation script:
cat > automation/deploy-pipelines.sh << 'EOF'
#!/bin/bash

# Pipeline Deployment Automation
# Deploys pipeline definitions to OpenShift cluster

ENVIRONMENT=${1:-dev}
DRY_RUN=${2:-false}

echo "=== Pipeline Deployment Automation ==="
echo "Environment: $ENVIRONMENT"
echo "Dry Run: $DRY_RUN"
echo "Timestamp: $(date)"
echo

# Function to validate pipeline YAML files
validate_pipelines() {
    echo "Validating pipeline definitions..."
    
    local validation_errors=0
    
    for pipeline_file in $(find pipelines/ environments/ -name "*.yaml" -type f); do
        echo -n "Validating $pipeline_file... "
        
        # Check YAML syntax
        if ! python3 -c "import yaml; yaml.safe_load(open('$pipeline_file'))" 2>/dev/null; then
            echo "❌ YAML syntax error"
            validation_errors=$((validation_errors + 1))
        else
            echo "✅ Valid"
        fi
    done
    
    if [ $validation_errors -gt 0 ]; then
        echo "❌ Validation failed with $validation_errors errors"
        return 1
    else
        echo "✅ All pipeline definitions are valid"
        return 0
    fi
}

# Function to deploy pipelines
deploy_pipelines() {
    local env=$1
    local dry_run=$2
    
    echo
    echo "Deploying pipelines for environment: $env"
    
    # Deploy common tasks first
    echo "Deploying common tasks..."
    for task_file in tasks/*.yaml; do
        if [ -f "$task_file" ]; then
            echo "  - $(basename "$task_file")"
            if [ "$dry_run" = "false" ]; then
                # In real environment: oc apply -f "$task_file"
                echo "    Would execute: oc apply -f $task_file"
            fi
        fi
    done
    
    # Deploy environment-specific pipelines
    echo "Deploying environment-specific pipelines..."
    if [ -d "environments/$env" ]; then
        for pipeline_file in environments/$env/*.yaml; do
            if [ -f "$pipeline_file" ]; then
                echo "  - $(basename "$pipeline_file")"
                if [ "$dry_run" = "false" ]; then
                    # In real environment: oc apply -f "$pipeline_file"
                    echo "    Would execute: oc apply -f $pipeline_file"
                fi
            fi
        done
    fi
    
    # Deploy general pipelines
    echo "Deploying general pipelines..."
    for pipeline_file in pipelines/*/*.yaml; do
        if [ -f "$pipeline_file" ]; then
            echo "  - $(basename "$pipeline_file")"
            if [ "$dry_run" = "false" ]; then
                # In real environment: oc apply -f "$pipeline_file"
                echo "    Would execute: oc apply -f $pipeline_file"
            fi
        fi
    done
    
    # Deploy configuration
    echo "Deploying pipeline configuration..."
    if [ -f "pipeline-config.yaml" ]; then
        echo "  - pipeline-config.yaml"
        if [ "$dry_run" = "false" ]; then
            # In real environment: oc apply -f pipeline-config.yaml
            echo "    Would execute: oc apply -f pipeline-config.yaml"
        fi
    fi
}

# Function to verify deployment
verify_deployment() {
    local env=$1
    
    echo
    echo "Verifying deployment..."
    
    # Simulate verification (in real environment, use oc get commands)
    echo "✅ Tasks deployed successfully:"
    echo "  - code-quality-check"
    
    echo "✅ Pipelines deployed successfully:"
    echo "  - nodejs-build-pipeline"
    echo "  - nodejs-deploy-pipeline"
    echo "  - nodejs-build-$env"
    
    echo "✅ Configuration deployed successfully:"
    echo "  - pipeline-config"
}

# Main execution
if ! validate_pipelines; then
    echo "❌ Deployment aborted due to validation errors"
    exit 1
fi

deploy_pipelines "$ENVIRONMENT" "$DRY_RUN"

if [ "$DRY_RUN" = "false" ]; then
    verify_deployment "$ENVIRONMENT"
    echo
    echo "🎉 Pipeline deployment completed successfully!"
else
    echo
    echo "🔍 Dry run completed. Use 'false' as second parameter to perform actual deployment."
fi

echo
echo "Next steps:"
echo "1. Test pipeline execution: tkn pipeline start nodejs-build-$ENVIRONMENT"
echo "2. Monitor pipeline runs: tkn pipelinerun list"
echo "3. View logs: tkn pipelinerun logs <pipeline-run-name>"
EOF

chmod +x automation/deploy-pipelines.sh
Create final commit with automation scripts:
git add automation/
git commit -m "feat: Add Git integration and deployment automation

- Added webhook handler for Git-triggered pipeline execution
- Implemented pipeline execution tracker
- Created rollback mechanism for pipeline versions
- Added automated deployment script with validation
- Integrated Git branch-based pipeline selection"

# Update version for the automation features
./scripts/version-manager.sh minor pipelines/build/nodejs-build-pipeline.yaml
git add pipelines/build/nodejs-build-pipeline.yaml
git commit -m "chore: Bump pipeline version to 1.2.0"
git tag -a v1.2.0 -m "Version 1.2.0: Git integration and automation"
git push origin main --tags
Subtask 3.4: Test the Complete Version Control Integration
Test the webhook handler:
echo "Testing Git webhook integration..."
./automation/git-webhook-handler.sh push refs/heads/main https://github.com/example/nodejs-app.git
Test the pipeline tracker:
echo "Testing pipeline execution tracking..."
./automation/pipeline-tracker.sh
Test the rollback mechanism:
echo "Testing pipeline rollback..."
./automation/pipeline-rollback.sh nodejs-build-pipeline v1.0.0
Test the deployment automation:
echo "Testing deployment automation (dry run)..."
./automation/deploy-pipelines.sh dev true
View the complete Git history:
echo "Complete Git history with pipeline versions:"
git log --oneline --graph --decorate --all
echo
echo "Available tags:"
git tag --list --sort=-version:refname
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Pipeline YAML validation errors

Symptom: YAML syntax errors when applying pipeline definitions
Solution: Use python3 -c "import yaml; yaml.safe_load(open('file.yaml'))" to validate YAML syntax
Prevention: Set up pre-commit hooks to validate YAML files
Issue 2: Git merge conflicts in pipeline files

Symptom: Conflicts when merging pipeline changes from different branches
Solution: Use semantic merge strategies and maintain clear separation between environment-specific configurations
Prevention: Use separate files for different environments and avoid editing the same pipeline sections simultaneously
Issue 3: Version tag conflicts

Symptom: Git tag already exists errors when creating new versions
Solution: Use git tag -d <tag-name> to delete local tags and git push origin :refs/tags/<tag-name> to delete remote tags
Prevention: Implement automated version checking in the version manager script
Issue 4: Pipeline execution failures after rollback

Symptom: Pipelines fail to execute after rolling back to previous versions
Solution: Ensure all referenced tasks and resources exist in the target version
Prevention: Maintain backward compatibility and test rollback procedures regularly
Issue 5: Webhook handler not triggering pipelines

Symptom: Git pushes don't trigger pipeline execution
Solution: Check webhook configuration and ensure the handler script has proper permissions
Prevention: Implement logging and monitoring for webhook events
Conclusion
In this comprehensive lab, you have successfully implemented a complete version control
