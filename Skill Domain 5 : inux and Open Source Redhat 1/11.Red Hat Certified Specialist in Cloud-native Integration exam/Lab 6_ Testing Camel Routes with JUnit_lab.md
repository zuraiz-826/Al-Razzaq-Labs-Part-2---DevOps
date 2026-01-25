Lab 6: Testing Camel Routes with JUnit
Objectives
By the end of this lab, students will be able to:

Set up unit tests for Apache Camel routes using JUnit framework
Create and configure mock endpoints to simulate external systems
Write comprehensive test cases that validate route behavior with different inputs
Use Camel test assertions to verify message processing and routing logic
Implement best practices for testing integration routes in enterprise applications
Prerequisites
Before starting this lab, students should have:

Basic understanding of Apache Camel concepts (routes, endpoints, processors)
Familiarity with Java programming language
Knowledge of Maven build tool and dependency management
Understanding of unit testing concepts
Experience with JUnit testing framework (version 4 or 5)
Completed previous Camel labs covering basic route creation
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines with all necessary tools pre-installed. Simply click Start Lab to begin - no need to build your own VM or install software.

Your cloud machine includes:

OpenJDK 11 or higher
Apache Maven 3.6+
Apache Camel 3.x
JUnit 5
IDE (Visual Studio Code or IntelliJ IDEA Community Edition)
Task 1: Set Up Unit Tests for Camel Routes Using JUnit
Subtask 1.1: Create Maven Project Structure
First, let's create a new Maven project with the proper structure for testing Camel routes.

Open your terminal and create a new project directory:
mkdir camel-testing-lab
cd camel-testing-lab
Create the Maven project structure:
mkdir -p src/main/java/com/example/camel
mkdir -p src/test/java/com/example/camel
mkdir -p src/main/resources
mkdir -p src/test/resources
Create the pom.xml file with necessary dependencies:
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>camel-testing-lab</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <camel.version>3.20.2</camel.version>
        <junit.version>5.9.2</junit.version>
    </properties>
    
    <dependencies>
        <!-- Camel Core -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-core</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel Test Support -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-test-junit5</artifactId>
            <version>${camel.version}</version>
            <scope>test</scope>
        </dependency>
        
        <!-- JUnit 5 -->
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>${junit.version}</version>
            <scope>test</scope>
        </dependency>
        
        <!-- Camel Components for Testing -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-direct</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-file</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-bean</artifactId>
            <version>${camel.version}</version>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.0.0-M9</version>
            </plugin>
        </plugins>
    </build>
</project>
Subtask 1.2: Create a Sample Camel Route
Create a simple Camel route that we'll test throughout this lab.

Create the route builder class:
touch src/main/java/com/example/camel/OrderProcessingRoute.java
Add the following content to OrderProcessingRoute.java:
package com.example.camel;

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.dataformat.JsonLibrary;

public class OrderProcessingRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Route 1: Basic order processing
        from("direct:processOrder")
            .routeId("order-processing-route")
            .log("Processing order: ${body}")
            .choice()
                .when(xpath("/order/priority[text()='HIGH']"))
                    .log("High priority order detected")
                    .to("direct:highPriorityQueue")
                .when(xpath("/order/priority[text()='MEDIUM']"))
                    .log("Medium priority order detected")
                    .to("direct:mediumPriorityQueue")
                .otherwise()
                    .log("Low priority order detected")
                    .to("direct:lowPriorityQueue")
            .end();
        
        // Route 2: Order validation
        from("direct:validateOrder")
            .routeId("order-validation-route")
            .log("Validating order: ${body}")
            .choice()
                .when(xpath("/order/customerId[text()='']"))
                    .throwException(new IllegalArgumentException("Customer ID is required"))
                .when(xpath("/order/amount[number(.) <= 0]"))
                    .throwException(new IllegalArgumentException("Order amount must be positive"))
                .otherwise()
                    .log("Order validation successful")
                    .setHeader("ValidationStatus", constant("VALID"))
                    .to("direct:processOrder")
            .end();
        
        // Route 3: Order transformation
        from("direct:transformOrder")
            .routeId("order-transformation-route")
            .log("Transforming order format")
            .setHeader("ProcessedTimestamp", simple("${date:now:yyyy-MM-dd HH:mm:ss}"))
            .transform().xpath("/order/customerId", String.class)
            .setHeader("CustomerId", body())
            .to("direct:orderTransformed");
    }
}
Create a simple processor for testing:
touch src/main/java/com/example/camel/OrderProcessor.java
Add the following content to OrderProcessor.java:
package com.example.camel;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;

public class OrderProcessor implements Processor {
    
    @Override
    public void process(Exchange exchange) throws Exception {
        String body = exchange.getIn().getBody(String.class);
        String processedBody = body.toUpperCase() + " - PROCESSED";
        exchange.getIn().setBody(processedBody);
        exchange.getIn().setHeader("ProcessedBy", "OrderProcessor");
    }
}
Subtask 1.3: Create Basic Test Class Structure
Now let's create our first test class using JUnit 5 and Camel Test Support.

Create the test class:
touch src/test/java/com/example/camel/OrderProcessingRouteTest.java
Add the basic test structure:
package com.example.camel;

import org.apache.camel.CamelContext;
import org.apache.camel.EndpointInject;
import org.apache.camel.ProducerTemplate;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.component.mock.MockEndpoint;
import org.apache.camel.test.junit5.CamelTestSupport;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.BeforeEach;

public class OrderProcessingRouteTest extends CamelTestSupport {
    
    @EndpointInject("mock:highPriorityQueue")
    private MockEndpoint highPriorityMock;
    
    @EndpointInject("mock:mediumPriorityQueue")
    private MockEndpoint mediumPriorityMock;
    
    @EndpointInject("mock:lowPriorityQueue")
    private MockEndpoint lowPriorityMock;
    
    @Override
    protected RouteBuilder createRouteBuilder() throws Exception {
        return new OrderProcessingRoute();
    }
    
    @Override
    protected CamelContext createCamelContext() throws Exception {
        CamelContext context = super.createCamelContext();
        return context;
    }
    
    @BeforeEach
    void setUp() {
        // Reset mock endpoints before each test
        highPriorityMock.reset();
        mediumPriorityMock.reset();
        lowPriorityMock.reset();
    }
    
    @Test
    @DisplayName("Test basic route creation and context startup")
    void testRouteCreation() throws Exception {
        // Verify that routes are created and started
        assertEquals(3, context.getRoutes().size());
        assertTrue(context.getRouteController().getRouteStatus("order-processing-route").isStarted());
    }
}
Task 2: Mock Endpoints Using mock: and Simulate Different Inputs
Subtask 2.1: Configure Mock Endpoints
Mock endpoints allow us to simulate external systems and capture messages for testing without actually connecting to real endpoints.

Update the test class to include mock endpoint configuration:
package com.example.camel;

import org.apache.camel.CamelContext;
import org.apache.camel.EndpointInject;
import org.apache.camel.ProducerTemplate;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.component.mock.MockEndpoint;
import org.apache.camel.test.junit5.CamelTestSupport;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.BeforeEach;

public class OrderProcessingRouteTest extends CamelTestSupport {
    
    @EndpointInject("mock:highPriorityQueue")
    private MockEndpoint highPriorityMock;
    
    @EndpointInject("mock:mediumPriorityQueue")
    private MockEndpoint mediumPriorityMock;
    
    @EndpointInject("mock:lowPriorityQueue")
    private MockEndpoint lowPriorityMock;
    
    @EndpointInject("mock:orderTransformed")
    private MockEndpoint orderTransformedMock;
    
    @Override
    protected RouteBuilder createRouteBuilder() throws Exception {
        return new OrderProcessingRoute();
    }
    
    @Override
    protected String isMockEndpoints() {
        // This tells Camel to replace certain endpoints with mock endpoints
        return "direct:highPriorityQueue|direct:mediumPriorityQueue|direct:lowPriorityQueue|direct:orderTransformed";
    }
    
    @BeforeEach
    void setUp() {
        // Reset mock endpoints before each test
        highPriorityMock.reset();
        mediumPriorityMock.reset();
        lowPriorityMock.reset();
        orderTransformedMock.reset();
    }
    
    @Test
    @DisplayName("Test basic route creation and context startup")
    void testRouteCreation() throws Exception {
        // Verify that routes are created and started
        assertEquals(3, context.getRoutes().size());
        assertTrue(context.getRouteController().getRouteStatus("order-processing-route").isStarted());
    }
}
Subtask 2.2: Create Test Data and Input Simulation
Let's create various test scenarios with different input data to thoroughly test our routes.

Add test data creation methods to the test class:
// Add these methods to the OrderProcessingRouteTest class

private String createHighPriorityOrder() {
    return """
        <order>
            <orderId>12345</orderId>
            <customerId>CUST001</customerId>
            <priority>HIGH</priority>
            <amount>1500.00</amount>
            <product>Laptop</product>
        </order>
        """;
}

private String createMediumPriorityOrder() {
    return """
        <order>
            <orderId>12346</orderId>
            <customerId>CUST002</customerId>
            <priority>MEDIUM</priority>
            <amount>750.00</amount>
            <product>Tablet</product>
        </order>
        """;
}

private String createLowPriorityOrder() {
    return """
        <order>
            <orderId>12347</orderId>
            <customerId>CUST003</customerId>
            <priority>LOW</priority>
            <amount>250.00</amount>
            <product>Mouse</product>
        </order>
        """;
}

private String createInvalidOrderNoCustomer() {
    return """
        <order>
            <orderId>12348</orderId>
            <customerId></customerId>
            <priority>HIGH</priority>
            <amount>1000.00</amount>
            <product>Keyboard</product>
        </order>
        """;
}

private String createInvalidOrderNegativeAmount() {
    return """
        <order>
            <orderId>12349</orderId>
            <customerId>CUST004</customerId>
            <priority>MEDIUM</priority>
            <amount>-100.00</amount>
            <product>Monitor</product>
        </order>
        """;
}
Subtask 2.3: Implement Mock Endpoint Testing
Now let's create comprehensive tests that use mock endpoints to verify route behavior.

Add the following test methods to test different priority routing:
@Test
@DisplayName("Test high priority order routing")
void testHighPriorityOrderRouting() throws Exception {
    // Arrange
    String highPriorityOrder = createHighPriorityOrder();
    
    // Set expectations on mock endpoints
    highPriorityMock.expectedMessageCount(1);
    highPriorityMock.expectedBodiesReceived(highPriorityOrder);
    mediumPriorityMock.expectedMessageCount(0);
    lowPriorityMock.expectedMessageCount(0);
    
    // Act
    template.sendBody("direct:processOrder", highPriorityOrder);
    
    // Assert
    assertMockEndpointsSatisfied();
}

@Test
@DisplayName("Test medium priority order routing")
void testMediumPriorityOrderRouting() throws Exception {
    // Arrange
    String mediumPriorityOrder = createMediumPriorityOrder();
    
    // Set expectations
    highPriorityMock.expectedMessageCount(0);
    mediumPriorityMock.expectedMessageCount(1);
    mediumPriorityMock.expectedBodiesReceived(mediumPriorityOrder);
    lowPriorityMock.expectedMessageCount(0);
    
    // Act
    template.sendBody("direct:processOrder", mediumPriorityOrder);
    
    // Assert
    assertMockEndpointsSatisfied();
}

@Test
@DisplayName("Test low priority order routing (default case)")
void testLowPriorityOrderRouting() throws Exception {
    // Arrange
    String lowPriorityOrder = createLowPriorityOrder();
    
    // Set expectations
    highPriorityMock.expectedMessageCount(0);
    mediumPriorityMock.expectedMessageCount(0);
    lowPriorityMock.expectedMessageCount(1);
    lowPriorityMock.expectedBodiesReceived(lowPriorityOrder);
    
    // Act
    template.sendBody("direct:processOrder", lowPriorityOrder);
    
    // Assert
    assertMockEndpointsSatisfied();
}
Add tests for the validation route:
@Test
@DisplayName("Test valid order processing through validation")
void testValidOrderValidation() throws Exception {
    // Arrange
    String validOrder = createHighPriorityOrder();
    
    // Set expectations - valid order should go through to processing
    highPriorityMock.expectedMessageCount(1);
    highPriorityMock.expectedBodiesReceived(validOrder);
    highPriorityMock.expectedHeaderReceived("ValidationStatus", "VALID");
    
    // Act
    template.sendBody("direct:validateOrder", validOrder);
    
    // Assert
    assertMockEndpointsSatisfied();
}

@Test
@DisplayName("Test invalid order with empty customer ID")
void testInvalidOrderEmptyCustomerId() throws Exception {
    // Arrange
    String invalidOrder = createInvalidOrderNoCustomer();
    
    // Set expectations - no messages should reach any queue
    highPriorityMock.expectedMessageCount(0);
    mediumPriorityMock.expectedMessageCount(0);
    lowPriorityMock.expectedMessageCount(0);
    
    // Act & Assert
    assertThrows(Exception.class, () -> {
        template.sendBody("direct:validateOrder", invalidOrder);
    });
    
    assertMockEndpointsSatisfied();
}

@Test
@DisplayName("Test invalid order with negative amount")
void testInvalidOrderNegativeAmount() throws Exception {
    // Arrange
    String invalidOrder = createInvalidOrderNegativeAmount();
    
    // Set expectations
    highPriorityMock.expectedMessageCount(0);
    mediumPriorityMock.expectedMessageCount(0);
    lowPriorityMock.expectedMessageCount(0);
    
    // Act & Assert
    assertThrows(Exception.class, () -> {
        template.sendBody("direct:validateOrder", invalidOrder);
    });
    
    assertMockEndpointsSatisfied();
}
Task 3: Assert the Results to Ensure Route Correctness
Subtask 3.1: Implement Advanced Assertions
Let's create more sophisticated tests that verify not just message routing, but also message content, headers, and transformations.

Add tests for the transformation route:
@Test
@DisplayName("Test order transformation route")
void testOrderTransformation() throws Exception {
    // Arrange
    String originalOrder = createHighPriorityOrder();
    
    // Set expectations
    orderTransformedMock.expectedMessageCount(1);
    orderTransformedMock.expectedBodiesReceived("CUST001"); // Should extract customer ID
    orderTransformedMock.expectedHeaderReceived("CustomerId", "CUST001");
    
    // Verify that ProcessedTimestamp header is set
    orderTransformedMock.allMessages().header("ProcessedTimestamp").isNotNull();
    
    // Act
    template.sendBody("direct:transformOrder", originalOrder);
    
    // Assert
    assertMockEndpointsSatisfied();
}

@Test
@DisplayName("Test multiple orders processing in sequence")
void testMultipleOrdersProcessing() throws Exception {
    // Arrange
    String highOrder = createHighPriorityOrder();
    String mediumOrder = createMediumPriorityOrder();
    String lowOrder = createLowPriorityOrder();
    
    // Set expectations
    highPriorityMock.expectedMessageCount(1);
    mediumPriorityMock.expectedMessageCount(1);
    lowPriorityMock.expectedMessageCount(1);
    
    // Act
    template.sendBody("direct:processOrder", highOrder);
    template.sendBody("direct:processOrder", mediumOrder);
    template.sendBody("direct:processOrder", lowOrder);
    
    // Assert
    assertMockEndpointsSatisfied();
}
Subtask 3.2: Create Custom Assertions and Predicates
Let's implement custom assertions to verify specific business logic.

Add advanced assertion tests:
@Test
@DisplayName("Test message content and headers with custom assertions")
void testMessageContentAndHeaders() throws Exception {
    // Arrange
    String order = createHighPriorityOrder();
    
    // Set up custom expectations
    highPriorityMock.expectedMessageCount(1);
    
    // Custom predicate to verify XML content
    highPriorityMock.allMessages().body().contains("CUST001");
    highPriorityMock.allMessages().body().contains("HIGH");
    highPriorityMock.allMessages().body().contains("1500.00");
    
    // Act
    template.sendBody("direct:processOrder", order);
    
    // Assert
    assertMockEndpointsSatisfied();
    
    // Additional custom assertions
    String receivedBody = highPriorityMock.getReceivedExchanges().get(0).getIn().getBody(String.class);
    assertTrue(receivedBody.contains("<priority>HIGH</priority>"), 
               "Message should contain HIGH priority");
    assertTrue(receivedBody.contains("<customerId>CUST001</customerId>"), 
               "Message should contain correct customer ID");
}

@Test
@DisplayName("Test route performance and timing")
void testRoutePerformance() throws Exception {
    // Arrange
    String order = createMediumPriorityOrder();
    long startTime = System.currentTimeMillis();
    
    // Set expectations
    mediumPriorityMock.expectedMessageCount(1);
    
    // Act
    template.sendBody("direct:processOrder", order);
    
    // Assert
    assertMockEndpointsSatisfied(5000); // 5 second timeout
    
    long endTime = System.currentTimeMillis();
    long processingTime = endTime - startTime;
    
    assertTrue(processingTime < 1000, 
               "Route processing should complete within 1 second, took: " + processingTime + "ms");
}
Subtask 3.3: Create Integration Test with Error Handling
Let's create a comprehensive integration test that covers error scenarios and recovery.

Create a new test class for integration testing:
touch src/test/java/com/example/camel/OrderProcessingIntegrationTest.java
Add comprehensive integration tests:
package com.example.camel;

import org.apache.camel.CamelContext;
import org.apache.camel.EndpointInject;
import org.apache.camel.Exchange;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.component.mock.MockEndpoint;
import org.apache.camel.test.junit5.CamelTestSupport;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.BeforeEach;

import java.util.concurrent.TimeUnit;

public class OrderProcessingIntegrationTest extends CamelTestSupport {
    
    @EndpointInject("mock:result")
    private MockEndpoint resultMock;
    
    @EndpointInject("mock:error")
    private MockEndpoint errorMock;
    
    @Override
    protected RouteBuilder createRouteBuilder() throws Exception {
        return new RouteBuilder() {
            @Override
            public void configure() throws Exception {
                // Error handling route
                onException(IllegalArgumentException.class)
                    .handled(true)
                    .log("Error processing order: ${exception.message}")
                    .setBody(simple("Error: ${exception.message}"))
                    .to("mock:error");
                
                // Main integration route
                from("direct:orderIntegration")
                    .routeId("order-integration-test")
                    .log("Starting order integration test")
                    .to("direct:validateOrder")
                    .log("Order validated successfully")
                    .to("direct:transformOrder")
                    .log("Order transformed successfully")
                    .to("mock:result");
                
                // Include the original routes
                from("direct:processOrder")
                    .routeId("order-processing-route")
                    .log("Processing order: ${body}")
                    .choice()
                        .when(xpath("/order/priority[text()='HIGH']"))
                            .log("High priority order detected")
                            .to("mock:highPriorityQueue")
                        .when(xpath("/order/priority[text()='MEDIUM']"))
                            .log("Medium priority order detected")
                            .to("mock:mediumPriorityQueue")
                        .otherwise()
                            .log("Low priority order detected")
                            .to("mock:lowPriorityQueue")
                    .end();
                
                from("direct:validateOrder")
                    .routeId("order-validation-route")
                    .log("Validating order: ${body}")
                    .choice()
                        .when(xpath("/order/customerId[text()='']"))
                            .throwException(new IllegalArgumentException("Customer ID is required"))
                        .when(xpath("/order/amount[number(.) <= 0]"))
                            .throwException(new IllegalArgumentException("Order amount must be positive"))
                        .otherwise()
                            .log("Order validation successful")
                            .setHeader("ValidationStatus", constant("VALID"))
                    .end();
                
                from("direct:transformOrder")
                    .routeId("order-transformation-route")
                    .log("Transforming order format")
                    .setHeader("ProcessedTimestamp", simple("${date:now:yyyy-MM-dd HH:mm:ss}"))
                    .transform().xpath("/order/customerId", String.class)
                    .setHeader("CustomerId", body());
            }
        };
    }
    
    @BeforeEach
    void setUp() {
        resultMock.reset();
        errorMock.reset();
    }
    
    @Test
    @DisplayName("Test complete order processing integration flow")
    void testCompleteOrderProcessingFlow() throws Exception {
        // Arrange
        String validOrder = """
            <order>
                <orderId>INT001</orderId>
                <customerId>CUST_INTEGRATION</customerId>
                <priority>HIGH</priority>
                <amount>2000.00</amount>
                <product>Integration Test Product</product>
            </order>
            """;
        
        // Set expectations
        resultMock.expectedMessageCount(1);
        resultMock.expectedBodiesReceived("CUST_INTEGRATION");
        resultMock.expectedHeaderReceived("CustomerId", "CUST_INTEGRATION");
        resultMock.allMessages().header("ProcessedTimestamp").isNotNull();
        errorMock.expectedMessageCount(0);
        
        // Act
        template.sendBody("direct:orderIntegration", validOrder);
        
        // Assert
        assertMockEndpointsSatisfied();
    }
    
    @Test
    @DisplayName("Test error handling in integration flow")
    void testErrorHandlingIntegrationFlow() throws Exception {
        // Arrange
        String invalidOrder = """
            <order>
                <orderId>INT002</orderId>
                <customerId></customerId>
                <priority>HIGH</priority>
                <amount>1000.00</amount>
                <product>Error Test Product</product>
            </order>
            """;
        
        // Set expectations
        resultMock.expectedMessageCount(0);
        errorMock.expectedMessageCount(1);
        errorMock.expectedBodiesReceived("Error: Customer ID is required");
        
        // Act
        template.sendBody("direct:orderIntegration", invalidOrder);
        
        // Assert
        assertMockEndpointsSatisfied();
    }
    
    @Test
    @DisplayName("Test concurrent order processing")
    void testConcurrentOrderProcessing() throws Exception {
        // Arrange
        int numberOfOrders = 5;
        resultMock.expectedMessageCount(numberOfOrders);
        errorMock.expectedMessageCount(0);
        
        // Act - Send multiple orders concurrently
        for (int i = 1; i <= numberOfOrders; i++) {
            String order = String.format("""
                <order>
                    <orderId>CONCURRENT_%d</orderId>
                    <customerId>CUST_%d</customerId>
                    <priority>MEDIUM</priority>
                    <amount>%d00.00</amount>
                    <product>Concurrent Test Product %d</product>
                </order>
                """, i, i, i, i);
            
            template.asyncSendBody("direct:orderIntegration", order);
        }
        
        // Assert
        assertMockEndpointsSatisfied(10, TimeUnit.SECONDS);
        
        // Verify all orders were processed
        assertEquals(numberOfOrders, resultMock.getReceivedCounter());
    }
}
Subtask 3.4: Run and Verify Tests
Now let's run our comprehensive test suite and verify everything works correctly.

Compile and run the tests:
mvn clean compile test
Run specific test classes:
# Run only the basic route tests
mvn test -Dtest=OrderProcessingRouteTest

# Run only the integration tests
mvn test -Dtest=OrderProcessingIntegrationTest

# Run all tests with verbose output
mvn test -X
Generate test reports:
mvn surefire-report:report
Create a test execution script for easy running:
touch run-tests.sh
chmod +x run-tests.sh
Add the following content to run-tests.sh:

#!/bin/bash

echo "=== Running Camel Route Tests ==="
echo "Cleaning and compiling project..."
mvn clean compile

echo ""
echo "Running unit tests..."
mvn test -Dtest=OrderProcessingRouteTest

echo ""
echo "Running integration tests..."
mvn test -Dtest=OrderProcessingIntegrationTest

echo ""
echo "Generating test report..."
mvn surefire-report:report

echo ""
echo "Test execution completed!"
echo "Check target/surefire-reports/ for detailed test results"
Troubleshooting Common Issues
Issue 1: Mock Endpoints Not Working
Problem: Mock endpoints are not receiving expected messages.

Solution:

Verify that isMockEndpoints() method returns the correct endpoint patterns
Check that mock endpoint names match exactly with the route definitions
Ensure assertMockEndpointsSatisfied() is called after sending messages
Issue 2: XPath Expressions Failing
Problem: XPath expressions in routes are not evaluating correctly.

Solution:

Verify XML structure matches XPath expressions exactly
Check for namespace issues in XML
Use simple XPath expressions for testing: /order/priority[text()='HIGH']
Issue 3: Test Timeouts
Problem: Tests are timing out or taking too long.

Solution:

Increase timeout values in assertMockEndpointsSatisfied(timeout)
Check for infinite loops in routes
Verify that all expected messages are actually being sent
Issue 4: Maven Dependencies
Problem: Missing dependencies or
