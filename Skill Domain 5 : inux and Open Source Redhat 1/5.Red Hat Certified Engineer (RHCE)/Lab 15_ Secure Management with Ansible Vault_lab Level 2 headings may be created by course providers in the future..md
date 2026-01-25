Lab 15: Secure Management with Ansible Vault
Objectives
By the end of this lab, students will be able to:

Understand the importance of securing sensitive data in automation workflows
Create and manage encrypted files using Ansible Vault
Integrate encrypted variables seamlessly into Ansible playbooks
Implement secure credential management practices using ansible-vault commands
Apply encryption and decryption techniques for production-ready automation
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with Ansible fundamentals (playbooks, variables, and inventory)
Knowledge of YAML syntax and structure
Understanding of basic security concepts
Completion of previous Ansible labs or equivalent experience
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ansible already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

CentOS/RHEL-based control node with Ansible installed
Pre-configured SSH access between nodes
All necessary tools and dependencies ready to use
Task 1: Create an Encrypted File with Ansible Vault
Subtask 1.1: Understanding Ansible Vault Basics
Ansible Vault is a feature that allows you to encrypt sensitive data such as passwords, keys, and other secrets. This ensures that sensitive information is not stored in plain text within your playbooks or variable files.

Key Benefits:

Security: Protects sensitive data from unauthorized access
Version Control Safety: Encrypted files can be safely committed to repositories
Team Collaboration: Secure sharing of credentials across team members
Subtask 1.2: Create Your First Encrypted File
Navigate to your working directory:
cd /home/student/ansible-lab
mkdir vault-lab
cd vault-lab
Create an encrypted file containing database credentials:
ansible-vault create db_secrets.yml
When prompted, enter a vault password (remember this password):
New Vault password: SecurePass123!
Confirm New Vault password: SecurePass123!
Add the following content to the encrypted file:
---
# Database Configuration Secrets
db_host: "production-db.company.com"
db_username: "app_user"
db_password: "MySecureDBPassword2024!"
db_port: 5432
db_name: "production_app"

# API Keys
api_key: "sk-1234567890abcdef"
secret_token: "token_abc123xyz789"

# SSL Certificate Paths
ssl_cert_path: "/etc/ssl/certs/app.crt"
ssl_key_path: "/etc/ssl/private/app.key"
Save and exit the editor (Ctrl+X, then Y, then Enter if using nano)
Subtask 1.3: Verify the Encrypted File
View the encrypted file content:
cat db_secrets.yml
Expected Output: You should see encrypted content that looks like this:

$ANSIBLE_VAULT;1.1;AES256
66386439653765386464323464663835633634313734653137353834643765653665353432373762
3334633462613162386565323632343936346435323766310a663635353834643765653665353432
...
View the decrypted content:
ansible-vault view db_secrets.yml
Enter your vault password when prompted to see the original content.

Task 2: Use Encrypted Variables in Playbooks
Subtask 2.1: Create a Playbook Using Encrypted Variables
Create a playbook that uses the encrypted variables:
nano secure_deployment.yml
Add the following playbook content:
---
- name: Secure Application Deployment
  hosts: localhost
  vars_files:
    - db_secrets.yml
  vars:
    app_name: "secure-web-app"
    deployment_env: "production"
  
  tasks:
    - name: Display deployment information (non-sensitive)
      debug:
        msg: |
          Deploying {{ app_name }} to {{ deployment_env }} environment
          Database Host: {{ db_host }}
          Database Port: {{ db_port }}
          Database Name: {{ db_name }}
    
    - name: Create application configuration file
      copy:
        content: |
          [database]
          host={{ db_host }}
          port={{ db_port }}
          username={{ db_username }}
          password={{ db_password }}
          database={{ db_name }}
          
          [api]
          key={{ api_key }}
          token={{ secret_token }}
          
          [ssl]
          cert_path={{ ssl_cert_path }}
          key_path={{ ssl_key_path }}
        dest: /tmp/app_config.ini
        mode: '0600'
    
    - name: Verify configuration file was created
      stat:
        path: /tmp/app_config.ini
      register: config_file
    
    - name: Show configuration file status
      debug:
        msg: "Configuration file created: {{ config_file.stat.exists }}"
Subtask 2.2: Run the Playbook with Vault Password
Execute the playbook with vault password prompt:
ansible-playbook secure_deployment.yml --ask-vault-pass
Enter your vault password when prompted:
Vault password: SecurePass123!
Verify the playbook execution and check the created configuration file:
ls -la /tmp/app_config.ini
cat /tmp/app_config.ini
Subtask 2.3: Create a Mixed Variables Playbook
Create a playbook with both encrypted and plain variables:
nano mixed_vars_playbook.yml
Add the following content:
---
- name: Mixed Variables Demonstration
  hosts: localhost
  vars_files:
    - db_secrets.yml
  vars:
    # Plain variables (non-sensitive)
    app_version: "2.1.0"
    deployment_date: "2024-01-15"
    environment: "production"
    
  tasks:
    - name: Show public information
      debug:
        msg: |
          Application Version: {{ app_version }}
          Deployment Date: {{ deployment_date }}
          Environment: {{ environment }}
    
    - name: Create database connection test
      shell: |
        echo "Testing connection to {{ db_host }}:{{ db_port }}"
        echo "Database: {{ db_name }}"
        echo "Connection test completed"
      register: db_test
    
    - name: Display connection test results
      debug:
        var: db_test.stdout_lines
Run the mixed variables playbook:
ansible-playbook mixed_vars_playbook.yml --ask-vault-pass
Task 3: Securely Manage Credentials Using ansible-vault
Subtask 3.1: Advanced Vault Management Commands
Create a password file for automated vault operations:
echo "SecurePass123!" > .vault_password
chmod 600 .vault_password
Edit an existing encrypted file:
ansible-vault edit db_secrets.yml --vault-password-file .vault_password
Add additional secrets to the file:
# Add these new entries to the existing file
ldap_server: "ldap.company.com"
ldap_bind_dn: "cn=admin,dc=company,dc=com"
ldap_bind_password: "LDAPSecurePass2024!"

# Email Configuration
smtp_server: "smtp.company.com"
smtp_username: "noreply@company.com"
smtp_password: "EmailSecurePass2024!"
Subtask 3.2: Create Multiple Encrypted Files for Different Environments
Create development environment secrets:
ansible-vault create dev_secrets.yml --vault-password-file .vault_password
Content for dev_secrets.yml:

---
# Development Environment Secrets
db_host: "dev-db.company.com"
db_username: "dev_user"
db_password: "DevPassword123!"
db_port: 5432
db_name: "development_app"

api_key: "dev-sk-1234567890abcdef"
secret_token: "dev-token_abc123xyz789"
Create staging environment secrets:
ansible-vault create staging_secrets.yml --vault-password-file .vault_password
Content for staging_secrets.yml:

---
# Staging Environment Secrets
db_host: "staging-db.company.com"
db_username: "staging_user"
db_password: "StagingPassword123!"
db_port: 5432
db_name: "staging_app"

api_key: "staging-sk-1234567890abcdef"
secret_token: "staging-token_abc123xyz789"
Subtask 3.3: Create Environment-Specific Deployment Playbook
Create a flexible deployment playbook:
nano environment_deployment.yml
Add the following content:
---
- name: Environment-Specific Secure Deployment
  hosts: localhost
  vars:
    target_env: "{{ env | default('dev') }}"
  vars_files:
    - "{{ target_env }}_secrets.yml"
  
  tasks:
    - name: Display current environment
      debug:
        msg: "Deploying to {{ target_env }} environment"
    
    - name: Show environment-specific database configuration
      debug:
        msg: |
          Environment: {{ target_env }}
          Database Host: {{ db_host }}
          Database Name: {{ db_name }}
          Database Port: {{ db_port }}
    
    - name: Create environment-specific configuration
      copy:
        content: |
          # {{ target_env | upper }} ENVIRONMENT CONFIGURATION
          # Generated on {{ ansible_date_time.iso8601 }}
          
          [database]
          host={{ db_host }}
          port={{ db_port }}
          username={{ db_username }}
          password={{ db_password }}
          database={{ db_name }}
          
          [api]
          key={{ api_key }}
          token={{ secret_token }}
          
          [environment]
          name={{ target_env }}
          deployment_time={{ ansible_date_time.iso8601 }}
        dest: "/tmp/{{ target_env }}_config.ini"
        mode: '0600'
    
    - name: Validate configuration file
      stat:
        path: "/tmp/{{ target_env }}_config.ini"
      register: env_config
    
    - name: Confirm deployment success
      debug:
        msg: "{{ target_env | title }} configuration deployed successfully!"
      when: env_config.stat.exists
Test deployments to different environments:
# Deploy to development
ansible-playbook environment_deployment.yml --vault-password-file .vault_password -e env=dev

# Deploy to staging
ansible-playbook environment_deployment.yml --vault-password-file .vault_password -e env=staging

# Deploy to production (using default db_secrets.yml)
ansible-playbook environment_deployment.yml --vault-password-file .vault_password -e env=production --extra-vars "vars_files=db_secrets.yml"
Subtask 3.4: Vault Security Best Practices Implementation
Create a vault management script:
nano vault_manager.sh
Add the following script content:
#!/bin/bash

# Ansible Vault Management Script
# Usage: ./vault_manager.sh [create|edit|view|encrypt|decrypt] [filename]

VAULT_PASSWORD_FILE=".vault_password"

function show_usage() {
    echo "Usage: $0 [create|edit|view|encrypt|decrypt|rekey] [filename]"
    echo "Examples:"
    echo "  $0 create new_secrets.yml"
    echo "  $0 edit db_secrets.yml"
    echo "  $0 view staging_secrets.yml"
    echo "  $0 encrypt plain_file.yml"
    echo "  $0 decrypt encrypted_file.yml"
    echo "  $0 rekey old_secrets.yml"
}

if [ $# -lt 2 ]; then
    show_usage
    exit 1
fi

ACTION=$1
FILENAME=$2

case $ACTION in
    create)
        echo "Creating new encrypted file: $FILENAME"
        ansible-vault create "$FILENAME" --vault-password-file "$VAULT_PASSWORD_FILE"
        ;;
    edit)
        echo "Editing encrypted file: $FILENAME"
        ansible-vault edit "$FILENAME" --vault-password-file "$VAULT_PASSWORD_FILE"
        ;;
    view)
        echo "Viewing encrypted file: $FILENAME"
        ansible-vault view "$FILENAME" --vault-password-file "$VAULT_PASSWORD_FILE"
        ;;
    encrypt)
        echo "Encrypting plain file: $FILENAME"
        ansible-vault encrypt "$FILENAME" --vault-password-file "$VAULT_PASSWORD_FILE"
        ;;
    decrypt)
        echo "Decrypting file: $FILENAME"
        ansible-vault decrypt "$FILENAME" --vault-password-file "$VAULT_PASSWORD_FILE"
        ;;
    rekey)
        echo "Changing password for: $FILENAME"
        ansible-vault rekey "$FILENAME" --vault-password-file "$VAULT_PASSWORD_FILE"
        ;;
    *)
        echo "Unknown action: $ACTION"
        show_usage
        exit 1
        ;;
esac
Make the script executable and test it:
chmod +x vault_manager.sh

# Test viewing a file
./vault_manager.sh view db_secrets.yml
Subtask 3.5: Implement Vault ID for Multiple Passwords
Create different vault password files:
echo "DevTeamPassword123!" > .vault_dev
echo "ProdTeamPassword456!" > .vault_prod
chmod 600 .vault_dev .vault_prod
Create a file encrypted with a specific vault ID:
ansible-vault create --vault-id dev@.vault_dev team_dev_secrets.yml
Content for team_dev_secrets.yml:

---
# Development Team Specific Secrets
team_lead_email: "dev-lead@company.com"
team_slack_webhook: "https://hooks.slack.com/dev-team-webhook"
dev_server_ssh_key: "ssh-rsa AAAAB3NzaC1yc2E... dev-team-key"
Create a playbook using vault IDs:
nano vault_id_playbook.yml
---
- name: Multi-Vault ID Demonstration
  hosts: localhost
  vars_files:
    - team_dev_secrets.yml
    - db_secrets.yml
  
  tasks:
    - name: Show team-specific information
      debug:
        msg: |
          Team Lead: {{ team_lead_email }}
          Slack Webhook configured: {{ team_slack_webhook is defined }}
    
    - name: Show database information
      debug:
        msg: |
          Database Host: {{ db_host }}
          Database Name: {{ db_name }}
Run the playbook with multiple vault IDs:
ansible-playbook vault_id_playbook.yml --vault-id dev@.vault_dev --vault-id prod@.vault_password
Troubleshooting Common Issues
Issue 1: Vault Password Mismatch
Problem: Getting "Decryption failed" error

Solution:

# Verify the correct password file is being used
ansible-vault view db_secrets.yml --vault-password-file .vault_password

# If password is forgotten, you'll need to recreate the file
# First, try to remember and decrypt
ansible-vault decrypt db_secrets.yml
# Then re-encrypt with new password
ansible-vault encrypt db_secrets.yml
Issue 2: Permission Denied on Password Files
Problem: Cannot read vault password file

Solution:

# Check file permissions
ls -la .vault_password

# Fix permissions
chmod 600 .vault_password
Issue 3: Playbook Cannot Find Encrypted Variables
Problem: Variables from encrypted files not loading

Solution:

# Ensure vars_files path is correct
# Check if file exists
ls -la db_secrets.yml

# Verify file is properly encrypted
ansible-vault view db_secrets.yml --ask-vault-pass
Security Best Practices Summary
Password File Security:

Always set restrictive permissions (600) on password files
Never commit password files to version control
Use different passwords for different environments
Vault File Management:

Use descriptive names for encrypted files
Organize files by environment or purpose
Regularly rotate vault passwords
Playbook Security:

Avoid displaying sensitive variables in debug tasks
Use no_log: true for tasks handling sensitive data
Validate file permissions on created configuration files
Conclusion
In this comprehensive lab, you have successfully learned to:

Create encrypted files using Ansible Vault to protect sensitive information like passwords, API keys, and certificates
Integrate encrypted variables seamlessly into Ansible playbooks while maintaining security
Implement advanced vault management techniques including multiple vault IDs, environment-specific configurations, and automated vault operations
Apply security best practices for credential management in production environments
Why This Matters:

Ansible Vault is crucial for real-world automation because it allows you to:

Safely store sensitive data in version control systems
Share automation code with team members without exposing credentials
Maintain different security levels for different environments
Comply with security policies and regulations in enterprise environments
These skills are essential for the Red Hat Certified Engineer (RHCE) certification and are directly applicable in production environments where security is paramount. You now have the foundation to implement secure automation practices that protect sensitive data while maintaining the flexibility and power of Ansible automation.

The techniques you've learned here will enable you to build robust, secure automation solutions that can be safely deployed in enterprise environments, making you a more valuable automation engineer and helping you advance in your career.

Lab Terminal
