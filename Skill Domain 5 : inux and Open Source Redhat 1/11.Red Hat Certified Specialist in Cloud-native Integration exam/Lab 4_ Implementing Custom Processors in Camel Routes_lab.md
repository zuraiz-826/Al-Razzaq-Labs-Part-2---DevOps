Lab 4: Implementing Custom Processors in Camel Routes
Objectives
By the end of this lab, you will be able to:

Understand the role of custom processors in Apache Camel integration patterns
Implement custom processors by creating classes that implement the Processor interface
Insert custom processors into Camel routes to modify message content and headers
Test Camel routes with custom processors using different message types and formats
Debug and troubleshoot custom processor implementations
Apply best practices for custom processor development in enterprise integration scenarios
Prerequisites
Before starting this lab, you should have:

Basic understanding of Java programming concepts (classes, interfaces, methods)
Familiarity with Apache Camel fundamentals and route building
Knowledge of Maven project structure and dependency management
Understanding of message exchange patterns in integration frameworks
Experience with basic Linux command-line operations
Required Knowledge Areas
Java Development: Object-oriented programming, exception handling
Apache Camel Basics: Routes, endpoints, and message exchanges
Maven: Project lifecycle, dependencies, and build processes
Integration Patterns: Message transformation and routing concepts
Lab Environment Setup
Ready-to-Use Cloud Machines
Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click Start Lab to access your environment. No need to build your own VM or install software - everything is ready to use!

Your cloud machine includes:

OpenJDK 11 or higher
Apache Maven 3.6+
Apache Camel 3.x libraries
Text editors (nano, vim)
All necessary development tools
Task 1: Create a Custom Processor Implementing the Processor Interface
Subtask 1.1: Set Up the Maven Project Structure
First, let's create a new Maven project for our custom processor implementation.

# Navigate to your home directory
cd ~

# Create a new Maven project
mvn archetype:generate \
  -DgroupId=com.alnafi.camel.lab4 \
  -DartifactId=custom-processor-lab \
  -DarchetypeArtifactId=maven-archetype-quickstart \
  -DinteractiveMode=false

# Navigate to the project directory
cd custom-processor-lab
Subtask 1.2: Configure Maven Dependencies
Update the pom.xml file to include necessary Camel dependencies:

# Open the pom.xml file for editing
nano pom.xml
Replace the content with the following configuration:

<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.alnafi.camel.lab4</groupId>
    <artifactId>custom-processor-lab</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <camel.version>3.20.0</camel.version>
        <slf4j.version>1.7.36</slf4j.version>
    </properties>

    <dependencies>
        <!-- Apache Camel Core -->
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

        <!-- Camel Direct component -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-direct</artifactId>
            <version>${camel.version}</version>
        </dependency>

        <!-- Camel Timer component -->
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

        <!-- JUnit for testing -->
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.13.2</version>
            <scope>test</scope>
        </dependency>

        <!-- Camel Test -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-test</artifactId>
            <version>${camel.version}</version>
            <scope>test</scope>
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
Save and exit the editor (Ctrl+X, then Y, then Enter for nano).

Subtask 1.3: Create the Custom Processor Class
Now let's create our first custom processor that will transform message content:

# Create the package directory structure
mkdir -p src/main/java/com/alnafi/camel/lab4/processors

# Create the custom processor class
nano src/main/java/com/alnafi/camel/lab4/processors/MessageTransformProcessor.java
Add the following code for the custom processor:

package com.alnafi.camel.lab4.processors;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Custom processor that transforms incoming messages by:
 * 1. Converting text to uppercase
 * 2. Adding a timestamp
 * 3. Adding custom headers
 */
public class MessageTransformProcessor implements Processor {
    
    private static final Logger logger = LoggerFactory.getLogger(MessageTransformProcessor.class);
    
    @Override
    public void process(Exchange exchange) throws Exception {
        // Log the incoming message
        logger.info("Processing message in custom processor");
        
        // Get the message body as String
        String originalMessage = exchange.getIn().getBody(String.class);
        logger.info("Original message: {}", originalMessage);
        
        // Transform the message
        String transformedMessage = transformMessage(originalMessage);
        
        // Set the transformed message back to the exchange
        exchange.getIn().setBody(transformedMessage);
        
        // Add custom headers
        addCustomHeaders(exchange);
        
        logger.info("Transformed message: {}", transformedMessage);
    }
    
    /**
     * Transform the message content
     */
    private String transformMessage(String originalMessage) {
        if (originalMessage == null) {
            return "NULL_MESSAGE_PROCESSED_AT_" + System.currentTimeMillis();
        }
        
        // Convert to uppercase and add timestamp
        String transformed = originalMessage.toUpperCase() + 
                           " [PROCESSED_AT_" + System.currentTimeMillis() + "]";
        
        return transformed;
    }
    
    /**
     * Add custom headers to the message
     */
    private void addCustomHeaders(Exchange exchange) {
        exchange.getIn().setHeader("ProcessedBy", "MessageTransformProcessor");
        exchange.getIn().setHeader("ProcessingTimestamp", System.currentTimeMillis());
        exchange.getIn().setHeader("MessageLength", 
                                 exchange.getIn().getBody(String.class).length());
    }
}
Subtask 1.4: Create an Advanced Custom Processor
Let's create a second, more advanced custom processor that handles different message types:

# Create another custom processor
nano src/main/java/com/alnafi/camel/lab4/processors/MessageEnrichmentProcessor.java
Add the following code:

package com.alnafi.camel.lab4.processors;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

/**
 * Advanced custom processor that enriches messages with additional data
 * and handles different message formats
 */
public class MessageEnrichmentProcessor implements Processor {
    
    private static final Logger logger = LoggerFactory.getLogger(MessageEnrichmentProcessor.class);
    
    // Simulated data store for enrichment
    private static final Map<String, String> enrichmentData = new HashMap<>();
    
    static {
        enrichmentData.put("USER001", "John Doe - Premium Customer");
        enrichmentData.put("USER002", "Jane Smith - Standard Customer");
        enrichmentData.put("USER003", "Bob Johnson - VIP Customer");
    }
    
    @Override
    public void process(Exchange exchange) throws Exception {
        logger.info("Starting message enrichment process");
        
        // Get message body and headers
        String messageBody = exchange.getIn().getBody(String.class);
        String messageType = exchange.getIn().getHeader("MessageType", String.class);
        
        logger.info("Processing message type: {}", messageType);
        logger.info("Original message body: {}", messageBody);
        
        // Process based on message type
        String enrichedMessage = enrichMessage(messageBody, messageType);
        
        // Set enriched message
        exchange.getIn().setBody(enrichedMessage);
        
        // Add processing metadata
        addProcessingMetadata(exchange, messageType);
        
        logger.info("Message enrichment completed");
    }
    
    /**
     * Enrich message based on type and content
     */
    private String enrichMessage(String originalMessage, String messageType) {
        StringBuilder enriched = new StringBuilder();
        
        // Add message type prefix
        enriched.append("[").append(messageType != null ? messageType : "UNKNOWN").append("] ");
        
        // Process the message content
        if (originalMessage != null && originalMessage.startsWith("USER")) {
            // Extract user ID and enrich with user data
            String userId = originalMessage.split(" ")[0];
            String userData = enrichmentData.get(userId);
            
            if (userData != null) {
                enriched.append("ENRICHED: ").append(userData);
                enriched.append(" | Original: ").append(originalMessage);
            } else {
                enriched.append("UNKNOWN_USER: ").append(originalMessage);
            }
        } else {
            // Standard message processing
            enriched.append("STANDARD: ").append(originalMessage);
        }
        
        // Add processing timestamp
        enriched.append(" | Enriched at: ").append(System.currentTimeMillis());
        
        return enriched.toString();
    }
    
    /**
     * Add processing metadata headers
     */
    private void addProcessingMetadata(Exchange exchange, String messageType) {
        exchange.getIn().setHeader("EnrichedBy", "MessageEnrichmentProcessor");
        exchange.getIn().setHeader("EnrichmentTimestamp", System.currentTimeMillis());
        exchange.getIn().setHeader("OriginalMessageType", messageType);
        exchange.getIn().setHeader("EnrichmentApplied", true);
        
        // Add specific metadata based on message type
        if ("USER_REQUEST".equals(messageType)) {
            exchange.getIn().setHeader("Priority", "HIGH");
        } else if ("SYSTEM_MESSAGE".equals(messageType)) {
            exchange.getIn().setHeader("Priority", "MEDIUM");
        } else {
            exchange.getIn().setHeader("Priority", "LOW");
        }
    }
}
Task 2: Insert the Custom Processor into a Camel Route
Subtask 2.1: Create a Route Builder with Custom Processors
Now let's create a Camel route that uses our custom processors:

# Create the route builder class
mkdir -p src/main/java/com/alnafi/camel/lab4/routes
nano src/main/java/com/alnafi/camel/lab4/routes/CustomProcessorRouteBuilder.java
Add the following route configuration:

package com.alnafi.camel.lab4.routes;

import com.alnafi.camel.lab4.processors.MessageEnrichmentProcessor;
import com.alnafi.camel.lab4.processors.MessageTransformProcessor;
import org.apache.camel.builder.RouteBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Route builder that demonstrates custom processor integration
 */
public class CustomProcessorRouteBuilder extends RouteBuilder {
    
    private static final Logger logger = LoggerFactory.getLogger(CustomProcessorRouteBuilder.class);
    
    @Override
    public void configure() throws Exception {
        
        // Route 1: Basic message transformation using custom processor
        from("direct:transform")
            .routeId("message-transform-route")
            .log("Received message for transformation: ${body}")
            .process(new MessageTransformProcessor())
            .log("Message after transformation: ${body}")
            .log("Custom headers added: ProcessedBy=${header.ProcessedBy}, " +
                 "Timestamp=${header.ProcessingTimestamp}")
            .to("direct:output");
        
        // Route 2: Advanced message enrichment using custom processor
        from("direct:enrich")
            .routeId("message-enrichment-route")
            .log("Received message for enrichment: ${body}")
            .log("Message type: ${header.MessageType}")
            .process(new MessageEnrichmentProcessor())
            .log("Message after enrichment: ${body}")
            .log("Enrichment metadata: EnrichedBy=${header.EnrichedBy}, " +
                 "Priority=${header.Priority}")
            .to("direct:output");
        
        // Route 3: Combined processing - both processors in sequence
        from("direct:combined")
            .routeId("combined-processing-route")
            .log("Starting combined processing for: ${body}")
            .process(new MessageTransformProcessor())
            .log("After transformation: ${body}")
            .process(new MessageEnrichmentProcessor())
            .log("After enrichment: ${body}")
            .log("Final headers: ProcessedBy=${header.ProcessedBy}, " +
                 "EnrichedBy=${header.EnrichedBy}, Priority=${header.Priority}")
            .to("direct:output");
        
        // Route 4: Timer-based route for automatic testing
        from("timer:autoTest?period=10000&repeatCount=3")
            .routeId("auto-test-route")
            .setBody(constant("Hello from timer route"))
            .setHeader("MessageType", constant("SYSTEM_MESSAGE"))
            .log("Auto-generated message: ${body}")
            .to("direct:transform");
        
        // Output route - final destination for all processed messages
        from("direct:output")
            .routeId("output-route")
            .log("=== FINAL PROCESSED MESSAGE ===")
            .log("Body: ${body}")
            .log("All Headers: ${headers}")
            .log("=== END OF PROCESSING ===");
    }
}
Subtask 2.2: Create the Main Application Class
Create the main application class to run our Camel context:

# Create the main application class
nano src/main/java/com/alnafi/camel/lab4/CustomProcessorApplication.java
Add the following code:

package com.alnafi.camel.lab4;

import com.alnafi.camel.lab4.routes.CustomProcessorRouteBuilder;
import org.apache.camel.CamelContext;
import org.apache.camel.ProducerTemplate;
import org.apache.camel.impl.DefaultCamelContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Main application class for custom processor demonstration
 */
public class CustomProcessorApplication {
    
    private static final Logger logger = LoggerFactory.getLogger(CustomProcessorApplication.class);
    
    public static void main(String[] args) throws Exception {
        logger.info("Starting Custom Processor Lab Application");
        
        // Create Camel context
        CamelContext camelContext = new DefaultCamelContext();
        
        try {
            // Add our route builder
            camelContext.addRoutes(new CustomProcessorRouteBuilder());
            
            // Start the context
            camelContext.start();
            logger.info("Camel context started successfully");
            
            // Get producer template for sending messages
            ProducerTemplate producer = camelContext.createProducerTemplate();
            
            // Test the routes with different messages
            testRoutes(producer);
            
            // Keep the application running for timer-based route
            logger.info("Application running... Timer route will execute automatically");
            logger.info("Press Ctrl+C to stop the application");
            
            // Keep running for 60 seconds to see timer route execution
            Thread.sleep(60000);
            
        } finally {
            // Stop the context
            camelContext.stop();
            logger.info("Camel context stopped");
        }
    }
    
    /**
     * Test all routes with different message types
     */
    private static void testRoutes(ProducerTemplate producer) throws Exception {
        logger.info("=== Starting Route Testing ===");
        
        // Test 1: Basic transformation route
        logger.info("\n--- Test 1: Basic Transformation ---");
        producer.sendBody("direct:transform", "hello world from camel");
        
        Thread.sleep(1000); // Small delay for log readability
        
        // Test 2: Enrichment route with user message
        logger.info("\n--- Test 2: User Message Enrichment ---");
        producer.sendBodyAndHeader("direct:enrich", "USER001 requesting account balance", 
                                 "MessageType", "USER_REQUEST");
        
        Thread.sleep(1000);
        
        // Test 3: Enrichment route with unknown user
        logger.info("\n--- Test 3: Unknown User Message ---");
        producer.sendBodyAndHeader("direct:enrich", "USER999 unknown user request", 
                                 "MessageType", "USER_REQUEST");
        
        Thread.sleep(1000);
        
        // Test 4: Combined processing
        logger.info("\n--- Test 4: Combined Processing ---");
        producer.sendBodyAndHeader("direct:combined", "USER002 premium service request", 
                                 "MessageType", "USER_REQUEST");
        
        Thread.sleep(1000);
        
        // Test 5: System message
        logger.info("\n--- Test 5: System Message ---");
        producer.sendBodyAndHeader("direct:enrich", "System maintenance scheduled", 
                                 "MessageType", "SYSTEM_MESSAGE");
        
        Thread.sleep(1000);
        
        logger.info("=== Route Testing Completed ===\n");
    }
}
Subtask 2.3: Build and Compile the Project
Let's build our project to ensure everything compiles correctly:

# Clean and compile the project
mvn clean compile

# If compilation is successful, you should see "BUILD SUCCESS"
If you encounter any compilation errors, check the following:

Ensure all Java files are saved properly
Verify the package declarations match the directory structure
Check that all imports are correct
Task 3: Test the Route with Different Messages
Subtask 3.1: Run the Basic Application
Let's run our application to see the custom processors in action:

# Run the application
mvn exec:java -Dexec.mainClass="com.alnafi.camel.lab4.CustomProcessorApplication"
You should see output similar to:

INFO  CustomProcessorApplication - Starting Custom Processor Lab Application
INFO  CustomProcessorApplication - Camel context started successfully
INFO  CustomProcessorApplication - === Starting Route Testing ===
INFO  CustomProcessorApplication - --- Test 1: Basic Transformation ---
INFO  message-transform-route - Received message for transformation: hello world from camel
INFO  MessageTransformProcessor - Processing message in custom processor
INFO  MessageTransformProcessor - Original message: hello world from camel
INFO  MessageTransformProcessor - Transformed message: HELLO WORLD FROM CAMEL [PROCESSED_AT_1234567890]
INFO  message-transform-route - Message after transformation: HELLO WORLD FROM CAMEL [PROCESSED_AT_1234567890]
Subtask 3.2: Create a Test Class for Unit Testing
Let's create proper unit tests for our custom processors:

# Create test directory structure
mkdir -p src/test/java/com/alnafi/camel/lab4/processors

# Create test class for MessageTransformProcessor
nano src/test/java/com/alnafi/camel/lab4/processors/MessageTransformProcessorTest.java
Add the following test code:

package com.alnafi.camel.lab4.processors;

import org.apache.camel.Exchange;
import org.apache.camel.impl.DefaultCamelContext;
import org.apache.camel.support.DefaultExchange;
import org.junit.Before;
import org.junit.Test;
import static org.junit.Assert.*;

/**
 * Unit tests for MessageTransformProcessor
 */
public class MessageTransformProcessorTest {
    
    private MessageTransformProcessor processor;
    private Exchange exchange;
    
    @Before
    public void setUp() {
        processor = new MessageTransformProcessor();
        exchange = new DefaultExchange(new DefaultCamelContext());
    }
    
    @Test
    public void testBasicMessageTransformation() throws Exception {
        // Given
        String originalMessage = "hello world";
        exchange.getIn().setBody(originalMessage);
        
        // When
        processor.process(exchange);
        
        // Then
        String transformedMessage = exchange.getIn().getBody(String.class);
        assertTrue("Message should be uppercase", 
                  transformedMessage.startsWith("HELLO WORLD"));
        assertTrue("Message should contain timestamp", 
                  transformedMessage.contains("PROCESSED_AT_"));
    }
    
    @Test
    public void testNullMessageHandling() throws Exception {
        // Given
        exchange.getIn().setBody(null);
        
        // When
        processor.process(exchange);
        
        // Then
        String transformedMessage = exchange.getIn().getBody(String.class);
        assertTrue("Null message should be handled", 
                  transformedMessage.startsWith("NULL_MESSAGE_PROCESSED_AT_"));
    }
    
    @Test
    public void testCustomHeadersAdded() throws Exception {
        // Given
        exchange.getIn().setBody("test message");
        
        // When
        processor.process(exchange);
        
        // Then
        assertEquals("ProcessedBy header should be set", 
                    "MessageTransformProcessor", 
                    exchange.getIn().getHeader("ProcessedBy"));
        assertNotNull("ProcessingTimestamp should be set", 
                     exchange.getIn().getHeader("ProcessingTimestamp"));
        assertNotNull("MessageLength should be set", 
                     exchange.getIn().getHeader("MessageLength"));
    }
}
Subtask 3.3: Create Integration Tests
Create an integration test that tests the complete route:

# Create integration test
nano src/test/java/com/alnafi/camel/lab4/routes/CustomProcessorRouteTest.java
Add the following integration test:

package com.alnafi.camel.lab4.routes;

import com.alnafi.camel.lab4.routes.CustomProcessorRouteBuilder;
import org.apache.camel.CamelContext;
import org.apache.camel.ProducerTemplate;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.component.mock.MockEndpoint;
import org.apache.camel.test.junit4.CamelTestSupport;
import org.junit.Test;

/**
 * Integration tests for custom processor routes
 */
public class CustomProcessorRouteTest extends CamelTestSupport {
    
    @Override
    protected RouteBuilder createRouteBuilder() throws Exception {
        return new RouteBuilder() {
            @Override
            public void configure() throws Exception {
                // Include our custom processor routes
                CustomProcessorRouteBuilder customRoutes = new CustomProcessorRouteBuilder();
                customRoutes.configure();
                
                // Override the output endpoint with mock for testing
                from("direct:output")
                    .to("mock:result");
            }
        };
    }
    
    @Test
    public void testTransformRoute() throws Exception {
        // Given
        MockEndpoint mockResult = getMockEndpoint("mock:result");
        mockResult.expectedMessageCount(1);
        
        // When
        template.sendBody("direct:transform", "test message");
        
        // Then
        assertMockEndpointsSatisfied();
        
        String resultBody = mockResult.getReceivedExchanges().get(0)
                                    .getIn().getBody(String.class);
        assertTrue("Message should be transformed to uppercase", 
                  resultBody.startsWith("TEST MESSAGE"));
        assertTrue("Message should contain processing timestamp", 
                  resultBody.contains("PROCESSED_AT_"));
    }
    
    @Test
    public void testEnrichmentRoute() throws Exception {
        // Given
        MockEndpoint mockResult = getMockEndpoint("mock:result");
        mockResult.expectedMessageCount(1);
        
        // When
        template.sendBodyAndHeader("direct:enrich", "USER001 account inquiry", 
                                 "MessageType", "USER_REQUEST");
        
        // Then
        assertMockEndpointsSatisfied();
        
        String resultBody = mockResult.getReceivedExchanges().get(0)
                                    .getIn().getBody(String.class);
        assertTrue("Message should be enriched with user data", 
                  resultBody.contains("John Doe - Premium Customer"));
        assertTrue("Message should contain message type", 
                  resultBody.startsWith("[USER_REQUEST]"));
    }
    
    @Test
    public void testCombinedProcessing() throws Exception {
        // Given
        MockEndpoint mockResult = getMockEndpoint("mock:result");
        mockResult.expectedMessageCount(1);
        
        // When
        template.sendBodyAndHeader("direct:combined", "USER002 service request", 
                                 "MessageType", "USER_REQUEST");
        
        // Then
        assertMockEndpointsSatisfied();
        
        // Verify both processors were applied
        Exchange resultExchange = mockResult.getReceivedExchanges().get(0);
        String resultBody = resultExchange.getIn().getBody(String.class);
        
        assertTrue("Message should contain enrichment data", 
                  resultBody.contains("Jane Smith - Standard Customer"));
        assertEquals("Should have ProcessedBy header", 
                    "MessageTransformProcessor", 
                    resultExchange.getIn().getHeader("ProcessedBy"));
        assertEquals("Should have EnrichedBy header", 
                    "MessageEnrichmentProcessor", 
                    resultExchange.getIn().getHeader("EnrichedBy"));
    }
}
Subtask 3.4: Run the Tests
Execute the unit and integration tests:

# Run all tests
mvn test

# Run specific test class
mvn test -Dtest=MessageTransformProcessorTest

# Run integration tests
mvn test -Dtest=CustomProcessorRouteTest
Subtask 3.5: Create a Manual Testing Script
Create a script for manual testing with various message types:

# Create a testing script
nano test-custom-processors.sh
Add the following script content:

#!/bin/bash

echo "=== Custom Processor Testing Script ==="
echo "This script will test various message scenarios"
echo

# Function to run a test case
run_test() {
    echo "Running test: $1"
    echo "Command: $2"
    eval $2
    echo "Test completed. Press Enter to continue..."
    read
    echo
}

# Build the project first
echo "Building the project..."
mvn clean compile -q

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo
else
    echo "Build failed. Please check for compilation errors."
    exit 1
fi

# Test 1: Run the main application
run_test "Main Application Test" \
         "timeout 30s mvn exec:java -Dexec.mainClass='com.alnafi.camel.lab4.CustomProcessorApplication' -q"

# Test 2: Run unit tests
run_test "Unit Tests" \
         "mvn test -Dtest=MessageTransformProcessorTest -q"

# Test 3: Run integration tests
run_test "Integration Tests" \
         "mvn test -Dtest=CustomProcessorRouteTest -q"

# Test 4: Run all tests
run_test "All Tests" \
         "mvn test -q"

echo "=== All tests completed ==="
echo "Check the output above for any failures or errors."
Make the script executable and run it:

# Make the script executable
chmod +x test-custom-processors.sh

# Run the testing script
./test-custom-processors.sh
Subtask 3.6: Advanced Testing with Different Message Formats
Create a comprehensive test application that demonstrates various message processing scenarios:

# Create advanced test application
nano src/main/java/com/alnafi/camel/lab4/AdvancedTestApplication.java
Add the following code:

package com.alnafi.camel.lab4;

import com.alnafi.camel.lab4.routes.CustomProcessorRouteBuilder;
import org.apache.camel.CamelContext;
import org.apache.camel.ProducerTemplate;
import org.apache.camel.impl.DefaultCamelContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

/**
 * Advanced test application for comprehensive custom processor testing
 */
public class AdvancedTestApplication {
    
    private static final Logger logger = LoggerFactory.getLogger(AdvancedTestApplication.class);
    
    public static void main(String[] args) throws Exception {
        logger.info("Starting Advanced Custom Processor Testing");
        
        CamelContext camelContext = new DefaultCamelContext();
        
        try {
            camelContext.addRoutes(new CustomProcessorRouteBuilder());
            camelContext.start();
            
            ProducerTemplate producer = camelContext.createProducerTemplate();
            
            // Run comprehensive tests
            runComprehensiveTests(producer);
            
        } finally {
            camelContext.stop();
        }
    }
    
    private static void runComprehensiveTests(ProducerTemplate producer) throws Exception {
        
        // Test Case 1: Various message lengths
        logger.info("\n=== Test Case 1: Message Length Variations ===");
        testMessageLengths(producer);
        
        // Test Case 2: Special characters and encoding
        logger.info("\n=== Test Case 2: Special Characters ===");
        testSpecialCharacters(producer);
        
        // Test Case 3: Different user types
        logger.info("\n=== Test Case 3: User Type Variations ===");
        testUserTypes(producer);
        
        // Test Case 4: Error scenarios
        logger.info("\n=== Test Case 4: Error Scenarios ===");
        testErrorScenarios(producer);
        
        // Test Case 5: Performance testing
        logger.info("\n=== Test Case 5: Performance Testing ===");
        testPerformance(producer);
    }
    
    private static void testMessage
