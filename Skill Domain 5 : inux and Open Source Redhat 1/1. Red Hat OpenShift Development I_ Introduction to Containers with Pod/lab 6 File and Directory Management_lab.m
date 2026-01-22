Lab 6: File and Directory Management
Objectives
To manage files and directories using command-line tools
To create, delete, move, and copy files and directories
To use relative and absolute paths for file manipulation
Prerequisites
Linux-based operating system (Ubuntu/CentOS/Fedora recommended)
Basic familiarity with command-line interface
Terminal application access
Setup Requirements
Open a terminal window
Verify your current working directory with:
pwd
Create a dedicated lab directory:
mkdir file_management_lab
cd file_management_lab
Task 1: Create and Delete Files and Directories
Subtask 1.1: Creating Files and Directories
Create a new directory called documents:

mkdir documents
Create three empty files using touch:

touch file1.txt file2.txt file3.txt
Verify creation with:

ls -l
Expected Output: Should show documents/ directory and three .txt files

Subtask 1.2: Deleting Files and Directories
Delete file3.txt:

rm file3.txt
Attempt to delete the documents directory (this should fail):

rmdir documents
Troubleshooting: Directories must be empty before deletion with rmdir

Force delete all files and the directory:

rm -r documents
Key Concept: -r flag enables recursive deletion

Task 2: Move and Copy Files
Subtask 2.1: Moving Files
Recreate our directory structure:

mkdir documents backups
touch file1.txt file2.txt
Move file1.txt into documents:

mv file1.txt documents/
Verify with:

ls documents/
Subtask 2.2: Copying Files
Copy file2.txt to the backups directory:

cp file2.txt backups/
Create a duplicate in current directory:

cp file2.txt file2_backup.txt
Verify both copies exist:

ls backups/ && ls
Task 3: Using Relative and Absolute Paths
Subtask 3.1: Relative Path Navigation
From your lab directory, access documents using relative path:

cd documents
Return to parent directory:

cd ..
List contents of backups from current location:

ls backups/
Subtask 3.2: Absolute Path Operations
Find your absolute path:

pwd
(Output might look like: /home/user/file_management_lab)

Create file using absolute path:

touch /home/user/file_management_lab/absolute_example.txt
Copy file between directories using absolute paths:

cp /home/user/file_management_lab/absolute_example.txt /home/user/file_management_lab/backups/
Advanced Exercise
Create nested directory structure with one command:

mkdir -p projects/{src,doc,bin}
Move all .txt files to doc directory:

mv *.txt projects/doc/
Verify complex structure:

tree
(Install tree with sudo apt install tree or sudo dnf install tree if needed)

Conclusion
In this lab, you have:

Practiced creating and deleting files/directories
Learned to move and copy files between locations
Worked with both relative and absolute paths
Gained experience with essential file management commands
Final Verification: Run this command to see your complete directory structure:

find . -type d -print
Cleanup
To remove all lab files:

cd ..
rm -rf file_management_lab
Additional Resources
GNU Coreutils Manual: https://www.gnu.org/software/coreutils/manual/
Linux Filesystem Hierarchy Standard: https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html
