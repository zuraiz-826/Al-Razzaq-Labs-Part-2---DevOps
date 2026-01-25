Lab 12: Consuming External REST APIs with Camel
Objectives
By the end of this lab, you will be able to:

Set up Apache Camel routes to consume external REST APIs using the HTTP component
Process and transform JSON data received from REST API responses
Implement error handling for external API integrations
Test REST API consumption with real-world examples
Configure HTTP headers and authentication for API requests
Monitor and log API interactions for debugging purposes
Prerequisites
Before starting this lab, you should have:

Basic understanding of Apache Camel concepts and routing
Familiarity with REST APIs and HTTP protocols
Knowledge of JSON data format and processing
Basic Java programming skills
Understanding of Maven project structure
Experience with Linux command line operations
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides Linux-based cloud machines with all necessary tools pre-installed. Simply click Start Lab to begin - no need to build your own VM or install software.

Your cloud machine includes:

OpenJDK 11
Apache Maven 3.8+
Apache Camel 3.20+
curl and wget utilities
Text editors (nano, vim)
Task 1: Set Up a Route to Consume External REST API
Subtask 1.1: Create Maven Project Structure
First, let's create a new Maven project for our Camel REST API consumer.

# Navigate to home directory
cd ~

# Create project directory
mkdir camel-rest-consumer
cd camel-rest-consumer

# Create Maven directory structure
mkdir -p src/main/java/com/example/camel
mkdir -p src/main/resources
mkdir -p src/test/java
Subtask 1.2: Configure Maven Dependencies
Create the pom.xml file with necessary Camel dependencies:

nano pom.xml
Add the following content:

<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>camel-rest-consumer</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <camel.version>3.20.2</camel.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
    
    <dependencies>
        <!-- Camel Core -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-core</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel HTTP Component -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-http</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel Jackson for JSON processing -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-jackson</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel Timer for scheduling -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-timer</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel Log component -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-log</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- SLF4J Logging -->
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
            
            <plugin>
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>exec-maven-plugin</artifactId>
                <version>3.1.0</version>
                <configuration>
                    <mainClass>com.example.camel.RestConsumerApplication</mainClass>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
Subtask 1.3: Create Basic REST Consumer Route
Create the main application class:

nano src/main/java/com/example/camel/RestConsumerApplication.java
Add the following code:

package com.example.camel;

import org.apache.camel.CamelContext;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.impl.DefaultCamelContext;

public class RestConsumerApplication {
    
    public static void main(String[] args) throws Exception {
        // Create Camel context
        CamelContext camelContext = new DefaultCamelContext();
        
        // Add route builder
        camelContext.addRoutes(new RestApiConsumerRoute());
        
        // Start the context
        camelContext.start();
        
        System.out.println("Camel REST Consumer started. Press Ctrl+C to stop.");
        
        // Keep the application running
        Thread.sleep(60000); // Run for 1 minute for testing
        
        // Stop the context
        camelContext.stop();
    }
}
Subtask 1.4: Implement REST API Consumer Route
Create the route builder class:

nano src/main/java/com/example/camel/RestApiConsumerRoute.java
Add the following implementation:

package com.example.camel;

import org.apache.camel.Exchange;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.component.http.HttpMethods;

public class RestApiConsumerRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Route 1: Consume JSONPlaceholder API for posts
        from("timer://fetchPosts?period=30000&repeatCount=3")
            .routeId("fetch-posts-route")
            .log("Starting to fetch posts from JSONPlaceholder API...")
            .setHeader(Exchange.HTTP_METHOD, constant(HttpMethods.GET))
            .setHeader("Content-Type", constant("application/json"))
            .to("https://jsonplaceholder.typicode.com/posts?bridgeEndpoint=true")
            .log("Received response with ${header.CamelHttpResponseCode} status code")
            .choice()
                .when(header("CamelHttpResponseCode").isEqualTo(200))
                    .log("Successfully fetched posts data")
                    .to("direct:processPostsData")
                .otherwise()
                    .log("Failed to fetch posts. Status: ${header.CamelHttpResponseCode}")
            .end();
        
        // Route 2: Consume specific user information
        from("timer://fetchUser?period=45000&repeatCount=2")
            .routeId("fetch-user-route")
            .log("Fetching user information...")
            .setHeader(Exchange.HTTP_METHOD, constant(HttpMethods.GET))
            .setHeader("Content-Type", constant("application/json"))
            .to("https://jsonplaceholder.typicode.com/users/1?bridgeEndpoint=true")
            .log("User API response status: ${header.CamelHttpResponseCode}")
            .choice()
                .when(header("CamelHttpResponseCode").isEqualTo(200))
                    .to("direct:processUserData")
                .otherwise()
                    .log("Error fetching user data: ${header.CamelHttpResponseCode}")
            .end();
        
        // Route 3: Process posts data
        from("direct:processPostsData")
            .routeId("process-posts-route")
            .log("Processing posts data...")
            .unmarshal().json()
            .log("Converted JSON to object. Processing ${body.size} posts")
            .split().jsonpath("$[*]")
                .log("Processing post: ID=${body[id]}, Title=${body[title]}")
                .to("direct:savePostData")
            .end();
        
        // Route 4: Process user data
        from("direct:processUserData")
            .routeId("process-user-route")
            .log("Processing user data...")
            .unmarshal().json()
            .log("User Info - Name: ${body[name]}, Email: ${body[email]}, Company: ${body[company][name]}")
            .to("direct:saveUserData");
        
        // Route 5: Save post data (simulation)
        from("direct:savePostData")
            .routeId("save-post-route")
            .log("Saving post data: ${body}")
            .process(exchange -> {
                // Simulate data processing/saving
                Object body = exchange.getIn().getBody();
                System.out.println("Post saved to database: " + body);
            });
        
        // Route 6: Save user data (simulation)
        from("direct:saveUserData")
            .routeId("save-user-route")
            .log("Saving user data: ${body}")
            .process(exchange -> {
                // Simulate data processing/saving
                Object body = exchange.getIn().getBody();
                System.out.println("User saved to database: " + body);
            });
    }
}
Subtask 1.5: Build and Test Basic Setup
Compile and run the basic setup:

# Compile the project
mvn clean compile

# Run the application
mvn exec:java
You should see output showing the application fetching data from the JSONPlaceholder API.

Task 2: Process and Transform the Data
Subtask 2.1: Create Data Transformation Processor
Create a custom processor for advanced data transformation:

nano src/main/java/com/example/camel/DataTransformProcessor.java
Add the following code:

package com.example.camel;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.util.Date;

public class DataTransformProcessor implements Processor {
    
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    @Override
    public void process(Exchange exchange) throws Exception {
        String jsonBody = exchange.getIn().getBody(String.class);
        
        // Parse JSON
        JsonNode rootNode = objectMapper.readTree(jsonBody);
        
        if (rootNode.isArray()) {
            // Process array of posts
            for (JsonNode postNode : rootNode) {
                transformPost((ObjectNode) postNode);
            }
        } else {
            // Process single object (user)
            transformUser((ObjectNode) rootNode);
        }
        
        // Set transformed data back to exchange
        exchange.getIn().setBody(objectMapper.writeValueAsString(rootNode));
    }
    
    private void transformPost(ObjectNode postNode) {
        // Add metadata
        postNode.put("processedAt", new Date().toString());
        postNode.put("source", "jsonplaceholder-api");
        
        // Transform title to uppercase
        if (postNode.has("title")) {
            String title = postNode.get("title").asText();
            postNode.put("title", title.toUpperCase());
        }
        
        // Add word count for body
        if (postNode.has("body")) {
            String body = postNode.get("body").asText();
            int wordCount = body.split("\\s+").length;
            postNode.put("wordCount", wordCount);
        }
        
        // Add category based on userId
        if (postNode.has("userId")) {
            int userId = postNode.get("userId").asInt();
            String category = userId <= 5 ? "PRIORITY" : "STANDARD";
            postNode.put("category", category);
        }
    }
    
    private void transformUser(ObjectNode userNode) {
        // Add metadata
        userNode.put("processedAt", new Date().toString());
        userNode.put("source", "jsonplaceholder-api");
        
        // Create full address string
        if (userNode.has("address")) {
            JsonNode address = userNode.get("address");
            String fullAddress = String.format("%s, %s, %s %s",
                address.get("street").asText(),
                address.get("city").asText(),
                address.get("suite").asText(),
                address.get("zipcode").asText()
            );
            userNode.put("fullAddress", fullAddress);
        }
        
        // Extract domain from email
        if (userNode.has("email")) {
            String email = userNode.get("email").asText();
            String domain = email.substring(email.indexOf("@") + 1);
            userNode.put("emailDomain", domain);
        }
    }
}
Subtask 2.2: Create Enhanced Route with Data Transformation
Create an enhanced route builder:

nano src/main/java/com/example/camel/EnhancedRestConsumerRoute.java
Add the following implementation:

package com.example.camel;

import org.apache.camel.Exchange;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.component.http.HttpMethods;

public class EnhancedRestConsumerRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Global error handler
        onException(Exception.class)
            .handled(true)
            .log("Error occurred: ${exception.message}")
            .to("direct:handleError");
        
        // Route 1: Enhanced posts fetching with transformation
        from("timer://enhancedPosts?period=20000&repeatCount=2")
            .routeId("enhanced-posts-route")
            .log("=== Starting Enhanced Posts Fetch ===")
            .setHeader(Exchange.HTTP_METHOD, constant(HttpMethods.GET))
            .setHeader("User-Agent", constant("Camel-REST-Consumer/1.0"))
            .setHeader("Accept", constant("application/json"))
            .to("https://jsonplaceholder.typicode.com/posts?_limit=5&bridgeEndpoint=true")
            .log("Posts API Response Code: ${header.CamelHttpResponseCode}")
            .choice()
                .when(header("CamelHttpResponseCode").isEqualTo(200))
                    .log("Successfully received posts data")
                    .process(new DataTransformProcessor())
                    .log("Data transformation completed")
                    .to("direct:validateAndStore")
                .otherwise()
                    .log("Failed to fetch posts: ${header.CamelHttpResponseCode}")
                    .to("direct:handleApiError")
            .end();
        
        // Route 2: Enhanced user fetching with multiple users
        from("timer://enhancedUsers?period=25000&repeatCount=2")
            .routeId("enhanced-users-route")
            .log("=== Starting Enhanced Users Fetch ===")
            .setHeader(Exchange.HTTP_METHOD, constant(HttpMethods.GET))
            .setHeader("User-Agent", constant("Camel-REST-Consumer/1.0"))
            .setHeader("Accept", constant("application/json"))
            .to("https://jsonplaceholder.typicode.com/users?_limit=3&bridgeEndpoint=true")
            .log("Users API Response Code: ${header.CamelHttpResponseCode}")
            .choice()
                .when(header("CamelHttpResponseCode").isEqualTo(200))
                    .log("Successfully received users data")
                    .process(new DataTransformProcessor())
                    .log("User data transformation completed")
                    .to("direct:processUsersArray")
                .otherwise()
                    .log("Failed to fetch users: ${header.CamelHttpResponseCode}")
                    .to("direct:handleApiError")
            .end();
        
        // Route 3: Validate and store transformed data
        from("direct:validateAndStore")
            .routeId("validate-store-route")
            .log("Validating transformed data...")
            .unmarshal().json()
            .choice()
                .when().jsonpath("$[?(@.category)]")
                    .log("Data validation passed - category field present")
                    .split().jsonpath("$[*]")
                        .log("Storing post: ${body[title]} (Category: ${body[category]})")
                        .to("direct:storeInDatabase")
                    .end()
                .otherwise()
                    .log("Data validation failed - missing required fields")
            .end();
        
        // Route 4: Process users array
        from("direct:processUsersArray")
            .routeId("process-users-array-route")
            .log("Processing users array...")
            .unmarshal().json()
            .split().jsonpath("$[*]")
                .log("Processing user: ${body[name]} (${body[email]}) - Domain: ${body[emailDomain]}")
                .choice()
                    .when().jsonpath("$[?(@.emailDomain == 'biz')]")
                        .log("Business user detected: ${body[name]}")
                        .setHeader("UserType", constant("BUSINESS"))
                    .otherwise()
                        .setHeader("UserType", constant("PERSONAL"))
                .end()
                .to("direct:storeUserInDatabase")
            .end();
        
        // Route 5: Store in database (simulation)
        from("direct:storeInDatabase")
            .routeId("store-database-route")
            .log("=== STORING POST IN DATABASE ===")
            .process(exchange -> {
                Object body = exchange.getIn().getBody();
                System.out.println("DATABASE INSERT: " + body);
                // Simulate database operation
                Thread.sleep(100);
            })
            .log("Post successfully stored in database");
        
        // Route 6: Store user in database (simulation)
        from("direct:storeUserInDatabase")
            .routeId("store-user-database-route")
            .log("=== STORING USER IN DATABASE ===")
            .log("User Type: ${header.UserType}")
            .process(exchange -> {
                Object body = exchange.getIn().getBody();
                String userType = exchange.getIn().getHeader("UserType", String.class);
                System.out.println("DATABASE INSERT USER (" + userType + "): " + body);
                // Simulate database operation
                Thread.sleep(100);
            })
            .log("User successfully stored in database");
        
        // Route 7: Handle API errors
        from("direct:handleApiError")
            .routeId("handle-api-error-route")
            .log("=== API ERROR HANDLER ===")
            .log("Response Code: ${header.CamelHttpResponseCode}")
            .log("Response Text: ${body}")
            .choice()
                .when(header("CamelHttpResponseCode").isEqualTo(404))
                    .log("Resource not found - skipping")
                .when(header("CamelHttpResponseCode").isEqualTo(429))
                    .log("Rate limit exceeded - implementing backoff")
                    .delay(5000)
                .otherwise()
                    .log("Unexpected error occurred")
            .end();
        
        // Route 8: General error handler
        from("direct:handleError")
            .routeId("general-error-handler-route")
            .log("=== GENERAL ERROR HANDLER ===")
            .log("Error: ${exception.message}")
            .log("Stack trace: ${exception.stacktrace}");
    }
}
Subtask 2.3: Update Main Application
Update the main application to use the enhanced route:

nano src/main/java/com/example/camel/RestConsumerApplication.java
Replace the content with:

package com.example.camel;

import org.apache.camel.CamelContext;
import org.apache.camel.impl.DefaultCamelContext;

public class RestConsumerApplication {
    
    public static void main(String[] args) throws Exception {
        System.out.println("=== Starting Camel REST API Consumer ===");
        
        // Create Camel context
        CamelContext camelContext = new DefaultCamelContext();
        
        // Add enhanced route builder
        camelContext.addRoutes(new EnhancedRestConsumerRoute());
        
        // Start the context
        camelContext.start();
        
        System.out.println("Camel REST Consumer started successfully!");
        System.out.println("The application will run for 2 minutes to demonstrate API consumption.");
        System.out.println("Press Ctrl+C to stop earlier if needed.");
        
        // Keep the application running for demonstration
        Thread.sleep(120000); // Run for 2 minutes
        
        System.out.println("=== Stopping Camel REST API Consumer ===");
        
        // Stop the context
        camelContext.stop();
        
        System.out.println("Application stopped successfully!");
    }
}
Task 3: Test the Integration with External APIs
Subtask 3.1: Create Test Configuration
Create a logging configuration file:

nano src/main/resources/simplelogger.properties
Add the following content:

# Simple Logger Configuration
org.slf4j.simpleLogger.defaultLogLevel=INFO
org.slf4j.simpleLogger.log.org.apache.camel=INFO
org.slf4j.simpleLogger.log.com.example.camel=DEBUG
org.slf4j.simpleLogger.showDateTime=true
org.slf4j.simpleLogger.dateTimeFormat=yyyy-MM-dd HH:mm:ss
org.slf4j.simpleLogger.showThreadName=true
org.slf4j.simpleLogger.showLogName=true
org.slf4j.simpleLogger.showShortLogName=false
Subtask 3.2: Create Test Runner Script
Create a test script to run different scenarios:

nano test-runner.sh
Add the following content:

#!/bin/bash

echo "=== Camel REST API Consumer Test Runner ==="
echo ""

# Function to run test
run_test() {
    echo "Starting test: $1"
    echo "Duration: $2 seconds"
    echo "----------------------------------------"
    
    timeout $2 mvn exec:java -Dexec.mainClass="com.example.camel.RestConsumerApplication" 2>&1 | tee test-output.log
    
    echo ""
    echo "Test completed. Check test-output.log for details."
    echo "========================================"
    echo ""
}

# Test 1: Basic functionality test
echo "Test 1: Basic API consumption test"
run_test "Basic API Test" 60

# Check if JSONPlaceholder API is accessible
echo "Verifying API accessibility..."
curl -s -o /dev/null -w "%{http_code}" https://jsonplaceholder.typicode.com/posts/1
echo ""

# Test 2: Extended test with more data
echo "Test 2: Extended API consumption test"
run_test "Extended API Test" 90

echo "All tests completed!"
echo "Check the logs above for detailed results."
Make the script executable:

chmod +x test-runner.sh
Subtask 3.3: Run Comprehensive Tests
Execute the comprehensive test:

# Build the project first
mvn clean compile

# Run the test script
./test-runner.sh
Subtask 3.4: Manual API Testing
Test individual API endpoints manually:

# Test JSONPlaceholder Posts API
echo "Testing Posts API..."
curl -X GET "https://jsonplaceholder.typicode.com/posts?_limit=3" \
     -H "Accept: application/json" \
     -H "User-Agent: Camel-REST-Consumer/1.0" | jq '.'

echo ""
echo "Testing Users API..."
curl -X GET "https://jsonplaceholder.typicode.com/users?_limit=2" \
     -H "Accept: application/json" \
     -H "User-Agent: Camel-REST-Consumer/1.0" | jq '.'

echo ""
echo "Testing Single User API..."
curl -X GET "https://jsonplaceholder.typicode.com/users/1" \
     -H "Accept: application/json" \
     -H "User-Agent: Camel-REST-Consumer/1.0" | jq '.'
Subtask 3.5: Create Monitoring and Debugging Route
Create a monitoring route to track API performance:

nano src/main/java/com/example/camel/MonitoringRoute.java
Add the following code:

package com.example.camel;

import org.apache.camel.Exchange;
import org.apache.camel.builder.RouteBuilder;

public class MonitoringRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Monitoring route for API performance
        from("timer://monitor?period=30000")
            .routeId("monitoring-route")
            .log("=== API MONITORING CHECK ===")
            .setHeader("StartTime", simple("${date:now:yyyy-MM-dd HH:mm:ss}"))
            .to("https://jsonplaceholder.typicode.com/posts/1?bridgeEndpoint=true")
            .process(exchange -> {
                long startTime = System.currentTimeMillis();
                exchange.setProperty("RequestStartTime", startTime);
            })
            .choice()
                .when(header("CamelHttpResponseCode").isEqualTo(200))
                    .log("API Health Check: HEALTHY")
                    .log("Response time: ${exchangeProperty.RequestStartTime}")
                .otherwise()
                    .log("API Health Check: UNHEALTHY - Status: ${header.CamelHttpResponseCode}")
            .end()
            .log("=== MONITORING CHECK COMPLETE ===");
        
        // Route to collect API statistics
        from("timer://stats?period=60000")
            .routeId("statistics-route")
            .log("=== COLLECTING API STATISTICS ===")
            .process(exchange -> {
                // Simulate collecting statistics
                System.out.println("Total API calls made: " + getContext().getRoutes().size());
                System.out.println("Active routes: " + getContext().getRoutes().size());
                System.out.println("Context status: " + getContext().getStatus());
            })
            .log("Statistics collection completed");
    }
}
Subtask 3.6: Create Complete Test Application
Create a comprehensive test application:

nano src/main/java/com/example/camel/CompleteTestApplication.java
Add the following code:

package com.example.camel;

import org.apache.camel.CamelContext;
import org.apache.camel.impl.DefaultCamelContext;

public class CompleteTestApplication {
    
    public static void main(String[] args) throws Exception {
        System.out.println("=== Complete Camel REST API Consumer Test ===");
        System.out.println("This application demonstrates:");
        System.out.println("1. REST API consumption");
        System.out.println("2. Data transformation");
        System.out.println("3. Error handling");
        System.out.println("4. Monitoring and logging");
        System.out.println("===============================================");
        
        // Create Camel context
        CamelContext camelContext = new DefaultCamelContext();
        
        // Add all route builders
        camelContext.addRoutes(new EnhancedRestConsumerRoute());
        camelContext.addRoutes(new MonitoringRoute());
        
        // Start the context
        camelContext.start();
        
        System.out.println("All routes started successfully!");
        System.out.println("Application will run for 3 minutes...");
        
        // Run for 3 minutes to see all functionality
        Thread.sleep(180000);
        
        System.out.println("=== Stopping Application ===");
        
        // Print final statistics
        System.out.println("Final Statistics:");
        System.out.println("- Total routes: " + camelContext.getRoutes().size());
        System.out.println("- Context uptime: " + camelContext.getUptime());
        
        // Stop the context
        camelContext.stop();
        
        System.out.println("Application stopped successfully!");
    }
}
Subtask 3.7: Run Complete Test
Execute the complete test application:

# Compile everything
mvn clean compile

# Run the complete test
mvn exec:java -Dexec.mainClass="com.example.camel.CompleteTestApplication"
Troubleshooting Common Issues
Issue 1: Connection Timeouts
If you experience connection timeouts:

# Test network connectivity
ping jsonplaceholder.typicode.com

# Check if the API is accessible
curl -I https://jsonplaceholder.typicode.com/posts/1
Solution: Add timeout configuration to your routes:

.to("https://jsonplaceholder.typicode.com/posts?bridgeEndpoint=true&connectTimeout=5000&socketTimeout=10000")
Issue 2: JSON Parsing Errors
If JSON parsing fails:

Solution: Add validation before unmarshalling:

.choice()
    .when(header("Content-Type").contains("application/json"))
        .unmarshal().json()
    .otherwise()
        .log("Non-JSON response received: ${body}")
.end()
Issue 3: Maven Dependency Issues
If you encounter dependency conflicts:

# Clean and reinstall dependencies
mvn clean
mvn dependency:resolve
mvn compile
Issue 4: Memory Issues
If the application runs out of memory:

# Run with increased memory
export MAVEN_OPTS="-Xmx512m -Xms256m"
mvn exec:java
Advanced Features and Extensions
Adding Authentication
To add API key authentication:

.setHeader("Authorization", constant("Bearer YOUR_API_KEY"))
.setHeader("X-API-Key", constant("YOUR_API_KEY"))
Adding Request Retry Logic
To implement retry logic:

.onException(Exception.class)
    .maximumRedeliveries(3)
    .redeliveryDelay(2000)
    .handled(true)
    .log("Retrying API call...")
Adding Response Caching
To cache API responses:

.choice()
    .when(header("CacheKey").isNotNull())
        .log("Using cached response")
    .otherwise()
        .to("https://api.example.com/data")
        .setHeader("CacheKey", simple("${body}"))
Conclusion
Congratulations! You have successfully completed Lab 12: Consuming External REST APIs with Camel. In this comprehensive lab, you have accomplished the following:

Key Achievements
REST API Integration: You learned how to set up Apache Camel routes to consume external REST APIs using the HTTP component, including proper header configuration and HTTP method specification.

Data Processing and Transformation: You implemented sophisticated data transformation using custom processors, JSON parsing, and data enrichment techniques to convert raw API responses into structure
