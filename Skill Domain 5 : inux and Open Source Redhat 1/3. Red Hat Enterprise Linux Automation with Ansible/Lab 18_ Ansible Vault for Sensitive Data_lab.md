Lab 18: Ansible Vault for Sensitive Data
Objectives
By the end of this lab, students will be able to:

• Understand the importance of securing sensitive data in Ansible automation • Create and manage encrypted files using Ansible Vault • Encrypt passwords, API keys, and other sensitive information • Integrate Ansible Vault into playbooks for secure task execution • Use different methods to provide vault passwords during playbook execution • Edit and view encrypted vault files • Implement best practices for managing sensitive data in Ansible projects

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Familiarity with Ansible fundamentals (playbooks, tasks, variables) • Knowledge of YAML syntax • Understanding of file permissions and security concepts • Completion of previous Ansible labs or equivalent experience

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes: • CentOS/RHEL 8 or Ubuntu 20.04 LTS • Ansible 4.0+ pre-installed • Text editors (nano, vim) • Sample files and directories for practice

Task 1: Understanding Ansible Vault Basics
Subtask 1.1: Verify Ansible Installation and Create Lab Directory
First, let's verify that Ansible is properly installed and create our working directory.

# Check Ansible version
ansible --version

# Create lab directory
mkdir -p ~/ansible-vault-lab
cd ~/ansible-vault-lab

# Create subdirectories for organization
mkdir -p {playbooks,vars,inventory}
Subtask 1.2: Create Sample Sensitive Data
Let's create some sample sensitive data that we'll encrypt using Ansible Vault.

# Create a file with sensitive database credentials
cat > vars/database_secrets.yml << 'EOF'
---
database_password: "MySecretPassword123!"
database_username: "admin"
database_host: "db.example.com"
database_port: 5432
api_key: "sk-1234567890abcdef"
ssl_certificate_key: |
  -----BEGIN PRIVATE KEY-----
  MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7...
  -----END PRIVATE KEY-----
EOF
# Create another file with user credentials
cat > vars/user_secrets.yml << 'EOF'
---
admin_password: "AdminPass2023!"
service_account_password: "ServiceAccount456"
ldap_bind_password: "LdapSecret789"
encryption_key: "MyEncryptionKey2023"
EOF
Subtask 1.3: View Unencrypted Files
Let's examine our sensitive files before encryption to understand what we're protecting.

# View the database secrets file
echo "=== Database Secrets (UNENCRYPTED) ==="
cat vars/database_secrets.yml

echo -e "\n=== User Secrets (UNENCRYPTED) ==="
cat vars/user_secrets.yml
Task 2: Encrypting Files with Ansible Vault
Subtask 2.1: Encrypt Your First Vault File
Now let's encrypt our sensitive data files using Ansible Vault.

# Encrypt the database secrets file
ansible-vault encrypt vars/database_secrets.yml
When prompted, enter a vault password (remember this password - you'll need it later). For this lab, use: VaultPassword123

# Encrypt the user secrets file with the same password
ansible-vault encrypt vars/user_secrets.yml
Subtask 2.2: Verify Encryption
Let's verify that our files are now encrypted and unreadable.

# Try to view the encrypted file
echo "=== Encrypted Database Secrets ==="
cat vars/database_secrets.yml

echo -e "\n=== Encrypted User Secrets ==="
cat vars/user_secrets.yml
You should see encrypted content that looks like this:

$ANSIBLE_VAULT;1.1;AES256
66386439653765386161303831663966633464613765386135663731303265656235643366316464
3438373434353661643266323464663936346435323833310a663635373139653265353464636139
...
Subtask 2.3: Create Encrypted Files Directly
You can also create encrypted files directly without creating them in plain text first.

# Create a new encrypted file directly
ansible-vault create vars/api_secrets.yml
When prompted for the vault password, use: VaultPassword123

Add the following content to the file: ```yaml
stripe_api_key: "sk_test_1234567890abcdef" paypal_client_secret: "PayPalSecret123" aws_secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" github_token: "ghp_1234567890abcdefghijklmnopqrstuvwxyz"


## Task 3: Working with Encrypted Vault Files

### Subtask 3.1: View Encrypted Files

To view the contents of encrypted files without decrypting them permanently:

```bash
# View encrypted database secrets
ansible-vault view vars/database_secrets.yml

# View encrypted user secrets
ansible-vault view vars/user_secrets.yml

# View the API secrets we just created
ansible-vault view vars/api_secrets.yml
Subtask 3.2: Edit Encrypted Files
To edit encrypted files:

# Edit the database secrets file
ansible-vault edit vars/database_secrets.yml
Add a new variable to the file:

database_backup_password: "BackupSecret456"
Save and exit the editor.

Subtask 3.3: Change Vault Password
You can change the password for encrypted files:

# Change password for database secrets
ansible-vault rekey vars/database_secrets.yml
Enter the current password (VaultPassword123), then enter a new password: NewVaultPassword456

Task 4: Integrating Vault into Playbooks
Subtask 4.1: Create Inventory File
First, let's create an inventory file for our playbook:

cat > inventory/hosts << 'EOF'
[webservers]
localhost ansible_connection=local

[databases]
localhost ansible_connection=local
EOF
Subtask 4.2: Create a Playbook Using Vault Variables
Now let's create a playbook that uses our encrypted variables:

cat > playbooks/secure_deployment.yml << 'EOF'
---
- name: Secure Application Deployment
  hosts: webservers
  gather_facts: yes
  vars_files:
    - ../vars/database_secrets.yml
    - ../vars/user_secrets.yml
    - ../vars/api_secrets.yml
  
  tasks:
    - name: Display server information (safe)
      debug:
        msg: "Deploying to {{ ansible_hostname }}"
    
    - name: Create application configuration directory
      file:
        path: /tmp/app-config
        state: directory
        mode: '0750'
      become: yes
    
    - name: Generate database configuration file
      template:
        src: ../templates/database.conf.j2
        dest: /tmp/app-config/database.conf
        mode: '0600'
      become: yes
    
    - name: Generate API configuration file
      template:
        src: ../templates/api.conf.j2
        dest: /tmp/app-config/api.conf
        mode: '0600'
      become: yes
    
    - name: Create service user with encrypted password
      user:
        name: appservice
        password: "{{ service_account_password | password_hash('sha512') }}"
        shell: /bin/bash
        create_home: yes
      become: yes
    
    - name: Display configuration status (without sensitive data)
      debug:
        msg: "Configuration files created successfully for user: {{ database_username }}"
EOF
Subtask 4.3: Create Template Files
Create template files that will use our encrypted variables:

# Create templates directory
mkdir -p templates

# Create database configuration template
cat > templates/database.conf.j2 << 'EOF'
# Database Configuration
# Generated by Ansible - Do not edit manually

[database]
host = {{ database_host }}
port = {{ database_port }}
username = {{ database_username }}
password = {{ database_password }}

[backup]
backup_password = {{ database_backup_password | default('DefaultBackup123') }}

# Connection settings
max_connections = 100
timeout = 30
EOF
# Create API configuration template
cat > templates/api.conf.j2 << 'EOF'
# API Configuration
# Generated by Ansible - Do not edit manually

[stripe]
api_key = {{ stripe_api_key }}

[paypal]
client_secret = {{ paypal_client_secret }}

[aws]
secret_access_key = {{ aws_secret_access_key }}

[github]
token = {{ github_token }}

[encryption]
key = {{ encryption_key }}
EOF
Subtask 4.4: Run Playbook with Vault Password
Now let's run our playbook. Since we have files with different vault passwords, we need to handle this:

# First, let's rekey the database_secrets.yml back to the original password
ansible-vault rekey vars/database_secrets.yml
Enter the current password (NewVaultPassword456), then enter the original password: VaultPassword123

# Run the playbook with vault password prompt
ansible-playbook -i inventory/hosts playbooks/secure_deployment.yml --ask-vault-pass
Enter the vault password: VaultPassword123

Subtask 4.5: Using Vault Password File
For automation purposes, you can store the vault password in a file:

# Create a vault password file (be careful with permissions!)
echo "VaultPassword123" > .vault_password
chmod 600 .vault_password

# Run playbook using password file
ansible-playbook -i inventory/hosts playbooks/secure_deployment.yml --vault-password-file .vault_password
Subtask 4.6: Verify Deployment Results
Let's check that our playbook worked correctly:

# Check if configuration files were created
echo "=== Database Configuration ==="
sudo cat /tmp/app-config/database.conf

echo -e "\n=== API Configuration ==="
sudo cat /tmp/app-config/api.conf

# Check if service user was created
echo -e "\n=== Service User Information ==="
id appservice

# Check directory permissions
echo -e "\n=== Directory Permissions ==="
ls -la /tmp/app-config/
Task 5: Advanced Vault Operations
Subtask 5.1: Decrypt Files Permanently
Sometimes you need to decrypt files permanently:

# Create a backup first
cp vars/user_secrets.yml vars/user_secrets.yml.backup

# Decrypt the file permanently
ansible-vault decrypt vars/user_secrets.yml

# View the decrypted content
cat vars/user_secrets.yml

# Re-encrypt it
ansible-vault encrypt vars/user_secrets.yml
Subtask 5.2: Encrypt Specific Variables
You can encrypt individual variables instead of entire files:

# Encrypt a single string
ansible-vault encrypt_string 'SuperSecretPassword123!' --name 'mysql_root_password'
This will output something like:

mysql_root_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          66386439653765386161303831663966633464613765386135663731303265656235643366316464
          3438373434353661643266323464663936346435323833310a663635373139653265353464636139
          ...
Subtask 5.3: Create Mixed Variable File
Create a file with both encrypted and unencrypted variables:

cat > vars/mixed_secrets.yml << 'EOF'
---
# Unencrypted variables
application_name: "MyWebApp"
version: "2.1.0"
debug_mode: false

# This will be replaced with encrypted content
database_root_password: "PLACEHOLDER"
EOF
Now encrypt just the password variable:

# Generate encrypted string for the password
encrypted_password=$(ansible-vault encrypt_string 'RootPassword789!' --name 'database_root_password' --vault-password-file .vault_password)

# Replace the placeholder with encrypted content
sed -i 's/database_root_password: "PLACEHOLDER"/'"$encrypted_password"'/' vars/mixed_secrets.yml

# View the mixed file
cat vars/mixed_secrets.yml
Subtask 5.4: Using Multiple Vault IDs
Ansible supports multiple vault IDs for different types of secrets:

# Create vault files with different IDs
ansible-vault create --vault-id dev@prompt vars/dev_secrets.yml
Add content for development environment: ```yaml
dev_database_password: "DevPassword123" dev_api_key: "dev-api-key-123"


```bash
# Create production vault with different ID
ansible-vault create --vault-id prod@prompt vars/prod_secrets.yml
Add content for production environment: ```yaml
prod_database_password: "ProdPassword456" prod_api_key: "prod-api-key-456"


## Task 6: Best Practices and Security

### Subtask 6.1: Create Secure Playbook Structure

Let's create a more secure playbook structure:

```bash
# Create environment-specific directories
mkdir -p {group_vars,host_vars}
mkdir -p group_vars/{development,production}

# Create development group variables
cat > group_vars/development/main.yml << 'EOF'
---
environment: development
database_host: dev-db.example.com
api_endpoint: https://api-dev.example.com
debug_enabled: true
EOF
# Create encrypted development secrets
ansible-vault create group_vars/development/vault.yml --vault-password-file .vault_password
Add the following content: ```yaml
vault_database_password: "DevDBPassword123" vault_api_secret: "dev-secret-key-789" vault_ssl_key: "dev-ssl-private-key"


### Subtask 6.2: Create Production Configuration

```bash
# Create production group variables
cat > group_vars/production/main.yml << 'EOF'
---
environment: production
database_host: prod-db.example.com
api_endpoint: https://api.example.com
debug_enabled: false
EOF
# Create encrypted production secrets
ansible-vault create group_vars/production/vault.yml --vault-password-file .vault_password
Add the following content: ```yaml
vault_database_password: "ProdDBPassword456" vault_api_secret: "prod-secret-key-abc" vault_ssl_key: "prod-ssl-private-key"


### Subtask 6.3: Create Environment-Aware Playbook

```bash
cat > playbooks/environment_deployment.yml << 'EOF'
---
- name: Environment-Specific Deployment
  hosts: "{{ target_environment | default('development') }}"
  gather_facts: yes
  
  tasks:
    - name: Display environment information
      debug:
        msg: |
          Deploying to: {{ environment }}
          Database Host: {{ database_host }}
          API Endpoint: {{ api_endpoint }}
          Debug Mode: {{ debug_enabled }}
    
    - name: Create environment-specific configuration
      template:
        src: ../templates/app_config.j2
        dest: "/tmp/{{ environment }}_config.conf"
        mode: '0600'
      become: yes
    
    - name: Verify sensitive variables are loaded
      debug:
        msg: "Database password is configured (length: {{ vault_database_password | length }})"
      when: vault_database_password is defined
EOF
Subtask 6.4: Create Application Configuration Template
cat > templates/app_config.j2 << 'EOF'
# {{ environment | upper }} Environment Configuration
# Generated on {{ ansible_date_time.iso8601 }}

[application]
name = MyWebApp
environment = {{ environment }}
debug = {{ debug_enabled }}

[database]
host = {{ database_host }}
password = {{ vault_database_password }}

[api]
endpoint = {{ api_endpoint }}
secret = {{ vault_api_secret }}

[ssl]
private_key = {{ vault_ssl_key }}
EOF
Subtask 6.5: Test Environment-Specific Deployment
# Update inventory for environment groups
cat > inventory/hosts << 'EOF'
[development]
localhost ansible_connection=local

[production]
localhost ansible_connection=local

[webservers:children]
development
production
EOF
# Deploy to development environment
ansible-playbook -i inventory/hosts playbooks/environment_deployment.yml \
  --limit development \
  --vault-password-file .vault_password

# Deploy to production environment
ansible-playbook -i inventory/hosts playbooks/environment_deployment.yml \
  --limit production \
  --vault-password-file .vault_password
Subtask 6.6: Verify Environment Configurations
# Check development configuration
echo "=== Development Configuration ==="
sudo cat /tmp/development_config.conf

echo -e "\n=== Production Configuration ==="
sudo cat /tmp/production_config.conf
Task 7: Troubleshooting and Common Issues
Subtask 7.1: Handle Common Vault Errors
Let's simulate and fix common vault-related issues:

# Create a playbook that will fail without vault password
cat > playbooks/test_vault_errors.yml << 'EOF'
---
- name: Test Vault Error Handling
  hosts: localhost
  vars_files:
    - ../vars/database_secrets.yml
  
  tasks:
    - name: This will fail without vault password
      debug:
        msg: "Database user: {{ database_username }}"
EOF
# Try to run without vault password (this should fail)
echo "=== Testing without vault password (should fail) ==="
ansible-playbook -i inventory/hosts playbooks/test_vault_errors.yml || echo "Expected failure occurred"

# Run with correct vault password
echo -e "\n=== Running with correct vault password ==="
ansible-playbook -i inventory/hosts playbooks/test_vault_errors.yml --vault-password-file .vault_password
Subtask 7.2: Vault File Validation
# Check if files are properly encrypted
echo "=== Checking vault file status ==="
for file in vars/*.yml group_vars/*/vault.yml; do
    if [ -f "$file" ]; then
        echo "File: $file"
        if head -1 "$file" | grep -q "ANSIBLE_VAULT"; then
            echo "  Status: Encrypted ✓"
        else
            echo "  Status: Not encrypted ⚠️"
        fi
        echo
    fi
done
Subtask 7.3: Create Vault Management Script
cat > manage_vault.sh << 'EOF'
#!/bin/bash

# Vault management script
VAULT_PASSWORD_FILE=".vault_password"

case "$1" in
    "encrypt")
        if [ -z "$2" ]; then
            echo "Usage: $0 encrypt <file>"
            exit 1
        fi
        ansible-vault encrypt "$2" --vault-password-file "$VAULT_PASSWORD_FILE"
        ;;
    "decrypt")
        if [ -z "$2" ]; then
            echo "Usage: $0 decrypt <file>"
            exit 1
        fi
        ansible-vault decrypt "$2" --vault-password-file "$VAULT_PASSWORD_FILE"
        ;;
    "view")
        if [ -z "$2" ]; then
            echo "Usage: $0 view <file>"
            exit 1
        fi
        ansible-vault view "$2" --vault-password-file "$VAULT_PASSWORD_FILE"
        ;;
    "edit")
        if [ -z "$2" ]; then
            echo "Usage: $0 edit <file>"
            exit 1
        fi
        ansible-vault edit "$2" --vault-password-file "$VAULT_PASSWORD_FILE"
        ;;
    "status")
        echo "=== Vault Files Status ==="
        find . -name "*.yml" -type f | while read file; do
            if head -1 "$file" 2>/dev/null | grep -q "ANSIBLE_VAULT"; then
                echo "✓ $file (encrypted)"
            else
                echo "○ $file (plain text)"
            fi
        done
        ;;
    *)
        echo "Usage: $0 {encrypt|decrypt|view|edit|status} [file]"
        echo "Commands:"
        echo "  encrypt <file>  - Encrypt a file"
        echo "  decrypt <file>  - Decrypt a file"
        echo "  view <file>     - View encrypted file content"
        echo "  edit <file>     - Edit encrypted file"
        echo "  status          - Show encryption status of all YAML files"
        exit 1
        ;;
esac
EOF

chmod +x manage_vault.sh

# Test the script
./manage_vault.sh status
Conclusion
Congratulations! You have successfully completed Lab 18: Ansible Vault for Sensitive Data. In this comprehensive lab, you have accomplished the following:

Key Achievements
Security Implementation: You learned how to protect sensitive data such as passwords, API keys, and certificates using Ansible Vault encryption, ensuring that confidential information is never stored in plain text.

Vault Operations Mastery: You gained hands-on experience with all essential vault operations including encrypting files, creating encrypted files directly, viewing encrypted content, editing vault files, and changing vault passwords.

Playbook Integration: You successfully integrated encrypted variables into Ansible playbooks, demonstrating how to use sensitive data securely in automated deployments while maintaining the functionality of your automation scripts.

Environment Management: You implemented environment-specific configurations using encrypted group variables, showing how to manage different security requirements across development and production environments.

Best Practices Implementation: You learned and applied security best practices including proper file permissions, vault password management, and secure playbook structure organization.

Why This Matters
Production Security: In real-world scenarios, protecting sensitive data is crucial for maintaining security compliance and preventing data breaches. Ansible Vault provides enterprise-grade encryption for automation workflows.

Compliance Requirements: Many organizations must meet regulatory requirements (SOX, HIPAA, PCI-DSS) that mandate encryption of sensitive data. Ansible Vault helps meet these compliance standards.

Team Collaboration: Vault enables teams to share automation code safely without exposing sensitive credentials, making collaboration more secure and efficient.

Operational Excellence: By mastering Ansible Vault, you can build robust, secure automation that protects your organization's most valuable assets while maintaining operational efficiency.

Next Steps
To continue building your Ansible expertise, consider exploring:

Advanced vault features like multiple vault IDs
Integration with external secret management systems
Automated vault password rotation strategies
Ansible Tower/AWX integration for enterprise vault management
You now have the skills to implement secure automation practices that protect sensitive data while maintaining the power and flexibility of Ansible automation.
