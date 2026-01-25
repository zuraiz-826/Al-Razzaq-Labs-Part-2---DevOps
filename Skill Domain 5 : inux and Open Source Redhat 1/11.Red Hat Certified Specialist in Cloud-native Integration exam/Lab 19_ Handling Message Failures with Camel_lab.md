Lab 19: Handling Message Failures with Camel
Objectives
By the end of this lab, students will be able to:

Understand Apache Camel's error handling mechanisms and strategies
Implement retry policies for handling transient failures
Configure dead letter queues (DLQ) for managing failed messages
Create fallback processors to provide alternative processing paths
Simulate various failure scenarios and validate recovery behaviors
Monitor and troubleshoot message failures in Camel applications
Apply best practices for robust message processing in enterprise integration patterns
Prerequisites
Before starting this lab, students should have:

Basic understanding of Apache Camel framework and routing concepts
Familiarity with Java programming language
Knowledge of Maven build tool
Understanding of enterprise integration patterns
Basic Linux command line skills
Experience with message queues and asynchronous processing concepts
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines with all necessary tools pre-installed. Simply click Start Lab to begin - no need to build your own VM or install software.

Your cloud machine includes:

Java 11 or higher
Apache Maven 3.6+
Apache Camel 3.x
Text editor (nano/vim)
All required dependencies
Task 1: Setting Up Error Handling Strategies
Subtask 1.1: Create the Base Project Structure
First, let's create a new Maven project for our Camel error handling demonstration.

Create the project directory and navigate to it:
mkdir camel-error-handling-lab
cd camel-error-handling-lab
Create the Maven project structure:
mkdir -p src/main/java/com/example/camel
mkdir -p src/main/resources
mkdir -p src/test/java
Create the pom.xml file:
nano pom.xml
Add the following content:

<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>camel-error-handling</artifactId>
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
            <artifactId>camel-main</artifactId>
            <version>${camel.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-file</artifactId>
            <version>${camel.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-activemq</artifactId>
            <version>${camel.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.activemq</groupId>
            <artifactId>activemq-broker</artifactId>
            <version>5.17.0</version>
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
                <version>3.8.1</version>
                <configuration>
                    <source>11</source>
                    <target>11</target>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
Subtask 1.2: Create a Failure Simulation Processor
Create a processor that simulates failures:
nano src/main/java/com/example/camel/FailureSimulatorProcessor.java
Add the following content:

package com.example.camel;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import java.util.Random;

public class FailureSimulatorProcessor implements Processor {
    
    private final double failureRate;
    private final Random random = new Random();
    private int processCount = 0;
    
    public FailureSimulatorProcessor(double failureRate) {
        this.failureRate = failureRate;
    }
    
    @Override
    public void process(Exchange exchange) throws Exception {
        processCount++;
        String body = exchange.getIn().getBody(String.class);
        
        // Simulate different types of failures
        if (random.nextDouble() < failureRate) {
            if (processCount % 3 == 0) {
                throw new RuntimeException("Simulated runtime exception for message: " + body);
            } else if (processCount % 5 == 0) {
                throw new IllegalArgumentException("Simulated validation error for message: " + body);
            } else {
                throw new Exception("Simulated general exception for message: " + body);
            }
        }
        
        // Success case
        exchange.getIn().setBody("Processed successfully: " + body + " (attempt #" + processCount + ")");
        System.out.println("Successfully processed: " + body);
    }
}
Subtask 1.3: Create Retry Strategy Route
Create a route with retry error handling:
nano src/main/java/com/example/camel/RetryRouteBuilder.java
Add the following content:

package com.example.camel;

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.LoggingLevel;

public class RetryRouteBuilder extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Configure error handler with retry policy
        errorHandler(defaultErrorHandler()
            .maximumRedeliveries(3)
            .redeliveryDelay(2000)
            .retryAttemptedLogLevel(LoggingLevel.WARN)
            .retriesExhaustedLogLevel(LoggingLevel.ERROR)
            .logRetryAttempted(true)
            .logExhausted(true));
        
        // Route with retry strategy
        from("file:input/retry?noop=true&delay=5000")
            .routeId("retry-route")
            .log("Processing message with retry strategy: ${body}")
            .process(new FailureSimulatorProcessor(0.7)) // 70% failure rate
            .log("Message processed successfully: ${body}")
            .to("file:output/retry");
    }
}
Subtask 1.4: Create Dead Letter Queue Route
Create a route with dead letter queue handling:
nano src/main/java/com/example/camel/DeadLetterQueueRouteBuilder.java
Add the following content:

package com.example.camel;

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.LoggingLevel;

public class DeadLetterQueueRouteBuilder extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Configure error handler with dead letter queue
        errorHandler(deadLetterChannel("direct:dlq")
            .maximumRedeliveries(2)
            .redeliveryDelay(1000)
            .retryAttemptedLogLevel(LoggingLevel.WARN)
            .retriesExhaustedLogLevel(LoggingLevel.ERROR)
            .logRetryAttempted(true)
            .logExhausted(true)
            .useOriginalMessage());
        
        // Main processing route
        from("file:input/dlq?noop=true&delay=5000")
            .routeId("dlq-main-route")
            .log("Processing message with DLQ strategy: ${body}")
            .process(new FailureSimulatorProcessor(0.8)) // 80% failure rate
            .log("Message processed successfully: ${body}")
            .to("file:output/dlq/success");
        
        // Dead letter queue handler
        from("direct:dlq")
            .routeId("dlq-handler-route")
            .log("Message sent to DLQ: ${body}")
            .setHeader("FailureReason", simple("${exception.message}"))
            .setHeader("OriginalDestination", constant("file:output/dlq/success"))
            .setHeader("FailureTimestamp", simple("${date:now:yyyy-MM-dd HH:mm:ss}"))
            .to("file:output/dlq/failed");
    }
}
Task 2: Implementing Fallback Processors
Subtask 2.1: Create Fallback Processor
Create a fallback processor for alternative processing:
nano src/main/java/com/example/camel/FallbackProcessor.java
Add the following content:

package com.example.camel;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;

public class FallbackProcessor implements Processor {
    
    @Override
    public void process(Exchange exchange) throws Exception {
        String originalBody = exchange.getIn().getBody(String.class);
        
        // Provide fallback processing logic
        String fallbackResult = "FALLBACK_PROCESSED: " + originalBody + " [Processed via fallback mechanism]";
        
        exchange.getIn().setBody(fallbackResult);
        exchange.getIn().setHeader("ProcessingMethod", "FALLBACK");
        exchange.getIn().setHeader("FallbackTimestamp", System.currentTimeMillis());
        
        System.out.println("Fallback processing applied for: " + originalBody);
    }
}
Subtask 2.2: Create Route with Fallback Strategy
Create a route that uses fallback processing:
nano src/main/java/com/example/camel/FallbackRouteBuilder.java
Add the following content:

package com.example.camel;

import org.apache.camel.builder.RouteBuilder;

public class FallbackRouteBuilder extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Route with fallback strategy using doTry/doCatch
        from("file:input/fallback?noop=true&delay=5000")
            .routeId("fallback-route")
            .log("Processing message with fallback strategy: ${body}")
            .doTry()
                .process(new FailureSimulatorProcessor(0.6)) // 60% failure rate
                .log("Primary processing successful: ${body}")
                .to("file:output/fallback/primary")
            .doCatch(Exception.class)
                .log("Primary processing failed, applying fallback: ${exception.message}")
                .process(new FallbackProcessor())
                .log("Fallback processing completed: ${body}")
                .to("file:output/fallback/fallback")
            .end();
        
        // Alternative route using onException
        from("file:input/fallback-alt?noop=true&delay=5000")
            .routeId("fallback-alt-route")
            .onException(Exception.class)
                .handled(true)
                .log("Exception caught, applying fallback: ${exception.message}")
                .process(new FallbackProcessor())
                .to("file:output/fallback/alternative")
            .end()
            .log("Processing message with alternative fallback: ${body}")
            .process(new FailureSimulatorProcessor(0.5)) // 50% failure rate
            .to("file:output/fallback/alt-primary");
    }
}
Subtask 2.3: Create Advanced Error Handling Route
Create a comprehensive error handling route:
nano src/main/java/com/example/camel/AdvancedErrorHandlingRouteBuilder.java
Add the following content:

package com.example.camel;

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.LoggingLevel;

public class AdvancedErrorHandlingRouteBuilder extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Global exception handling
        onException(IllegalArgumentException.class)
            .handled(true)
            .log("Validation error occurred: ${exception.message}")
            .setHeader("ErrorType", constant("VALIDATION_ERROR"))
            .process(new FallbackProcessor())
            .to("file:output/advanced/validation-errors");
        
        onException(RuntimeException.class)
            .handled(false)
            .maximumRedeliveries(2)
            .redeliveryDelay(1000)
            .log("Runtime error, retrying: ${exception.message}")
            .to("file:output/advanced/runtime-errors");
        
        onException(Exception.class)
            .handled(true)
            .log("General exception caught: ${exception.message}")
            .setHeader("ErrorType", constant("GENERAL_ERROR"))
            .to("file:output/advanced/general-errors");
        
        // Main processing route
        from("file:input/advanced?noop=true&delay=5000")
            .routeId("advanced-error-handling-route")
            .log("Processing message with advanced error handling: ${body}")
            .choice()
                .when(body().contains("VALIDATE"))
                    .process(exchange -> {
                        throw new IllegalArgumentException("Validation failed for: " + 
                            exchange.getIn().getBody(String.class));
                    })
                .when(body().contains("RUNTIME"))
                    .process(exchange -> {
                        throw new RuntimeException("Runtime error for: " + 
                            exchange.getIn().getBody(String.class));
                    })
                .when(body().contains("GENERAL"))
                    .process(exchange -> {
                        throw new Exception("General error for: " + 
                            exchange.getIn().getBody(String.class));
                    })
                .otherwise()
                    .process(new FailureSimulatorProcessor(0.3)) // 30% failure rate
            .end()
            .log("Message processed successfully: ${body}")
            .to("file:output/advanced/success");
    }
}
Task 3: Creating the Main Application
Subtask 3.1: Create the Main Application Class
Create the main application to run all routes:
nano src/main/java/com/example/camel/ErrorHandlingApplication.java
Add the following content:

package com.example.camel;

import org.apache.camel.main.Main;

public class ErrorHandlingApplication {
    
    public static void main(String[] args) throws Exception {
        Main main = new Main();
        
        // Add route builders
        main.addRouteBuilder(new RetryRouteBuilder());
        main.addRouteBuilder(new DeadLetterQueueRouteBuilder());
        main.addRouteBuilder(new FallbackRouteBuilder());
        main.addRouteBuilder(new AdvancedErrorHandlingRouteBuilder());
        
        // Configure main
        main.configure().setDurationMaxMessages(100);
        main.configure().setShutdownTimeout(30);
        
        System.out.println("Starting Camel Error Handling Application...");
        System.out.println("Press Ctrl+C to stop the application");
        
        // Run the application
        main.run(args);
    }
}
Subtask 3.2: Create Directory Structure for Testing
Create input and output directories:
mkdir -p input/retry input/dlq input/fallback input/fallback-alt input/advanced
mkdir -p output/retry output/dlq/success output/dlq/failed
mkdir -p output/fallback/primary output/fallback/fallback output/fallback/alternative output/fallback/alt-primary
mkdir -p output/advanced/success output/advanced/validation-errors output/advanced/runtime-errors output/advanced/general-errors
Subtask 3.3: Build the Application
Compile and package the application:
mvn clean compile
Verify the build is successful:
mvn package -DskipTests
Task 4: Simulating Message Failures and Validating Recovery
Subtask 4.1: Test Retry Strategy
Create test messages for retry strategy:
echo "Test message for retry strategy - Message 1" > input/retry/retry-test-1.txt
echo "Test message for retry strategy - Message 2" > input/retry/retry-test-2.txt
echo "Test message for retry strategy - Message 3" > input/retry/retry-test-3.txt
Run the application to test retry behavior:
mvn exec:java -Dexec.mainClass="com.example.camel.ErrorHandlingApplication" &
Monitor the logs and output directories:
# In a new terminal, watch the logs
tail -f nohup.out

# Check output directory
ls -la output/retry/
Subtask 4.2: Test Dead Letter Queue Strategy
Create test messages for DLQ strategy:
echo "DLQ test message - Message 1" > input/dlq/dlq-test-1.txt
echo "DLQ test message - Message 2" > input/dlq/dlq-test-2.txt
echo "DLQ test message - Message 3" > input/dlq/dlq-test-3.txt
Monitor DLQ behavior:
# Watch both success and failed directories
watch -n 2 'ls -la output/dlq/success/ && echo "---" && ls -la output/dlq/failed/'
Examine failed message headers:
# Check the content of failed messages
cat output/dlq/failed/*.txt
Subtask 4.3: Test Fallback Processing
Create test messages for fallback strategy:
echo "Fallback test message - Primary processing" > input/fallback/fallback-test-1.txt
echo "Fallback test message - Should trigger fallback" > input/fallback/fallback-test-2.txt
Create test messages for alternative fallback:
echo "Alternative fallback test - Message 1" > input/fallback-alt/alt-test-1.txt
echo "Alternative fallback test - Message 2" > input/fallback-alt/alt-test-2.txt
Monitor fallback processing:
# Watch fallback directories
watch -n 2 'echo "Primary:" && ls -la output/fallback/primary/ && echo "Fallback:" && ls -la output/fallback/fallback/'
Subtask 4.4: Test Advanced Error Handling
Create test messages for different error types:
echo "VALIDATE - This should trigger validation error" > input/advanced/validation-test.txt
echo "RUNTIME - This should trigger runtime error" > input/advanced/runtime-test.txt
echo "GENERAL - This should trigger general error" > input/advanced/general-test.txt
echo "Normal message for processing" > input/advanced/normal-test.txt
Monitor advanced error handling:
# Watch all advanced output directories
watch -n 2 'echo "Success:" && ls -la output/advanced/success/ && echo "Validation Errors:" && ls -la output/advanced/validation-errors/ && echo "Runtime Errors:" && ls -la output/advanced/runtime-errors/ && echo "General Errors:" && ls -la output/advanced/general-errors/'
Subtask 4.5: Create Monitoring Script
Create a monitoring script to track all processing:
nano monitor-processing.sh
Add the following content:

#!/bin/bash

echo "=== Camel Error Handling Monitoring ==="
echo "Timestamp: $(date)"
echo

echo "=== Retry Strategy Results ==="
echo "Successful processing:"
ls -la output/retry/ 2>/dev/null || echo "No files processed yet"
echo

echo "=== Dead Letter Queue Results ==="
echo "Successful processing:"
ls -la output/dlq/success/ 2>/dev/null || echo "No successful files yet"
echo "Failed processing (DLQ):"
ls -la output/dlq/failed/ 2>/dev/null || echo "No failed files yet"
echo

echo "=== Fallback Strategy Results ==="
echo "Primary processing:"
ls -la output/fallback/primary/ 2>/dev/null || echo "No primary processed files yet"
echo "Fallback processing:"
ls -la output/fallback/fallback/ 2>/dev/null || echo "No fallback processed files yet"
echo

echo "=== Advanced Error Handling Results ==="
echo "Successful processing:"
ls -la output/advanced/success/ 2>/dev/null || echo "No successful files yet"
echo "Validation errors:"
ls -la output/advanced/validation-errors/ 2>/dev/null || echo "No validation errors yet"
echo "Runtime errors:"
ls -la output/advanced/runtime-errors/ 2>/dev/null || echo "No runtime errors yet"
echo "General errors:"
ls -la output/advanced/general-errors/ 2>/dev/null || echo "No general errors yet"
Make the script executable and run it:
chmod +x monitor-processing.sh
./monitor-processing.sh
Subtask 4.6: Performance and Behavior Analysis
Create a script to analyze error handling performance:
nano analyze-performance.sh
Add the following content:

#!/bin/bash

echo "=== Error Handling Performance Analysis ==="
echo "Analysis timestamp: $(date)"
echo

# Count files in each category
retry_count=$(ls output/retry/ 2>/dev/null | wc -l)
dlq_success_count=$(ls output/dlq/success/ 2>/dev/null | wc -l)
dlq_failed_count=$(ls output/dlq/failed/ 2>/dev/null | wc -l)
fallback_primary_count=$(ls output/fallback/primary/ 2>/dev/null | wc -l)
fallback_fallback_count=$(ls output/fallback/fallback/ 2>/dev/null | wc -l)
advanced_success_count=$(ls output/advanced/success/ 2>/dev/null | wc -l)
advanced_validation_count=$(ls output/advanced/validation-errors/ 2>/dev/null | wc -l)
advanced_runtime_count=$(ls output/advanced/runtime-errors/ 2>/dev/null | wc -l)
advanced_general_count=$(ls output/advanced/general-errors/ 2>/dev/null | wc -l)

echo "Retry Strategy:"
echo "  Successfully processed: $retry_count messages"
echo

echo "Dead Letter Queue Strategy:"
echo "  Successfully processed: $dlq_success_count messages"
echo "  Failed (sent to DLQ): $dlq_failed_count messages"
if [ $((dlq_success_count + dlq_failed_count)) -gt 0 ]; then
    success_rate=$(echo "scale=2; $dlq_success_count * 100 / ($dlq_success_count + $dlq_failed_count)" | bc -l)
    echo "  Success rate: ${success_rate}%"
fi
echo

echo "Fallback Strategy:"
echo "  Primary processing: $fallback_primary_count messages"
echo "  Fallback processing: $fallback_fallback_count messages"
if [ $((fallback_primary_count + fallback_fallback_count)) -gt 0 ]; then
    primary_rate=$(echo "scale=2; $fallback_primary_count * 100 / ($fallback_primary_count + $fallback_fallback_count)" | bc -l)
    echo "  Primary success rate: ${primary_rate}%"
fi
echo

echo "Advanced Error Handling:"
echo "  Successful processing: $advanced_success_count messages"
echo "  Validation errors: $advanced_validation_count messages"
echo "  Runtime errors: $advanced_runtime_count messages"
echo "  General errors: $advanced_general_count messages"
echo

total_processed=$((retry_count + dlq_success_count + dlq_failed_count + fallback_primary_count + fallback_fallback_count + advanced_success_count + advanced_validation_count + advanced_runtime_count + advanced_general_count))
echo "Total messages processed across all strategies: $total_processed"
Make the script executable:
chmod +x analyze-performance.sh
Install bc calculator if not available:
# Check if bc is installed
which bc || sudo apt-get update && sudo apt-get install -y bc
Run the performance analysis:
./analyze-performance.sh
Task 5: Advanced Testing and Validation
Subtask 5.1: Create Load Testing Script
Create a load testing script to generate multiple messages:
nano load-test.sh
Add the following content:

#!/bin/bash

echo "Starting load test for Camel error handling..."

# Generate messages for retry strategy
for i in {1..10}; do
    echo "Retry load test message $i - $(date)" > input/retry/load-test-retry-$i.txt
    sleep 0.5
done

# Generate messages for DLQ strategy
for i in {1..10}; do
    echo "DLQ load test message $i - $(date)" > input/dlq/load-test-dlq-$i.txt
    sleep 0.5
done

# Generate messages for fallback strategy
for i in {1..10}; do
    echo "Fallback load test message $i - $(date)" > input/fallback/load-test-fallback-$i.txt
    sleep 0.5
done

# Generate messages for advanced error handling
for i in {1..5}; do
    echo "VALIDATE - Load test validation message $i" > input/advanced/load-test-validate-$i.txt
    echo "RUNTIME - Load test runtime message $i" > input/advanced/load-test-runtime-$i.txt
    echo "Normal load test message $i - $(date)" > input/advanced/load-test-normal-$i.txt
    sleep 0.5
done

echo "Load test messages generated successfully!"
echo "Monitor the processing with: ./monitor-processing.sh"
Make the script executable and run it:
chmod +x load-test.sh
./load-test.sh
Subtask 5.2: Validate Error Handling Behaviors
Stop the current application (if running):
# Find the process ID
ps aux | grep ErrorHandlingApplication
# Kill the process (replace PID with actual process ID)
kill -9 <PID>
Restart the application with detailed logging:
mvn exec:java -Dexec.mainClass="com.example.camel.ErrorHandlingApplication" > application.log 2>&1 &
Run the load test and monitor results:
./load-test.sh
sleep 30  # Wait for processing
./analyze-performance.sh
Examine the application logs for error patterns:
# Look for retry attempts
grep -i "retry" application.log

# Look for DLQ messages
grep -i "dlq" application.log

# Look for fallback processing
grep -i "fallback" application.log

# Look for exception handling
grep -i "exception" application.log
Subtask 5.3: Create Comprehensive Test Report
Create a test report generator:
nano generate-test-report.sh
Add the following content:

#!/bin/bash

REPORT_FILE="error-handling-test-report.txt"

echo "=== CAMEL ERROR HANDLING LAB TEST REPORT ===" > $REPORT_FILE
echo "Generated on: $(date)" >> $REPORT_FILE
echo "=========================================" >> $REPORT_FILE
echo >> $REPORT_FILE

echo "=== CONFIGURATION SUMMARY ===" >> $REPORT_FILE
echo "- Retry Strategy: Max 3 retries, 2 second delay" >> $REPORT_FILE
echo "- DLQ Strategy: Max 2 retries, 1 second delay" >> $REPORT_FILE
echo "- Fallback Strategy: Immediate fallback on failure" >> $REPORT_FILE
echo "- Advanced Handling: Exception-specific routing" >> $REPORT_FILE
echo >> $REPORT_FILE

echo "=== PROCESSING RESULTS ===" >> $REPORT_FILE
./analyze-performance.sh >> $REPORT_FILE
echo >> $REPORT_FILE

echo "=== ERROR PATTERNS ANALYSIS ===" >> $REPORT_FILE
echo "Retry attempts found:" >> $REPORT_FILE
grep -c "retry" application.log 2>/dev/null >> $REPORT_FILE || echo "0" >> $REPORT_FILE
echo >> $REPORT_FILE

echo "DLQ routing events:" >> $REPORT_FILE
grep -c "DLQ" application.log 2>/dev/null >> $REPORT_FILE || echo "0" >> $REPORT_FILE
echo >> $REPORT_FILE

echo "Fallback processing events:" >> $REPORT_FILE
grep -c "Fallback" application.log 2>/dev/null >> $REPORT_FILE || echo "0" >> $REPORT_FILE
echo >> $REPORT_FILE

echo "=== SAMPLE ERROR MESSAGES ===" >> $REPORT_FILE
echo "Recent error log entries:" >> $REPORT_FILE
tail -20 application.log 2>/dev/null | grep -i error >> $REPORT_FILE || echo "No recent errors found" >> $REPORT_FILE
echo >> $REPORT_FILE

echo "=== RECOMMENDATIONS ===" >> $REPORT_FILE
echo "1. Monitor DLQ messages regularly for business impact" >> $REPORT_FILE
echo "2. Adjust retry delays based on downstream system capabilities" >> $REPORT_FILE
echo "3. Implement alerting for high failure rates" >> $REPORT_FILE
echo "4. Consider circuit breaker patterns for external dependencies" >> $REPORT_FILE
echo >> $REPORT_FILE

echo "Test report generated: $REPORT_FILE"
Generate the test report:
chmod +x generate-test-report.sh
./generate-test-report.sh
Review the test report:
cat error-handling-test-report.txt
Troubleshooting Common Issues
Issue 1: Application Not Starting
Symptoms: Maven exec fails or application exits immediately

Solutions:

# Check Java version
java -version

# Verify Maven compilation
mvn clean compile

# Check for port conflicts
netstat -tulpn | grep :61616
Issue 2: Messages Not Being Processed
Symptoms: Input files remain unprocessed

Solutions:

# Check file permissions
ls -la input/*/

# Verify directory structure
find . -type d -name "input" -o -name "output"

# Check application logs
tail -f application.log
Issue 3: Error Handling Not Working
Symptoms: Exceptions not being caught or routed properly

Solutions:

# Verify route configuration
grep -n "onException\|errorHandler" src/main/java/com/example/camel/*.java
