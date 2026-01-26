Lab 12: Encrypting Data with GPG
Objectives
By the end of this lab, students will be able to:

• Generate and manage GPG key pairs for secure communication • Encrypt and decrypt files using GPG symmetric and asymmetric encryption • Create and verify digital signatures to ensure data integrity and authenticity • Import and export GPG keys for sharing with other users • Understand the fundamentals of public key cryptography in practice

Prerequisites
Before starting this lab, students should have:

• Basic understanding of Linux command line operations • Familiarity with file system navigation and basic file operations • Understanding of cryptographic concepts such as public/private keys • Knowledge of text editors like nano or vim

Lab Environment Setup
Al Nafi Cloud Machines: This lab uses Linux-based cloud machines provided by Al Nafi. Simply click Start Lab to access your pre-configured environment. No need to build your own virtual machine or install additional software.

Your cloud machine comes with: • GPG (GNU Privacy Guard) pre-installed • Text editors (nano, vim) available • Sample files for practice

Task 1: Set up GPG Keys for Encryption
Subtask 1.1: Check GPG Installation and Version
First, let's verify that GPG is installed and check its version.

gpg --version
You should see output showing GPG version 2.x or higher. If GPG is not installed, use:

# For Ubuntu/Debian systems
sudo apt update && sudo apt install gnupg

# For CentOS/RHEL systems
sudo yum install gnupg2
Subtask 1.2: Generate Your First GPG Key Pair
Generate a new GPG key pair that will be used for encryption and signing.

gpg --full-generate-key
Follow the interactive prompts:

Key type: Select (1) RSA and RSA (default)
Key size: Enter 4096 for maximum security
Key validity: Enter 1y for 1 year (or 0 for no expiration)
Real name: Enter your full name (e.g., "John Student")
Email address: Enter your email (e.g., "john.student@example.com")
Comment: Enter a comment (e.g., "Lab Practice Key")
Passphrase: Create a strong passphrase and remember it
Example interaction:

Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
Your selection? 1

RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (3072) 4096

Key is valid for? (0) 1y
Subtask 1.3: List Your GPG Keys
Verify that your key pair was created successfully.

# List public keys
gpg --list-keys

# List private keys
gpg --list-secret-keys
Take note of your Key ID (the 8-character string after the key size).

Subtask 1.4: Export Your Public Key
Export your public key to share with others for encrypted communication.

# Export in ASCII format (human-readable)
gpg --armor --export your-email@example.com > my-public-key.asc

# View the exported key
cat my-public-key.asc
Replace your-email@example.com with the email you used when creating the key.

Task 2: Encrypt and Decrypt Files with GPG
Subtask 2.1: Create Sample Files for Testing
Create some sample files to practice encryption and decryption.

# Create a directory for lab files
mkdir ~/gpg-lab
cd ~/gpg-lab

# Create sample text files
echo "This is confidential information for Lab 12" > secret-message.txt
echo "Financial data: Account balance $50,000" > financial-data.txt
echo "Personal information: SSN 123-45-6789" > personal-info.txt

# Verify files were created
ls -la
Subtask 2.2: Symmetric Encryption (Password-Based)
Encrypt a file using symmetric encryption where the same password is used for both encryption and decryption.

# Encrypt using symmetric encryption
gpg --symmetric --cipher-algo AES256 secret-message.txt

# This creates secret-message.txt.gpg
ls -la *.gpg
You'll be prompted to enter a passphrase. Choose a strong password and remember it.

Subtask 2.3: Decrypt Symmetrically Encrypted File
Decrypt the file you just encrypted.

# Decrypt the file
gpg --decrypt secret-message.txt.gpg > decrypted-message.txt

# Verify the content
cat decrypted-message.txt
Subtask 2.4: Asymmetric Encryption (Public Key)
Encrypt a file using your public key (asymmetric encryption).

# Encrypt for yourself using your email/key ID
gpg --encrypt --armor --recipient your-email@example.com financial-data.txt

# This creates financial-data.txt.asc
ls -la *.asc
Subtask 2.5: Decrypt Asymmetrically Encrypted File
Decrypt the file using your private key.

# Decrypt the file
gpg --decrypt financial-data.txt.asc > decrypted-financial.txt

# Verify the content
cat decrypted-financial.txt
You'll be prompted for your GPG key passphrase.

Subtask 2.6: Encrypt for Multiple Recipients
Create a scenario where you encrypt a file for multiple recipients.

# First, let's create another key pair for demonstration
gpg --quick-generate-key "Lab Partner <partner@example.com>" rsa4096 encrypt 1y

# Encrypt for multiple recipients
gpg --encrypt --armor \
    --recipient your-email@example.com \
    --recipient partner@example.com \
    personal-info.txt

# This creates personal-info.txt.asc
Task 3: Verify Signatures Using GPG
Subtask 3.1: Create Digital Signatures
Digital signatures ensure data integrity and authenticity.

# Create a detached signature
gpg --detach-sign --armor secret-message.txt

# This creates secret-message.txt.asc (signature file)
ls -la secret-message.txt*
Subtask 3.2: Verify Digital Signatures
Verify that the signature is valid and the file hasn't been tampered with.

# Verify the signature
gpg --verify secret-message.txt.asc secret-message.txt
You should see output indicating "Good signature from [your name]".

Subtask 3.3: Sign and Encrypt Simultaneously
Combine signing and encryption for maximum security.

# Sign and encrypt in one operation
gpg --sign --encrypt --armor \
    --recipient your-email@example.com \
    --output secure-document.asc \
    financial-data.txt

# Verify the signed and encrypted file
gpg --decrypt secure-document.asc > verified-financial.txt
Subtask 3.4: Test Signature Verification with Modified File
Demonstrate what happens when a signed file is modified.

# Create a new file and sign it
echo "Original content for verification test" > test-integrity.txt
gpg --detach-sign --armor test-integrity.txt

# Verify original signature (should succeed)
gpg --verify test-integrity.txt.asc test-integrity.txt

# Modify the file
echo "Modified content - signature should fail" > test-integrity.txt

# Try to verify again (should fail)
gpg --verify test-integrity.txt.asc test-integrity.txt
Subtask 3.5: Import and Trust External Keys
Practice importing someone else's public key and establishing trust.

# Create a sample external key for demonstration
gpg --quick-generate-key "External User <external@example.com>" rsa4096 encrypt 1y

# Export this key as if it came from someone else
gpg --armor --export external@example.com > external-public-key.asc

# Delete the key from your keyring
gpg --delete-secret-keys external@example.com
gpg --delete-keys external@example.com

# Import the "external" key
gpg --import external-public-key.asc

# List imported keys
gpg --list-keys external@example.com

# Check trust level
gpg --list-keys --with-colons external@example.com | grep "^pub"
Advanced Operations
Key Management Commands
Here are additional useful GPG commands for key management:

# Edit key properties (trust, expiration, etc.)
gpg --edit-key your-email@example.com

# Backup your private key (KEEP SECURE!)
gpg --export-secret-keys --armor your-email@example.com > private-key-backup.asc

# Revoke a key (if compromised)
gpg --generate-revocation your-email@example.com > revocation-certificate.asc

# Search for keys on keyserver
gpg --keyserver keyserver.ubuntu.com --search-keys someone@example.com

# Send your key to keyserver
gpg --keyserver keyserver.ubuntu.com --send-keys YOUR-KEY-ID
Batch Operations
For automating GPG operations:

# Create a batch file for unattended operations
cat > batch-encrypt.sh << 'EOF'
#!/bin/bash
for file in *.txt; do
    if [ -f "$file" ]; then
        gpg --trust-model always --encrypt --armor \
            --recipient your-email@example.com \
            --output "${file}.encrypted" \
            "$file"
        echo "Encrypted: $file"
    fi
done
EOF

chmod +x batch-encrypt.sh
./batch-encrypt.sh
Troubleshooting Common Issues
Issue 1: "No such file or directory" when decrypting
Problem: GPG can't find the encrypted file. Solution:

# Check current directory and file names
ls -la *.gpg *.asc
# Use full path if necessary
gpg --decrypt /full/path/to/file.gpg
Issue 2: "No secret key" error
Problem: Trying to decrypt with wrong key or key not available. Solution:

# List available secret keys
gpg --list-secret-keys
# Make sure you're using the correct recipient email/key ID
Issue 3: "Bad passphrase" repeatedly
Problem: Incorrect passphrase or GPG agent issues. Solution:

# Kill GPG agent and restart
gpgconf --kill gpg-agent
# Try the operation again
Issue 4: Permission denied errors
Problem: Incorrect file permissions on GPG directory. Solution:

# Fix GPG directory permissions
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/*
Security Best Practices
Key Management Security
• Use strong passphrases with at least 12 characters including mixed case, numbers, and symbols • Backup your private keys securely and store them offline • Set key expiration dates and renew them regularly • Generate revocation certificates immediately after key creation • Never share your private key or passphrase with anyone

Operational Security
• Verify key fingerprints through secure channels before trusting • Use the strongest available algorithms (RSA 4096-bit minimum) • Keep GPG software updated to latest versions • Use secure systems for key generation and storage • Regularly audit your keyring and remove unused keys

Lab Summary and Verification
Verification Checklist
Ensure you have completed all tasks by checking the following:

# 1. Verify you have generated keys
gpg --list-secret-keys | grep -c "sec"

# 2. Check encrypted files exist
ls -la ~/gpg-lab/*.gpg ~/gpg-lab/*.asc | wc -l

# 3. Verify you can decrypt your own files
gpg --decrypt ~/gpg-lab/secret-message.txt.gpg > /tmp/test-decrypt.txt
cat /tmp/test-decrypt.txt

# 4. Check signature verification works
gpg --verify ~/gpg-lab/secret-message.txt.asc ~/gpg-lab/secret-message.txt

# Clean up test file
rm /tmp/test-decrypt.txt
Files Created During Lab
You should have created the following files:

ls -la ~/gpg-lab/
Expected files: • secret-message.txt and secret-message.txt.gpg • financial-data.txt and financial-data.txt.asc • personal-info.txt and personal-info.txt.asc • Various signature files (.asc extensions) • Public key exports • Decrypted verification files

Conclusion
In this comprehensive lab, you have successfully:

• Generated GPG key pairs using RSA 4096-bit encryption for maximum security • Implemented both symmetric and asymmetric encryption to protect sensitive data • Created and verified digital signatures to ensure data integrity and authenticity • Practiced key management operations including import, export, and trust establishment • Applied security best practices for real-world cryptographic operations

Why This Matters: GPG encryption is fundamental to modern cybersecurity and is widely used in enterprise environments for:

• Secure email communication between organizations • Software package verification in Linux distributions • Backup encryption for sensitive corporate data • Code signing for software development • Compliance requirements in regulated industries

These skills directly apply to the Red Hat Certified Specialist in Security: Linux exam and are essential for cybersecurity professionals working with Linux systems. The hands-on experience gained in this lab provides practical knowledge that employers value in security-focused roles.

Next Steps: Practice these operations regularly, explore GPG integration with email clients, and consider implementing GPG in your organization's security workflows. The foundation you've built here will serve you well in advanced security certifications and professional cybersecurity roles.
