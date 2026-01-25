Lab 7: Error Handling and Dead Letter Queues (DLQ)
Objectives
By the end of this lab, you will be able to:

Implement robust error handling mechanisms in Apache Camel routes
Configure retry logic using the onException() clause
Create and configure Dead Letter Queues (DLQ) for failed message processing
Simulate various error scenarios to test error handling behavior
Monitor and analyze failed messages in DLQ for troubleshooting
Apply best practices for enterprise-level error handling patterns
Prerequisites
Before starting this lab, you should have:

Basic understanding of Apache Camel concepts and routing
Familiarity with Java programming fundamentals
Knowledge of Maven build tool
Understanding of message queuing concepts
Completion of previous Camel labs or equivalent experience
Basic Linux command-line skills
Ready-to-Use Cloud Machines
Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to access your environment. No need to build your own VM or install software - everything is ready to use!

Your cloud machine includes:

Apache Camel 3.20+
Apache ActiveMQ Artemis
Maven 3.8+
OpenJDK 11
VS Code with Java extensions
Lab Environment Setup
Task 1: Initialize the Lab Environment
Subtask 1.1: Access Your Cloud Machine
Click the Start Lab button to access your pre-configured environment
Open the terminal application
Verify your working directory:
pwd
cd /home/student/camel-labs
Subtask 1.2: Create Project Structure
Create a new Maven project for this lab:
mkdir lab7-error-handling
cd lab7-error-handling
Create the Maven project structure:
mkdir -p src/main/java/com/alnafi/camel/errorhandling
mkdir -p src/main/resources
mkdir -p src/test/java
Create the pom.xml file:
cat > pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.alnafi.camel</groupId>
    <artifactId>error-handling-lab</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <camel.version>3.20.2</camel.version>
        <activemq.version>5.17.3</activemq.version>
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
            <artifactId>camel-jms</artifactId>
            <version>${camel.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.activemq</groupId>
            <artifactId>activemq-client</artifactId>
            <version>${activemq.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.activemq</groupId>
            <artifactId>activemq-broker</artifactId>
            <version>${activemq.version}</version>
        </dependency>
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-simple</artifactId>
            <version>1.7.36</version>
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
EOF
Subtask 1.3: Start ActiveMQ Broker
Start the embedded ActiveMQ broker:
# Create a simple broker starter script
cat > start-broker.sh << 'EOF'
#!/bin/bash
echo "Starting ActiveMQ Broker..."
java -cp "$(mvn dependency:build-classpath -q -Dmdep.outputFile=/dev/stdout):target/classes" \
org.apache.activemq.broker.BrokerService &
echo "Broker started in background"
EOF

chmod +x start-broker.sh
Task 1: Set up Retry Logic for Routes using onException()
Subtask 1.1: Create Basic Route with Error Simulation
Create a service class that simulates errors:
cat > src/main/java/com/alnafi/camel/errorhandling/ErrorSimulationService.java << 'EOF'
package com.alnafi.camel.errorhandling;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ErrorSimulationService {
    private static final Logger logger = LoggerFactory.getLogger(ErrorSimulationService.class);
    private int callCount = 0;
    
    public String processMessage(String message) throws Exception {
        callCount++;
        logger.info("Processing message attempt #{}: {}", callCount, message);
        
        // Simulate different error scenarios
        if (message.contains("NETWORK_ERROR")) {
            throw new RuntimeException("Network connection failed");
        } else if (message.contains("TIMEOUT_ERROR")) {
            throw new RuntimeException("Operation timed out");
        } else if (message.contains("VALIDATION_ERROR")) {
            throw new IllegalArgumentException("Invalid message format");
        } else if (message.contains("RETRY_SUCCESS") && callCount < 3) {
            // Fail first 2 attempts, succeed on 3rd
            throw new RuntimeException("Temporary failure - attempt " + callCount);
        }
        
        logger.info("Message processed successfully: {}", message);
        return "Processed: " + message;
    }
    
    public void resetCallCount() {
        callCount = 0;
    }
}
EOF
Subtask 1.2: Create Route with Basic Retry Logic
Create the main route builder with retry configuration:
cat > src/main/java/com/alnafi/camel/errorhandling/ErrorHandlingRouteBuilder.java << 'EOF'
package com.alnafi.camel.errorhandling;

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.LoggingLevel;

public class ErrorHandlingRouteBuilder extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Global error handling with retry logic
        onException(RuntimeException.class)
            .log(LoggingLevel.WARN, "RuntimeException occurred: ${exception.message}")
            .maximumRedeliveries(3)
            .redeliveryDelay(2000)  // 2 seconds delay between retries
            .backOffMultiplier(2)   // Exponential backoff
            .useExponentialBackOff()
            .retryAttemptedLogLevel(LoggingLevel.WARN)
            .retriesExhaustedLogLevel(LoggingLevel.ERROR)
            .handled(false);  // Let the exception propagate after retries
            
        // Specific handling for IllegalArgumentException (validation errors)
        onException(IllegalArgumentException.class)
            .log(LoggingLevel.ERROR, "Validation error - no retry: ${exception.message}")
            .maximumRedeliveries(0)  // No retries for validation errors
            .handled(true)
            .to("direct:validation-error-handler");
        
        // Main processing route
        from("direct:process-message")
            .routeId("main-processing-route")
            .log("Received message: ${body}")
            .bean(ErrorSimulationService.class, "processMessage")
            .log("Successfully processed: ${body}")
            .to("direct:success-handler");
            
        // Success handler
        from("direct:success-handler")
            .routeId("success-handler")
            .log("Message processing completed successfully: ${body}")
            .to("file:output/success?fileName=success-${date:now:yyyyMMdd-HHmmss}.txt");
            
        // Validation error handler
        from("direct:validation-error-handler")
            .routeId("validation-error-handler")
            .log("Handling validation error for message: ${body}")
            .setBody(simple("Validation failed for: ${body}"))
            .to("file:output/validation-errors?fileName=validation-error-${date:now:yyyyMMdd-HHmmss}.txt");
    }
}
EOF
Subtask 1.3: Test Basic Retry Logic
Create a test application:
cat > src/main/java/com/alnafi/camel/errorhandling/RetryTestApplication.java << 'EOF'
package com.alnafi.camel.errorhandling;

import org.apache.camel.CamelContext;
import org.apache.camel.ProducerTemplate;
import org.apache.camel.impl.DefaultCamelContext;

public class RetryTestApplication {
    
    public static void main(String[] args) throws Exception {
        CamelContext context = new DefaultCamelContext();
        
        // Add route builder
        context.addRoutes(new ErrorHandlingRouteBuilder());
        
        // Register the service bean
        context.getRegistry().bind("errorSimulationService", new ErrorSimulationService());
        
        // Create output directories
        java.nio.file.Files.createDirectories(java.nio.file.Paths.get("output/success"));
        java.nio.file.Files.createDirectories(java.nio.file.Paths.get("output/validation-errors"));
        
        context.start();
        
        ProducerTemplate template = context.createProducerTemplate();
        
        System.out.println("=== Testing Retry Logic ===");
        
        // Test 1: Message that will succeed after retries
        System.out.println("\n1. Testing message that succeeds after retries...");
        try {
            template.sendBody("direct:process-message", "RETRY_SUCCESS - This will fail twice then succeed");
            Thread.sleep(15000); // Wait for retries to complete
        } catch (Exception e) {
            System.out.println("Final exception: " + e.getMessage());
        }
        
        // Test 2: Validation error (no retries)
        System.out.println("\n2. Testing validation error (no retries)...");
        try {
            template.sendBody("direct:process-message", "VALIDATION_ERROR - Invalid format");
            Thread.sleep(2000);
        } catch (Exception e) {
            System.out.println("Validation exception: " + e.getMessage());
        }
        
        // Test 3: Successful message
        System.out.println("\n3. Testing successful message...");
        try {
            template.sendBody("direct:process-message", "SUCCESS - This message will process normally");
            Thread.sleep(2000);
        } catch (Exception e) {
            System.out.println("Unexpected exception: " + e.getMessage());
        }
        
        Thread.sleep(5000);
        context.stop();
        System.out.println("Test completed. Check output directories for results.");
    }
}
EOF
Compile and run the retry test:
mvn clean compile
mvn exec:java -Dexec.mainClass="com.alnafi.camel.errorhandling.RetryTestApplication"
Observe the retry behavior in the console output and check the generated files:
ls -la output/success/
ls -la output/validation-errors/
Task 2: Create a Dead Letter Queue for Failed Messages
Subtask 2.1: Configure JMS Connection Factory
Create a JMS configuration class:
cat > src/main/java/com/alnafi/camel/errorhandling/JmsConfig.java << 'EOF'
package com.alnafi.camel.errorhandling;

import org.apache.activemq.ActiveMQConnectionFactory;
import org.apache.camel.component.jms.JmsComponent;
import org.apache.camel.CamelContext;

public class JmsConfig {
    
    public static void configureJms(CamelContext context) {
        // Create ActiveMQ connection factory
        ActiveMQConnectionFactory connectionFactory = new ActiveMQConnectionFactory();
        connectionFactory.setBrokerURL("vm://localhost?broker.persistent=false");
        
        // Create JMS component
        JmsComponent jmsComponent = JmsComponent.jmsComponentAutoAcknowledge(connectionFactory);
        
        // Add JMS component to Camel context
        context.addComponent("jms", jmsComponent);
    }
}
EOF
Subtask 2.2: Create Route Builder with Dead Letter Queue
Create an enhanced route builder with DLQ support:
cat > src/main/java/com/alnafi/camel/errorhandling/DLQRouteBuilder.java << 'EOF'
package com.alnafi.camel.errorhandling;

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.LoggingLevel;

public class DLQRouteBuilder extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Configure Dead Letter Channel for RuntimeException
        onException(RuntimeException.class)
            .log(LoggingLevel.WARN, "RuntimeException occurred: ${exception.message}")
            .maximumRedeliveries(3)
            .redeliveryDelay(1000)
            .backOffMultiplier(2)
            .useExponentialBackOff()
            .retryAttemptedLogLevel(LoggingLevel.WARN)
            .retriesExhaustedLogLevel(LoggingLevel.ERROR)
            .deadLetterUri("jms:queue:DLQ.RuntimeErrors")
            .deadLetterHandleNewException(false)
            .log(LoggingLevel.ERROR, "Message sent to DLQ after ${property.CamelRedeliveryCounter} retries: ${body}")
            .handled(true);
            
        // Configure Dead Letter Channel for IllegalArgumentException
        onException(IllegalArgumentException.class)
            .log(LoggingLevel.ERROR, "Validation error: ${exception.message}")
            .maximumRedeliveries(0)
            .deadLetterUri("jms:queue:DLQ.ValidationErrors")
            .log(LoggingLevel.ERROR, "Validation error sent to DLQ: ${body}")
            .handled(true);
            
        // Configure Dead Letter Channel for any other Exception
        onException(Exception.class)
            .log(LoggingLevel.ERROR, "Unexpected exception: ${exception.message}")
            .maximumRedeliveries(2)
            .redeliveryDelay(500)
            .deadLetterUri("jms:queue:DLQ.UnexpectedErrors")
            .log(LoggingLevel.ERROR, "Unexpected error sent to DLQ: ${body}")
            .handled(true);
        
        // Input queue route
        from("jms:queue:input.messages")
            .routeId("input-message-processor")
            .log("Processing message from input queue: ${body}")
            .bean(ErrorSimulationService.class, "processMessage")
            .log("Message processed successfully: ${body}")
            .to("jms:queue:output.success");
            
        // Success queue consumer (for demonstration)
        from("jms:queue:output.success")
            .routeId("success-consumer")
            .log("Success: ${body}")
            .to("file:output/success?fileName=success-${date:now:yyyyMMdd-HHmmss-SSS}.txt");
            
        // DLQ monitoring routes
        from("jms:queue:DLQ.RuntimeErrors")
            .routeId("dlq-runtime-monitor")
            .log(LoggingLevel.ERROR, "DLQ Runtime Error: ${body}")
            .setHeader("ErrorType", constant("RuntimeError"))
            .setHeader("Timestamp", simple("${date:now:yyyy-MM-dd HH:mm:ss}"))
            .to("file:output/dlq/runtime-errors?fileName=runtime-error-${date:now:yyyyMMdd-HHmmss-SSS}.txt");
            
        from("jms:queue:DLQ.ValidationErrors")
            .routeId("dlq-validation-monitor")
            .log(LoggingLevel.ERROR, "DLQ Validation Error: ${body}")
            .setHeader("ErrorType", constant("ValidationError"))
            .setHeader("Timestamp", simple("${date:now:yyyy-MM-dd HH:mm:ss}"))
            .to("file:output/dlq/validation-errors?fileName=validation-error-${date:now:yyyyMMdd-HHmmss-SSS}.txt");
            
        from("jms:queue:DLQ.UnexpectedErrors")
            .routeId("dlq-unexpected-monitor")
            .log(LoggingLevel.ERROR, "DLQ Unexpected Error: ${body}")
            .setHeader("ErrorType", constant("UnexpectedError"))
            .setHeader("Timestamp", simple("${date:now:yyyy-MM-dd HH:mm:ss}"))
            .to("file:output/dlq/unexpected-errors?fileName=unexpected-error-${date:now:yyyyMMdd-HHmmss-SSS}.txt");
    }
}
EOF
Subtask 2.3: Create DLQ Test Application
Create a comprehensive test application for DLQ functionality:
cat > src/main/java/com/alnafi/camel/errorhandling/DLQTestApplication.java << 'EOF'
package com.alnafi.camel.errorhandling;

import org.apache.camel.CamelContext;
import org.apache.camel.ProducerTemplate;
import org.apache.camel.impl.DefaultCamelContext;
import java.nio.file.Files;
import java.nio.file.Paths;

public class DLQTestApplication {
    
    public static void main(String[] args) throws Exception {
        CamelContext context = new DefaultCamelContext();
        
        // Configure JMS
        JmsConfig.configureJms(context);
        
        // Add route builder
        context.addRoutes(new DLQRouteBuilder());
        
        // Register the service bean
        context.getRegistry().bind("errorSimulationService", new ErrorSimulationService());
        
        // Create output directories
        Files.createDirectories(Paths.get("output/success"));
        Files.createDirectories(Paths.get("output/dlq/runtime-errors"));
        Files.createDirectories(Paths.get("output/dlq/validation-errors"));
        Files.createDirectories(Paths.get("output/dlq/unexpected-errors"));
        
        context.start();
        
        ProducerTemplate template = context.createProducerTemplate();
        
        System.out.println("=== Testing Dead Letter Queue Functionality ===");
        
        // Test 1: Message that will eventually go to DLQ after retries
        System.out.println("\n1. Testing message that goes to DLQ after retries...");
        template.sendBody("jms:queue:input.messages", "NETWORK_ERROR - This will fail and go to DLQ");
        Thread.sleep(10000); // Wait for retries and DLQ processing
        
        // Test 2: Validation error (immediate DLQ)
        System.out.println("\n2. Testing validation error (immediate DLQ)...");
        template.sendBody("jms:queue:input.messages", "VALIDATION_ERROR - Invalid format");
        Thread.sleep(3000);
        
        // Test 3: Successful message
        System.out.println("\n3. Testing successful message...");
        template.sendBody("jms:queue:input.messages", "SUCCESS - This will process normally");
        Thread.sleep(3000);
        
        // Test 4: Timeout error
        System.out.println("\n4. Testing timeout error...");
        template.sendBody("jms:queue:input.messages", "TIMEOUT_ERROR - This will timeout and go to DLQ");
        Thread.sleep(10000);
        
        // Test 5: Multiple messages for load testing
        System.out.println("\n5. Sending multiple test messages...");
        for (int i = 1; i <= 5; i++) {
            if (i % 2 == 0) {
                template.sendBody("jms:queue:input.messages", "SUCCESS - Message " + i);
            } else {
                template.sendBody("jms:queue:input.messages", "NETWORK_ERROR - Failed message " + i);
            }
            Thread.sleep(1000);
        }
        
        // Wait for all processing to complete
        Thread.sleep(15000);
        
        // Display results
        displayResults();
        
        context.stop();
        System.out.println("\nDLQ test completed. Check output directories for detailed results.");
    }
    
    private static void displayResults() {
        System.out.println("\n=== Processing Results ===");
        
        try {
            System.out.println("Success files: " + 
                Files.list(Paths.get("output/success")).count());
            System.out.println("Runtime error DLQ files: " + 
                Files.list(Paths.get("output/dlq/runtime-errors")).count());
            System.out.println("Validation error DLQ files: " + 
                Files.list(Paths.get("output/dlq/validation-errors")).count());
            System.out.println("Unexpected error DLQ files: " + 
                Files.list(Paths.get("output/dlq/unexpected-errors")).count());
        } catch (Exception e) {
            System.err.println("Error reading results: " + e.getMessage());
        }
    }
}
EOF
Run the DLQ test application:
mvn clean compile
mvn exec:java -Dexec.mainClass="com.alnafi.camel.errorhandling.DLQTestApplication"
Task 3: Simulate Errors and Test DLQ Behavior
Subtask 3.1: Create Advanced Error Simulation
Create an enhanced error simulation service with more realistic scenarios:
cat > src/main/java/com/alnafi/camel/errorhandling/AdvancedErrorSimulation.java << 'EOF'
package com.alnafi.camel.errorhandling;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.Random;
import java.util.concurrent.atomic.AtomicInteger;

public class AdvancedErrorSimulation {
    private static final Logger logger = LoggerFactory.getLogger(AdvancedErrorSimulation.class);
    private final AtomicInteger callCount = new AtomicInteger(0);
    private final Random random = new Random();
    
    public String processComplexMessage(String message) throws Exception {
        int attempt = callCount.incrementAndGet();
        logger.info("Processing complex message attempt #{}: {}", attempt, message);
        
        // Simulate database connection errors (transient)
        if (message.contains("DB_ERROR")) {
            if (attempt < 3) {
                throw new RuntimeException("Database connection failed - attempt " + attempt);
            }
            logger.info("Database connection recovered on attempt {}", attempt);
        }
        
        // Simulate network timeouts (transient with random recovery)
        else if (message.contains("NETWORK_TIMEOUT")) {
            if (random.nextDouble() < 0.7) { // 70% chance of failure
                throw new RuntimeException("Network timeout occurred");
            }
            logger.info("Network recovered successfully");
        }
        
        // Simulate service unavailable (transient)
        else if (message.contains("SERVICE_UNAVAILABLE")) {
            if (attempt <= 2) {
                throw new RuntimeException("External service unavailable");
            }
            logger.info("External service recovered");
        }
        
        // Simulate permanent failures
        else if (message.contains("PERMANENT_FAILURE")) {
            throw new RuntimeException("Permanent system failure - cannot recover");
        }
        
        // Simulate data format errors (permanent)
        else if (message.contains("INVALID_FORMAT")) {
            throw new IllegalArgumentException("Message format is invalid and cannot be processed");
        }
        
        // Simulate authentication errors (permanent)
        else if (message.contains("AUTH_ERROR")) {
            throw new SecurityException("Authentication failed - invalid credentials");
        }
        
        // Random failures for stress testing
        else if (message.contains("RANDOM_ERROR")) {
            if (random.nextDouble() < 0.3) { // 30% chance of failure
                throw new RuntimeException("Random failure occurred");
            }
        }
        
        logger.info("Message processed successfully: {}", message);
        return "Processed successfully: " + message + " (attempt " + attempt + ")";
    }
    
    public void resetCounters() {
        callCount.set(0);
    }
}
EOF
Subtask 3.2: Create Comprehensive Error Handling Routes
Create a comprehensive route builder for testing various error scenarios:
cat > src/main/java/com/alnafi/camel/errorhandling/ComprehensiveErrorRoutes.java << 'EOF'
package com.alnafi.camel.errorhandling;

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.LoggingLevel;

public class ComprehensiveErrorRoutes extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Handle SecurityException (authentication errors) - no retries
        onException(SecurityException.class)
            .log(LoggingLevel.ERROR, "Security error - no retries: ${exception.message}")
            .maximumRedeliveries(0)
            .deadLetterUri("jms:queue:DLQ.SecurityErrors")
            .setHeader("ErrorCategory", constant("SECURITY"))
            .setHeader("RetryCount", simple("${property.CamelRedeliveryCounter}"))
            .setHeader("FailureTime", simple("${date:now:yyyy-MM-dd HH:mm:ss}"))
            .log(LoggingLevel.ERROR, "Security error sent to DLQ: ${body}")
            .handled(true);
            
        // Handle IllegalArgumentException (validation errors) - no retries
        onException(IllegalArgumentException.class)
            .log(LoggingLevel.ERROR, "Validation error - no retries: ${exception.message}")
            .maximumRedeliveries(0)
            .deadLetterUri("jms:queue:DLQ.ValidationErrors")
            .setHeader("ErrorCategory", constant("VALIDATION"))
            .setHeader("RetryCount", simple("${property.CamelRedeliveryCounter}"))
            .setHeader("FailureTime", simple("${date:now:yyyy-MM-dd HH:mm:ss}"))
            .log(LoggingLevel.ERROR, "Validation error sent to DLQ: ${body}")
            .handled(true);
            
        // Handle RuntimeException (transient errors) - with retries
        onException(RuntimeException.class)
            .log(LoggingLevel.WARN, "Runtime error (attempt ${property.CamelRedeliveryCounter}): ${exception.message}")
            .maximumRedeliveries(4)
            .redeliveryDelay(1000)
            .backOffMultiplier(1.5)
            .useExponentialBackOff()
            .maximumRedeliveryDelay(10000)
            .retryAttemptedLogLevel(LoggingLevel.WARN)
            .retriesExhaustedLogLevel(LoggingLevel.ERROR)
            .deadLetterUri("jms:queue:DLQ.RuntimeErrors")
            .setHeader("ErrorCategory", constant("RUNTIME"))
            .setHeader("RetryCount", simple("${property.CamelRedeliveryCounter}"))
            .setHeader("FailureTime", simple("${date:now:yyyy-MM-dd HH:mm:ss}"))
            .log(LoggingLevel.ERROR, "Runtime error sent to DLQ after ${property.CamelRedeliveryCounter} retries: ${body}")
            .handled(true);
        
        // Main processing route
        from("jms:queue:test.input")
            .routeId("comprehensive-error-test")
            .log("Processing message: ${body}")
            .setHeader("ProcessingStartTime", simple("${date:now:yyyy-MM-dd HH:mm:ss}"))
            .bean(AdvancedErrorSimulation.class, "processComplexMessage")
            .log("Successfully processed: ${body}")
            .setHeader("ProcessingEndTime", simple("${date:now:yyyy-MM-dd HH:mm:ss}"))
            .to("jms:queue:test.success");
            
        // Success message handler
        from("jms:queue:test.success")
            .routeId("success-handler")
            .log("Success: ${body}")
            .to("file:output/success?fileName=success-${date:now:yyyyMMdd-HHmmss-SSS}.txt");
            
        // DLQ Monitoring and Analysis Routes
        from("jms:queue:DLQ.SecurityErrors")
            .routeId("dlq-security-monitor")
            .log(LoggingLevel.ERROR, "DLQ Security Error: ${body}")
            .setBody(simple("Security Error at ${header.FailureTime}\nMessage: ${body}\nRetries: ${header.RetryCount}\n"))
            .to("file:output/dlq/security-errors?fileName=security-error-${date:now:yyyyMMdd-HHmmss-SSS}.txt");
            
        from("jms:queue:DLQ.ValidationErrors")
            .routeId("dlq-validation-monitor")
            .log(LoggingLevel.ERROR, "DLQ Validation Error: ${body}")
            .setBody(simple("Validation Error at ${header.FailureTime}\nMessage: ${body}\nRetries: ${header.RetryCount}\n"))
            .to("file:output/dlq/validation-errors?fileName=validation-error-${date:now:yyyyMMdd-HHmmss-SSS}.txt");
            
        from("jms:queue:DLQ.RuntimeErrors")
            .routeId("dlq-runtime-monitor")
            .log(LoggingLevel.ERROR, "DLQ Runtime Error: ${body}")
            .setBody(simple("Runtime Error at ${header.FailureTime}\nMessage: ${body}\nRetries: ${header.RetryCount}\n"))
            .to("file:output/dlq/runtime-errors?fileName=runtime-error-${date:now:yyyyMMdd-HHmmss-SSS}.txt");
            
        // DLQ Analysis Route - aggregates error statistics
        from("timer://dlq-stats?period=30000") // Every 30 seconds
            .routeId("dlq-statistics")
            .setBody(constant("Generating DLQ statistics..."))
            .to("direct:generate-dlq-stats");
            
        from("direct:generate-dlq-stats")
            .routeId("dlq-stats-generator")
            .log("Generating DLQ
