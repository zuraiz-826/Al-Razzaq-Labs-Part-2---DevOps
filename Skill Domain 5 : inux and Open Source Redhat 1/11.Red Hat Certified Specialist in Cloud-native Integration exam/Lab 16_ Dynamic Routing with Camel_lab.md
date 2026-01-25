Lab 16: Dynamic Routing with Camel
Objectives
By the end of this lab, you will be able to:

• Understand the concept of dynamic routing in Apache Camel • Implement dynamic routing using choice() and predicates • Configure external data sources to drive routing decisions • Create conditional logic for message routing based on content • Test dynamic routes with various data inputs • Troubleshoot common dynamic routing issues

Prerequisites
Before starting this lab, you should have:

• Basic understanding of Apache Camel concepts and routing • Familiarity with Java programming language • Knowledge of Maven build tool • Understanding of REST APIs and HTTP protocols • Basic knowledge of JSON and XML data formats • Experience with Linux command line operations

Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines with all necessary tools pre-installed. Simply click Start Lab to begin - no need to build your own VM or install software.

Your cloud machine includes: • Java 11 or higher • Apache Maven 3.6+ • Apache Camel 3.x • Text editors (nano, vim) • curl for testing HTTP endpoints

Task 1: Set up Dynamic Routing with choice() and Predicates
Subtask 1.1: Create the Project Structure
First, let's create a new Maven project for our dynamic routing implementation.

# Create project directory
mkdir camel-dynamic-routing
cd camel-dynamic-routing

# Create Maven project structure
mkdir -p src/main/java/com/example/routing
mkdir -p src/main/resources
mkdir -p src/test/java
Subtask 1.2: Configure Maven Dependencies
Create the pom.xml file with necessary Camel dependencies:

<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>camel-dynamic-routing</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <camel.version>3.20.0</camel.version>
        <slf4j.version>1.7.36</slf4j.version>
    </properties>
    
    <dependencies>
        <!-- Camel Core -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-core</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel Main -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-main</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel HTTP -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-http</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel Jetty -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-jetty</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel Jackson for JSON -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-jackson</artifactId>
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
                <version>3.8.1</version>
                <configuration>
                    <source>11</source>
                    <target>11</target>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
Subtask 1.3: Create Basic Dynamic Routing Class
Create the main routing class with choice() and predicates:

// File: src/main/java/com/example/routing/DynamicRoutingExample.java
package com.example.routing;

import org.apache.camel.CamelContext;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.impl.DefaultCamelContext;
import org.apache.camel.main.Main;

public class DynamicRoutingExample extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Route 1: Basic dynamic routing based on message content
        from("jetty:http://localhost:8080/orders")
            .log("Received order: ${body}")
            .choice()
                .when(jsonpath("$.priority[?(@ == 'HIGH')]"))
                    .log("Processing HIGH priority order")
                    .to("direct:highPriorityProcessor")
                .when(jsonpath("$.priority[?(@ == 'MEDIUM')]"))
                    .log("Processing MEDIUM priority order")
                    .to("direct:mediumPriorityProcessor")
                .when(jsonpath("$.priority[?(@ == 'LOW')]"))
                    .log("Processing LOW priority order")
                    .to("direct:lowPriorityProcessor")
                .otherwise()
                    .log("Processing DEFAULT priority order")
                    .to("direct:defaultProcessor")
            .end()
            .setBody(constant("Order processed successfully"));
        
        // Route 2: Dynamic routing based on customer type
        from("jetty:http://localhost:8080/customers")
            .log("Received customer request: ${body}")
            .choice()
                .when(jsonpath("$.customerType[?(@ == 'PREMIUM')]"))
                    .log("Routing to premium customer service")
                    .to("direct:premiumService")
                .when(jsonpath("$.customerType[?(@ == 'STANDARD')]"))
                    .log("Routing to standard customer service")
                    .to("direct:standardService")
                .when(jsonpath("$.customerType[?(@ == 'BASIC')]"))
                    .log("Routing to basic customer service")
                    .to("direct:basicService")
                .otherwise()
                    .log("Routing to default customer service")
                    .to("direct:defaultService")
            .end()
            .setBody(constant("Customer request processed"));
        
        // Processor routes for orders
        from("direct:highPriorityProcessor")
            .log("HIGH Priority: Expedited processing")
            .delay(1000) // Simulate processing time
            .setHeader("ProcessingTime", constant("1 second"))
            .setHeader("Priority", constant("HIGH"));
        
        from("direct:mediumPriorityProcessor")
            .log("MEDIUM Priority: Standard processing")
            .delay(3000)
            .setHeader("ProcessingTime", constant("3 seconds"))
            .setHeader("Priority", constant("MEDIUM"));
        
        from("direct:lowPriorityProcessor")
            .log("LOW Priority: Batch processing")
            .delay(5000)
            .setHeader("ProcessingTime", constant("5 seconds"))
            .setHeader("Priority", constant("LOW"));
        
        from("direct:defaultProcessor")
            .log("DEFAULT Priority: Standard processing")
            .delay(3000)
            .setHeader("ProcessingTime", constant("3 seconds"))
            .setHeader("Priority", constant("DEFAULT"));
        
        // Service routes for customers
        from("direct:premiumService")
            .log("Premium Service: VIP treatment")
            .setHeader("ServiceLevel", constant("PREMIUM"))
            .setHeader("ResponseTime", constant("Immediate"));
        
        from("direct:standardService")
            .log("Standard Service: Regular treatment")
            .setHeader("ServiceLevel", constant("STANDARD"))
            .setHeader("ResponseTime", constant("Within 24 hours"));
        
        from("direct:basicService")
            .log("Basic Service: Standard treatment")
            .setHeader("ServiceLevel", constant("BASIC"))
            .setHeader("ResponseTime", constant("Within 48 hours"));
        
        from("direct:defaultService")
            .log("Default Service: Standard treatment")
            .setHeader("ServiceLevel", constant("DEFAULT"))
            .setHeader("ResponseTime", constant("Within 24 hours"));
    }
    
    public static void main(String[] args) throws Exception {
        Main main = new Main();
        main.addRouteBuilder(new DynamicRoutingExample());
        main.run(args);
    }
}
Subtask 1.4: Build and Test Basic Dynamic Routing
Build the project and start the application:

# Build the project
mvn clean compile

# Run the application
mvn exec:java -Dexec.mainClass="com.example.routing.DynamicRoutingExample"
Test the basic dynamic routing with different priority orders:

# Test HIGH priority order
curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{"orderId": "ORD001", "priority": "HIGH", "amount": 1000}'

# Test MEDIUM priority order
curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{"orderId": "ORD002", "priority": "MEDIUM", "amount": 500}'

# Test LOW priority order
curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{"orderId": "ORD003", "priority": "LOW", "amount": 100}'

# Test customer routing
curl -X POST http://localhost:8080/customers \
  -H "Content-Type: application/json" \
  -d '{"customerId": "CUST001", "customerType": "PREMIUM", "name": "John Doe"}'
Task 2: Use External Data to Drive Routing Decisions
Subtask 2.1: Create External Configuration Service
Create a configuration service that provides routing rules:

// File: src/main/java/com/example/routing/ConfigurationService.java
package com.example.routing;

import java.util.HashMap;
import java.util.Map;

public class ConfigurationService {
    
    private static final Map<String, String> routingRules = new HashMap<>();
    private static final Map<String, Integer> priorityWeights = new HashMap<>();
    
    static {
        // Initialize routing rules
        routingRules.put("ELECTRONICS", "direct:electronicsProcessor");
        routingRules.put("CLOTHING", "direct:clothingProcessor");
        routingRules.put("BOOKS", "direct:booksProcessor");
        routingRules.put("FOOD", "direct:foodProcessor");
        
        // Initialize priority weights
        priorityWeights.put("URGENT", 1);
        priorityWeights.put("HIGH", 2);
        priorityWeights.put("MEDIUM", 3);
        priorityWeights.put("LOW", 4);
    }
    
    public static String getRouteForCategory(String category) {
        return routingRules.getOrDefault(category.toUpperCase(), "direct:defaultCategoryProcessor");
    }
    
    public static int getPriorityWeight(String priority) {
        return priorityWeights.getOrDefault(priority.toUpperCase(), 5);
    }
    
    public static boolean isHighValueOrder(double amount) {
        return amount > 1000.0;
    }
    
    public static String getProcessingQueue(String region) {
        switch (region.toUpperCase()) {
            case "NORTH":
                return "direct:northRegionQueue";
            case "SOUTH":
                return "direct:southRegionQueue";
            case "EAST":
                return "direct:eastRegionQueue";
            case "WEST":
                return "direct:westRegionQueue";
            default:
                return "direct:defaultRegionQueue";
        }
    }
}
Subtask 2.2: Create Advanced Dynamic Routing with External Data
Create an advanced routing class that uses external configuration:

// File: src/main/java/com/example/routing/AdvancedDynamicRouting.java
package com.example.routing;

import org.apache.camel.Exchange;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.main.Main;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

public class AdvancedDynamicRouting extends RouteBuilder {
    
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    @Override
    public void configure() throws Exception {
        
        // Route 1: Category-based dynamic routing using external configuration
        from("jetty:http://localhost:8080/products")
            .log("Received product order: ${body}")
            .process(exchange -> {
                String body = exchange.getIn().getBody(String.class);
                JsonNode json = objectMapper.readTree(body);
                String category = json.get("category").asText();
                String targetRoute = ConfigurationService.getRouteForCategory(category);
                exchange.getIn().setHeader("targetRoute", targetRoute);
                exchange.getIn().setHeader("category", category);
            })
            .recipientList(header("targetRoute"))
            .setBody(constant("Product order routed successfully"));
        
        // Route 2: Multi-criteria dynamic routing
        from("jetty:http://localhost:8080/complex-orders")
            .log("Received complex order: ${body}")
            .process(exchange -> {
                String body = exchange.getIn().getBody(String.class);
                JsonNode json = objectMapper.readTree(body);
                
                String priority = json.get("priority").asText();
                double amount = json.get("amount").asDouble();
                String region = json.get("region").asText();
                String category = json.get("category").asText();
                
                // Set routing headers based on external configuration
                exchange.getIn().setHeader("priorityWeight", 
                    ConfigurationService.getPriorityWeight(priority));
                exchange.getIn().setHeader("isHighValue", 
                    ConfigurationService.isHighValueOrder(amount));
                exchange.getIn().setHeader("regionQueue", 
                    ConfigurationService.getProcessingQueue(region));
                exchange.getIn().setHeader("categoryRoute", 
                    ConfigurationService.getRouteForCategory(category));
            })
            .choice()
                .when(header("isHighValue").isEqualTo(true))
                    .log("High value order - routing to premium processing")
                    .to("direct:premiumProcessing")
                .when(header("priorityWeight").isLessThan(3))
                    .log("High priority order - routing to express processing")
                    .to("direct:expressProcessing")
                .otherwise()
                    .log("Standard order - routing based on region and category")
                    .recipientList(simple("${header.regionQueue},${header.categoryRoute}"))
            .end()
            .setBody(constant("Complex order processed"));
        
        // Route 3: Time-based dynamic routing
        from("jetty:http://localhost:8080/time-sensitive")
            .log("Received time-sensitive request: ${body}")
            .choice()
                .when(simple("${date:now:HH} >= 9 && ${date:now:HH} < 17"))
                    .log("Business hours - routing to regular processing")
                    .to("direct:businessHoursProcessor")
                .when(simple("${date:now:HH} >= 17 && ${date:now:HH} < 21"))
                    .log("Evening hours - routing to evening shift")
                    .to("direct:eveningShiftProcessor")
                .otherwise()
                    .log("Off hours - routing to automated processing")
                    .to("direct:automatedProcessor")
            .end()
            .setBody(constant("Time-sensitive request processed"));
        
        // Category processors
        from("direct:electronicsProcessor")
            .log("Processing electronics order")
            .setHeader("ProcessingDepartment", constant("Electronics"))
            .setHeader("EstimatedDelivery", constant("2-3 business days"));
        
        from("direct:clothingProcessor")
            .log("Processing clothing order")
            .setHeader("ProcessingDepartment", constant("Clothing"))
            .setHeader("EstimatedDelivery", constant("3-5 business days"));
        
        from("direct:booksProcessor")
            .log("Processing books order")
            .setHeader("ProcessingDepartment", constant("Books"))
            .setHeader("EstimatedDelivery", constant("1-2 business days"));
        
        from("direct:foodProcessor")
            .log("Processing food order")
            .setHeader("ProcessingDepartment", constant("Food"))
            .setHeader("EstimatedDelivery", constant("Same day"));
        
        from("direct:defaultCategoryProcessor")
            .log("Processing general order")
            .setHeader("ProcessingDepartment", constant("General"))
            .setHeader("EstimatedDelivery", constant("3-7 business days"));
        
        // Priority processors
        from("direct:premiumProcessing")
            .log("Premium processing for high-value order")
            .setHeader("ProcessingType", constant("Premium"))
            .setHeader("AssignedAgent", constant("Senior Agent"));
        
        from("direct:expressProcessing")
            .log("Express processing for high-priority order")
            .setHeader("ProcessingType", constant("Express"))
            .setHeader("AssignedAgent", constant("Express Team"));
        
        // Regional queues
        from("direct:northRegionQueue")
            .log("Processing in North region")
            .setHeader("ProcessingRegion", constant("North"));
        
        from("direct:southRegionQueue")
            .log("Processing in South region")
            .setHeader("ProcessingRegion", constant("South"));
        
        from("direct:eastRegionQueue")
            .log("Processing in East region")
            .setHeader("ProcessingRegion", constant("East"));
        
        from("direct:westRegionQueue")
            .log("Processing in West region")
            .setHeader("ProcessingRegion", constant("West"));
        
        from("direct:defaultRegionQueue")
            .log("Processing in default region")
            .setHeader("ProcessingRegion", constant("Central"));
        
        // Time-based processors
        from("direct:businessHoursProcessor")
            .log("Business hours processing")
            .setHeader("ProcessingShift", constant("Day Shift"));
        
        from("direct:eveningShiftProcessor")
            .log("Evening shift processing")
            .setHeader("ProcessingShift", constant("Evening Shift"));
        
        from("direct:automatedProcessor")
            .log("Automated processing")
            .setHeader("ProcessingShift", constant("Automated"));
    }
    
    public static void main(String[] args) throws Exception {
        Main main = new Main();
        main.addRouteBuilder(new AdvancedDynamicRouting());
        main.run(args);
    }
}
Subtask 2.3: Create External Configuration File
Create a properties file for external configuration:

# File: src/main/resources/routing-config.properties

# Category routing configuration
routing.electronics.endpoint=direct:electronicsProcessor
routing.clothing.endpoint=direct:clothingProcessor
routing.books.endpoint=direct:booksProcessor
routing.food.endpoint=direct:foodProcessor
routing.default.endpoint=direct:defaultCategoryProcessor

# Priority weights
priority.urgent.weight=1
priority.high.weight=2
priority.medium.weight=3
priority.low.weight=4

# High value threshold
order.highvalue.threshold=1000.0

# Regional processing queues
region.north.queue=direct:northRegionQueue
region.south.queue=direct:southRegionQueue
region.east.queue=direct:eastRegionQueue
region.west.queue=direct:westRegionQueue
region.default.queue=direct:defaultRegionQueue

# Business hours configuration
business.hours.start=9
business.hours.end=17
evening.hours.end=21
Task 3: Test the Dynamic Routes Using Different Data Inputs
Subtask 3.1: Create Test Data Sets
Create various test data files to test different routing scenarios:

# Create test data directory
mkdir -p test-data
Create test JSON files:

# File: test-data/high-priority-order.json
{
    "orderId": "ORD001",
    "priority": "HIGH",
    "amount": 1500.0,
    "category": "ELECTRONICS",
    "region": "NORTH",
    "customerType": "PREMIUM"
}
# File: test-data/medium-priority-order.json
{
    "orderId": "ORD002",
    "priority": "MEDIUM",
    "amount": 500.0,
    "category": "CLOTHING",
    "region": "SOUTH",
    "customerType": "STANDARD"
}
# File: test-data/low-priority-order.json
{
    "orderId": "ORD003",
    "priority": "LOW",
    "amount": 100.0,
    "category": "BOOKS",
    "region": "EAST",
    "customerType": "BASIC"
}
# File: test-data/high-value-order.json
{
    "orderId": "ORD004",
    "priority": "MEDIUM",
    "amount": 2500.0,
    "category": "ELECTRONICS",
    "region": "WEST",
    "customerType": "PREMIUM"
}
Subtask 3.2: Create Automated Test Script
Create a comprehensive test script:

# File: test-dynamic-routing.sh
#!/bin/bash

echo "=== Testing Dynamic Routing with Camel ==="
echo

# Wait for application to start
sleep 5

echo "1. Testing Basic Priority Routing..."
echo "   - High Priority Order:"
curl -s -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d @test-data/high-priority-order.json
echo
echo

echo "   - Medium Priority Order:"
curl -s -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d @test-data/medium-priority-order.json
echo
echo

echo "   - Low Priority Order:"
curl -s -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d @test-data/low-priority-order.json
echo
echo

echo "2. Testing Category-based Routing..."
echo "   - Electronics Product:"
curl -s -X POST http://localhost:8080/products \
  -H "Content-Type: application/json" \
  -d '{"productId": "PROD001", "category": "ELECTRONICS", "name": "Laptop"}'
echo
echo

echo "   - Clothing Product:"
curl -s -X POST http://localhost:8080/products \
  -H "Content-Type: application/json" \
  -d '{"productId": "PROD002", "category": "CLOTHING", "name": "T-Shirt"}'
echo
echo

echo "   - Books Product:"
curl -s -X POST http://localhost:8080/products \
  -H "Content-Type: application/json" \
  -d '{"productId": "PROD003", "category": "BOOKS", "name": "Programming Guide"}'
echo
echo

echo "3. Testing Complex Multi-criteria Routing..."
echo "   - High Value Order:"
curl -s -X POST http://localhost:8080/complex-orders \
  -H "Content-Type: application/json" \
  -d @test-data/high-value-order.json
echo
echo

echo "   - Standard Order:"
curl -s -X POST http://localhost:8080/complex-orders \
  -H "Content-Type: application/json" \
  -d @test-data/medium-priority-order.json
echo
echo

echo "4. Testing Customer Type Routing..."
echo "   - Premium Customer:"
curl -s -X POST http://localhost:8080/customers \
  -H "Content-Type: application/json" \
  -d '{"customerId": "CUST001", "customerType": "PREMIUM", "name": "John Doe"}'
echo
echo

echo "   - Standard Customer:"
curl -s -X POST http://localhost:8080/customers \
  -H "Content-Type: application/json" \
  -d '{"customerId": "CUST002", "customerType": "STANDARD", "name": "Jane Smith"}'
echo
echo

echo "5. Testing Time-sensitive Routing..."
curl -s -X POST http://localhost:8080/time-sensitive \
  -H "Content-Type: application/json" \
  -d '{"requestId": "REQ001", "type": "URGENT", "timestamp": "'$(date -Iseconds)'"}'
echo
echo

echo "=== All tests completed ==="
Make the script executable:

chmod +x test-dynamic-routing.sh
Subtask 3.3: Run Comprehensive Tests
Start the advanced dynamic routing application:

# Terminal 1: Start the application
mvn exec:java -Dexec.mainClass="com.example.routing.AdvancedDynamicRouting"
In another terminal, run the tests:

# Terminal 2: Run tests
./test-dynamic-routing.sh
Subtask 3.4: Create Performance Test
Create a performance test to validate routing under load:

// File: src/main/java/com/example/routing/PerformanceTest.java
package com.example.routing;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.URI;

public class PerformanceTest {
    
    private static final String BASE_URL = "http://localhost:8080";
    private static final HttpClient client = HttpClient.newHttpClient();
    
    public static void main(String[] args) throws Exception {
        System.out.println("Starting performance test for dynamic routing...");
        
        ExecutorService executor = Executors.newFixedThreadPool(10);
        
        // Test different routing scenarios concurrently
        for (int i = 0; i < 100; i++) {
            final int requestId = i;
            executor.submit(() -> {
                try {
                    testOrderRouting(requestId);
                    testProductRouting(requestId);
                    testComplexRouting(requestId);
                } catch (Exception e) {
                    System.err.println("Error in request " + requestId + ": " + e.getMessage());
                }
            });
        }
        
        executor.shutdown();
        executor.awaitTermination(60, TimeUnit.SECONDS);
        
        System.out.println("Performance test completed.");
    }
    
    private static void testOrderRouting(int id) throws Exception {
        String[] priorities = {"HIGH", "MEDIUM", "LOW"};
        String priority = priorities[id % 3];
        
        String json = String.format(
            "{\"orderId\": \"ORD%03d\", \"priority\": \"%s\", \"amount\": %d}",
            id, priority, (id * 100) % 2000
        );
        
        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create(BASE_URL + "/orders"))
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(json))
            .build();
        
        HttpResponse<String> response = client.send(request, 
            HttpResponse.BodyHandlers.ofString());
        
        if (response.statusCode() == 200) {
            System.out.println("Order " + id + " processed successfully");
        }
    }
    
    private static void testProductRouting(int id) throws Exception {
        String[] categories = {"ELECTRONICS", "CLOTHING", "BOOKS", "FOOD"};
        String category = categories[id % 4];
        
        String json = String.format(
            "{\"productId\": \"PROD%03d\", \"category\": \"%s\", \"name\": \"Product %d\"}",
            id, category, id
        );
        
        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create(BASE_URL + "/products"))
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(json))
            .build();
        
        HttpResponse<String> response = client.send(request, 
            HttpResponse.BodyHandlers.ofString());
        
        if (response.statusCode() == 200) {
            System.out.println("Product " + id + " processed successfully");
        }
    }
    
    private static void testComplexRouting(int id) throws Exception {
        String[] priorities = {"URGENT", "HIGH", "MEDIUM", "LOW"};
        String[] regions = {"NORTH", "SOUTH", "EAST", "WEST"};
        String[] categories = {"ELECTRONICS", "CLOTHING", "BOOKS", "FOOD"};
        
        String json = String.format(
            "{\"orderId\": \"COMPLEX%03d\", \"priority\": \"%s\", \"amount\": %d, \"region\": \"%s\", \"category\": \"%s\"}",
            id, priorities[id % 4], (id * 150) % 3000, regions[id % 4], categories[id % 4]
        );
        
        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create(BASE_URL + "/complex-orders"))
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(json))
            .build();
        
        HttpResponse<String> response = client.send(request, 
            HttpResponse.BodyHandlers.ofString());
        
        if (response.statusCode() == 200) {
            System.out.println("Complex order " + id + " processed successfully");
        }
    }
}
Run the performance test:

# Compile and run performance test
mvn exec:java -Dexec.mainClass="com.example.routing.PerformanceTest"
Troubleshooting Common Issues
Issue 1: JSON Parsing Errors
Problem: JsonPath expressions not working correctly

Solution: Ensure proper JSON format and valid JsonPath syntax:

// Correct JsonPath for nested properties
.when(jsonpath("$.order.priority[?(@ == 'HIGH')]"))

// Alternative using simple expressions
.when(simple("${body[priority]} == 'HIGH'"))
Issue 2: Route Not Found
Problem: Dynamic route destination not found

Solution: Add error handling and default routes:

.choice()
    .when(header("targetRoute").isNotNull())
        .recipientList(header("targetRoute"))
    .otherwise()
        .log("No valid route found, using default")
        .to("direct:defaultProcessor")
.end()
Issue 3: Performance Issues
Problem: Slow routing decisions

Solution: Cache external configuration and optimize predicates:

// Cache configuration in memory
private
