Lab 14: Archiving and Compressing Files
Objectives
By the end of this lab, you will be able to:

Create and extract archives using the tar command
Compress and decompress files using gzip compression
Compress and decompress files using bzip2 compression
Combine tar with compression tools for efficient file management
Test and verify the integrity of archived data
Understand the differences between various compression methods
Restore archived data to verify backup integrity
Prerequisites
Before starting this lab, you should have:

Basic knowledge of Linux command line navigation
Understanding of file and directory operations (ls, cd, mkdir, cp, mv)
Familiarity with file permissions and ownership concepts
Access to a Linux terminal environment
Ready-to-Use Cloud Machines
Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build or configure your own virtual machine. Your lab environment includes all necessary tools and a clean workspace to practice archiving and compression techniques.

Lab Environment Setup
Once you access your cloud machine, open a terminal and verify your environment:

# Check current directory
pwd

# List available compression tools
which tar gzip bzip2

# Create a working directory for this lab
mkdir ~/lab14-archive
cd ~/lab14-archive
Task 1: Create Archives with tar
The tar (tape archive) command is used to create archive files that bundle multiple files and directories into a single file. Let's explore various tar operations.

Subtask 1.1: Create Sample Files and Directories
First, let's create some sample content to work with:

# Create a directory structure with sample files
mkdir -p documents/reports documents/presentations data/logs data/backups

# Create sample text files
echo "This is a sample document about Linux administration." > documents/linux_guide.txt
echo "Network configuration best practices." > documents/network_config.txt
echo "Security policies and procedures." > documents/security_policy.txt

# Create sample report files
echo "Monthly server performance report." > documents/reports/monthly_report.txt
echo "Quarterly system analysis." > documents/reports/quarterly_analysis.txt

# Create sample presentation files
echo "Linux fundamentals presentation slides." > documents/presentations/linux_basics.txt
echo "System administration workshop materials." > documents/presentations/sysadmin_workshop.txt

# Create sample log files
echo "System log entries from $(date)" > data/logs/system.log
echo "Application log entries from $(date)" > data/logs/application.log

# Create sample backup files
echo "Database backup metadata" > data/backups/db_backup.txt
echo "Configuration backup information" > data/backups/config_backup.txt

# Verify the structure
tree . || find . -type f
Subtask 1.2: Create Basic tar Archives
Now let's create different types of tar archives:

# Create a simple tar archive of the documents directory
tar -cf documents_archive.tar documents/

# Verify the archive was created
ls -lh documents_archive.tar

# List the contents of the archive without extracting
tar -tf documents_archive.tar

# Create a tar archive with verbose output
tar -cvf data_archive.tar data/

# Create a tar archive of specific files
tar -cf selected_files.tar documents/linux_guide.txt documents/network_config.txt data/logs/system.log
Subtask 1.3: Extract tar Archives
Learn how to extract archives and verify their contents:

# Create a test directory for extraction
mkdir extraction_test
cd extraction_test

# Extract the documents archive
tar -xf ../documents_archive.tar

# Verify extraction
ls -la
tree documents/ || find documents/ -type f

# Extract with verbose output
cd ..
mkdir verbose_extraction
cd verbose_extraction
tar -xvf ../data_archive.tar

# Return to main directory
cd ..
Subtask 1.4: Advanced tar Operations
Explore more advanced tar features:

# Create archive and preserve permissions
tar -cpf permissions_archive.tar documents/

# Create archive excluding certain files
tar -cf filtered_archive.tar --exclude="*.log" data/

# Create archive with absolute paths
tar -cf absolute_archive.tar -P /home/$(whoami)/lab14-archive/documents/

# Append files to existing archive
echo "Additional content for archive" > new_file.txt
tar -rf documents_archive.tar new_file.txt

# Verify the file was added
tar -tf documents_archive.tar | grep new_file.txt
Task 2: Compress and Decompress Files using gzip and bzip2
Compression reduces file sizes for storage efficiency and faster transfers. Let's explore both gzip and bzip2 compression methods.

Subtask 2.1: Using gzip Compression
gzip is a fast compression tool commonly used in Linux systems:

# Create a large sample file for compression testing
dd if=/dev/zero of=large_file.txt bs=1M count=10
echo "This file contains sample data for compression testing." >> large_file.txt

# Check original file size
ls -lh large_file.txt

# Compress file with gzip
gzip large_file.txt

# Check compressed file size
ls -lh large_file.txt.gz

# Decompress the file
gunzip large_file.txt.gz

# Alternative: compress while keeping original
gzip -c large_file.txt > large_file_copy.txt.gz
ls -lh large_file*

# Compress with different compression levels (1=fastest, 9=best compression)
gzip -1 -c large_file.txt > large_file_fast.txt.gz
gzip -9 -c large_file.txt > large_file_best.txt.gz

# Compare compression ratios
ls -lh large_file*.gz
Subtask 2.2: Using bzip2 Compression
bzip2 provides better compression ratios but takes more time:

# Compress file with bzip2
bzip2 -c large_file.txt > large_file.txt.bz2

# Check compressed file size
ls -lh large_file.txt.bz2

# Decompress bzip2 file
bunzip2 -c large_file.txt.bz2 > large_file_restored.txt

# Verify decompression
diff large_file.txt large_file_restored.txt

# Compare compression efficiency
echo "Compression Comparison:"
echo "Original file: $(ls -lh large_file.txt | awk '{print $5}')"
echo "gzip compressed: $(ls -lh large_file_copy.txt.gz | awk '{print $5}')"
echo "bzip2 compressed: $(ls -lh large_file.txt.bz2 | awk '{print $5}')"
Subtask 2.3: Combining tar with Compression
The real power comes from combining tar with compression:

# Create compressed tar archive with gzip
tar -czf documents_compressed.tar.gz documents/

# Create compressed tar archive with bzip2
tar -cjf documents_compressed.tar.bz2 documents/

# Compare archive sizes
echo "Archive Size Comparison:"
ls -lh documents_archive.tar documents_compressed.tar.gz documents_compressed.tar.bz2

# Extract compressed archives
mkdir gzip_extraction bzip2_extraction

# Extract gzip compressed archive
tar -xzf documents_compressed.tar.gz -C gzip_extraction/

# Extract bzip2 compressed archive
tar -xjf documents_compressed.tar.bz2 -C bzip2_extraction/

# Verify extractions
ls -la gzip_extraction/
ls -la bzip2_extraction/
Subtask 2.4: Working with Multiple Files
Practice compressing multiple files and directories:

# Create multiple sample files
for i in {1..5}; do
    echo "Sample content for file $i - $(date)" > sample_file_$i.txt
done

# Compress all sample files individually
gzip sample_file_*.txt

# List compressed files
ls -lh sample_file_*.gz

# Decompress all files
gunzip sample_file_*.gz

# Create a compressed archive of all sample files
tar -czf sample_files.tar.gz sample_file_*.txt

# Clean up individual files and extract from archive
rm sample_file_*.txt
tar -xzf sample_files.tar.gz

# Verify restoration
ls -la sample_file_*.txt
Task 3: Test the Restoration of Archived Data
Testing archive integrity is crucial for reliable backups. Let's verify our archives work correctly.

Subtask 3.1: Create Test Archives
First, let's create comprehensive test archives:

# Create a complete backup of our lab directory
cd ~/lab14-archive

# Create checksums for verification
find . -type f -exec md5sum {} \; > original_checksums.txt

# Create comprehensive archives
tar -czf complete_backup.tar.gz documents/ data/ sample_file_*.txt
tar -cjf complete_backup.tar.bz2 documents/ data/ sample_file_*.txt

# Create archive with verification
tar -czf verified_backup.tar.gz --verify documents/ data/
Subtask 3.2: Test Archive Integrity
Verify that archives can be read and are not corrupted:

# Test gzip archive integrity
gzip -t complete_backup.tar.gz
echo "Gzip archive test result: $?"

# Test bzip2 archive integrity
bzip2 -t complete_backup.tar.bz2
echo "Bzip2 archive test result: $?"

# Test tar archive integrity
tar -tzf complete_backup.tar.gz > /dev/null
echo "Tar gzip archive test result: $?"

tar -tjf complete_backup.tar.bz2 > /dev/null
echo "Tar bzip2 archive test result: $?"

# List archive contents to verify structure
echo "Archive contents verification:"
tar -tzf complete_backup.tar.gz | head -10
Subtask 3.3: Full Restoration Test
Perform complete restoration and verify data integrity:

# Create a clean test environment
mkdir ~/restoration_test
cd ~/restoration_test

# Copy archives to test location
cp ~/lab14-archive/complete_backup.tar.gz .
cp ~/lab14-archive/complete_backup.tar.bz2 .
cp ~/lab14-archive/original_checksums.txt .

# Test restoration from gzip archive
mkdir gzip_restore
tar -xzf complete_backup.tar.gz -C gzip_restore/

# Test restoration from bzip2 archive
mkdir bzip2_restore
tar -xjf complete_backup.tar.bz2 -C bzip2_restore/

# Verify restored data integrity
cd gzip_restore
find . -type f -exec md5sum {} \; > restored_checksums.txt

# Compare checksums
echo "Comparing original and restored checksums:"
diff ../original_checksums.txt restored_checksums.txt
if [ $? -eq 0 ]; then
    echo "SUCCESS: All files restored correctly!"
else
    echo "WARNING: Some files may have differences"
fi
Subtask 3.4: Selective Restoration
Practice restoring specific files from archives:

# Return to test directory
cd ~/restoration_test

# Create directory for selective restoration
mkdir selective_restore

# Extract only specific files
tar -xzf complete_backup.tar.gz -C selective_restore/ documents/linux_guide.txt

# Extract only specific directories
tar -xzf complete_backup.tar.gz -C selective_restore/ data/logs/

# Verify selective restoration
echo "Selectively restored files:"
find selective_restore/ -type f

# Extract files matching a pattern
mkdir pattern_restore
tar -xzf complete_backup.tar.gz -C pattern_restore/ --wildcards "*/reports/*"

echo "Pattern-based restored files:"
find pattern_restore/ -type f
Subtask 3.5: Archive Maintenance and Verification
Learn to maintain and verify archives over time:

# Create a verification script
cat > verify_archive.sh << 'EOF'
#!/bin/bash

ARCHIVE_FILE="$1"

if [ -z "$ARCHIVE_FILE" ]; then
    echo "Usage: $0 <archive_file>"
    exit 1
fi

echo "Verifying archive: $ARCHIVE_FILE"

# Check if file exists
if [ ! -f "$ARCHIVE_FILE" ]; then
    echo "ERROR: Archive file not found"
    exit 1
fi

# Determine archive type and test
if [[ "$ARCHIVE_FILE" == *.tar.gz ]]; then
    echo "Testing gzip compressed tar archive..."
    tar -tzf "$ARCHIVE_FILE" > /dev/null
    if [ $? -eq 0 ]; then
        echo "SUCCESS: Archive is valid"
        echo "Archive contains $(tar -tzf "$ARCHIVE_FILE" | wc -l) files"
    else
        echo "ERROR: Archive is corrupted"
    fi
elif [[ "$ARCHIVE_FILE" == *.tar.bz2 ]]; then
    echo "Testing bzip2 compressed tar archive..."
    tar -tjf "$ARCHIVE_FILE" > /dev/null
    if [ $? -eq 0 ]; then
        echo "SUCCESS: Archive is valid"
        echo "Archive contains $(tar -tjf "$ARCHIVE_FILE" | wc -l) files"
    else
        echo "ERROR: Archive is corrupted"
    fi
else
    echo "Unsupported archive format"
    exit 1
fi
EOF

# Make script executable
chmod +x verify_archive.sh

# Test the verification script
./verify_archive.sh complete_backup.tar.gz
./verify_archive.sh complete_backup.tar.bz2

# Create archive information summary
echo "Archive Summary Report" > archive_report.txt
echo "======================" >> archive_report.txt
echo "Date: $(date)" >> archive_report.txt
echo "" >> archive_report.txt

for archive in complete_backup.tar.gz complete_backup.tar.bz2; do
    echo "Archive: $archive" >> archive_report.txt
    echo "Size: $(ls -lh $archive | awk '{print $5}')" >> archive_report.txt
    echo "Files: $(tar -tf $archive | wc -l)" >> archive_report.txt
    echo "Created: $(ls -l $archive | awk '{print $6, $7, $8}')" >> archive_report.txt
    echo "" >> archive_report.txt
done

cat archive_report.txt
Troubleshooting Common Issues
Issue 1: Permission Denied Errors
# If you encounter permission issues during extraction:
# Use sudo if necessary (in real environments)
# Or change ownership after extraction
tar -xzf archive.tar.gz
sudo chown -R $(whoami):$(whoami) extracted_directory/
Issue 2: Archive Corruption
# Always test archives after creation
tar -tzf archive.tar.gz > /dev/null && echo "Archive OK" || echo "Archive corrupted"

# For bzip2 archives
tar -tjf archive.tar.bz2 > /dev/null && echo "Archive OK" || echo "Archive corrupted"
Issue 3: Disk Space Issues
# Check available space before creating large archives
df -h .

# Monitor space during operations
du -sh archive_name.tar.gz
Key Commands Summary
tar Commands
tar -cf archive.tar files/ - Create archive
tar -xf archive.tar - Extract archive
tar -tf archive.tar - List archive contents
tar -czf archive.tar.gz files/ - Create gzip compressed archive
tar -cjf archive.tar.bz2 files/ - Create bzip2 compressed archive
tar -xzf archive.tar.gz - Extract gzip compressed archive
tar -xjf archive.tar.bz2 - Extract bzip2 compressed archive
gzip Commands
gzip file.txt - Compress file
gunzip file.txt.gz - Decompress file
gzip -c file.txt > file.txt.gz - Compress keeping original
gzip -t file.txt.gz - Test archive integrity
bzip2 Commands
bzip2 file.txt - Compress file
bunzip2 file.txt.bz2 - Decompress file
bzip2 -c file.txt > file.txt.bz2 - Compress keeping original
bzip2 -t file.txt.bz2 - Test archive integrity
Conclusion
In this lab, you have successfully learned how to:

Create and manage tar archives for bundling multiple files and directories
Use gzip compression for fast, efficient file compression
Use bzip2 compression for maximum compression ratios
Combine tar with compression tools to create space-efficient archives
Test and verify archive integrity to ensure reliable backups
Restore data from archives both completely and selectively
Understand the trade-offs between different compression methods
These skills are essential for system administration, as archiving and compression are fundamental for:

Backup Management: Creating reliable backups of important data
Storage Optimization: Reducing storage space requirements
Data Transfer: Efficiently moving large amounts of data
System Maintenance: Managing log files and temporary data
Disaster Recovery: Ensuring data can be restored when needed
The knowledge gained in this lab directly applies to the Red Hat Certified System Administrator (RHCSA) exam and real-world Linux system administration tasks. Regular practice with these tools will help you become proficient in managing data archives and maintaining system backups effectively.

Remember to always test your archives after creation and periodically verify their integrity to ensure your backup strategy is reliable and your data remains safe.
