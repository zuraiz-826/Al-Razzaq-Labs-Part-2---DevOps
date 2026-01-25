Lab 5: Implementing Enterprise Integration Patterns (EIPs)
Objectives
By the end of this lab, students will be able to:

Understand the fundamental concepts of Enterprise Integration Patterns (EIPs)
Implement the Content-Based Router pattern to route messages based on their content
Implement the Splitter pattern to break large messages into smaller, manageable pieces
Use Apache Camel as an open-source integration framework
Configure routing rules and message transformation logic
Test and validate EIP implementations in a practical environment
Prerequisites
Before starting this lab, students should have:

Basic understanding of Java programming concepts
Familiarity with XML and JSON data formats
Knowledge of Maven build tool
Understanding of messaging concepts and REST APIs
Basic Linux command-line skills
Technical Requirements:

Java 11 or higher
Apache Maven 3.6+
Text editor or IDE (VS Code, IntelliJ IDEA, or Eclipse)
Internet connection for downloading dependencies
Lab Environment Setup
Good News! Al Nafi provides ready-to-use Linux-based cloud machines for this lab. Simply click Start Lab and you'll have access to a pre-configured environment with all necessary tools installed. No need to build your own VM or install software locally.

Your cloud machine includes:

Ubuntu 20.04 LTS
Java 11 OpenJDK
Apache Maven 3.8
VS Code with Java extensions
All required dependencies pre-downloaded
Task 1: Implement Content-Based Router Pattern
The Content-Based Router pattern examines message content and routes it to different destinations based on specific criteria. Think of it like a postal sorting office that reads addresses and sends mail to the correct delivery routes.

Subtask 1.1: Create Project Structure
Open Terminal in your cloud machine and create a new Maven project:
mkdir ~/eip-lab
cd ~/eip-lab
mvn archetype:generate -DgroupId=com.alnafi.eip \
    -DartifactId=eip-patterns-lab \
    -DarchetypeArtifactId=maven-archetype-quickstart \
    -DinteractiveMode=false
Navigate to the project directory:
cd eip-patterns-lab
Update the Maven configuration by editing the pom.xml file:
nano pom.xml
Replace the content with:

<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.alnafi.eip</groupId>
    <artifactId>eip-patterns-lab</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <camel.version>3.20.1</camel.version>
        <spring.boot.version>2.7.8</spring.boot.version>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.apache.camel.springboot</groupId>
            <artifactId>camel-spring-boot-starter</artifactId>
            <version>${camel.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-jackson</artifactId>
            <version>${camel.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-http</artifactId>
            <version>${camel.version}</version>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <version>${spring.boot.version}</version>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <version>${spring.boot.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <version>${spring.boot.version}</version>
            </plugin>
        </plugins>
    </build>
</project>
Subtask 1.2: Create Message Models
Create the package structure:
mkdir -p src/main/java/com/alnafi/eip/model
mkdir -p src/main/java/com/alnafi/eip/routes
mkdir -p src/main/resources
Create a Customer Order model for our routing example:
nano src/main/java/com/alnafi/eip/model/CustomerOrder.java
Add the following content:

package com.alnafi.eip.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class CustomerOrder {
    @JsonProperty("orderId")
    private String orderId;
    
    @JsonProperty("customerType")
    private String customerType;
    
    @JsonProperty("amount")
    private double amount;
    
    @JsonProperty("priority")
    private String priority;
    
    @JsonProperty("productCategory")
    private String productCategory;
    
    // Default constructor
    public CustomerOrder() {}
    
    // Constructor with parameters
    public CustomerOrder(String orderId, String customerType, double amount, 
                        String priority, String productCategory) {
        this.orderId = orderId;
        this.customerType = customerType;
        this.amount = amount;
        this.priority = priority;
        this.productCategory = productCategory;
    }
    
    // Getters and Setters
    public String getOrderId() { return orderId; }
    public void setOrderId(String orderId) { this.orderId = orderId; }
    
    public String getCustomerType() { return customerType; }
    public void setCustomerType(String customerType) { this.customerType = customerType; }
    
    public double getAmount() { return amount; }
    public void setAmount(double amount) { this.amount = amount; }
    
    public String getPriority() { return priority; }
    public void setPriority(String priority) { this.priority = priority; }
    
    public String getProductCategory() { return productCategory; }
    public void setProductCategory(String productCategory) { this.productCategory = productCategory; }
    
    @Override
    public String toString() {
        return "CustomerOrder{" +
                "orderId='" + orderId + '\'' +
                ", customerType='" + customerType + '\'' +
                ", amount=" + amount +
                ", priority='" + priority + '\'' +
                ", productCategory='" + productCategory + '\'' +
                '}';
    }
}
Subtask 1.3: Implement Content-Based Router
Create the Content-Based Router route:
nano src/main/java/com/alnafi/eip/routes/ContentBasedRouterRoute.java
Add the following implementation:

package com.alnafi.eip.routes;

import com.alnafi.eip.model.CustomerOrder;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.dataformat.JsonLibrary;
import org.springframework.stereotype.Component;

@Component
public class ContentBasedRouterRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Main route that receives orders and routes them based on content
        from("direct:processOrder")
            .routeId("content-based-router")
            .log("Received order: ${body}")
            .unmarshal().json(JsonLibrary.Jackson, CustomerOrder.class)
            .choice()
                // Route 1: Premium customers with high-value orders
                .when(simple("${body.customerType} == 'PREMIUM' && ${body.amount} > 1000"))
                    .log("Routing to Premium High-Value queue: ${body.orderId}")
                    .to("direct:premiumHighValue")
                // Route 2: Premium customers with regular orders
                .when(simple("${body.customerType} == 'PREMIUM'"))
                    .log("Routing to Premium Regular queue: ${body.orderId}")
                    .to("direct:premiumRegular")
                // Route 3: High priority orders regardless of customer type
                .when(simple("${body.priority} == 'HIGH'"))
                    .log("Routing to High Priority queue: ${body.orderId}")
                    .to("direct:highPriority")
                // Route 4: Electronics category orders
                .when(simple("${body.productCategory} == 'ELECTRONICS'"))
                    .log("Routing to Electronics queue: ${body.orderId}")
                    .to("direct:electronics")
                // Default route for all other orders
                .otherwise()
                    .log("Routing to Standard queue: ${body.orderId}")
                    .to("direct:standard")
            .end();
        
        // Destination routes for different order types
        from("direct:premiumHighValue")
            .routeId("premium-high-value-processor")
            .log("Processing Premium High-Value order: ${body.orderId}")
            .process(exchange -> {
                CustomerOrder order = exchange.getIn().getBody(CustomerOrder.class);
                System.out.println("*** PREMIUM HIGH-VALUE PROCESSING ***");
                System.out.println("Order ID: " + order.getOrderId());
                System.out.println("Amount: $" + order.getAmount());
                System.out.println("Applying 15% discount and priority shipping");
                System.out.println("*************************************");
            });
        
        from("direct:premiumRegular")
            .routeId("premium-regular-processor")
            .log("Processing Premium Regular order: ${body.orderId}")
            .process(exchange -> {
                CustomerOrder order = exchange.getIn().getBody(CustomerOrder.class);
                System.out.println("*** PREMIUM REGULAR PROCESSING ***");
                System.out.println("Order ID: " + order.getOrderId());
                System.out.println("Applying 10% discount");
                System.out.println("**********************************");
            });
        
        from("direct:highPriority")
            .routeId("high-priority-processor")
            .log("Processing High Priority order: ${body.orderId}")
            .process(exchange -> {
                CustomerOrder order = exchange.getIn().getBody(CustomerOrder.class);
                System.out.println("*** HIGH PRIORITY PROCESSING ***");
                System.out.println("Order ID: " + order.getOrderId());
                System.out.println("Express processing initiated");
                System.out.println("********************************");
            });
        
        from("direct:electronics")
            .routeId("electronics-processor")
            .log("Processing Electronics order: ${body.orderId}")
            .process(exchange -> {
                CustomerOrder order = exchange.getIn().getBody(CustomerOrder.class);
                System.out.println("*** ELECTRONICS PROCESSING ***");
                System.out.println("Order ID: " + order.getOrderId());
                System.out.println("Extended warranty offered");
                System.out.println("******************************");
            });
        
        from("direct:standard")
            .routeId("standard-processor")
            .log("Processing Standard order: ${body.orderId}")
            .process(exchange -> {
                CustomerOrder order = exchange.getIn().getBody(CustomerOrder.class);
                System.out.println("*** STANDARD PROCESSING ***");
                System.out.println("Order ID: " + order.getOrderId());
                System.out.println("Standard processing applied");
                System.out.println("***************************");
            });
    }
}
Subtask 1.4: Create REST Controller for Testing
Create a REST controller to test the Content-Based Router:
nano src/main/java/com/alnafi/eip/controller/OrderController.java
Add the following content:

package com.alnafi.eip.controller;

import com.alnafi.eip.model.CustomerOrder;
import org.apache.camel.ProducerTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/orders")
public class OrderController {
    
    @Autowired
    private ProducerTemplate producerTemplate;
    
    @PostMapping("/process")
    public ResponseEntity<String> processOrder(@RequestBody CustomerOrder order) {
        try {
            // Convert order to JSON and send to Content-Based Router
            producerTemplate.sendBody("direct:processOrder", order);
            return ResponseEntity.ok("Order " + order.getOrderId() + " processed successfully");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error processing order: " + e.getMessage());
        }
    }
    
    @GetMapping("/test")
    public ResponseEntity<String> testEndpoint() {
        return ResponseEntity.ok("Order processing service is running!");
    }
}
Task 2: Implement Splitter Pattern
The Splitter pattern takes a large message containing multiple items and breaks it into individual messages. Think of it like unpacking a box of mixed items and sorting each item into separate containers.

Subtask 2.1: Create Batch Order Model
Create a model for batch orders:
nano src/main/java/com/alnafi/eip/model/BatchOrder.java
Add the following content:

package com.alnafi.eip.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public class BatchOrder {
    @JsonProperty("batchId")
    private String batchId;
    
    @JsonProperty("orders")
    private List<CustomerOrder> orders;
    
    @JsonProperty("totalOrders")
    private int totalOrders;
    
    // Default constructor
    public BatchOrder() {}
    
    // Constructor with parameters
    public BatchOrder(String batchId, List<CustomerOrder> orders) {
        this.batchId = batchId;
        this.orders = orders;
        this.totalOrders = orders != null ? orders.size() : 0;
    }
    
    // Getters and Setters
    public String getBatchId() { return batchId; }
    public void setBatchId(String batchId) { this.batchId = batchId; }
    
    public List<CustomerOrder> getOrders() { return orders; }
    public void setOrders(List<CustomerOrder> orders) { 
        this.orders = orders;
        this.totalOrders = orders != null ? orders.size() : 0;
    }
    
    public int getTotalOrders() { return totalOrders; }
    public void setTotalOrders(int totalOrders) { this.totalOrders = totalOrders; }
    
    @Override
    public String toString() {
        return "BatchOrder{" +
                "batchId='" + batchId + '\'' +
                ", totalOrders=" + totalOrders +
                ", orders=" + orders +
                '}';
    }
}
Subtask 2.2: Implement Splitter Route
Create the Splitter route:
nano src/main/java/com/alnafi/eip/routes/SplitterRoute.java
Add the following implementation:

package com.alnafi.eip.routes;

import com.alnafi.eip.model.BatchOrder;
import com.alnafi.eip.model.CustomerOrder;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.dataformat.JsonLibrary;
import org.springframework.stereotype.Component;

@Component
public class SplitterRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Main splitter route
        from("direct:processBatchOrder")
            .routeId("batch-order-splitter")
            .log("Received batch order: ${body}")
            .unmarshal().json(JsonLibrary.Jackson, BatchOrder.class)
            .process(exchange -> {
                BatchOrder batchOrder = exchange.getIn().getBody(BatchOrder.class);
                System.out.println("=== BATCH ORDER PROCESSING ===");
                System.out.println("Batch ID: " + batchOrder.getBatchId());
                System.out.println("Total Orders: " + batchOrder.getTotalOrders());
                System.out.println("Starting to split batch...");
                System.out.println("==============================");
            })
            // Split the batch into individual orders
            .split(simple("${body.orders}"))
                .streaming() // Process one at a time to save memory
                .log("Processing individual order from batch: ${body.orderId}")
                .process(exchange -> {
                    CustomerOrder order = exchange.getIn().getBody(CustomerOrder.class);
                    System.out.println("--- Individual Order Processing ---");
                    System.out.println("Order ID: " + order.getOrderId());
                    System.out.println("Customer Type: " + order.getCustomerType());
                    System.out.println("Amount: $" + order.getAmount());
                    System.out.println("----------------------------------");
                })
                // Send each individual order to the Content-Based Router
                .marshal().json(JsonLibrary.Jackson)
                .to("direct:processOrder")
            .end()
            .log("Batch processing completed");
        
        // Route to demonstrate aggregation after splitting (optional)
        from("direct:processBatchWithAggregation")
            .routeId("batch-splitter-with-aggregation")
            .log("Processing batch with aggregation: ${body}")
            .unmarshal().json(JsonLibrary.Jackson, BatchOrder.class)
            .split(simple("${body.orders}"))
                .streaming()
                .log("Processing and aggregating order: ${body.orderId}")
                .process(exchange -> {
                    CustomerOrder order = exchange.getIn().getBody(CustomerOrder.class);
                    // Simulate processing time
                    Thread.sleep(100);
                    
                    // Add processing result to order
                    System.out.println("Processed order: " + order.getOrderId() + 
                                     " for customer type: " + order.getCustomerType());
                })
                // Aggregate results back together
                .aggregate(constant(true))
                    .strategy((oldExchange, newExchange) -> {
                        if (oldExchange == null) {
                            return newExchange;
                        }
                        
                        String oldBody = oldExchange.getIn().getBody(String.class);
                        String newBody = newExchange.getIn().getBody(String.class);
                        
                        oldExchange.getIn().setBody(oldBody + "," + newBody);
                        return oldExchange;
                    })
                    .completionTimeout(5000) // Complete after 5 seconds
            .end()
            .log("Aggregated results: ${body}");
    }
}
Subtask 2.3: Create Batch Order Controller
Create a controller for batch order processing:
nano src/main/java/com/alnafi/eip/controller/BatchOrderController.java
Add the following content:

package com.alnafi.eip.controller;

import com.alnafi.eip.model.BatchOrder;
import com.alnafi.eip.model.CustomerOrder;
import org.apache.camel.ProducerTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;

@RestController
@RequestMapping("/api/batch")
public class BatchOrderController {
    
    @Autowired
    private ProducerTemplate producerTemplate;
    
    @PostMapping("/process")
    public ResponseEntity<String> processBatchOrder(@RequestBody BatchOrder batchOrder) {
        try {
            producerTemplate.sendBody("direct:processBatchOrder", batchOrder);
            return ResponseEntity.ok("Batch " + batchOrder.getBatchId() + 
                                   " with " + batchOrder.getTotalOrders() + 
                                   " orders processed successfully");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error processing batch: " + e.getMessage());
        }
    }
    
    @PostMapping("/process-with-aggregation")
    public ResponseEntity<String> processBatchWithAggregation(@RequestBody BatchOrder batchOrder) {
        try {
            producerTemplate.sendBody("direct:processBatchWithAggregation", batchOrder);
            return ResponseEntity.ok("Batch " + batchOrder.getBatchId() + 
                                   " processed with aggregation");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error processing batch: " + e.getMessage());
        }
    }
    
    @GetMapping("/sample")
    public ResponseEntity<BatchOrder> getSampleBatch() {
        // Create sample orders for testing
        List<CustomerOrder> sampleOrders = Arrays.asList(
            new CustomerOrder("ORD-001", "PREMIUM", 1500.0, "HIGH", "ELECTRONICS"),
            new CustomerOrder("ORD-002", "STANDARD", 250.0, "NORMAL", "CLOTHING"),
            new CustomerOrder("ORD-003", "PREMIUM", 800.0, "NORMAL", "BOOKS"),
            new CustomerOrder("ORD-004", "STANDARD", 150.0, "HIGH", "ELECTRONICS"),
            new CustomerOrder("ORD-005", "PREMIUM", 2000.0, "HIGH", "FURNITURE")
        );
        
        BatchOrder sampleBatch = new BatchOrder("BATCH-001", sampleOrders);
        return ResponseEntity.ok(sampleBatch);
    }
}
Subtask 2.4: Create Main Application Class
Create the Spring Boot main application:
nano src/main/java/com/alnafi/eip/EipPatternsApplication.java
Add the following content:

package com.alnafi.eip;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class EipPatternsApplication {
    public static void main(String[] args) {
        SpringApplication.run(EipPatternsApplication.class, args);
    }
}
Subtask 2.5: Configure Application Properties
Create application configuration:
nano src/main/resources/application.yml
Add the following configuration:

server:
  port: 8080

spring:
  application:
    name: eip-patterns-lab

camel:
  springboot:
    name: EIP-Patterns-Camel-Context
  component:
    servlet:
      mapping:
        context-path: /camel/*

logging:
  level:
    com.alnafi.eip: DEBUG
    org.apache.camel: INFO
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
Task 3: Testing the Implementation
Subtask 3.1: Build and Run the Application
Build the project:
mvn clean compile
Run the application:
mvn spring-boot:run
The application will start on port 8080. You should see logs indicating that Camel routes are starting.

Subtask 3.2: Test Content-Based Router
Open a new terminal and test the individual order processing:
# Test Premium High-Value order
curl -X POST http://localhost:8080/api/orders/process \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "TEST-001",
    "customerType": "PREMIUM",
    "amount": 1500.0,
    "priority": "NORMAL",
    "productCategory": "ELECTRONICS"
  }'
Test different routing scenarios:
# Test High Priority order
curl -X POST http://localhost:8080/api/orders/process \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "TEST-002",
    "customerType": "STANDARD",
    "amount": 300.0,
    "priority": "HIGH",
    "productCategory": "CLOTHING"
  }'

# Test Electronics category
curl -X POST http://localhost:8080/api/orders/process \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "TEST-003",
    "customerType": "STANDARD",
    "amount": 500.0,
    "priority": "NORMAL",
    "productCategory": "ELECTRONICS"
  }'

# Test Standard processing
curl -X POST http://localhost:8080/api/orders/process \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "TEST-004",
    "customerType": "STANDARD",
    "amount": 100.0,
    "priority": "NORMAL",
    "productCategory": "BOOKS"
  }'
Subtask 3.3: Test Splitter Pattern
Get sample batch data:
curl -X GET http://localhost:8080/api/batch/sample
Test batch processing with splitter:
curl -X POST http://localhost:8080/api/batch/process \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": "BATCH-TEST-001",
    "orders": [
      {
        "orderId": "BATCH-ORD-001",
        "customerType": "PREMIUM",
        "amount": 1200.0,
        "priority": "HIGH",
        "productCategory": "ELECTRONICS"
      },
      {
        "orderId": "BATCH-ORD-002",
        "customerType": "STANDARD",
        "amount": 300.0,
        "priority": "NORMAL",
        "productCategory": "CLOTHING"
      },
      {
        "orderId": "BATCH-ORD-003",
        "customerType": "PREMIUM",
        "amount": 800.0,
        "priority": "NORMAL",
        "productCategory": "BOOKS"
      }
    ],
    "totalOrders": 3
  }'
Test batch processing with aggregation:
curl -X POST http://localhost:8080/api/batch/process-with-aggregation \
  -H "Content-Type: application/json" \
  -d '{
    "batchId": "BATCH-AGG-001",
    "orders": [
      {
        "orderId": "AGG-ORD-001",
        "customerType": "PREMIUM",
        "amount": 1500.0,
        "priority": "HIGH",
        "productCategory": "ELECTRONICS"
      },
      {
        "orderId": "AGG-ORD-002",
        "customerType": "STANDARD",
        "amount": 250.0,
        "priority": "NORMAL",
        "productCategory": "CLOTHING"
      }
    ],
    "totalOrders": 2
  }'
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Port Already in Use

# Check what's using port 8080
sudo netstat -tulpn | grep 8080
# Kill the process if needed
sudo kill -9 <process_id>
Issue 2: Maven Dependencies Not Downloaded

# Force download dependencies
mvn dependency:resolve
# Clean and rebuild
mvn clean install
Issue 3: JSON Parsing Errors

Ensure JSON payload matches the model structure exactly
Check that all required fields are included
Verify Content-Type header is set to application/json
Issue 4: Camel Routes Not Starting

Check application logs for detailed error messages
Verify all required dependencies are in the classpath
Ensure Spring Boot annotations are correctly applied
Advanced Testing Scenarios
Subtask 3.4: Performance Testing
Create a script to test multiple orders:
nano test-performance.sh
Add the following content:

#!/bin/bash

echo "Starting performance test..."

for i in {1..10}
do
  echo "Sending order $i"
  curl -X POST http://localhost:8080/api/orders/process \
    -H "Content-Type: application/json" \
    -d "{
      \"orderId\": \"PERF-TEST-$i\",
      \"customerType\": \"PREMIUM\",
      \"amount\": $((RANDOM % 2000 + 100)),
      \"priority\": \"HIGH\",
      \"productCategory\": \"ELECTRONICS\"
    }" &
done

wait
echo "Performance test completed"
Make the script executable and run it:
chmod +x test-performance.sh
./test-performance.sh
Key Concepts Summary
Content-Based Router Pattern
Purpose: Routes messages to different destinations based on message content
Implementation: Uses Camel's choice() and when() constructs
Benefits: Enables intelligent message routing without tight coupling
Use Cases: Order processing, message filtering, conditional workflows
Splitter Pattern
Purpose: Breaks large messages into smaller, manageable pieces
Implementation: Uses Camel's split() method with expressions
Benefits: Enables parallel processing and better resource utilization
Use Cases: Batch processing, bulk operations, data transformation
Apache Camel Features Used
Route Builders: Define integration routes using Java DSL
Processors: Custom message processing logic
Type Converters: Automatic data type conversion
JSON Marshalling: Convert between Java objects and JSON
Conclusion
Congratulations! You have successfully implemented two fundamental Enterprise Integration Patterns using Apache Camel:

What You Accomplished
Content-Based Router Implementation

Created a sophisticated routing system that examines message content
Implemented multiple routing rules based on customer type, order amount, priority, and product category
Built a flexible system that can easily accommodate new routing rules
Splitter Pattern Implementation

Developed a batch processing system that breaks large messages into individual items
Implemented streaming processing for memory efficiency
Created an aggregation mechanism to collect results after splitting
Practical Integration Skills

Used Apache Camel as a powerful open-source integration framework
Integrated with Spring Boot for enterprise-grade application development
Created RESTful APIs for testing and interaction
Implemented proper error handling and logging
Why This Matters
These Enterprise Integration Patterns are fundamental building blocks for:

Microservices Architecture: Enabling communication between distributed services
Data Processing Pipelines: Handling large volumes of data efficiently
Business Process Automation: Routing and processing business transactions
System Integration: Connecting disparate systems and applications
Real-World Applications
The patterns you've learned are used in:

E-commerce platforms for order processing and fulfillment
Financial systems for transaction routing and processing
Healthcare systems for patient data management and routing
Supply chain management for inventory and logistics coordination
Next Steps
To further enhance your integration skills:

Explore additional EIP patterns like Aggregator, Message Filter, and Transformer
Learn about error handling and retry mechanisms in integration scenarios
Study message queuing systems like Apache ActiveMQ or RabbitMQ
Investigate cloud-native
