Lab 5: Text Processing with grep, sed, and awk
Objectives
By the end of this lab, students will be able to:

• Use grep to search for patterns and text within files and directories • Apply sed (stream editor) to perform text substitution and basic text transformations • Create and execute awk scripts for advanced text extraction, manipulation, and reporting • Combine these three powerful text processing tools to solve real-world data processing challenges • Understand regular expressions and pattern matching in Linux environments • Process log files and structured data efficiently using command-line tools

Prerequisites
Before starting this lab, students should have:

• Basic knowledge of Linux command line navigation (cd, ls, cat, etc.) • Understanding of file system structure and file permissions • Familiarity with text editors like nano or vim • Basic understanding of regular expressions (helpful but not required) • Completed previous labs covering basic Linux commands

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment - no need to build your own virtual machine or install any software.

Your cloud machine includes: • CentOS/RHEL-based Linux distribution • All necessary text processing tools (grep, sed, awk) pre-installed • Sample data files for practice • Full root access for system administration tasks

Task 1: Search Text in Files Using grep
Subtask 1.1: Understanding grep Basics
grep (Global Regular Expression Print) is a powerful command-line tool for searching text patterns in files.

First, let's create some sample files to work with:

# Create a working directory
mkdir ~/text_processing_lab
cd ~/text_processing_lab

# Create sample files with different types of data
cat > employees.txt << 'EOF'
John Smith,Manager,Sales,75000
Jane Doe,Developer,IT,65000
Mike Johnson,Analyst,Finance,55000
Sarah Wilson,Manager,IT,80000
Tom Brown,Developer,IT,60000
Lisa Davis,Analyst,Sales,50000
Robert Taylor,Manager,Finance,85000
Emily White,Developer,IT,62000
David Lee,Analyst,IT,58000
Maria Garcia,Manager,Sales,78000
EOF

cat > server_logs.txt << 'EOF'
2024-01-15 10:30:15 INFO: Server started successfully
2024-01-15 10:31:22 ERROR: Database connection failed
2024-01-15 10:32:10 WARNING: High memory usage detected
2024-01-15 10:33:45 INFO: User login: admin
2024-01-15 10:34:12 ERROR: File not found: /var/log/app.log
2024-01-15 10:35:30 INFO: Backup process completed
2024-01-15 10:36:18 WARNING: Disk space low
2024-01-15 10:37:25 ERROR: Network timeout occurred
2024-01-15 10:38:40 INFO: User logout: admin
2024-01-15 10:39:55 INFO: System maintenance scheduled
EOF

cat > products.txt << 'EOF'
Laptop,Electronics,999.99,50
Mouse,Electronics,29.99,200
Keyboard,Electronics,79.99,150
Chair,Furniture,299.99,25
Desk,Furniture,499.99,15
Monitor,Electronics,399.99,75
Headphones,Electronics,149.99,100
Lamp,Furniture,89.99,40
Notebook,Office,12.99,500
Pen,Office,2.99,1000
EOF
Subtask 1.2: Basic grep Operations
Now let's practice basic grep commands:

# Search for a specific word
grep "Manager" employees.txt

# Search case-insensitively
grep -i "manager" employees.txt

# Count occurrences of a pattern
grep -c "IT" employees.txt

# Show line numbers with matches
grep -n "Developer" employees.txt

# Search for lines that don't contain a pattern
grep -v "IT" employees.txt
Subtask 1.3: Advanced grep with Regular Expressions
# Search for lines starting with specific text
grep "^2024-01-15 10:3[0-5]" server_logs.txt

# Search for lines ending with specific text
grep "000$" employees.txt

# Search for any digit using regular expressions
grep "[0-9]" products.txt

# Search for specific patterns with multiple options
grep -E "(ERROR|WARNING)" server_logs.txt

# Search recursively in directories (create subdirectory first)
mkdir logs
cp server_logs.txt logs/
grep -r "ERROR" .
Subtask 1.4: Practical grep Examples
# Find all employees with salary above 70000
grep -E ",[7-9][0-9][0-9][0-9][0-9]$" employees.txt

# Find all products in Electronics category
grep "Electronics" products.txt

# Find all log entries with timestamps between 10:30 and 10:35
grep "10:3[0-5]" server_logs.txt

# Combine grep with other commands
grep "IT" employees.txt | grep "Manager"
Task 2: Use sed for Text Replacement
Subtask 2.1: Understanding sed Basics
sed (Stream Editor) is a powerful tool for performing text transformations on files or input streams.

Subtask 2.2: Basic Text Substitution
# Basic substitution (first occurrence per line)
sed 's/IT/Information Technology/' employees.txt

# Global substitution (all occurrences)
sed 's/IT/Information Technology/g' employees.txt

# Save changes to a new file
sed 's/IT/Information Technology/g' employees.txt > employees_updated.txt

# Edit file in place (be careful with this!)
cp employees.txt employees_backup.txt
sed -i 's/IT/Information Technology/g' employees_backup.txt
cat employees_backup.txt
Subtask 2.3: Advanced sed Operations
# Delete specific lines
sed '2d' employees.txt  # Delete line 2
sed '/Manager/d' employees.txt  # Delete lines containing "Manager"

# Insert text before or after lines
sed '1i\Employee Database Report' employees.txt  # Insert before line 1
sed '$a\End of Report' employees.txt  # Append after last line

# Replace text only on specific lines
sed '3s/Analyst/Senior Analyst/' employees.txt  # Only on line 3
sed '/Finance/s/Analyst/Senior Analyst/' employees.txt  # Only on lines containing "Finance"
Subtask 2.4: Complex sed Transformations
# Multiple operations in one command
sed -e 's/IT/Information Technology/g' -e 's/Manager/Director/g' employees.txt

# Using sed with regular expressions
sed 's/[0-9][0-9][0-9][0-9][0-9]/SALARY_HIDDEN/g' employees.txt

# Format log entries
sed 's/ERROR:/[ERROR]:/g; s/WARNING:/[WARNING]:/g; s/INFO:/[INFO]:/' server_logs.txt

# Extract specific parts of lines
sed 's/.*,\([^,]*\),\([^,]*\),.*/Department: \2, Role: \1/' employees.txt
Subtask 2.5: Practical sed Examples
# Create a formatted report
sed -e '1i\=== EMPLOYEE REPORT ===' \
    -e 's/,/ | /g' \
    -e '$a\=== END OF REPORT ===' employees.txt

# Clean up log format
sed -e 's/2024-01-15 //' \
    -e 's/INFO:/[INFO]/' \
    -e 's/ERROR:/[ERROR]/' \
    -e 's/WARNING:/[WARN]/' server_logs.txt

# Convert CSV to pipe-separated format
sed 's/,/|/g' products.txt
Task 3: Create and Use awk Scripts for Text Extraction and Manipulation
Subtask 3.1: Understanding awk Basics
awk is a powerful programming language designed for text processing and data extraction. It processes files line by line and can perform complex operations.

Subtask 3.2: Basic awk Operations
# Print specific columns (fields)
awk -F',' '{print $1}' employees.txt  # Print first column (names)
awk -F',' '{print $1, $2}' employees.txt  # Print first and second columns

# Print with custom formatting
awk -F',' '{print "Name: " $1 ", Position: " $2}' employees.txt

# Print line numbers with content
awk -F',' '{print NR ": " $1}' employees.txt

# Print total number of lines
awk 'END {print "Total employees: " NR}' employees.txt
Subtask 3.3: awk with Conditions and Patterns
# Print lines matching specific conditions
awk -F',' '$2 == "Manager" {print $1, $4}' employees.txt

# Print employees with salary > 60000
awk -F',' '$4 > 60000 {print $1, $4}' employees.txt

# Print employees in IT department
awk -F',' '$3 == "IT" {print $1, $2}' employees.txt

# Count employees by department
awk -F',' '{dept[$3]++} END {for (d in dept) print d, dept[d]}' employees.txt
Subtask 3.4: Advanced awk Programming
Create an awk script file for complex operations:

# Create an awk script for employee analysis
cat > employee_analysis.awk << 'EOF'
BEGIN {
    FS = ","
    print "=== EMPLOYEE ANALYSIS REPORT ==="
    print "================================="
    total_salary = 0
    employee_count = 0
}

{
    # Count employees by department
    dept[$3]++
    
    # Count employees by position
    position[$2]++
    
    # Calculate total salary
    total_salary += $4
    employee_count++
    
    # Track highest paid employee
    if ($4 > max_salary) {
        max_salary = $4
        highest_paid = $1
    }
}

END {
    print "\nDEPARTMENT BREAKDOWN:"
    for (d in dept) {
        printf "%-15s: %d employees\n", d, dept[d]
    }
    
    print "\nPOSITION BREAKDOWN:"
    for (p in position) {
        printf "%-15s: %d employees\n", p, position[p]
    }
    
    print "\nSALARY STATISTICS:"
    printf "Total Employees: %d\n", employee_count
    printf "Total Salary: $%.2f\n", total_salary
    printf "Average Salary: $%.2f\n", total_salary/employee_count
    printf "Highest Paid: %s ($%.2f)\n", highest_paid, max_salary
    
    print "\n=== END OF REPORT ==="
}
EOF

# Run the awk script
awk -f employee_analysis.awk employees.txt
Subtask 3.5: awk for Log Analysis
# Analyze server logs
awk '{
    # Count log levels
    if ($3 == "ERROR:") errors++
    else if ($3 == "WARNING:") warnings++
    else if ($3 == "INFO:") info++
    
    # Store all log entries
    logs[NR] = $0
}
END {
    print "=== LOG ANALYSIS ==="
    print "INFO entries:", info
    print "WARNING entries:", warnings  
    print "ERROR entries:", errors
    print "Total entries:", NR
    
    if (errors > 0) {
        print "\nERROR DETAILS:"
        for (i=1; i<=NR; i++) {
            if (logs[i] ~ /ERROR:/) {
                print logs[i]
            }
        }
    }
}' server_logs.txt
Subtask 3.6: awk for Data Processing
# Process product data
awk -F',' '
BEGIN {
    print "=== INVENTORY REPORT ==="
    total_value = 0
}
{
    # Calculate total value for each product
    product_value = $3 * $4
    total_value += product_value
    
    printf "%-15s: $%8.2f x %3d = $%10.2f\n", $1, $3, $4, product_value
    
    # Track category totals
    category_value[$2] += product_value
    category_count[$2] += $4
}
END {
    print "\n=== CATEGORY SUMMARY ==="
    for (cat in category_value) {
        printf "%-15s: %3d items, Total Value: $%10.2f\n", 
               cat, category_count[cat], category_value[cat]
    }
    printf "\nGRAND TOTAL INVENTORY VALUE: $%.2f\n", total_value
}' products.txt
Task 4: Combining grep, sed, and awk
Subtask 4.1: Pipeline Processing
# Complex data processing pipeline
grep "IT" employees.txt | sed 's/IT/Information Technology/g' | awk -F',' '{print $1 " works in " $3 " earning $" $4}'

# Process logs and format output
grep -E "(ERROR|WARNING)" server_logs.txt | sed 's/2024-01-15 //' | awk '{print "Alert at " $1 ": " substr($0, index($0,$2))}'

# Filter and analyze product data
grep "Electronics" products.txt | awk -F',' '{total += $3 * $4; count++} END {print "Electronics inventory value: $" total " (" count " items)"}'
Subtask 4.2: Creating a Complete Data Processing Script
# Create a comprehensive data processing script
cat > process_data.sh << 'EOF'
#!/bin/bash

echo "=== COMPREHENSIVE DATA PROCESSING REPORT ==="
echo "Generated on: $(date)"
echo "=============================================="

echo -e "\n1. HIGH-VALUE EMPLOYEES (Salary > 70000):"
grep -E ",[7-9][0-9][0-9][0-9][0-9]$" employees.txt | \
sed 's/,/ | /g' | \
awk '{print "   " $0}'

echo -e "\n2. IT DEPARTMENT ANALYSIS:"
grep "IT" employees.txt | \
awk -F',' '{
    total += $4; 
    count++; 
    if ($2 == "Manager") managers++;
    else if ($2 == "Developer") developers++;
    else analysts++;
} 
END {
    print "   Total IT employees: " count
    print "   Managers: " managers
    print "   Developers: " developers  
    print "   Analysts: " analysts
    print "   Average IT salary: $" total/count
}'

echo -e "\n3. CRITICAL LOG ENTRIES:"
grep "ERROR" server_logs.txt | \
sed 's/ERROR:/[CRITICAL ERROR]/' | \
awk '{print "   " $0}'

echo -e "\n4. ELECTRONICS INVENTORY:"
grep "Electronics" products.txt | \
awk -F',' '{
    value = $3 * $4;
    total_value += value;
    total_items += $4;
    printf "   %-15s: $%7.2f x %3d = $%8.2f\n", $1, $3, $4, value
}
END {
    print "   " "----------------------------------------"
    printf "   %-15s: %3d items = $%8.2f\n", "TOTAL", total_items, total_value
}'

echo -e "\n=============================================="
echo "Report completed successfully!"
EOF

# Make the script executable and run it
chmod +x process_data.sh
./process_data.sh
Task 5: Real-World Scenarios
Subtask 5.1: System Administration Tasks
# Create a system monitoring script
cat > system_monitor.sh << 'EOF'
#!/bin/bash

# Generate sample system data
cat > system_status.log << 'SYSEOF'
2024-01-15 10:30:00 CPU: 45% Memory: 67% Disk: 23%
2024-01-15 10:31:00 CPU: 52% Memory: 71% Disk: 23%
2024-01-15 10:32:00 CPU: 89% Memory: 78% Disk: 24%
2024-01-15 10:33:00 CPU: 34% Memory: 65% Disk: 24%
2024-01-15 10:34:00 CPU: 91% Memory: 82% Disk: 25%
2024-01-15 10:35:00 CPU: 28% Memory: 59% Disk: 25%
SYSEOF

echo "=== SYSTEM PERFORMANCE ANALYSIS ==="

# Find high CPU usage
echo "High CPU Usage (>80%):"
grep -E "CPU: [8-9][0-9]%" system_status.log | \
awk '{print "   " $1 " " $2 " - " $3}'

# Find high memory usage  
echo -e "\nHigh Memory Usage (>75%):"
grep -E "Memory: [7-9][0-9]%" system_status.log | \
awk '{print "   " $1 " " $2 " - " $4}'

# Calculate averages
echo -e "\nSystem Averages:"
awk '{
    gsub(/[CPU:Memory:Disk:%]/, "");
    cpu_total += $3;
    mem_total += $4; 
    disk_total += $5;
    count++;
}
END {
    printf "   Average CPU: %.1f%%\n", cpu_total/count;
    printf "   Average Memory: %.1f%%\n", mem_total/count;
    printf "   Average Disk: %.1f%%\n", disk_total/count;
}' system_status.log

rm system_status.log
EOF

chmod +x system_monitor.sh
./system_monitor.sh
Subtask 5.2: Data Cleaning and Formatting
# Create messy data file
cat > messy_data.txt << 'EOF'
  John Smith  ,  Manager  ,  Sales  ,  75000  
Jane Doe,Developer,IT,65000
  Mike Johnson,Analyst,Finance,55000
Sarah Wilson  ,Manager,IT,80000  
  Tom Brown,Developer  ,IT,60000
EOF

# Clean and format the data
echo "=== DATA CLEANING EXAMPLE ==="
echo "Original messy data:"
cat messy_data.txt

echo -e "\nCleaned data:"
sed 's/^[ \t]*//; s/[ \t]*$//; s/[ \t]*,[ \t]*/,/g' messy_data.txt | \
awk -F',' '{printf "%-15s | %-10s | %-8s | $%s\n", $1, $2, $3, $4}'
Troubleshooting Tips
Common Issues and Solutions
Issue 1: grep not finding patterns

# Check if pattern is case-sensitive
grep -i "pattern" filename

# Check for hidden characters
cat -A filename | head -5
Issue 2: sed not making changes

# Remember sed doesn't modify original file unless using -i
sed 's/old/new/g' file > newfile

# For in-place editing (be careful!)
sed -i.backup 's/old/new/g' file
Issue 3: awk field separator issues

# Explicitly set field separator
awk -F',' '{print $1}' file

# For multiple separators
awk -F'[,|]' '{print $1}' file
Issue 4: Regular expression not working

# Use extended regex with grep
grep -E "pattern" file

# Escape special characters
grep "\$[0-9]" file
Verification and Testing
Test your understanding with these verification commands:

# Test 1: Count IT employees
echo "IT employees count:"
grep -c "IT" employees.txt

# Test 2: Replace and count
echo "After replacing IT with Information Technology:"
sed 's/IT/Information Technology/g' employees.txt | grep -c "Information Technology"

# Test 3: Calculate average salary
echo "Average salary:"
awk -F',' '{total += $4; count++} END {print total/count}' employees.txt

# Test 4: Find highest paid employee
echo "Highest paid employee:"
awk -F',' '{if ($4 > max) {max = $4; name = $1}} END {print name, max}' employees.txt
Conclusion
In this comprehensive lab, you have successfully learned and practiced:

• grep fundamentals: Searching for patterns in files using basic and advanced regular expressions, case-insensitive searches, and combining grep with other commands

• sed mastery: Performing text substitutions, deletions, insertions, and complex transformations using stream editing techniques

• awk programming: Creating powerful text processing scripts that can analyze data, generate reports, and perform complex calculations

• Integration skills: Combining all three tools in pipelines to solve real-world data processing challenges

• Practical applications: Processing employee data, analyzing log files, managing inventory data, and performing system administration tasks

These text processing skills are essential for Red Hat Certified System Administrator certification and daily Linux system administration tasks. You can now efficiently process log files, clean data, generate reports, and automate text-based operations that are crucial in enterprise Linux environments.

The combination of grep, sed, and awk provides you with a powerful toolkit for handling any text processing challenge you might encounter in your system administration career. Practice these commands regularly to build muscle memory and explore their extensive documentation using man grep, man sed, and man awk for even more advanced features.
