Lab 15: Implementing API Gateway Pattern with Camel
Objectives
By the end of this lab, you will be able to:

Understand the API Gateway pattern and its role in microservices architecture
Implement an API Gateway using Apache Camel for API mediation
Configure security mechanisms including authentication and authorization
Implement rate limiting to protect backend services
Set up response aggregation for multiple backend services
Test and evaluate gateway performance under load
Monitor and troubleshoot API Gateway operations
Prerequisites
Before starting this lab, you should have:

Basic understanding of REST APIs and HTTP protocols
Familiarity with Java programming language
Knowledge of Maven build tool
Understanding of microservices architecture concepts
Basic Linux command line skills
Experience with JSON data format
Required Knowledge Areas:
HTTP methods (GET, POST, PUT, DELETE)
Basic authentication concepts
Understanding of load balancing principles
Familiarity with logging and monitoring concepts
Lab Environment Setup
Good News! Al Nafi provides ready-to-use Linux-based cloud machines for this lab. Simply click Start Lab and you'll have access to a fully configured environment with all necessary tools pre-installed.

Your cloud machine includes:

Java 11 OpenJDK
Apache Maven 3.8+
Apache Camel 3.20+
Postman for API testing
curl command-line tool
Text editors (nano, vim)
Task 1: Create API Mediation Routes
Subtask 1.1: Set Up the Project Structure
First, let's create a new Maven project for our API Gateway implementation.

# Navigate to your home directory
cd ~

# Create project directory
mkdir camel-api-gateway
cd camel-api-gateway

# Create Maven project structure
mkdir -p src/main/java/com/example/gateway
mkdir -p src/main/resources
mkdir -p src/test/java
Subtask 1.2: Create Maven Configuration
Create the pom.xml file with necessary dependencies:

nano pom.xml
Add the following content:

<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>camel-api-gateway</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <camel.version>3.20.0</camel.version>
        <spring.boot.version>2.7.0</spring.boot.version>
    </properties>
    
    <dependencies>
        <!-- Camel Spring Boot Starter -->
        <dependency>
            <groupId>org.apache.camel.springboot</groupId>
            <artifactId>camel-spring-boot-starter</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel HTTP Component -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-http</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel Jetty Component -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-jetty</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel Jackson for JSON processing -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-jackson</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Spring Boot Starter Web -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <version>${spring.boot.version}</version>
        </dependency>
        
        <!-- Spring Boot Starter Security -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
            <version>${spring.boot.version}</version>
        </dependency>
        
        <!-- Camel Throttle for Rate Limiting -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-core</artifactId>
            <version>${camel.version}</version>
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
Subtask 1.3: Create Mock Backend Services
Let's create simple mock backend services to simulate real microservices:

nano src/main/java/com/example/gateway/MockBackendRoutes.java
package com.example.gateway;

import org.apache.camel.builder.RouteBuilder;
import org.springframework.stereotype.Component;

@Component
public class MockBackendRoutes extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Mock User Service
        from("jetty:http://0.0.0.0:8081/users?httpMethodRestrict=GET,POST")
            .routeId("user-service")
            .log("Received request for User Service: ${body}")
            .choice()
                .when(header("CamelHttpMethod").isEqualTo("GET"))
                    .setBody(constant("{\"users\": [{\"id\": 1, \"name\": \"John Doe\", \"email\": \"john@example.com\"}, {\"id\": 2, \"name\": \"Jane Smith\", \"email\": \"jane@example.com\"}]}"))
                .when(header("CamelHttpMethod").isEqualTo("POST"))
                    .setBody(constant("{\"message\": \"User created successfully\", \"id\": 3}"))
            .end()
            .setHeader("Content-Type", constant("application/json"));
        
        // Mock Product Service
        from("jetty:http://0.0.0.0:8082/products?httpMethodRestrict=GET,POST")
            .routeId("product-service")
            .log("Received request for Product Service: ${body}")
            .choice()
                .when(header("CamelHttpMethod").isEqualTo("GET"))
                    .setBody(constant("{\"products\": [{\"id\": 1, \"name\": \"Laptop\", \"price\": 999.99}, {\"id\": 2, \"name\": \"Mouse\", \"price\": 29.99}]}"))
                .when(header("CamelHttpMethod").isEqualTo("POST"))
                    .setBody(constant("{\"message\": \"Product created successfully\", \"id\": 3}"))
            .end()
            .setHeader("Content-Type", constant("application/json"));
        
        // Mock Order Service
        from("jetty:http://0.0.0.0:8083/orders?httpMethodRestrict=GET,POST")
            .routeId("order-service")
            .log("Received request for Order Service: ${body}")
            .choice()
                .when(header("CamelHttpMethod").isEqualTo("GET"))
                    .setBody(constant("{\"orders\": [{\"id\": 1, \"userId\": 1, \"productId\": 1, \"quantity\": 2, \"total\": 1999.98}]}"))
                .when(header("CamelHttpMethod").isEqualTo("POST"))
                    .setBody(constant("{\"message\": \"Order created successfully\", \"id\": 2}"))
            .end()
            .setHeader("Content-Type", constant("application/json"));
    }
}
Subtask 1.4: Create API Gateway Routes
Now, let's create the main API Gateway routes that will mediate requests:

nano src/main/java/com/example/gateway/ApiGatewayRoutes.java
package com.example.gateway;

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.rest.RestBindingMode;
import org.springframework.stereotype.Component;

@Component
public class ApiGatewayRoutes extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Configure REST DSL
        restConfiguration()
            .component("jetty")
            .host("0.0.0.0")
            .port(8080)
            .bindingMode(RestBindingMode.json)
            .enableCORS(true);
        
        // API Gateway Routes
        rest("/api/v1")
            .get("/users")
                .to("direct:get-users")
            .post("/users")
                .to("direct:create-user")
            .get("/products")
                .to("direct:get-products")
            .post("/products")
                .to("direct:create-product")
            .get("/orders")
                .to("direct:get-orders")
            .post("/orders")
                .to("direct:create-order")
            .get("/dashboard")
                .to("direct:aggregate-dashboard");
        
        // Route implementations with mediation logic
        from("direct:get-users")
            .routeId("gateway-get-users")
            .log("Gateway: Routing GET /users request")
            .removeHeaders("CamelHttp*")
            .setHeader("CamelHttpMethod", constant("GET"))
            .to("http://localhost:8081/users?bridgeEndpoint=true")
            .log("Gateway: Response from User Service: ${body}");
        
        from("direct:create-user")
            .routeId("gateway-create-user")
            .log("Gateway: Routing POST /users request")
            .removeHeaders("CamelHttp*")
            .setHeader("CamelHttpMethod", constant("POST"))
            .to("http://localhost:8081/users?bridgeEndpoint=true")
            .log("Gateway: Response from User Service: ${body}");
        
        from("direct:get-products")
            .routeId("gateway-get-products")
            .log("Gateway: Routing GET /products request")
            .removeHeaders("CamelHttp*")
            .setHeader("CamelHttpMethod", constant("GET"))
            .to("http://localhost:8082/products?bridgeEndpoint=true")
            .log("Gateway: Response from Product Service: ${body}");
        
        from("direct:create-product")
            .routeId("gateway-create-product")
            .log("Gateway: Routing POST /products request")
            .removeHeaders("CamelHttp*")
            .setHeader("CamelHttpMethod", constant("POST"))
            .to("http://localhost:8082/products?bridgeEndpoint=true")
            .log("Gateway: Response from Product Service: ${body}");
        
        from("direct:get-orders")
            .routeId("gateway-get-orders")
            .log("Gateway: Routing GET /orders request")
            .removeHeaders("CamelHttp*")
            .setHeader("CamelHttpMethod", constant("GET"))
            .to("http://localhost:8083/orders?bridgeEndpoint=true")
            .log("Gateway: Response from Order Service: ${body}");
        
        from("direct:create-order")
            .routeId("gateway-create-order")
            .log("Gateway: Routing POST /orders request")
            .removeHeaders("CamelHttp*")
            .setHeader("CamelHttpMethod", constant("POST"))
            .to("http://localhost:8083/orders?bridgeEndpoint=true")
            .log("Gateway: Response from Order Service: ${body}");
    }
}
Subtask 1.5: Create Application Main Class
Create the Spring Boot application main class:

nano src/main/java/com/example/gateway/ApiGatewayApplication.java
package com.example.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ApiGatewayApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(ApiGatewayApplication.class, args);
    }
}
Task 2: Implement Security and Rate Limiting
Subtask 2.1: Configure Basic Authentication
Create a security configuration class:

nano src/main/java/com/example/gateway/SecurityConfig.java
package com.example.gateway;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf().disable()
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/api/v1/users/**").hasRole("USER")
                .requestMatchers("/api/v1/products/**").hasRole("USER")
                .requestMatchers("/api/v1/orders/**").hasRole("ADMIN")
                .requestMatchers("/api/v1/dashboard/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .httpBasic();
        
        return http.build();
    }
    
    @Bean
    public UserDetailsService userDetailsService() {
        UserDetails user = User.builder()
            .username("user")
            .password(passwordEncoder().encode("password"))
            .roles("USER")
            .build();
        
        UserDetails admin = User.builder()
            .username("admin")
            .password(passwordEncoder().encode("admin"))
            .roles("USER", "ADMIN")
            .build();
        
        return new InMemoryUserDetailsManager(user, admin);
    }
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
Subtask 2.2: Implement Rate Limiting
Create a rate limiting component using Camel's throttling capabilities:

nano src/main/java/com/example/gateway/RateLimitingRoutes.java
package com.example.gateway;

import org.apache.camel.builder.RouteBuilder;
import org.springframework.stereotype.Component;

@Component
public class RateLimitingRoutes extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Enhanced API Gateway Routes with Rate Limiting
        from("direct:get-users")
            .routeId("gateway-get-users-with-throttle")
            .throttle(10).timePeriodMillis(60000) // 10 requests per minute
            .log("Gateway: Routing GET /users request (Rate Limited)")
            .removeHeaders("CamelHttp*")
            .setHeader("CamelHttpMethod", constant("GET"))
            .doTry()
                .to("http://localhost:8081/users?bridgeEndpoint=true&connectTimeout=5000&socketTimeout=10000")
                .log("Gateway: Response from User Service: ${body}")
            .doCatch(Exception.class)
                .log("Gateway: Error calling User Service: ${exception.message}")
                .setBody(constant("{\"error\": \"Service temporarily unavailable\"}"))
                .setHeader("Content-Type", constant("application/json"))
                .setHeader("CamelHttpResponseCode", constant(503))
            .end();
        
        from("direct:get-products")
            .routeId("gateway-get-products-with-throttle")
            .throttle(15).timePeriodMillis(60000) // 15 requests per minute
            .log("Gateway: Routing GET /products request (Rate Limited)")
            .removeHeaders("CamelHttp*")
            .setHeader("CamelHttpMethod", constant("GET"))
            .doTry()
                .to("http://localhost:8082/products?bridgeEndpoint=true&connectTimeout=5000&socketTimeout=10000")
                .log("Gateway: Response from Product Service: ${body}")
            .doCatch(Exception.class)
                .log("Gateway: Error calling Product Service: ${exception.message}")
                .setBody(constant("{\"error\": \"Service temporarily unavailable\"}"))
                .setHeader("Content-Type", constant("application/json"))
                .setHeader("CamelHttpResponseCode", constant(503))
            .end();
        
        from("direct:get-orders")
            .routeId("gateway-get-orders-with-throttle")
            .throttle(5).timePeriodMillis(60000) // 5 requests per minute (more restrictive)
            .log("Gateway: Routing GET /orders request (Rate Limited)")
            .removeHeaders("CamelHttp*")
            .setHeader("CamelHttpMethod", constant("GET"))
            .doTry()
                .to("http://localhost:8083/orders?bridgeEndpoint=true&connectTimeout=5000&socketTimeout=10000")
                .log("Gateway: Response from Order Service: ${body}")
            .doCatch(Exception.class)
                .log("Gateway: Error calling Order Service: ${exception.message}")
                .setBody(constant("{\"error\": \"Service temporarily unavailable\"}"))
                .setHeader("Content-Type", constant("application/json"))
                .setHeader("CamelHttpResponseCode", constant(503))
            .end();
    }
}
Subtask 2.3: Implement Response Aggregation
Create routes for aggregating responses from multiple services:

nano src/main/java/com/example/gateway/AggregationRoutes.java
package com.example.gateway;

import org.apache.camel.AggregationStrategy;
import org.apache.camel.Exchange;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.processor.aggregate.GroupedBodyAggregationStrategy;
import org.springframework.stereotype.Component;

@Component
public class AggregationRoutes extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Dashboard aggregation route
        from("direct:aggregate-dashboard")
            .routeId("dashboard-aggregation")
            .log("Gateway: Aggregating dashboard data")
            .multicast(new DashboardAggregationStrategy())
            .parallelProcessing()
            .to("direct:fetch-users-for-dashboard")
            .to("direct:fetch-products-for-dashboard")
            .to("direct:fetch-orders-for-dashboard")
            .end()
            .log("Gateway: Dashboard aggregation complete: ${body}");
        
        // Individual service calls for dashboard
        from("direct:fetch-users-for-dashboard")
            .routeId("fetch-users-dashboard")
            .removeHeaders("CamelHttp*")
            .setHeader("CamelHttpMethod", constant("GET"))
            .doTry()
                .to("http://localhost:8081/users?bridgeEndpoint=true&connectTimeout=3000&socketTimeout=5000")
                .setProperty("serviceType", constant("users"))
            .doCatch(Exception.class)
                .log("Error fetching users for dashboard: ${exception.message}")
                .setBody(constant("{\"users\": [], \"error\": \"Service unavailable\"}"))
                .setProperty("serviceType", constant("users"))
            .end();
        
        from("direct:fetch-products-for-dashboard")
            .routeId("fetch-products-dashboard")
            .removeHeaders("CamelHttp*")
            .setHeader("CamelHttpMethod", constant("GET"))
            .doTry()
                .to("http://localhost:8082/products?bridgeEndpoint=true&connectTimeout=3000&socketTimeout=5000")
                .setProperty("serviceType", constant("products"))
            .doCatch(Exception.class)
                .log("Error fetching products for dashboard: ${exception.message}")
                .setBody(constant("{\"products\": [], \"error\": \"Service unavailable\"}"))
                .setProperty("serviceType", constant("products"))
            .end();
        
        from("direct:fetch-orders-for-dashboard")
            .routeId("fetch-orders-dashboard")
            .removeHeaders("CamelHttp*")
            .setHeader("CamelHttpMethod", constant("GET"))
            .doTry()
                .to("http://localhost:8083/orders?bridgeEndpoint=true&connectTimeout=3000&socketTimeout=5000")
                .setProperty("serviceType", constant("orders"))
            .doCatch(Exception.class)
                .log("Error fetching orders for dashboard: ${exception.message}")
                .setBody(constant("{\"orders\": [], \"error\": \"Service unavailable\"}"))
                .setProperty("serviceType", constant("orders"))
            .end();
    }
    
    // Custom aggregation strategy for dashboard data
    public static class DashboardAggregationStrategy implements AggregationStrategy {
        
        @Override
        public Exchange aggregate(Exchange oldExchange, Exchange newExchange) {
            if (oldExchange == null) {
                // First exchange - initialize the aggregated body
                String serviceType = newExchange.getProperty("serviceType", String.class);
                String responseBody = newExchange.getIn().getBody(String.class);
                
                String aggregatedBody = String.format(
                    "{\"dashboard\": {\"%s\": %s}}", 
                    serviceType, responseBody
                );
                
                newExchange.getIn().setBody(aggregatedBody);
                return newExchange;
            } else {
                // Subsequent exchanges - merge with existing data
                String existingBody = oldExchange.getIn().getBody(String.class);
                String serviceType = newExchange.getProperty("serviceType", String.class);
                String responseBody = newExchange.getIn().getBody(String.class);
                
                // Simple JSON merging (in production, use proper JSON library)
                String mergedBody = existingBody.substring(0, existingBody.length() - 2) + 
                    String.format(", \"%s\": %s}}", serviceType, responseBody);
                
                oldExchange.getIn().setBody(mergedBody);
                return oldExchange;
            }
        }
    }
}
Subtask 2.4: Create Application Properties
Create the application configuration file:

nano src/main/resources/application.properties
# Server Configuration
server.port=8080
management.endpoints.web.exposure.include=health,info,metrics

# Logging Configuration
logging.level.com.example.gateway=INFO
logging.level.org.apache.camel=INFO
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} - %msg%n

# Camel Configuration
camel.springboot.name=ApiGateway
camel.springboot.main-run-controller=true
camel.component.http.connect-timeout=5000
camel.component.http.socket-timeout=10000

# Security Configuration
spring.security.user.name=admin
spring.security.user.password=admin
spring.security.user.roles=ADMIN
Task 3: Test Gateway Performance
Subtask 3.1: Build and Run the Application
First, let's build and start our API Gateway:

# Build the application
mvn clean compile

# Run the application
mvn spring-boot:run
Note: The application will start on port 8080 (API Gateway) and also start mock services on ports 8081, 8082, and 8083.

Subtask 3.2: Basic Functionality Testing
Open a new terminal window and test the basic functionality:

# Test User Service through Gateway (requires authentication)
curl -u user:password http://localhost:8080/api/v1/users

# Test Product Service through Gateway
curl -u user:password http://localhost:8080/api/v1/products

# Test Order Service through Gateway (requires admin role)
curl -u admin:admin http://localhost:8080/api/v1/orders

# Test Dashboard Aggregation (requires admin role)
curl -u admin:admin http://localhost:8080/api/v1/dashboard
Subtask 3.3: Rate Limiting Testing
Create a script to test rate limiting:

nano test-rate-limiting.sh
#!/bin/bash

echo "Testing Rate Limiting for User Service (10 requests/minute limit)"
echo "=================================================="

for i in {1..15}; do
    echo "Request $i:"
    response=$(curl -s -w "HTTP Status: %{http_code}\n" -u user:password http://localhost:8080/api/v1/users)
    echo "$response"
    echo "---"
    sleep 2
done

echo "Testing Rate Limiting for Product Service (15 requests/minute limit)"
echo "====================================================="

for i in {1..20}; do
    echo "Request $i:"
    response=$(curl -s -w "HTTP Status: %{http_code}\n" -u user:password http://localhost:8080/api/v1/products)
    echo "$response"
    echo "---"
    sleep 1
done
Make the script executable and run it:

chmod +x test-rate-limiting.sh
./test-rate-limiting.sh
Subtask 3.4: Performance Testing with Load
Create a performance testing script:

nano performance-test.sh
#!/bin/bash

echo "Performance Testing - Concurrent Requests"
echo "========================================"

# Function to make concurrent requests
make_requests() {
    local endpoint=$1
    local auth=$2
    local count=$3
    
    echo "Testing $endpoint with $count concurrent requests"
    
    for i in $(seq 1 $count); do
        (
            start_time=$(date +%s%N)
            response=$(curl -s -w "%{http_code}" -u $auth http://localhost:8080$endpoint)
            end_time=$(date +%s%N)
            duration=$(( (end_time - start_time) / 1000000 ))
            echo "Request $i: HTTP $response, Duration: ${duration}ms"
        ) &
    done
    
    wait
    echo "Completed $count requests to $endpoint"
    echo "---"
}

# Test different endpoints with concurrent requests
make_requests "/api/v1/users" "user:password" 5
make_requests "/api/v1/products" "user:password" 5
make_requests "/api/v1/orders" "admin:admin" 3
make_requests "/api/v1/dashboard" "admin:admin" 2

echo "Performance testing completed!"
Make it executable and run:

chmod +x performance-test.sh
./performance-test.sh
Subtask 3.5: Monitor Application Metrics
Check application health and metrics:

# Check application health
curl http://localhost:8080/actuator/health

# Check application info
curl http://localhost:8080/actuator/info

# Check metrics (if available)
curl http://localhost:8080/actuator/metrics
Subtask 3.6: Test Error Handling
Test how the gateway handles backend service failures:

# Stop one of the mock services by killing the process
# (In a separate terminal, find the process and stop it)
ps aux | grep java

# Test the gateway response when a service is down
curl -u user:password http://localhost:8080/api/v1/users

# The gateway should return a 503 Service Unavailable response
Subtask 3.7: Security Testing
Test the security implementation:

# Test without authentication (should fail)
curl http://localhost:8080/api/v1/users

# Test with wrong credentials (should fail)
curl -u wronguser:wrongpass http://localhost:8080/api/v1/users

# Test user trying to access admin endpoint (should fail)
curl -u user:password http://localhost:8080/api/v1/orders

# Test successful admin access
curl -u admin:admin http://localhost:8080/api/v1/orders
Troubleshooting Common Issues
Issue 1: Port Already in Use
If you encounter port binding errors:

# Check what's using the port
sudo netstat -tulpn | grep :8080

# Kill the process if needed
sudo kill -9 <process_id>
Issue 2: Maven Build Failures
If Maven build fails:

# Clean and rebuild
mvn clean install -U

# Check Java version
java -version

# Ensure JAVA_HOME is set correctly
echo $JAVA_HOME
Issue 3: Authentication Issues
If authentication doesn't work:

Check that Spring Security is properly configured
Verify user credentials in SecurityConfig.java
Check application logs for security-related errors
Issue 4: Rate Limiting Not Working
If rate limiting seems ineffective:

Verify the throttle configuration in routes
Check that requests are going through the correct routes
Monitor application logs for throttling messages
Performance Analysis and Optimization
Key Performance Metrics to Monitor
Response Time: Average time for requests to complete
Throughput: Number of requests processed per second
Error Rate: Percentage of failed requests
Resource Utilization: CPU and memory usage
Optimization Strategies
Connection Pooling: Configure HTTP client connection pools
Caching: Implement response caching for frequently requested data
Circuit Breaker: Add circuit breaker pattern for resilience
Load Balancing: Distribute requests across multiple backend instances
Conclusion
Congratulations! You have successfully implemented a comprehensive API Gateway using Apache Camel. Here's what you accomplished:

Key Achievements
API Mediation: Created routes that mediate requests between clients and backend services, providing a single entry point for your microservices architecture.

Security Implementation: Implemented role-based authentication and authorization using Spring Security, ensuring that only authorized users can access specific endpoints.

Rate Limiting: Added throttling mechanisms to protect backend services from being overwhelmed by too many requests, implementing different limits for different services based on their capacity.

Response Aggregation: Built a dashboard endpoint that aggregates data from multiple backend services, demonstrating how an API Gateway can compose responses from multiple sources.

Error Handling: Implemented robust error handling with proper HTTP status codes and fallback responses when backend services are unavailable.

Performance Testing: Created comprehensive tests to evaluate the gateway's performance under various load conditions and validated the rate limiting functionality.

Why This Matters
The API Gateway pattern is crucial in modern microservices architectures because it:

Simplifies Client Integration: Clients only need to know about one endpoint instead of multiple service endpoints
Provides Cross-Cutting Concerns: Handles authentication, rate limiting, logging, and monitoring in one place
Enables Service Evolution: Backend services can change without affecting clients
Improves Security: Centralizes security policies and reduces the attack surface
Enhances Observability: Provides a single point for monitoring and logging all API traffic
Real-World Applications
This API Gateway implementation can be extended for production use by adding:

Service Discovery: Integration with service registries like Consul or Eureka
**Advanced Load Bal
