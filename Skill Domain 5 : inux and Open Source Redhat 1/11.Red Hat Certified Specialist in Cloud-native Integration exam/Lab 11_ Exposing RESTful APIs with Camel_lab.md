Lab 11: Exposing RESTful APIs with Camel
Objectives
By the end of this lab, you will be able to:

Set up and configure Apache Camel to expose REST APIs using Camel's REST DSL
Define and implement HTTP verbs (GET, POST, PUT, DELETE) for API endpoints
Create a complete RESTful service with proper request/response handling
Test REST APIs using both CURL and Postman
Understand the integration between Camel REST DSL and underlying HTTP components
Implement proper error handling and response formatting for REST services
Prerequisites
Before starting this lab, you should have:

Basic understanding of REST API concepts and HTTP methods
Familiarity with Java programming language
Knowledge of Maven build tool
Understanding of JSON data format
Basic command-line interface skills
Previous experience with Apache Camel routing concepts (recommended)
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your cloud machine includes:

Java 11 or higher
Apache Maven 3.6+
Apache Camel 3.x
Text editor (nano/vim)
CURL command-line tool
All required dependencies pre-installed
Task 1: Set up a Camel Route to Expose a REST API
Subtask 1.1: Create the Project Structure
First, let's create a new Maven project for our Camel REST API.

Open your terminal in the cloud machine
Create a new directory for the project:
mkdir camel-rest-api
cd camel-rest-api
Create the Maven project structure:
mkdir -p src/main/java/com/example/camel
mkdir -p src/main/resources
Subtask 1.2: Create the Maven POM File
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
    <artifactId>camel-rest-api</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <camel.version>3.20.0</camel.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
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

        <!-- Camel REST DSL -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-rest</artifactId>
            <version>${camel.version}</version>
        </dependency>

        <!-- Camel Jetty for HTTP server -->
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

        <!-- Logging -->
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
                <groupId>org.apache.camel</groupId>
                <artifactId>camel-maven-plugin</artifactId>
                <version>${camel.version}</version>
            </plugin>
        </plugins>
    </build>
</project>
Save and exit the file (Ctrl+X, then Y, then Enter).

Subtask 1.3: Create the Data Model
Create a simple User model for our REST API:

nano src/main/java/com/example/camel/User.java
Add the following content:

package com.example.camel;

import com.fasterxml.jackson.annotation.JsonProperty;

public class User {
    @JsonProperty("id")
    private Long id;
    
    @JsonProperty("name")
    private String name;
    
    @JsonProperty("email")
    private String email;
    
    @JsonProperty("age")
    private Integer age;

    // Default constructor
    public User() {}

    // Constructor with parameters
    public User(Long id, String name, String email, Integer age) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.age = age;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public Integer getAge() {
        return age;
    }

    public void setAge(Integer age) {
        this.age = age;
    }

    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", email='" + email + '\'' +
                ", age=" + age +
                '}';
    }
}
Subtask 1.4: Create the User Service
Create a service class to handle user operations:

nano src/main/java/com/example/camel/UserService.java
Add the following content:

package com.example.camel;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

public class UserService {
    private static final Map<Long, User> users = new HashMap<>();
    private static final AtomicLong idGenerator = new AtomicLong(1);

    static {
        // Initialize with some sample data
        users.put(1L, new User(1L, "John Doe", "john.doe@example.com", 30));
        users.put(2L, new User(2L, "Jane Smith", "jane.smith@example.com", 25));
        users.put(3L, new User(3L, "Bob Johnson", "bob.johnson@example.com", 35));
        idGenerator.set(4L);
    }

    public List<User> getAllUsers() {
        return new ArrayList<>(users.values());
    }

    public User getUserById(Long id) {
        return users.get(id);
    }

    public User createUser(User user) {
        Long newId = idGenerator.getAndIncrement();
        user.setId(newId);
        users.put(newId, user);
        return user;
    }

    public User updateUser(Long id, User user) {
        if (users.containsKey(id)) {
            user.setId(id);
            users.put(id, user);
            return user;
        }
        return null;
    }

    public boolean deleteUser(Long id) {
        return users.remove(id) != null;
    }

    public int getUserCount() {
        return users.size();
    }
}
Task 2: Define HTTP Verbs for API Endpoints
Subtask 2.1: Create the Main Camel Route Class
Create the main route builder class that will define our REST endpoints:

nano src/main/java/com/example/camel/UserRestRoute.java
Add the following content:

package com.example.camel;

import org.apache.camel.Exchange;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.rest.RestBindingMode;

public class UserRestRoute extends RouteBuilder {
    
    private UserService userService = new UserService();

    @Override
    public void configure() throws Exception {
        
        // Configure REST configuration
        restConfiguration()
            .component("jetty")
            .host("0.0.0.0")
            .port(8080)
            .bindingMode(RestBindingMode.json)
            .dataFormatProperty("prettyPrint", "true")
            .enableCORS(true)
            .corsHeaderProperty("Access-Control-Allow-Origin", "*")
            .corsHeaderProperty("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
            .corsHeaderProperty("Access-Control-Allow-Headers", "Content-Type, Authorization");

        // Exception handling
        onException(Exception.class)
            .handled(true)
            .setHeader(Exchange.HTTP_RESPONSE_CODE, constant(500))
            .setHeader(Exchange.CONTENT_TYPE, constant("application/json"))
            .setBody(constant("{\"error\": \"Internal server error\", \"message\": \"${exception.message}\"}"));

        // REST API definition
        rest("/api/users")
            .description("User REST service")
            .consumes("application/json")
            .produces("application/json")

            // GET /api/users - Get all users
            .get()
                .description("Get all users")
                .outType(User[].class)
                .responseMessage().code(200).message("Users retrieved successfully").endResponseMessage()
                .to("direct:getAllUsers")

            // GET /api/users/{id} - Get user by ID
            .get("/{id}")
                .description("Get user by ID")
                .param().name("id").type(path).description("User ID").dataType("long").endParam()
                .outType(User.class)
                .responseMessage().code(200).message("User found").endResponseMessage()
                .responseMessage().code(404).message("User not found").endResponseMessage()
                .to("direct:getUserById")

            // POST /api/users - Create new user
            .post()
                .description("Create a new user")
                .type(User.class)
                .outType(User.class)
                .responseMessage().code(201).message("User created successfully").endResponseMessage()
                .responseMessage().code(400).message("Invalid user data").endResponseMessage()
                .to("direct:createUser")

            // PUT /api/users/{id} - Update user
            .put("/{id}")
                .description("Update an existing user")
                .param().name("id").type(path).description("User ID").dataType("long").endParam()
                .type(User.class)
                .outType(User.class)
                .responseMessage().code(200).message("User updated successfully").endResponseMessage()
                .responseMessage().code(404).message("User not found").endResponseMessage()
                .to("direct:updateUser")

            // DELETE /api/users/{id} - Delete user
            .delete("/{id}")
                .description("Delete a user")
                .param().name("id").type(path).description("User ID").dataType("long").endParam()
                .responseMessage().code(204).message("User deleted successfully").endResponseMessage()
                .responseMessage().code(404).message("User not found").endResponseMessage()
                .to("direct:deleteUser");

        // Route implementations
        
        // Get all users route
        from("direct:getAllUsers")
            .log("Getting all users")
            .process(exchange -> {
                exchange.getIn().setBody(userService.getAllUsers());
            });

        // Get user by ID route
        from("direct:getUserById")
            .log("Getting user by ID: ${header.id}")
            .process(exchange -> {
                Long id = Long.valueOf(exchange.getIn().getHeader("id", String.class));
                User user = userService.getUserById(id);
                if (user != null) {
                    exchange.getIn().setBody(user);
                } else {
                    exchange.getIn().setHeader(Exchange.HTTP_RESPONSE_CODE, 404);
                    exchange.getIn().setBody("{\"error\": \"User not found\", \"id\": " + id + "}");
                }
            });

        // Create user route
        from("direct:createUser")
            .log("Creating new user: ${body}")
            .process(exchange -> {
                User user = exchange.getIn().getBody(User.class);
                if (user != null && user.getName() != null && user.getEmail() != null) {
                    User createdUser = userService.createUser(user);
                    exchange.getIn().setHeader(Exchange.HTTP_RESPONSE_CODE, 201);
                    exchange.getIn().setBody(createdUser);
                } else {
                    exchange.getIn().setHeader(Exchange.HTTP_RESPONSE_CODE, 400);
                    exchange.getIn().setBody("{\"error\": \"Invalid user data\", \"message\": \"Name and email are required\"}");
                }
            });

        // Update user route
        from("direct:updateUser")
            .log("Updating user ID: ${header.id}")
            .process(exchange -> {
                Long id = Long.valueOf(exchange.getIn().getHeader("id", String.class));
                User user = exchange.getIn().getBody(User.class);
                if (user != null && user.getName() != null && user.getEmail() != null) {
                    User updatedUser = userService.updateUser(id, user);
                    if (updatedUser != null) {
                        exchange.getIn().setBody(updatedUser);
                    } else {
                        exchange.getIn().setHeader(Exchange.HTTP_RESPONSE_CODE, 404);
                        exchange.getIn().setBody("{\"error\": \"User not found\", \"id\": " + id + "}");
                    }
                } else {
                    exchange.getIn().setHeader(Exchange.HTTP_RESPONSE_CODE, 400);
                    exchange.getIn().setBody("{\"error\": \"Invalid user data\", \"message\": \"Name and email are required\"}");
                }
            });

        // Delete user route
        from("direct:deleteUser")
            .log("Deleting user ID: ${header.id}")
            .process(exchange -> {
                Long id = Long.valueOf(exchange.getIn().getHeader("id", String.class));
                boolean deleted = userService.deleteUser(id);
                if (deleted) {
                    exchange.getIn().setHeader(Exchange.HTTP_RESPONSE_CODE, 204);
                    exchange.getIn().setBody("");
                } else {
                    exchange.getIn().setHeader(Exchange.HTTP_RESPONSE_CODE, 404);
                    exchange.getIn().setBody("{\"error\": \"User not found\", \"id\": " + id + "}");
                }
            });
    }
}
Subtask 2.2: Create the Main Application Class
Create the main class to run the Camel application:

nano src/main/java/com/example/camel/CamelRestApplication.java
Add the following content:

package com.example.camel;

import org.apache.camel.main.Main;

public class CamelRestApplication {
    
    public static void main(String[] args) throws Exception {
        Main main = new Main();
        
        // Add our route
        main.addRouteBuilder(new UserRestRoute());
        
        // Configure main
        main.configure().setDurationMaxMessages(0);
        main.configure().setShutdownTimeout(10);
        
        System.out.println("Starting Camel REST API...");
        System.out.println("API will be available at: http://localhost:8080/api/users");
        System.out.println("Press Ctrl+C to stop the application");
        
        // Start and keep running
        main.run(args);
    }
}
Subtask 2.3: Build and Run the Application
Build the project:
mvn clean compile
Run the application:
mvn exec:java -Dexec.mainClass="com.example.camel.CamelRestApplication"
You should see output indicating that the Camel context has started and the REST API is available.

Note: Keep this terminal window open as the application needs to keep running for testing.

Task 3: Test the API Using CURL and Postman
Subtask 3.1: Test with CURL Commands
Open a new terminal window (keep the application running in the first terminal) and test each endpoint:

Test GET All Users
curl -X GET http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n"
Expected response: List of all users with HTTP status 200.

Test GET User by ID
curl -X GET http://localhost:8080/api/users/1 \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n"
Expected response: User with ID 1 and HTTP status 200.

Test GET Non-existent User
curl -X GET http://localhost:8080/api/users/999 \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n"
Expected response: Error message with HTTP status 404.

Test POST Create New User
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Cooper",
    "email": "alice.cooper@example.com",
    "age": 28
  }' \
  -w "\nHTTP Status: %{http_code}\n"
Expected response: Created user with assigned ID and HTTP status 201.

Test POST with Invalid Data
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "age": 28
  }' \
  -w "\nHTTP Status: %{http_code}\n"
Expected response: Error message with HTTP status 400.

Test PUT Update User
curl -X PUT http://localhost:8080/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Updated",
    "email": "john.updated@example.com",
    "age": 31
  }' \
  -w "\nHTTP Status: %{http_code}\n"
Expected response: Updated user data with HTTP status 200.

Test PUT Non-existent User
curl -X PUT http://localhost:8080/api/users/999 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Non Existent",
    "email": "nonexistent@example.com",
    "age": 25
  }' \
  -w "\nHTTP Status: %{http_code}\n"
Expected response: Error message with HTTP status 404.

Test DELETE User
curl -X DELETE http://localhost:8080/api/users/2 \
  -w "\nHTTP Status: %{http_code}\n"
Expected response: Empty body with HTTP status 204.

Test DELETE Non-existent User
curl -X DELETE http://localhost:8080/api/users/999 \
  -w "\nHTTP Status: %{http_code}\n"
Expected response: Error message with HTTP status 404.

Subtask 3.2: Test with Postman (Alternative Method)
If you prefer using Postman, follow these steps:

Setup Postman Collection
Open Postman (if available in your environment)
Create a new collection called "Camel REST API"
Set the base URL as http://localhost:8080
Create Test Requests
GET All Users

Method: GET
URL: http://localhost:8080/api/users
Headers: Content-Type: application/json
GET User by ID

Method: GET
URL: http://localhost:8080/api/users/1
Headers: Content-Type: application/json
POST Create User

Method: POST
URL: http://localhost:8080/api/users
Headers: Content-Type: application/json
Body (raw JSON):
{
  "name": "Test User",
  "email": "test@example.com",
  "age": 25
}
PUT Update User

Method: PUT
URL: http://localhost:8080/api/users/1
Headers: Content-Type: application/json
Body (raw JSON):
{
  "name": "Updated User",
  "email": "updated@example.com",
  "age": 30
}
DELETE User

Method: DELETE
URL: http://localhost:8080/api/users/3
Subtask 3.3: Verify API Functionality
Create a comprehensive test script to verify all functionality:

nano test-api.sh
Add the following content:

#!/bin/bash

echo "=== Testing Camel REST API ==="
echo

# Test GET all users
echo "1. Testing GET all users:"
curl -s -X GET http://localhost:8080/api/users | jq '.'
echo
echo

# Test GET user by ID
echo "2. Testing GET user by ID (1):"
curl -s -X GET http://localhost:8080/api/users/1 | jq '.'
echo
echo

# Test POST create user
echo "3. Testing POST create user:"
curl -s -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "age": 25
  }' | jq '.'
echo
echo

# Test GET all users again to see the new user
echo "4. Testing GET all users (after creation):"
curl -s -X GET http://localhost:8080/api/users | jq '.'
echo
echo

# Test PUT update user
echo "5. Testing PUT update user (ID 1):"
curl -s -X PUT http://localhost:8080/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Updated",
    "email": "john.updated@example.com",
    "age": 32
  }' | jq '.'
echo
echo

# Test DELETE user
echo "6. Testing DELETE user (ID 2):"
curl -s -X DELETE http://localhost:8080/api/users/2 -w "HTTP Status: %{http_code}\n"
echo
echo

# Test GET all users after deletion
echo "7. Testing GET all users (after deletion):"
curl -s -X GET http://localhost:8080/api/users | jq '.'
echo
echo

# Test error cases
echo "8. Testing GET non-existent user (404):"
curl -s -X GET http://localhost:8080/api/users/999 | jq '.'
echo
echo

echo "=== API Testing Complete ==="
Make the script executable and run it:

chmod +x test-api.sh
./test-api.sh
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Port Already in Use If you get a "port already in use" error:

# Check what's using port 8080
sudo netstat -tulpn | grep :8080

# Kill the process if needed
sudo kill -9 <process_id>
Issue 2: JSON Parsing Errors Ensure your JSON is properly formatted:

# Use jq to validate JSON
echo '{"name":"test"}' | jq '.'
Issue 3: Application Won't Start Check the logs for dependency issues:

# Verify Java version
java -version

# Check Maven dependencies
mvn dependency:tree
Issue 4: CURL Command Not Found If CURL is not available:

# Install CURL (if needed)
sudo apt-get update
sudo apt-get install curl

# Alternative: use wget
wget -qO- --post-data='{"name":"test"}' --header='Content-Type:application/json' http://localhost:8080/api/users
Performance Monitoring
Monitor your API performance:

# Check application logs
tail -f camel-rest-api.log

# Monitor HTTP connections
netstat -an | grep :8080

# Check memory usage
ps aux | grep java
Advanced Features (Optional)
Adding Request Validation
Enhance the UserRestRoute with validation:

// Add validation in the create user route
from("direct:createUser")
    .log("Creating new user: ${body}")
    .choice()
        .when(simple("${body.name} == null || ${body.email} == null"))
            .setHeader(Exchange.HTTP_RESPONSE_CODE, constant(400))
            .setBody(constant("{\"error\": \"Name and email are required\"}"))
        .when(simple("${body.email} not regex '^[A-Za-z0-9+_.-]+@(.+)$'"))
            .setHeader(Exchange.HTTP_RESPONSE_CODE, constant(400))
            .setBody(constant("{\"error\": \"Invalid email format\"}"))
        .otherwise()
            .process(exchange -> {
                User user = exchange.getIn().getBody(User.class);
                User createdUser = userService.createUser(user);
                exchange.getIn().setHeader(Exchange.HTTP_RESPONSE_CODE, 201);
                exchange.getIn().setBody(createdUser);
            });
Adding API Documentation
Add Swagger/OpenAPI documentation by including the camel-swagger-java dependency in your pom.xml:

<dependency>
    <groupId>org.apache.camel</groupId>
    <artifactId>camel-swagger-java</artifactId>
    <version>${camel.version}</version>
</dependency>
Then access the API documentation at: http://localhost:8080/api-doc

Conclusion
Congratulations! You have successfully completed Lab 11: Exposing RESTful APIs with Camel. In this lab, you accomplished the following:

What You Learned
REST API Development with Camel: You learned how to use Apache Camel's REST DSL to create professional RESTful web services with minimal configuration.

HTTP Verb Implementation: You successfully implemented all major HTTP methods (GET, POST, PUT, DELETE) with proper request/response handling and status codes.

JSON Data Handling: You configured automatic JSON serialization/deserialization using Camel's Jackson integration.

Error Handling: You implemented comprehensive error handling with appropriate HTTP status codes and error messages.

API Testing: You mastered testing REST APIs using both CURL commands and structured test scripts.

Why This Matters
Enterprise Integration: RESTful APIs are the backbone of modern enterprise integration, enabling systems to communicate effectively across different platforms and technologies.

Microservices Architecture: The skills you've learned are essential for building microservices that can be easily consumed by web applications, mobile apps, and other services.

Cloud-Native Development: REST APIs are fundamental to cloud-native applications and are required knowledge for the Red Hat Certified Specialist in Cloud-native Integration exam.

Industry Relevance: These skills directly apply to real-world scenarios where you need to expose business logic as consumable web services.

Next Steps
Explore advanced Camel REST features like authentication and authorization
Learn about API versioning strategies
Investigate integration with databases and external services
Study API gateway patterns and implementation
Practice with more complex data models and business logic
You now have the foundation to build robust, production-ready REST APIs using Apache Camel, a skill that's highly valued in modern enterprise development environments.
