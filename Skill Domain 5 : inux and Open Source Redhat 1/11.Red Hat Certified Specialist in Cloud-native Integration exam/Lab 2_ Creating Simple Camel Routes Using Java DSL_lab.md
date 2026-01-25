Lab 2: Creating Simple Camel Routes Using Java DSL
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of Apache Camel Java DSL (Domain Specific Language)
Create simple routes using Java DSL with from(), to(), and process() methods
Implement custom message processors to transform data
Test Camel routes by sending sample messages
Debug and troubleshoot basic routing issues
Apply best practices for route development in enterprise integration scenarios
Prerequisites
Before starting this lab, you should have:

Basic understanding of Java programming concepts
Familiarity with Maven build tool
Knowledge of enterprise integration patterns (helpful but not required)
Completion of Lab 1 or equivalent Apache Camel setup experience
Understanding of basic messaging concepts
Required Software Knowledge
Java 11 or higher
Apache Maven 3.6+
Basic command line operations
Text editor or IDE usage
Lab Environment Setup
Good News! Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to access your ready-to-use environment. No need to build your own VM or install software.

Your cloud machine includes:

OpenJDK 11
Apache Maven 3.8+
Apache Camel 3.20+
Text editors (nano, vim)
All required dependencies
Task 1: Create a Route Using Java DSL
Subtask 1.1: Set Up the Project Structure
First, let's create a new Maven project for our Camel routes.

Open terminal in your cloud machine

Create project directory and navigate to it:

mkdir camel-java-dsl-lab
cd camel-java-dsl-lab
Generate Maven project structure:
mvn archetype:generate \
  -DgroupId=com.alnafi.camel \
  -DartifactId=simple-routes \
  -DarchetypeArtifactId=maven-archetype-quickstart \
  -DinteractiveMode=false
Navigate to the project directory:
cd simple-routes
Subtask 1.2: Configure Maven Dependencies
Edit the pom.xml file:
nano pom.xml
Replace the content with the following configuration:
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.alnafi.camel</groupId>
    <artifactId>simple-routes</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <camel.version>3.20.2</camel.version>
        <slf4j.version>1.7.36</slf4j.version>
    </properties>

    <dependencies>
        <!-- Camel Core -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-core</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel Main for standalone applications -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-main</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- File component for file operations -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-file</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Timer component for scheduled operations -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-timer</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Logging -->
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
        </plugins>
    </build>
</project>
Save and exit (Ctrl+X, then Y, then Enter)
Subtask 1.3: Create Your First Route with from(), to(), and process()
Create the main Java class:
mkdir -p src/main/java/com/alnafi/camel
nano src/main/java/com/alnafi/camel/SimpleRouteBuilder.java
Add the following route builder code:
package com.alnafi.camel;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.apache.camel.builder.RouteBuilder;

public class SimpleRouteBuilder extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Route 1: Timer to File with Processing
        from("timer:hello?period=5000")
            .process(new MessageProcessor())
            .to("file:output?fileName=processed-message-${date:now:yyyyMMdd-HHmmss}.txt");
        
        // Route 2: File to File with Transformation
        from("file:input?noop=true")
            .process(new FileProcessor())
            .to("file:processed");
        
        // Route 3: Simple transformation route
        from("timer:simple?period=10000")
            .process(exchange -> {
                String originalMessage = "Simple message from timer";
                String transformedMessage = originalMessage.toUpperCase() + 
                    " - Processed at: " + new java.util.Date();
                exchange.getIn().setBody(transformedMessage);
            })
            .to("file:simple-output?fileName=simple-${date:now:HHmmss}.txt");
    }
    
    // Custom Processor Class
    private static class MessageProcessor implements Processor {
        @Override
        public void process(Exchange exchange) throws Exception {
            // Get the current timestamp
            String timestamp = new java.util.Date().toString();
            
            // Create a custom message
            String message = "Hello from Apache Camel!\n" +
                           "Route processed at: " + timestamp + "\n" +
                           "Exchange ID: " + exchange.getExchangeId() + "\n" +
                           "This message was created using Java DSL\n";
            
            // Set the processed message as the body
            exchange.getIn().setBody(message);
            
            // Add a custom header
            exchange.getIn().setHeader("ProcessedBy", "MessageProcessor");
            exchange.getIn().setHeader("ProcessingTime", timestamp);
            
            System.out.println("Message processed: " + message.substring(0, 50) + "...");
        }
    }
    
    // File Processor Class
    private static class FileProcessor implements Processor {
        @Override
        public void process(Exchange exchange) throws Exception {
            // Get the original file content
            String originalContent = exchange.getIn().getBody(String.class);
            String fileName = exchange.getIn().getHeader(Exchange.FILE_NAME, String.class);
            
            // Process the content
            String processedContent = "=== FILE PROCESSING REPORT ===\n" +
                                    "Original File: " + fileName + "\n" +
                                    "Processing Time: " + new java.util.Date() + "\n" +
                                    "Content Length: " + originalContent.length() + " characters\n" +
                                    "=== ORIGINAL CONTENT ===\n" +
                                    originalContent + "\n" +
                                    "=== END OF PROCESSING ===\n";
            
            // Set the processed content
            exchange.getIn().setBody(processedContent);
            
            // Update filename
            exchange.getIn().setHeader(Exchange.FILE_NAME, "processed-" + fileName);
            
            System.out.println("File processed: " + fileName);
        }
    }
}
Save and exit the file
Subtask 1.4: Create the Main Application Class
Create the main application class:
nano src/main/java/com/alnafi/camel/CamelApplication.java
Add the following code:
package com.alnafi.camel;

import org.apache.camel.main.Main;

public class CamelApplication {
    
    public static void main(String[] args) throws Exception {
        // Create Camel Main instance
        Main main = new Main();
        
        // Add our route builder
        main.addRouteBuilder(new SimpleRouteBuilder());
        
        // Configure Camel context
        main.configure().setName("SimpleRoutesApplication");
        
        // Start the application
        System.out.println("Starting Apache Camel Application...");
        System.out.println("Routes will process messages every 5-10 seconds");
        System.out.println("Check the 'output', 'processed', and 'simple-output' directories for results");
        System.out.println("Press Ctrl+C to stop the application");
        
        // Run the application
        main.run(args);
    }
}
Save and exit the file
Subtask 1.5: Create Required Directories
Create input and output directories:
mkdir -p input output processed simple-output
Verify directory structure:
ls -la
You should see directories: input, output, processed, simple-output

Task 2: Test the Route by Sending Sample Messages
Subtask 2.1: Build the Project
Compile the project:
mvn clean compile
Verify successful compilation:
echo "Build Status: $?"
If the output shows Build Status: 0, the compilation was successful.

Subtask 2.2: Run the Application
Start the Camel application:
mvn exec:java -Dexec.mainClass="com.alnafi.camel.CamelApplication"
Observe the console output. You should see messages like:
Starting Apache Camel Application...
Routes will process messages every 5-10 seconds
Message processed: Hello from Apache Camel!...
Subtask 2.3: Test File-to-File Route
Open a new terminal (keep the first one running)

Navigate to the project directory:

cd camel-java-dsl-lab/simple-routes
Create a test file in the input directory:
echo "This is a test message for file processing.
Line 2: Testing multi-line content
Line 3: Apache Camel is processing this file
Line 4: Java DSL makes routing easy!" > input/test-message.txt
Create another test file:
echo "Customer Order Details:
Order ID: 12345
Customer: John Doe
Items: Laptop, Mouse, Keyboard
Total: $1,299.99
Status: Processing" > input/order-data.txt
Subtask 2.4: Verify Route Processing
Check the output directories for generated files:
ls -la output/
ls -la processed/
ls -la simple-output/
View the content of processed files:
# View timer-generated files
cat output/processed-message-*.txt

# View file-processed content
cat processed/processed-test-message.txt

# View simple route output
cat simple-output/simple-*.txt
Monitor real-time processing (optional):
# In another terminal, watch the directories
watch -n 2 'ls -la output/ processed/ simple-output/'
Subtask 2.5: Test Different Message Types
Create a JSON test file:
echo '{
  "messageType": "order",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "orderId": "ORD-001",
    "customer": "Alice Johnson",
    "amount": 299.99
  }
}' > input/json-message.json
Create a CSV test file:
echo "Name,Age,City,Country
John Smith,30,New York,USA
Jane Doe,25,London,UK
Bob Johnson,35,Toronto,Canada" > input/customer-data.csv
Wait and observe the processing in your running application terminal
Subtask 2.6: Stop and Restart Testing
Stop the application in the first terminal (Ctrl+C)

Clear output directories for fresh testing:

rm -f output/* processed/* simple-output/*
Restart the application:
mvn exec:java -Dexec.mainClass="com.alnafi.camel.CamelApplication"
Observe the fresh processing of any files still in the input directory
Advanced Testing and Troubleshooting
Understanding Route Behavior
Key Concepts Demonstrated:

from() method: Defines the source endpoint (timer, file)
process() method: Applies custom transformation logic
to() method: Defines the destination endpoint
Exchange object: Carries message data and headers between endpoints
Common Issues and Solutions
Issue 1: Files not being processed

# Check file permissions
ls -la input/
# Ensure files are readable
chmod 644 input/*
Issue 2: Application won't start

# Check Java version
java -version
# Verify Maven dependencies
mvn dependency:tree
Issue 3: No output files generated

# Check directory permissions
ls -la
# Create directories if missing
mkdir -p output processed simple-output
Monitoring and Debugging
Enable debug logging by creating a logging configuration:
nano src/main/resources/simplelogger.properties
Add logging configuration:
org.slf4j.simpleLogger.defaultLogLevel=info
org.slf4j.simpleLogger.log.org.apache.camel=debug
org.slf4j.simpleLogger.showDateTime=true
org.slf4j.simpleLogger.dateTimeFormat=yyyy-MM-dd HH:mm:ss
Restart the application to see detailed logs
Extending the Lab
Optional Enhancement: Add Error Handling
Create an enhanced route builder:
nano src/main/java/com/alnafi/camel/EnhancedRouteBuilder.java
Add error handling capabilities:
package com.alnafi.camel;

import org.apache.camel.builder.RouteBuilder;

public class EnhancedRouteBuilder extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Global error handler
        errorHandler(deadLetterChannel("file:error")
            .maximumRedeliveries(3)
            .redeliveryDelay(1000));
        
        // Enhanced route with error handling
        from("file:input-enhanced?noop=true")
            .onException(Exception.class)
                .handled(true)
                .log("Error processing file: ${exception.message}")
                .to("file:error?fileName=error-${date:now:yyyyMMdd-HHmmss}.txt")
            .end()
            .log("Processing file: ${header.CamelFileName}")
            .process(exchange -> {
                String content = exchange.getIn().getBody(String.class);
                if (content == null || content.trim().isEmpty()) {
                    throw new IllegalArgumentException("Empty file content");
                }
                exchange.getIn().setBody("ENHANCED: " + content);
            })
            .to("file:enhanced-output");
    }
}
Conclusion
Congratulations! You have successfully completed Lab 2: Creating Simple Camel Routes Using Java DSL.

What You Accomplished
Created a complete Maven project with proper Apache Camel dependencies
Implemented three different types of routes using Java DSL:
Timer-based route with custom message processing
File-to-file route with content transformation
Simple inline processing route
Used all three core DSL methods:
from() to define message sources
process() to transform and manipulate messages
to() to route messages to destinations
Tested routes with various message types including text files, JSON, and CSV data
Learned debugging and troubleshooting techniques for Camel applications
Why This Matters
This lab provides the foundation for enterprise integration development using Apache Camel. The skills you've learned are directly applicable to:

Enterprise Application Integration (EAI) scenarios
Microservices communication patterns
Data transformation and routing in cloud-native applications
Red Hat Certified Specialist in Cloud-native Integration exam preparation
Key Takeaways
Java DSL provides a powerful, type-safe way to define integration routes
Processors enable custom business logic implementation
File components are essential for batch processing scenarios
Timer components enable scheduled and periodic processing
Error handling is crucial for production-ready integration solutions
Next Steps
You're now ready to explore more advanced Camel features such as:

Content-based routing
Message transformation patterns
Enterprise Integration Patterns (EIP)
REST API integration
Database connectivity
The foundation you've built in this lab will serve you well as you continue your journey toward becoming a certified integration specialist.
