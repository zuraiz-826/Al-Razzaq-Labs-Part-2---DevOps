Lab 13: Securing Sensitive Data with Ansible Vault
Objectives
By the end of this lab, you will be able to:

Create and encrypt sensitive variables using ansible-vault
Use encrypted variables in playbooks to protect sensitive data
Implement Vault for secure handling of credentials and secrets
Understand best practices for managing encrypted data in Ansible automation
Configure and manage vault passwords for team collaboration
Prerequisites
Before starting this lab, you should have:

Basic understanding of Ansible playbooks and variables
Familiarity with YAML syntax
Knowledge of Linux command line operations
Understanding of file permissions and security concepts
Completion of previous Ansible labs or equivalent experience
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS
Ansible 4.0+ pre-installed
Text editors (vim, nano)
Sample inventory files
Network connectivity between control and managed nodes
Task 1: Create and Encrypt Sensitive Variables Using ansible-vault
Subtask 1.1: Understanding Ansible Vault Basics
Ansible Vault is a feature that allows you to encrypt sensitive data such as passwords, keys, and other secrets within Ansible files.

Key Concepts:

Vault: Encrypted storage for sensitive data
Vault Password: The key used to encrypt/decrypt vault files
Vault ID: Labels for different vault passwords in complex environments
Subtask 1.2: Create Your First Encrypted Variable File
Navigate to your working directory:
cd /home/student/ansible-labs
mkdir lab13-vault
cd lab13-vault
Create a simple variables file with sensitive data:
cat > secrets.yml << 'EOF'
# Database credentials
db_username: admin
db_password: SuperSecret123!
db_host: database.example.com
db_port: 5432

# API keys
api_key: abc123def456ghi789
secret_token: xyz987uvw654rst321

# SSH credentials
ssh_private_key_path: /home/admin/.ssh/id_rsa
ssh_passphrase: MySSHPassphrase2023
EOF
Encrypt the file using ansible-vault:
ansible-vault encrypt secrets.yml
When prompted, enter a vault password (remember this password):

New Vault password: [enter your password]
Confirm New Vault password: [re-enter your password]
Verify the file is encrypted:
cat secrets.yml
You should see encrypted content starting with $ANSIBLE_VAULT;1.1;AES256

Subtask 1.3: Create Additional Encrypted Files
Create a production environment secrets file:
cat > prod-secrets.yml << 'EOF'
# Production database
prod_db_username: prod_admin
prod_db_password: Pr0d_S3cur3_P@ssw0rd!
prod_db_host: prod-db.company.com

# Production API credentials
prod_api_endpoint: https://api.production.company.com
prod_api_token: prod_abc123xyz789secure

# SSL certificates
ssl_cert_path: /etc/ssl/certs/company.crt
ssl_key_path: /etc/ssl/private/company.key
ssl_passphrase: SSL_Secure_2023!
EOF
Encrypt the production secrets:
ansible-vault encrypt prod-secrets.yml
Use the same password as before for consistency.

Subtask 1.4: Working with Encrypted Strings
Create individual encrypted strings:
ansible-vault encrypt_string 'DatabasePassword123!' --name 'database_password'
This will output an encrypted string that you can copy into playbooks.

Create a playbook with inline encrypted variables:
cat > secure-vars-playbook.yml << 'EOF'
---
- name: Playbook with encrypted variables
  hosts: localhost
  vars:
    username: admin
    password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          66386439653762336464626431626336396665663135363834643766386435626436396662313161
          3334633437303366366439326138316464376266323137650a626438346336643965386639323937
          63393265633831303264626266653864643835383564373334616263396330643832663062653834
          6664656264373765650a373936323837303739323835643765643966643439653838623939653939
          3739
  tasks:
    - name: Display username (safe to show)
      debug:
        msg: "Username: {{ username }}"
    
    - name: Use password securely (won't display actual value)
      debug:
        msg: "Password is configured"
EOF
Task 2: Use Encrypted Variables in Playbooks
Subtask 2.1: Create a Database Configuration Playbook
Create a playbook that uses encrypted variables:
cat > database-setup.yml << 'EOF'
---
- name: Configure Database Connection
  hosts: localhost
  vars_files:
    - secrets.yml
  tasks:
    - name: Create database configuration file
      copy:
        content: |
          [database]
          host={{ db_host }}
          port={{ db_port }}
          username={{ db_username }}
          password={{ db_password }}
          
          [api]
          key={{ api_key }}
          token={{ secret_token }}
        dest: /tmp/app-config.ini
        mode: '0600'
      
    - name: Display configuration file location
      debug:
        msg: "Database configuration created at /tmp/app-config.ini"
    
    - name: Verify file permissions
      stat:
        path: /tmp/app-config.ini
      register: config_file
    
    - name: Show file permissions
      debug:
        msg: "File permissions: {{ config_file.stat.mode }}"
EOF
Run the playbook with vault password:
ansible-playbook database-setup.yml --ask-vault-pass
Enter your vault password when prompted.

Subtask 2.2: Create a Multi-Environment Playbook
Create an inventory file with different environments:
cat > inventory.ini << 'EOF'
[development]
dev-server ansible_host=localhost

[production]
prod-server ansible_host=localhost

[all:vars]
ansible_connection=local
EOF
Create a multi-environment deployment playbook:
cat > deploy-app.yml << 'EOF'
---
- name: Deploy Application with Environment-Specific Secrets
  hosts: all
  vars_files:
    - secrets.yml
    - "{{ environment }}-secrets.yml"
  vars:
    app_name: "MySecureApp"
    app_version: "1.0.0"
  tasks:
    - name: Create application directory
      file:
        path: "/opt/{{ app_name }}"
        state: directory
        mode: '0755'
    
    - name: Deploy application configuration
      template:
        src: app-config.j2
        dest: "/opt/{{ app_name }}/config.yml"
        mode: '0600'
      
    - name: Create environment-specific database config
      copy:
        content: |
          environment: {{ environment }}
          database:
            host: "{{ prod_db_host | default(db_host) }}"
            username: "{{ prod_db_username | default(db_username) }}"
            password: "{{ prod_db_password | default(db_password) }}"
          api:
            endpoint: "{{ prod_api_endpoint | default('https://api.dev.company.com') }}"
            token: "{{ prod_api_token | default(api_key) }}"
        dest: "/opt/{{ app_name }}/env-config.yml"
        mode: '0600'
    
    - name: Display deployment summary
      debug:
        msg: |
          Application {{ app_name }} v{{ app_version }} deployed successfully
          Environment: {{ environment }}
          Config location: /opt/{{ app_name }}/
EOF
Create a Jinja2 template for application configuration:
mkdir -p templates
cat > templates/app-config.j2 << 'EOF'
# {{ app_name }} Configuration
# Generated by Ansible on {{ ansible_date_time.iso8601 }}

application:
  name: {{ app_name }}
  version: {{ app_version }}
  environment: {{ environment }}

security:
  encryption_enabled: true
  vault_managed: true
  
logging:
  level: {% if environment == 'production' %}INFO{% else %}DEBUG{% endif %}
  
database:
  connection_encrypted: true
  # Actual credentials stored securely in vault
EOF
Run the playbook for development environment:
ansible-playbook deploy-app.yml -i inventory.ini --limit development --ask-vault-pass -e environment=dev
Run the playbook for production environment:
ansible-playbook deploy-app.yml -i inventory.ini --limit production --ask-vault-pass -e environment=prod
Subtask 2.3: Create a User Management Playbook with Encrypted Passwords
Create encrypted user passwords:
# Create a file with user credentials
cat > user-secrets.yml << 'EOF'
# User account passwords
users:
  - name: alice
    password: Alice_Secure_2023!
    groups: ['developers', 'sudo']
  - name: bob
    password: Bob_Admin_Pass_2023!
    groups: ['admins', 'sudo']
  - name: charlie
    password: Charlie_User_2023!
    groups: ['users']

# Service account credentials
service_accounts:
  - name: webapp
    password: WebApp_Service_2023!
    home: /opt/webapp
  - name: dbuser
    password: DB_Service_Account_2023!
    home: /var/lib/dbuser
EOF
Encrypt the user secrets file:
ansible-vault encrypt user-secrets.yml
Create a user management playbook:
cat > user-management.yml << 'EOF'
---
- name: Manage Users with Encrypted Passwords
  hosts: localhost
  become: yes
  vars_files:
    - user-secrets.yml
  tasks:
    - name: Create user groups
      group:
        name: "{{ item }}"
        state: present
      loop:
        - developers
        - admins
        - users
    
    - name: Create regular users with encrypted passwords
      user:
        name: "{{ item.name }}"
        password: "{{ item.password | password_hash('sha512') }}"
        groups: "{{ item.groups }}"
        shell: /bin/bash
        create_home: yes
        state: present
      loop: "{{ users }}"
      no_log: true  # Prevents passwords from appearing in logs
    
    - name: Create service accounts
      user:
        name: "{{ item.name }}"
        password: "{{ item.password | password_hash('sha512') }}"
        home: "{{ item.home }}"
        shell: /bin/bash
        system: yes
        create_home: yes
        state: present
      loop: "{{ service_accounts }}"
      no_log: true
    
    - name: Display created users (without sensitive data)
      debug:
        msg: "Created user: {{ item.name }} with groups: {{ item.groups | join(', ') }}"
      loop: "{{ users }}"
EOF
Run the user management playbook:
ansible-playbook user-management.yml --ask-vault-pass --ask-become-pass
Task 3: Implement Vault for Secure Handling of Credentials
Subtask 3.1: Set Up Vault Password Files
Create a vault password file (for automation):
# Create a secure directory for vault passwords
mkdir -p ~/.ansible/vault
chmod 700 ~/.ansible/vault

# Create a vault password file
echo "MyVaultPassword2023!" > ~/.ansible/vault/lab13_pass
chmod 600 ~/.ansible/vault/lab13_pass
Configure ansible.cfg to use the password file:
cat > ansible.cfg << 'EOF'
[defaults]
host_key_checking = False
inventory = inventory.ini
vault_password_file = ~/.ansible/vault/lab13_pass

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
EOF
Test running playbooks without password prompts:
ansible-playbook database-setup.yml
Subtask 3.2: Implement Multiple Vault IDs
Create different vault files for different purposes:
# Create development vault password
echo "DevVaultPass2023!" > ~/.ansible/vault/dev_pass
chmod 600 ~/.ansible/vault/dev_pass

# Create production vault password  
echo "ProdVaultPass2023!" > ~/.ansible/vault/prod_pass
chmod 600 ~/.ansible/vault/prod_pass
Create vault files with different vault IDs:
# Create development secrets with dev vault ID
cat > dev-secrets.yml << 'EOF'
dev_database_url: "postgresql://dev:devpass@dev-db:5432/myapp"
dev_api_key: "dev_api_key_12345"
dev_secret_key: "dev_secret_key_67890"
EOF

ansible-vault encrypt dev-secrets.yml --vault-id dev@~/.ansible/vault/dev_pass
Create production secrets with production vault ID:
# Create production secrets with prod vault ID
cat > prod-secrets-multi.yml << 'EOF'
prod_database_url: "postgresql://prod:prodpass@prod-db:5432/myapp"
prod_api_key: "prod_api_key_abcdef"
prod_secret_key: "prod_secret_key_ghijkl"
EOF

ansible-vault encrypt prod-secrets-multi.yml --vault-id prod@~/.ansible/vault/prod_pass
Create a playbook that uses multiple vault IDs:
cat > multi-vault-playbook.yml << 'EOF'
---
- name: Deploy with Multiple Vault IDs
  hosts: localhost
  vars_files:
    - dev-secrets.yml
    - prod-secrets-multi.yml
  tasks:
    - name: Show development configuration
      debug:
        msg: "Dev API Key configured: {{ 'Yes' if dev_api_key is defined else 'No' }}"
    
    - name: Show production configuration  
      debug:
        msg: "Prod API Key configured: {{ 'Yes' if prod_api_key is defined else 'No' }}"
    
    - name: Create combined configuration
      copy:
        content: |
          # Multi-environment configuration
          [development]
          database_url={{ dev_database_url }}
          api_key={{ dev_api_key }}
          
          [production]
          database_url={{ prod_database_url }}
          api_key={{ prod_api_key }}
        dest: /tmp/multi-env-config.ini
        mode: '0600'
EOF
Run the playbook with multiple vault IDs:
ansible-playbook multi-vault-playbook.yml --vault-id dev@~/.ansible/vault/dev_pass --vault-id prod@~/.ansible/vault/prod_pass
Subtask 3.3: Implement Secure Credential Rotation
Create a credential rotation playbook:
cat > rotate-credentials.yml << 'EOF'
---
- name: Rotate Database Credentials
  hosts: localhost
  vars_files:
    - secrets.yml
  vars:
    new_password: "{{ lookup('password', '/tmp/new_db_password chars=ascii_letters,digits,punctuation length=16') }}"
  tasks:
    - name: Generate new secure password
      set_fact:
        generated_password: "{{ lookup('password', '/dev/null chars=ascii_letters,digits length=20') }}"
    
    - name: Display password generation confirmation
      debug:
        msg: "New password generated successfully"
    
    - name: Update database with new password (simulation)
      debug:
        msg: "Would update database password for user {{ db_username }}"
    
    - name: Create new secrets file with rotated credentials
      copy:
        content: |
          # Updated database credentials - {{ ansible_date_time.iso8601 }}
          db_username: {{ db_username }}
          db_password: {{ generated_password }}
          db_host: {{ db_host }}
          db_port: {{ db_port }}
          
          # Keep existing API credentials
          api_key: {{ api_key }}
          secret_token: {{ secret_token }}
          
          # SSH credentials (unchanged)
          ssh_private_key_path: {{ ssh_private_key_path }}
          ssh_passphrase: {{ ssh_passphrase }}
        dest: /tmp/new-secrets.yml
        mode: '0600'
    
    - name: Encrypt new secrets file
      shell: ansible-vault encrypt /tmp/new-secrets.yml --vault-password-file ~/.ansible/vault/lab13_pass
    
    - name: Create backup of old secrets
      copy:
        src: secrets.yml
        dest: "secrets.yml.backup.{{ ansible_date_time.epoch }}"
        mode: '0600'
    
    - name: Display rotation summary
      debug:
        msg: |
          Credential rotation completed:
          - New encrypted secrets: /tmp/new-secrets.yml
          - Backup created: secrets.yml.backup.{{ ansible_date_time.epoch }}
          - Manual step: Replace secrets.yml with new-secrets.yml after testing
EOF
Run the credential rotation playbook:
ansible-playbook rotate-credentials.yml
Subtask 3.4: Create Vault Management Utilities
Create a script to view encrypted files:
cat > view-vault.sh << 'EOF'
#!/bin/bash

# Script to safely view vault files
if [ $# -eq 0 ]; then
    echo "Usage: $0 <vault-file>"
    echo "Example: $0 secrets.yml"
    exit 1
fi

VAULT_FILE=$1

if [ ! -f "$VAULT_FILE" ]; then
    echo "Error: File $VAULT_FILE not found"
    exit 1
fi

echo "Viewing contents of encrypted file: $VAULT_FILE"
echo "================================================"
ansible-vault view "$VAULT_FILE" --vault-password-file ~/.ansible/vault/lab13_pass
EOF

chmod +x view-vault.sh
Create a script to edit encrypted files:
cat > edit-vault.sh << 'EOF'
#!/bin/bash

# Script to safely edit vault files
if [ $# -eq 0 ]; then
    echo "Usage: $0 <vault-file>"
    echo "Example: $0 secrets.yml"
    exit 1
fi

VAULT_FILE=$1

echo "Editing encrypted file: $VAULT_FILE"
echo "===================================="
ansible-vault edit "$VAULT_FILE" --vault-password-file ~/.ansible/vault/lab13_pass
EOF

chmod +x edit-vault.sh
Test the vault management utilities:
# View a vault file
./view-vault.sh secrets.yml

# Edit a vault file (will open in default editor)
# ./edit-vault.sh secrets.yml
Create a vault health check script:
cat > vault-health-check.sh << 'EOF'
#!/bin/bash

echo "Ansible Vault Health Check"
echo "=========================="

# Check if vault password file exists
if [ -f ~/.ansible/vault/lab13_pass ]; then
    echo "✓ Vault password file exists"
else
    echo "✗ Vault password file missing"
fi

# Check vault files
VAULT_FILES=("secrets.yml" "prod-secrets.yml" "user-secrets.yml" "dev-secrets.yml" "prod-secrets-multi.yml")

for file in "${VAULT_FILES[@]}"; do
    if [ -f "$file" ]; then
        if ansible-vault view "$file" --vault-password-file ~/.ansible/vault/lab13_pass > /dev/null 2>&1; then
            echo "✓ $file - encrypted and accessible"
        else
            echo "✗ $file - encryption issue or wrong password"
        fi
    else
        echo "- $file - not found (may be optional)"
    fi
done

# Check ansible.cfg
if [ -f "ansible.cfg" ]; then
    echo "✓ ansible.cfg exists"
else
    echo "✗ ansible.cfg missing"
fi

echo ""
echo "Health check completed"
EOF

chmod +x vault-health-check.sh
Run the health check:
./vault-health-check.sh
Verification and Testing
Test All Vault Functionality
Verify encrypted files can be decrypted:
ansible-vault view secrets.yml --vault-password-file ~/.ansible/vault/lab13_pass
Test playbook execution with vault:
ansible-playbook database-setup.yml
Verify file permissions are secure:
ls -la *secrets*.yml
ls -la ~/.ansible/vault/
Test vault editing functionality:
# Create a test vault file
echo "test_var: test_value" > test-vault.yml
ansible-vault encrypt test-vault.yml --vault-password-file ~/.ansible/vault/lab13_pass

# View it
./view-vault.sh test-vault.yml

# Clean up
rm test-vault.yml
Troubleshooting Common Issues
Issue 1: Vault Password Errors
Problem: "ERROR! Attempting to decrypt but no vault secrets found"

Solution:

# Check if file is actually encrypted
file secrets.yml

# Verify vault password file
cat ~/.ansible/vault/lab13_pass

# Test decryption manually
ansible-vault decrypt secrets.yml --vault-password-file ~/.ansible/vault/lab13_pass
ansible-vault encrypt secrets.yml --vault-password-file ~/.ansible/vault/lab13_pass
Issue 2: Permission Denied Errors
Problem: Cannot read vault password file

Solution:

# Fix permissions
chmod 600 ~/.ansible/vault/lab13_pass
chmod 700 ~/.ansible/vault/
Issue 3: Multiple Vault ID Conflicts
Problem: Wrong vault ID used for decryption

Solution:

# Check which vault ID was used
ansible-vault view secrets.yml --vault-id dev@~/.ansible/vault/dev_pass
ansible-vault view secrets.yml --vault-id prod@~/.ansible/vault/prod_pass
Best Practices Summary
Password Management:

Use strong, unique vault passwords
Store vault passwords securely
Rotate vault passwords regularly
File Organization:

Separate vault files by environment
Use descriptive naming conventions
Maintain proper file permissions (600)
Security:

Never commit vault passwords to version control
Use no_log: true for sensitive tasks
Regularly audit vault file access
Automation:

Use vault password files for automated deployments
Implement credential rotation procedures
Create health check scripts
Conclusion
In this lab, you have successfully learned how to secure sensitive data using Ansible Vault. You accomplished the following key objectives:

What You Learned:

Created and encrypted sensitive variables using ansible-vault commands
Integrated encrypted variables into playbooks for secure automation
Implemented comprehensive vault management for handling credentials safely
Set up multiple vault IDs for different environments
Created utility scripts for vault management and health checking
Why This Matters: Ansible Vault is crucial for production environments where sensitive data like passwords, API keys, and certificates must be protected. By mastering these skills, you can:

Maintain security compliance in automated deployments
Protect sensitive data from unauthorized access
Enable secure collaboration in team environments
Implement proper credential management practices
Prepare for RHCE certification requirements
Real-World Applications:

Securing database credentials in web application deployments
Managing API keys for cloud service integrations
Protecting SSL certificates and private keys
Implementing secure user account management
Enabling secure CI/CD pipeline automation
The skills you've developed in this lab are essential for any DevOps engineer working with Ansible in production environments, and they directly align with Red Hat Certified Engineer (RHCE) exam objectives for secure automation practices.
