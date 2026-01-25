Lab 4: Secure Sensitive Data with Ansible Vault
Objectives
By the end of this lab, students will be able to:

Understand the importance of securing sensitive data in automation workflows
Create and manage Ansible Vault encrypted files
Use ansible-vault commands to encrypt and decrypt sensitive information
Integrate encrypted variables into Ansible playbooks securely
Implement best practices for handling passwords and sensitive data in Ansible
Prerequisites
Before starting this lab, students should have:

Basic understanding of Linux command line operations
Familiarity with Ansible fundamentals (playbooks, variables, and tasks)
Knowledge of YAML syntax
Understanding of file permissions and text editors in Linux
Completion of previous Ansible labs or equivalent experience
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with Ansible already installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your lab environment includes:

CentOS/RHEL 8 or Ubuntu 20.04 LTS
Ansible 4.0+ pre-installed
Text editors (vim, nano) available
All necessary permissions configured
Task 1: Create an Ansible Vault to Secure Passwords
Subtask 1.1: Understanding Ansible Vault
Ansible Vault is a feature that allows you to encrypt sensitive data such as passwords, API keys, and certificates. This ensures that sensitive information is not stored in plain text within your playbooks or variable files.

Subtask 1.2: Create a Working Directory
First, let's create a dedicated directory for our vault exercises:

mkdir ~/ansible-vault-lab
cd ~/ansible-vault-lab
Subtask 1.3: Create Your First Encrypted File
Create an encrypted file containing database passwords:

ansible-vault create secrets.yml
When prompted, enter a vault password (remember this password - you'll need it throughout the lab):

New Vault password: mySecurePassword123
Confirm New Vault password: mySecurePassword123
The command will open your default editor. Add the following content:

---
# Database credentials
db_user: admin
db_password: SuperSecretPassword123
db_host: database.example.com
db_port: 5432

# API credentials
api_key: abc123def456ghi789
api_secret: xyz987uvw654rst321

# SSH credentials
ssh_private_key_password: MySSHKeyPassword456
Save and exit the editor (in vim: press Esc, type :wq, press Enter).

Subtask 1.4: Verify the Encrypted File
View the encrypted file to confirm it's properly secured:

cat secrets.yml
You should see encrypted content that looks similar to:

$ANSIBLE_VAULT;1.1;AES256
66386439653765386661373563643464336464643437643766386435663632343266393064373865
3131373132633264626464626138653863353230383566660a653638643435666633633964366136
...
Subtask 1.5: Create a Password File (Optional but Recommended)
For automation purposes, create a password file:

echo "mySecurePassword123" > .vault_password
chmod 600 .vault_password
Important: In production environments, store this file securely and never commit it to version control.

Task 2: Use ansible-vault to Encrypt and Decrypt Files
Subtask 2.1: Create a Plain Text File to Encrypt
Create a configuration file with sensitive information:

cat > database_config.yml << EOF
---
database_settings:
  primary_db:
    username: root
    password: RootPassword123
    host: primary-db.internal
  backup_db:
    username: backup_user
    password: BackupPassword456
    host: backup-db.internal
  
application_secrets:
  jwt_secret: jwt_super_secret_key_2023
  encryption_key: encryption_key_very_secure
EOF
Subtask 2.2: Encrypt an Existing File
Encrypt the plain text file you just created:

ansible-vault encrypt database_config.yml
Enter your vault password when prompted. Verify the file is now encrypted:

cat database_config.yml
Subtask 2.3: View Encrypted File Content
To view the content of an encrypted file without decrypting it permanently:

ansible-vault view database_config.yml
Enter your vault password to see the decrypted content temporarily.

Subtask 2.4: Edit Encrypted Files
To edit an encrypted file:

ansible-vault edit database_config.yml
Add the following section to the file:

monitoring_credentials:
  grafana_admin: admin
  grafana_password: GrafanaSecure789
  prometheus_token: prom_token_secure_123
Save and exit the editor.

Subtask 2.5: Decrypt Files
To permanently decrypt a file (use with caution):

# Create a copy first for safety
cp database_config.yml database_config_backup.yml

# Decrypt the copy
ansible-vault decrypt database_config_backup.yml
View the decrypted content:

cat database_config_backup.yml
Subtask 2.6: Change Vault Password
Change the password for an encrypted file:

ansible-vault rekey secrets.yml
Enter the old password, then the new password twice.

Subtask 2.7: Using Password Files
Demonstrate using a password file to avoid interactive prompts:

# View file using password file
ansible-vault view secrets.yml --vault-password-file .vault_password

# Edit file using password file
ansible-vault edit secrets.yml --vault-password-file .vault_password
Task 3: Use Encrypted Variables in Playbooks Securely
Subtask 3.1: Create a Test Inventory
Create an inventory file for our playbook:

cat > inventory.ini << EOF
[webservers]
localhost ansible_connection=local

[databases]
localhost ansible_connection=local
EOF
Subtask 3.2: Create a Playbook Using Encrypted Variables
Create a playbook that uses the encrypted variables:

cat > secure_deployment.yml << EOF
---
- name: Secure Application Deployment
  hosts: webservers
  vars_files:
    - secrets.yml
    - database_config.yml
  
  tasks:
    - name: Display database connection info (masked)
      debug:
        msg: "Connecting to database {{ db_host }}:{{ db_port }} as user {{ db_user }}"
    
    - name: Create database configuration file
      copy:
        content: |
          [database]
          host={{ database_settings.primary_db.host }}
          username={{ database_settings.primary_db.username }}
          password={{ database_settings.primary_db.password }}
          
          [backup_database]
          host={{ database_settings.backup_db.host }}
          username={{ database_settings.backup_db.username }}
          password={{ database_settings.backup_db.password }}
        dest: /tmp/app_database.conf
        mode: '0600'
      
    - name: Create API configuration
      copy:
        content: |
          API_KEY={{ api_key }}
          API_SECRET={{ api_secret }}
          JWT_SECRET={{ application_secrets.jwt_secret }}
        dest: /tmp/api_config.env
        mode: '0600'
    
    - name: Verify files were created
      stat:
        path: "{{ item }}"
      register: file_stats
      loop:
        - /tmp/app_database.conf
        - /tmp/api_config.env
    
    - name: Display file creation status
      debug:
        msg: "File {{ item.item }} exists: {{ item.stat.exists }}"
      loop: "{{ file_stats.results }}"
EOF
Subtask 3.3: Run the Playbook with Vault Password
Execute the playbook using the vault password:

ansible-playbook -i inventory.ini secure_deployment.yml --ask-vault-pass
Enter your vault password when prompted.

Subtask 3.4: Run Playbook with Password File
Execute the playbook using the password file:

ansible-playbook -i inventory.ini secure_deployment.yml --vault-password-file .vault_password
Subtask 3.5: Verify Secure File Creation
Check that the configuration files were created with proper permissions:

ls -la /tmp/app_database.conf /tmp/api_config.env
View the contents (they should contain the decrypted values):

cat /tmp/app_database.conf
echo "---"
cat /tmp/api_config.env
Subtask 3.6: Create a Playbook with Mixed Variables
Create a playbook that combines encrypted and non-encrypted variables:

cat > mixed_variables.yml << EOF
---
- name: Mixed Variables Example
  hosts: localhost
  vars:
    # Non-sensitive variables (plain text)
    app_name: "MySecureApp"
    app_version: "1.2.3"
    environment: "production"
    
  vars_files:
    # Sensitive variables (encrypted)
    - secrets.yml
  
  tasks:
    - name: Display application info
      debug:
        msg: |
          Application: {{ app_name }}
          Version: {{ app_version }}
          Environment: {{ environment }}
          Database Host: {{ db_host }}
          Database User: {{ db_user }}
    
    - name: Create application configuration
      copy:
        content: |
          # Application Configuration
          APP_NAME={{ app_name }}
          APP_VERSION={{ app_version }}
          ENVIRONMENT={{ environment }}
          
          # Database Configuration (from vault)
          DB_HOST={{ db_host }}
          DB_PORT={{ db_port }}
          DB_USER={{ db_user }}
          DB_PASSWORD={{ db_password }}
          
          # API Configuration (from vault)
          API_KEY={{ api_key }}
          API_SECRET={{ api_secret }}
        dest: /tmp/complete_app_config.env
        mode: '0600'
    
    - name: Display success message
      debug:
        msg: "Configuration file created successfully with mixed variables"
EOF
Subtask 3.7: Execute Mixed Variables Playbook
Run the playbook:

ansible-playbook mixed_variables.yml --vault-password-file .vault_password
Subtask 3.8: Advanced Vault Usage - Multiple Vault IDs
Create files with different vault passwords for different environments:

# Create production secrets
echo "ProductionVaultPass123" > .vault_password_prod
chmod 600 .vault_password_prod

ansible-vault create --vault-id prod@.vault_password_prod prod_secrets.yml
Add production-specific content:

---
prod_db_password: ProductionDBPassword789
prod_api_key: prod_api_key_secure_456
ssl_certificate_password: SSLCertPassword123
Create a playbook using multiple vault IDs:

cat > multi_vault_playbook.yml << EOF
---
- name: Multi-Vault Environment Deployment
  hosts: localhost
  vars_files:
    - secrets.yml  # Default vault
    - prod_secrets.yml  # Production vault
  
  tasks:
    - name: Display environment-specific database password
      debug:
        msg: "Production DB Password is configured"
        # Note: Never actually display passwords in debug messages
    
    - name: Create environment-specific config
      copy:
        content: |
          # Development Database
          DEV_DB_PASSWORD={{ db_password }}
          
          # Production Database  
          PROD_DB_PASSWORD={{ prod_db_password }}
          
          # API Keys
          DEV_API_KEY={{ api_key }}
          PROD_API_KEY={{ prod_api_key }}
        dest: /tmp/multi_env_config.env
        mode: '0600'
EOF
Run with multiple vault passwords:

ansible-playbook multi_vault_playbook.yml --vault-id default@.vault_password --vault-id prod@.vault_password_prod
Troubleshooting Common Issues
Issue 1: Forgot Vault Password
Problem: Cannot decrypt vault files because you forgot the password.

Solution: Unfortunately, there's no way to recover a forgotten vault password. Always:

Keep passwords in a secure password manager
Maintain backup copies of important vault files with known passwords
Document password storage locations securely
Issue 2: Permission Denied Errors
Problem: Getting permission errors when creating files.

Solution:

# Check current directory permissions
ls -la

# Ensure you have write permissions
chmod 755 ~/ansible-vault-lab
Issue 3: Vault File Corruption
Problem: Vault file appears corrupted or won't decrypt.

Solution:

# Check file integrity
file secrets.yml

# Verify it's a proper vault file
head -1 secrets.yml
# Should show: $ANSIBLE_VAULT;1.1;AES256
Issue 4: Editor Issues
Problem: Default editor is difficult to use.

Solution:

# Set a preferred editor
export EDITOR=nano
# or
export EDITOR=vim

# Then use vault commands normally
ansible-vault edit secrets.yml
Best Practices and Security Considerations
Security Best Practices
Never commit vault passwords to version control

# Add to .gitignore
echo ".vault_password*" >> .gitignore
echo "*.vault_pass" >> .gitignore
Use strong, unique passwords for vaults

Minimum 12 characters
Include uppercase, lowercase, numbers, and symbols
Use different passwords for different environments
Limit access to vault files

chmod 600 *.yml
chmod 600 .vault_password*
Regular password rotation

# Change vault passwords periodically
ansible-vault rekey secrets.yml
Use vault IDs for multiple environments

# Separate vault files for different environments
ansible-vault create --vault-id dev@prompt dev_secrets.yml
ansible-vault create --vault-id prod@prompt prod_secrets.yml
Cleanup
Remove the lab files and sensitive data:

# Remove temporary configuration files
rm -f /tmp/app_database.conf
rm -f /tmp/api_config.env  
rm -f /tmp/complete_app_config.env
rm -f /tmp/multi_env_config.env

# Remove lab directory (optional)
cd ~
rm -rf ~/ansible-vault-lab
Conclusion
In this lab, you have successfully learned how to:

Secure sensitive data using Ansible Vault encryption to protect passwords, API keys, and other confidential information
Master vault operations including creating, encrypting, decrypting, editing, and viewing encrypted files
Integrate encrypted variables seamlessly into Ansible playbooks while maintaining security
Implement advanced vault features such as multiple vault IDs for different environments
Apply security best practices for handling sensitive data in automation workflows
Why This Matters: In real-world DevOps and automation scenarios, protecting sensitive information is crucial for:

Compliance: Meeting security standards and regulations
Risk Management: Preventing data breaches and unauthorized access
Professional Standards: Following industry best practices for infrastructure automation
Career Advancement: Demonstrating security-conscious automation skills required for Red Hat certifications and enterprise roles
The skills you've developed in this lab are essential for the Red Hat Certified Specialist in Services Management and Automation exam and are directly applicable to production environments where security is paramount. You can now confidently handle sensitive data in Ansible automation while maintaining the highest security standards.
