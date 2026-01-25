Lab 18: Using Camel Components for File Handling
Objectives
By the end of this lab, you will be able to:

• Configure and use Apache Camel's File component to consume and produce files • Set up FTP and SFTP file transfer operations using Camel's FTP component • Implement file-based integration scenarios with proper error handling • Test and validate file processing workflows in enterprise integration patterns • Apply file handling best practices in cloud-native integration solutions

Prerequisites
Before starting this lab, you should have:

• Basic understanding of Apache Camel concepts and routing • Familiarity with Java programming and Maven build tool • Knowledge of file system operations and FTP/SFTP protocols • Understanding of enterprise integration patterns • Experience with Linux command line operations

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your cloud machine includes: • Java 11 or higher • Apache Maven 3.6+ • Apache Camel 3.x • OpenSSH server and client • vsftpd FTP server • Text editors (nano, vim)

Task 1: Configure Camel's File Component for File Processing
Subtask 1.1: Create Maven Project Structure
Open terminal and create a new directory for the project:
mkdir camel-file-handling-lab
cd camel-file-handling-lab
Create Maven project structure:
mkdir -p src/main/java/com/example/camel
mkdir -p src/main/resources
mkdir -p input
mkdir -p output
mkdir -p processed
mkdir -p error
Create the Maven POM file:
nano pom.xml
Add the following content:

<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>camel-file-handling</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <camel.version>3.20.0</camel.version>
        <slf4j.version>1.7.36</slf4j.version>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-core</artifactId>
            <version>${camel.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-file</artifactId>
            <version>${camel.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-ftp</artifactId>
            <version>${camel.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-main</artifactId>
            <version>${camel.version}</version>
        </dependency>
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-simple</artifactId>
            <version>${slf4j.version}</version>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.10.1</version>
                <configuration>
                    <source>11</source>
                    <target>11</target>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.camel</groupId>
                <artifactId>camel-maven-plugin</artifactId>
                <version>${camel.version}</version>
            </plugin>
        </plugins>
    </build>
</project>
Subtask 1.2: Create Basic File Processing Route
Create the main Camel application class:
nano src/main/java/com/example/camel/FileHandlingApplication.java
Add the following code:

package com.example.camel;

import org.apache.camel.main.Main;

public class FileHandlingApplication {
    
    public static void main(String[] args) throws Exception {
        Main main = new Main();
        main.configure().addRoutesBuilder(new FileProcessingRoute());
        main.run(args);
    }
}
Create the file processing route:
nano src/main/java/com/example/camel/FileProcessingRoute.java
Add the following code:

package com.example.camel;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.apache.camel.builder.RouteBuilder;

public class FileProcessingRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Basic file consumption and production route
        from("file:input?noop=false&move=processed")
            .routeId("file-processor")
            .log("Processing file: ${header.CamelFileName}")
            .process(new FileContentProcessor())
            .to("file:output")
            .log("File processed successfully: ${header.CamelFileName}");
        
        // Error handling route
        onException(Exception.class)
            .handled(true)
            .log("Error processing file: ${exception.message}")
            .to("file:error");
    }
    
    // Custom processor to transform file content
    private static class FileContentProcessor implements Processor {
        @Override
        public void process(Exchange exchange) throws Exception {
            String originalContent = exchange.getIn().getBody(String.class);
            String processedContent = "PROCESSED: " + originalContent.toUpperCase();
            exchange.getIn().setBody(processedContent);
            
            // Add processing timestamp
            exchange.getIn().setHeader("ProcessedTimestamp", 
                java.time.LocalDateTime.now().toString());
        }
    }
}
Subtask 1.3: Test Basic File Processing
Compile the project:
mvn clean compile
Create test files:
echo "Hello World from Camel File Component" > input/test1.txt
echo "This is a sample file for processing" > input/test2.txt
echo "File handling with Apache Camel" > input/test3.txt
Run the application:
mvn camel:run
Verify the results (open a new terminal):
# Check processed files
ls -la output/
cat output/test1.txt

# Check that files were moved to processed directory
ls -la processed/
Stop the application by pressing Ctrl+C in the original terminal.
Task 2: Set up FTP/SFTP File Transfer Using Camel's FTP Component
Subtask 2.1: Configure FTP Server
Install and configure vsftpd FTP server:
sudo apt update
sudo apt install -y vsftpd
Create FTP user and directories:
sudo useradd -m -s /bin/bash ftpuser
echo "ftpuser:ftppass123" | sudo chpasswd
sudo mkdir -p /home/ftpuser/ftp/upload
sudo mkdir -p /home/ftpuser/ftp/download
sudo chown -R ftpuser:ftpuser /home/ftpuser/ftp
sudo chmod -R 755 /home/ftpuser/ftp
Configure vsftpd:
sudo nano /etc/vsftpd.conf
Ensure these settings are configured:

listen=YES
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO
pasv_enable=YES
pasv_min_port=10000
pasv_max_port=10100
allow_writeable_chroot=YES
Start FTP service:
sudo systemctl restart vsftpd
sudo systemctl enable vsftpd
Subtask 2.2: Configure SFTP Server
Configure SSH for SFTP:
sudo nano /etc/ssh/sshd_config
Add or modify these lines:

Subsystem sftp /usr/lib/openssh/sftp-server
Match User sftpuser
    ChrootDirectory /home/sftpuser
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
Create SFTP user:
sudo useradd -m -s /bin/false sftpuser
echo "sftpuser:sftppass123" | sudo chpasswd
sudo mkdir -p /home/sftpuser/upload
sudo mkdir -p /home/sftpuser/download
sudo chown root:root /home/sftpuser
sudo chmod 755 /home/sftpuser
sudo chown sftpuser:sftpuser /home/sftpuser/upload /home/sftpuser/download
Restart SSH service:
sudo systemctl restart ssh
Subtask 2.3: Create FTP/SFTP Integration Routes
Create enhanced route with FTP/SFTP support:
nano src/main/java/com/example/camel/FtpSftpRoute.java
Add the following code:

package com.example.camel;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.apache.camel.builder.RouteBuilder;

public class FtpSftpRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // FTP file upload route
        from("file:ftp-upload?noop=false&move=ftp-processed")
            .routeId("ftp-upload-route")
            .log("Uploading file to FTP: ${header.CamelFileName}")
            .to("ftp://ftpuser@localhost:21/upload?password=ftppass123&binary=true")
            .log("File uploaded to FTP successfully: ${header.CamelFileName}");
        
        // FTP file download route
        from("ftp://ftpuser@localhost:21/download?password=ftppass123&binary=true&delete=true")
            .routeId("ftp-download-route")
            .log("Downloaded file from FTP: ${header.CamelFileName}")
            .to("file:ftp-downloaded")
            .log("File saved locally: ${header.CamelFileName}");
        
        // SFTP file upload route
        from("file:sftp-upload?noop=false&move=sftp-processed")
            .routeId("sftp-upload-route")
            .log("Uploading file to SFTP: ${header.CamelFileName}")
            .to("sftp://sftpuser@localhost:22/upload?password=sftppass123&binary=true")
            .log("File uploaded to SFTP successfully: ${header.CamelFileName}");
        
        // SFTP file download route
        from("sftp://sftpuser@localhost:22/download?password=sftppass123&binary=true&delete=true")
            .routeId("sftp-download-route")
            .log("Downloaded file from SFTP: ${header.CamelFileName}")
            .to("file:sftp-downloaded")
            .log("File saved locally: ${header.CamelFileName}");
        
        // File synchronization route (Local to FTP to SFTP)
        from("file:sync-source?noop=false&move=sync-processed")
            .routeId("file-sync-route")
            .log("Synchronizing file: ${header.CamelFileName}")
            .multicast()
            .to("ftp://ftpuser@localhost:21/upload?password=ftppass123&binary=true")
            .to("sftp://sftpuser@localhost:22/upload?password=sftppass123&binary=true")
            .to("file:sync-completed")
            .log("File synchronized across all destinations: ${header.CamelFileName}");
        
        // Error handling for FTP/SFTP operations
        onException(Exception.class)
            .handled(true)
            .log("Error in FTP/SFTP operation: ${exception.message}")
            .to("file:ftp-sftp-errors");
    }
}
Update the main application to include FTP/SFTP routes:
nano src/main/java/com/example/camel/FileHandlingApplication.java
Update the content:

package com.example.camel;

import org.apache.camel.main.Main;

public class FileHandlingApplication {
    
    public static void main(String[] args) throws Exception {
        Main main = new Main();
        main.configure().addRoutesBuilder(new FileProcessingRoute());
        main.configure().addRoutesBuilder(new FtpSftpRoute());
        main.run(args);
    }
}
Create necessary directories:
mkdir -p ftp-upload ftp-downloaded ftp-processed ftp-sftp-errors
mkdir -p sftp-upload sftp-downloaded sftp-processed
mkdir -p sync-source sync-completed sync-processed
Task 3: Test File-Based Integration Scenarios
Subtask 3.1: Test Basic File Processing
Compile and run the enhanced application:
mvn clean compile
mvn camel:run
Test basic file processing (in a new terminal):
# Create test files for basic processing
echo "Basic file processing test" > input/basic-test.txt
echo "Another test file" > input/basic-test2.txt

# Wait a few seconds and check results
sleep 5
ls -la output/
ls -la processed/
Subtask 3.2: Test FTP Operations
Test FTP upload (in a new terminal):
# Create files for FTP upload
echo "FTP upload test file" > ftp-upload/ftp-test1.txt
echo "Another FTP test" > ftp-upload/ftp-test2.txt

# Wait and verify upload
sleep 10
ls -la ftp-processed/

# Verify files on FTP server
ftp localhost
# Login with: ftpuser / ftppass123
# Commands: cd upload, ls, quit
Test FTP download:
# Manually place a file in FTP download directory
echo "Download test from FTP" > /tmp/ftp-download-test.txt
sudo cp /tmp/ftp-download-test.txt /home/ftpuser/ftp/download/

# Wait and check if file is downloaded
sleep 10
ls -la ftp-downloaded/
Subtask 3.3: Test SFTP Operations
Test SFTP upload:
# Create files for SFTP upload
echo "SFTP upload test file" > sftp-upload/sftp-test1.txt
echo "Another SFTP test" > sftp-upload/sftp-test2.txt

# Wait and verify
sleep 10
ls -la sftp-processed/

# Verify on SFTP server
sftp sftpuser@localhost
# Password: sftppass123
# Commands: cd upload, ls, quit
Test SFTP download:
# Place file in SFTP download directory
echo "Download test from SFTP" > /tmp/sftp-download-test.txt
sudo cp /tmp/sftp-download-test.txt /home/sftpuser/download/

# Wait and check
sleep 10
ls -la sftp-downloaded/
Subtask 3.4: Test File Synchronization
Test multi-destination sync:
# Create files for synchronization
echo "Sync test file 1" > sync-source/sync-test1.txt
echo "Sync test file 2" > sync-source/sync-test2.txt

# Wait and verify synchronization
sleep 15
ls -la sync-completed/
ls -la sync-processed/

# Check FTP and SFTP destinations
ftp localhost
# Login and check upload directory

sftp sftpuser@localhost
# Login and check upload directory
Subtask 3.5: Advanced File Processing with Content-Based Routing
Create advanced routing based on file content:
nano src/main/java/com/example/camel/AdvancedFileRoute.java
Add the following code:

package com.example.camel;

import org.apache.camel.builder.RouteBuilder;

public class AdvancedFileRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Content-based routing
        from("file:advanced-input?noop=false&move=advanced-processed")
            .routeId("content-based-routing")
            .log("Processing file with content-based routing: ${header.CamelFileName}")
            .choice()
                .when(body().contains("URGENT"))
                    .log("Urgent file detected: ${header.CamelFileName}")
                    .to("file:urgent-output")
                    .to("ftp://ftpuser@localhost:21/urgent?password=ftppass123&binary=true")
                .when(body().contains("ARCHIVE"))
                    .log("Archive file detected: ${header.CamelFileName}")
                    .to("file:archive-output")
                    .to("sftp://sftpuser@localhost:22/archive?password=sftppass123&binary=true")
                .otherwise()
                    .log("Regular file: ${header.CamelFileName}")
                    .to("file:regular-output")
            .end();
        
        // File size-based routing
        from("file:size-input?noop=false&move=size-processed")
            .routeId("size-based-routing")
            .log("File size: ${header.CamelFileLength} bytes")
            .choice()
                .when(header("CamelFileLength").isGreaterThan(1000))
                    .log("Large file: ${header.CamelFileName}")
                    .to("file:large-files")
                .otherwise()
                    .log("Small file: ${header.CamelFileName}")
                    .to("file:small-files")
            .end();
        
        // File extension-based routing
        from("file:extension-input?noop=false&move=extension-processed")
            .routeId("extension-based-routing")
            .choice()
                .when(header("CamelFileNameOnly").endsWith(".txt"))
                    .to("file:text-files")
                .when(header("CamelFileNameOnly").endsWith(".csv"))
                    .to("file:csv-files")
                .when(header("CamelFileNameOnly").endsWith(".xml"))
                    .to("file:xml-files")
                .otherwise()
                    .to("file:other-files")
            .end();
    }
}
Update main application:
nano src/main/java/com/example/camel/FileHandlingApplication.java
Update to include the advanced route:

package com.example.camel;

import org.apache.camel.main.Main;

public class FileHandlingApplication {
    
    public static void main(String[] args) throws Exception {
        Main main = new Main();
        main.configure().addRoutesBuilder(new FileProcessingRoute());
        main.configure().addRoutesBuilder(new FtpSftpRoute());
        main.configure().addRoutesBuilder(new AdvancedFileRoute());
        main.run(args);
    }
}
Create directories for advanced routing:
mkdir -p advanced-input advanced-processed urgent-output archive-output regular-output
mkdir -p size-input size-processed large-files small-files
mkdir -p extension-input extension-processed text-files csv-files xml-files other-files
Test advanced routing:
# Restart the application
# Press Ctrl+C to stop, then run again
mvn camel:run

# In new terminal, test content-based routing
echo "URGENT: Critical system alert" > advanced-input/urgent-file.txt
echo "ARCHIVE: Old data for storage" > advanced-input/archive-file.txt
echo "Regular processing file" > advanced-input/regular-file.txt

# Test size-based routing
echo "Small file content" > size-input/small.txt
dd if=/dev/zero of=size-input/large.txt bs=1024 count=2

# Test extension-based routing
echo "Text content" > extension-input/test.txt
echo "Name,Age,City" > extension-input/data.csv
echo "<root><item>test</item></root>" > extension-input/config.xml
echo "Binary data" > extension-input/file.bin

# Wait and verify results
sleep 10
ls -la urgent-output/ archive-output/ regular-output/
ls -la large-files/ small-files/
ls -la text-files/ csv-files/ xml-files/ other-files/
Subtask 3.6: Error Handling and Monitoring
Create monitoring and error handling route:
nano src/main/java/com/example/camel/MonitoringRoute.java
Add the following code:

package com.example.camel;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.apache.camel.builder.RouteBuilder;

public class MonitoringRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // File processing with retry and dead letter queue
        from("file:monitored-input?noop=false&move=monitored-processed")
            .routeId("monitored-file-processing")
            .onException(Exception.class)
                .maximumRedeliveries(3)
                .redeliveryDelay(2000)
                .retryAttemptedLogLevel(org.apache.camel.LoggingLevel.WARN)
                .to("file:dead-letter-queue")
                .handled(true)
            .end()
            .log("Processing monitored file: ${header.CamelFileName}")
            .process(new FileValidationProcessor())
            .to("file:validated-output")
            .log("File validated and processed: ${header.CamelFileName}");
        
        // Statistics and monitoring route
        from("timer://stats?period=30000")
            .routeId("statistics-route")
            .process(new StatisticsProcessor())
            .log("${body}");
    }
    
    private static class FileValidationProcessor implements Processor {
        @Override
        public void process(Exchange exchange) throws Exception {
            String content = exchange.getIn().getBody(String.class);
            String filename = exchange.getIn().getHeader("CamelFileName", String.class);
            
            // Simulate validation logic
            if (content == null || content.trim().isEmpty()) {
                throw new IllegalArgumentException("File is empty: " + filename);
            }
            
            if (filename.contains("invalid")) {
                throw new IllegalArgumentException("Invalid filename pattern: " + filename);
            }
            
            // Add validation timestamp
            exchange.getIn().setHeader("ValidationTimestamp", 
                java.time.LocalDateTime.now().toString());
        }
    }
    
    private static class StatisticsProcessor implements Processor {
        @Override
        public void process(Exchange exchange) throws Exception {
            // Simple statistics - in real scenario, you'd use proper metrics
            java.io.File inputDir = new java.io.File("input");
            java.io.File outputDir = new java.io.File("output");
            java.io.File processedDir = new java.io.File("processed");
            java.io.File errorDir = new java.io.File("error");
            
            String stats = String.format(
                "File Processing Statistics:\n" +
                "- Input files pending: %d\n" +
                "- Output files created: %d\n" +
                "- Files processed: %d\n" +
                "- Error files: %d\n" +
                "- Timestamp: %s",
                inputDir.listFiles() != null ? inputDir.listFiles().length : 0,
                outputDir.listFiles() != null ? outputDir.listFiles().length : 0,
                processedDir.listFiles() != null ? processedDir.listFiles().length : 0,
                errorDir.listFiles() != null ? errorDir.listFiles().length : 0,
                java.time.LocalDateTime.now()
            );
            
            exchange.getIn().setBody(stats);
        }
    }
}
Update main application:
nano src/main/java/com/example/camel/FileHandlingApplication.java
Final version:

package com.example.camel;

import org.apache.camel.main.Main;

public class FileHandlingApplication {
    
    public static void main(String[] args) throws Exception {
        Main main = new Main();
        main.configure().addRoutesBuilder(new FileProcessingRoute());
        main.configure().addRoutesBuilder(new FtpSftpRoute());
        main.configure().addRoutesBuilder(new AdvancedFileRoute());
        main.configure().addRoutesBuilder(new MonitoringRoute());
        main.run(args);
    }
}
Create monitoring directories:
mkdir -p monitored-input monitored-processed validated-output dead-letter-queue
Test error handling and monitoring:
# Restart application
mvn camel:run

# Test valid file
echo "Valid file content" > monitored-input/valid-file.txt

# Test empty file (should trigger error handling)
touch monitored-input/empty-file.txt

# Test invalid filename pattern
echo "Some content" > monitored-input/invalid-filename.txt

# Wait and observe logs and directories
sleep 30
ls -la validated-output/
ls -la dead-letter-queue/
Troubleshooting Tips
Common Issues and Solutions
Issue 1: FTP Connection Refused

Solution: Ensure vsftpd service is running: sudo systemctl status vsftpd
Check firewall settings: sudo ufw allow 21/tcp
Issue 2: SFTP Permission Denied

Solution: Verify user permissions: sudo chown sftpuser:sftpuser /home/sftpuser/upload
Check SSH configuration: sudo systemctl status ssh
Issue 3: Files Not Being Processed

Solution: Check file permissions: chmod 644 input/*.txt
Verify Camel route is active in logs
Issue 4: Maven Compilation Errors

Solution: Ensure Java 11+ is installed: java -version
Clean and rebuild: mvn clean compile
Issue 5: Out of Memory Errors

Solution: Increase JVM heap size: export MAVEN_OPTS="-Xmx1024m"
Conclusion
In this comprehensive lab, you have successfully:

• Configured Apache Camel's File component to consume files from input directories, process them with custom logic, and produce transformed files to output directories with proper error handling and file movement strategies

• Implemented FTP and SFTP file transfer operations using Camel's FTP component, including bidirectional file transfers, authentication, and integration with local file systems

• Created advanced file-based integration scenarios including content-based routing, size-based processing, extension-based filtering, and multi-destination file synchronization

• Developed robust error handling and monitoring capabilities with retry mechanisms, dead letter queues, and automated statistics reporting

• Applied enterprise integration patterns for file handling that are commonly used in cloud-native integration solutions and enterprise environments

This lab demonstrates essential skills for the Red Hat Certified Specialist in Cloud-native Integration exam, particularly in areas of:

File system integration patterns
Protocol-based file transfers (FTP/SFTP)
Error handling and resilience patterns
Content-based routing and message transformation
Monitoring and operational concerns
The hands-on experience gained here directly applies to real-world scenarios where organizations need to integrate legacy file-based systems with modern cloud-native applications, handle batch processing workflows, and maintain reliable file transfer operations across distributed environments.

These skills are fundamental for building robust, scalable integration solutions that can handle the diverse file processing requirements found in enterprise environments, making you well-prepared for both certification success and practical implementation challenges.
