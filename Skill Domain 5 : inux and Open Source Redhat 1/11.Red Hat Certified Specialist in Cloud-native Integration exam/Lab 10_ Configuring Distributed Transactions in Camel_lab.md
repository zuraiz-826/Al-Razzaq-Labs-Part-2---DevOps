Lab 10: Configuring Distributed Transactions in Camel
Objectives
By the end of this lab, you will be able to:

Understand the fundamentals of distributed transactions in Apache Camel
Configure and implement distributed transactions using Camel's transacted() method
Set up transaction managers for coordinating distributed transactions
Test transaction behavior with both rollback and commit scenarios
Handle transaction failures and implement proper error handling
Monitor and troubleshoot distributed transaction issues
Prerequisites
Before starting this lab, you should have:

Basic understanding of Apache Camel concepts and routing
Familiarity with Java programming and Maven build tool
Knowledge of database operations and JDBC
Understanding of transaction concepts (ACID properties)
Experience with Spring Framework basics
Familiarity with JMS messaging concepts
Required Knowledge Areas:
Apache Camel: Route building, endpoints, processors
Java: Basic syntax, exception handling, annotations
Databases: SQL operations, connection management
Transactions: Atomicity, consistency, isolation, durability
Lab Environment Setup
Good News! Al Nafi provides ready-to-use Linux-based cloud machines for this lab. Simply click Start Lab and you'll have access to a pre-configured environment with all necessary tools installed.

Pre-installed Tools:
OpenJDK 11
Apache Maven 3.8+
Apache Camel 3.20+
H2 Database
Apache ActiveMQ
Spring Boot 2.7+
Task 1: Setting Up the Distributed Transaction Environment
Subtask 1.1: Create the Maven Project Structure
First, let's create a new Maven project for our distributed transaction lab.

# Navigate to your workspace
cd /home/student/workspace

# Create the project directory
mkdir camel-distributed-transactions
cd camel-distributed-transactions

# Create the Maven project structure
mkdir -p src/main/java/com/alnafi/camel/transactions
mkdir -p src/main/resources
mkdir -p src/test/java
Subtask 1.2: Configure the Project Dependencies
Create the pom.xml file with all necessary dependencies:

<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.alnafi.camel</groupId>
    <artifactId>camel-distributed-transactions</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <camel.version>3.20.2</camel.version>
        <spring.boot.version>2.7.8</spring.boot.version>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-dependencies</artifactId>
                <version>${spring.boot.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
            <dependency>
                <groupId>org.apache.camel.springboot</groupId>
                <artifactId>camel-spring-boot-bom</artifactId>
                <version>${camel.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <dependencies>
        <!-- Spring Boot Starter -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>

        <!-- Camel Spring Boot Starter -->
        <dependency>
            <groupId>org.apache.camel.springboot</groupId>
            <artifactId>camel-spring-boot-starter</artifactId>
        </dependency>

        <!-- Camel JTA Support -->
        <dependency>
            <groupId>org.apache.camel.springboot</groupId>
            <artifactId>camel-jta-starter</artifactId>
        </dependency>

        <!-- Camel JDBC Support -->
        <dependency>
            <groupId>org.apache.camel.springboot</groupId>
            <artifactId>camel-jdbc-starter</artifactId>
        </dependency>

        <!-- Camel JMS Support -->
        <dependency>
            <groupId>org.apache.camel.springboot</groupId>
            <artifactId>camel-jms-starter</artifactId>
        </dependency>

        <!-- Camel SQL Support -->
        <dependency>
            <groupId>org.apache.camel.springboot</groupId>
            <artifactId>camel-sql-starter</artifactId>
        </dependency>

        <!-- H2 Database -->
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
        </dependency>

        <!-- ActiveMQ -->
        <dependency>
            <groupId>org.apache.activemq</groupId>
            <artifactId>activemq-broker</artifactId>
        </dependency>

        <!-- Atomikos Transaction Manager -->
        <dependency>
            <groupId>com.atomikos</groupId>
            <artifactId>transactions-spring-boot-starter</artifactId>
            <version>5.0.9</version>
        </dependency>

        <!-- Spring Boot Test -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
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
Subtask 1.3: Configure Application Properties
Create the src/main/resources/application.yml file:

server:
  port: 8080

spring:
  application:
    name: camel-distributed-transactions
  
  # H2 Database Configuration
  datasource:
    url: jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
    driver-class-name: org.h2.Driver
    username: sa
    password: password
  
  h2:
    console:
      enabled: true
      path: /h2-console

# Camel Configuration
camel:
  springboot:
    name: CamelDistributedTransactions
  component:
    jms:
      connection-factory: "#jmsConnectionFactory"

# Atomikos Transaction Manager Configuration
atomikos:
  properties:
    enable-logging: true
    log-base-name: tmlog
    log-base-dir: ./logs
    checkpoint-interval: 500

# Logging Configuration
logging:
  level:
    com.alnafi.camel: DEBUG
    org.apache.camel: INFO
    com.atomikos: DEBUG
  pattern:
    console: "%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n"
Task 2: Implementing Distributed Transactions with Camel's transacted() Method
Subtask 2.1: Create the Main Application Class
Create src/main/java/com/alnafi/camel/transactions/CamelTransactionApplication.java:

package com.alnafi.camel.transactions;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class CamelTransactionApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(CamelTransactionApplication.class, args);
    }
}
Subtask 2.2: Configure Transaction Manager and Data Sources
Create src/main/java/com/alnafi/camel/transactions/config/TransactionConfig.java:

package com.alnafi.camel.transactions.config;

import com.atomikos.icatch.jta.UserTransactionImp;
import com.atomikos.icatch.jta.UserTransactionManager;
import com.atomikos.jdbc.AtomikosDataSourceBean;
import org.apache.activemq.ActiveMQXAConnectionFactory;
import org.apache.camel.component.jms.JmsComponent;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.transaction.jta.JtaTransactionManager;

import javax.jms.ConnectionFactory;
import javax.sql.DataSource;
import javax.transaction.UserTransaction;
import java.util.Properties;

@Configuration
public class TransactionConfig {

    @Bean(name = "atomikosTransactionManager")
    @Primary
    public JtaTransactionManager transactionManager() throws Exception {
        UserTransactionManager userTransactionManager = new UserTransactionManager();
        userTransactionManager.setForceShutdown(false);
        
        UserTransaction userTransaction = new UserTransactionImp();
        
        JtaTransactionManager jtaTransactionManager = new JtaTransactionManager();
        jtaTransactionManager.setTransactionManager(userTransactionManager);
        jtaTransactionManager.setUserTransaction(userTransaction);
        
        return jtaTransactionManager;
    }

    @Bean(name = "xaDataSource")
    public DataSource xaDataSource() {
        AtomikosDataSourceBean dataSource = new AtomikosDataSourceBean();
        dataSource.setUniqueResourceName("h2XADataSource");
        dataSource.setXaDataSourceClassName("org.h2.jdbcx.JdbcDataSource");
        
        Properties properties = new Properties();
        properties.setProperty("URL", "jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE");
        properties.setProperty("user", "sa");
        properties.setProperty("password", "password");
        
        dataSource.setXaProperties(properties);
        dataSource.setPoolSize(5, 10);
        
        return dataSource;
    }

    @Bean(name = "jmsConnectionFactory")
    public ConnectionFactory jmsConnectionFactory() {
        ActiveMQXAConnectionFactory connectionFactory = new ActiveMQXAConnectionFactory();
        connectionFactory.setBrokerURL("vm://localhost?broker.persistent=false");
        connectionFactory.setUserName("admin");
        connectionFactory.setPassword("admin");
        return connectionFactory;
    }

    @Bean(name = "jms")
    public JmsComponent jmsComponent() throws Exception {
        JmsComponent jmsComponent = new JmsComponent();
        jmsComponent.setConnectionFactory(jmsConnectionFactory());
        jmsComponent.setTransactionManager(transactionManager());
        jmsComponent.setTransacted(true);
        return jmsComponent;
    }
}
Subtask 2.3: Create Database Schema and Sample Data
Create src/main/resources/schema.sql:

-- Create tables for our transaction demo
CREATE TABLE IF NOT EXISTS orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    quantity INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS inventory (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL UNIQUE,
    available_quantity INTEGER NOT NULL,
    reserved_quantity INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    operation VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id BIGINT,
    details VARCHAR(500),
    transaction_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample inventory data
INSERT INTO inventory (product_name, available_quantity) VALUES 
('Laptop', 10),
('Mouse', 50),
('Keyboard', 25),
('Monitor', 8);
Subtask 2.4: Create Data Transfer Objects
Create src/main/java/com/alnafi/camel/transactions/model/Order.java:

package com.alnafi.camel.transactions.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class Order {
    private Long id;
    private String customerName;
    private String productName;
    private Integer quantity;
    private BigDecimal price;
    private String status;
    private LocalDateTime createdAt;

    // Constructors
    public Order() {}

    public Order(String customerName, String productName, Integer quantity, BigDecimal price) {
        this.customerName = customerName;
        this.productName = productName;
        this.quantity = quantity;
        this.price = price;
        this.status = "PENDING";
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }

    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    @Override
    public String toString() {
        return "Order{" +
                "id=" + id +
                ", customerName='" + customerName + '\'' +
                ", productName='" + productName + '\'' +
                ", quantity=" + quantity +
                ", price=" + price +
                ", status='" + status + '\'' +
                '}';
    }
}
Subtask 2.5: Create the Distributed Transaction Route
Create src/main/java/com/alnafi/camel/transactions/routes/OrderProcessingRoute.java:

package com.alnafi.camel.transactions.routes;

import com.alnafi.camel.transactions.model.Order;
import com.alnafi.camel.transactions.processor.InventoryProcessor;
import com.alnafi.camel.transactions.processor.OrderProcessor;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.dataformat.JsonLibrary;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class OrderProcessingRoute extends RouteBuilder {

    @Autowired
    private OrderProcessor orderProcessor;

    @Autowired
    private InventoryProcessor inventoryProcessor;

    @Override
    public void configure() throws Exception {

        // Main order processing route with distributed transaction
        from("jms:queue:orders")
            .routeId("orderProcessingRoute")
            .log("Received order: ${body}")
            .transacted("atomikosTransactionManager")
            .unmarshal().json(JsonLibrary.Jackson, Order.class)
            .to("direct:validateOrder")
            .to("direct:processOrder")
            .to("direct:updateInventory")
            .to("direct:sendConfirmation")
            .log("Order processed successfully: ${body}");

        // Order validation route
        from("direct:validateOrder")
            .routeId("validateOrderRoute")
            .log("Validating order: ${body}")
            .process(orderProcessor)
            .choice()
                .when(header("orderValid").isEqualTo(false))
                    .log("Order validation failed: ${header.validationError}")
                    .throwException(new IllegalArgumentException("Order validation failed"))
                .otherwise()
                    .log("Order validation passed");

        // Order processing route
        from("direct:processOrder")
            .routeId("processOrderRoute")
            .log("Processing order in database")
            .setHeader("orderId", simple("${body.id}"))
            .to("sql:INSERT INTO orders (customer_name, product_name, quantity, price, status) " +
                "VALUES (:#${body.customerName}, :#${body.productName}, :#${body.quantity}, :#${body.price}, 'PROCESSING')" +
                "?dataSource=#xaDataSource")
            .to("sql:INSERT INTO audit_log (operation, table_name, details, transaction_id) " +
                "VALUES ('INSERT', 'orders', 'Order created', '${exchangeId}')" +
                "?dataSource=#xaDataSource")
            .log("Order saved to database");

        // Inventory update route
        from("direct:updateInventory")
            .routeId("updateInventoryRoute")
            .log("Updating inventory for product: ${body.productName}")
            .process(inventoryProcessor)
            .choice()
                .when(header("inventoryAvailable").isEqualTo(false))
                    .log("Insufficient inventory for product: ${body.productName}")
                    .to("sql:INSERT INTO audit_log (operation, table_name, details, transaction_id) " +
                        "VALUES ('ERROR', 'inventory', 'Insufficient inventory', '${exchangeId}')" +
                        "?dataSource=#xaDataSource")
                    .throwException(new RuntimeException("Insufficient inventory"))
                .otherwise()
                    .to("sql:UPDATE inventory SET available_quantity = available_quantity - :#${body.quantity}, " +
                        "reserved_quantity = reserved_quantity + :#${body.quantity} " +
                        "WHERE product_name = :#${body.productName}" +
                        "?dataSource=#xaDataSource")
                    .to("sql:INSERT INTO audit_log (operation, table_name, details, transaction_id) " +
                        "VALUES ('UPDATE', 'inventory', 'Inventory updated', '${exchangeId}')" +
                        "?dataSource=#xaDataSource")
                    .log("Inventory updated successfully");

        // Confirmation route
        from("direct:sendConfirmation")
            .routeId("sendConfirmationRoute")
            .log("Sending order confirmation")
            .setBody(simple("Order confirmed for customer: ${body.customerName}, Product: ${body.productName}"))
            .to("jms:queue:confirmations")
            .to("sql:UPDATE orders SET status = 'CONFIRMED' WHERE customer_name = :#${body.customerName} " +
                "AND product_name = :#${body.productName} AND status = 'PROCESSING'" +
                "?dataSource=#xaDataSource")
            .log("Order confirmation sent");

        // Error handling route
        onException(Exception.class)
            .handled(true)
            .log("Transaction failed, rolling back: ${exception.message}")
            .to("sql:INSERT INTO audit_log (operation, table_name, details, transaction_id) " +
                "VALUES ('ROLLBACK', 'transaction', '${exception.message}', '${exchangeId}')" +
                "?dataSource=#xaDataSource")
            .setBody(simple("Order processing failed: ${exception.message}"))
            .to("jms:queue:errors");
    }
}
Subtask 2.6: Create Processing Components
Create src/main/java/com/alnafi/camel/transactions/processor/OrderProcessor.java:

package com.alnafi.camel.transactions.processor;

import com.alnafi.camel.transactions.model.Order;
import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

@Component
public class OrderProcessor implements Processor {

    @Override
    public void process(Exchange exchange) throws Exception {
        Order order = exchange.getIn().getBody(Order.class);
        
        // Validate order
        boolean isValid = true;
        String validationError = null;
        
        if (order.getCustomerName() == null || order.getCustomerName().trim().isEmpty()) {
            isValid = false;
            validationError = "Customer name is required";
        } else if (order.getProductName() == null || order.getProductName().trim().isEmpty()) {
            isValid = false;
            validationError = "Product name is required";
        } else if (order.getQuantity() == null || order.getQuantity() <= 0) {
            isValid = false;
            validationError = "Quantity must be greater than 0";
        } else if (order.getPrice() == null || order.getPrice().compareTo(BigDecimal.ZERO) <= 0) {
            isValid = false;
            validationError = "Price must be greater than 0";
        }
        
        exchange.getIn().setHeader("orderValid", isValid);
        if (!isValid) {
            exchange.getIn().setHeader("validationError", validationError);
        }
        
        // Set order ID for tracking
        if (order.getId() == null) {
            order.setId(System.currentTimeMillis());
        }
    }
}
Create src/main/java/com/alnafi/camel/transactions/processor/InventoryProcessor.java:

package com.alnafi.camel.transactions.processor;

import com.alnafi.camel.transactions.model.Order;
import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;

@Component
public class InventoryProcessor implements Processor {

    @Autowired
    private DataSource xaDataSource;

    @Override
    public void process(Exchange exchange) throws Exception {
        Order order = exchange.getIn().getBody(Order.class);
        JdbcTemplate jdbcTemplate = new JdbcTemplate(xaDataSource);
        
        // Check inventory availability
        String sql = "SELECT available_quantity FROM inventory WHERE product_name = ?";
        
        try {
            Integer availableQuantity = jdbcTemplate.queryForObject(sql, Integer.class, order.getProductName());
            
            boolean inventoryAvailable = availableQuantity != null && availableQuantity >= order.getQuantity();
            exchange.getIn().setHeader("inventoryAvailable", inventoryAvailable);
            exchange.getIn().setHeader("availableQuantity", availableQuantity);
            
            if (!inventoryAvailable) {
                exchange.getIn().setHeader("inventoryError", 
                    String.format("Insufficient inventory. Available: %d, Requested: %d", 
                        availableQuantity != null ? availableQuantity : 0, order.getQuantity()));
            }
        } catch (Exception e) {
            exchange.getIn().setHeader("inventoryAvailable", false);
            exchange.getIn().setHeader("inventoryError", "Product not found in inventory");
        }
    }
}
Task 3: Testing Transaction Behavior with Rollback and Commit Logic
Subtask 3.1: Create Test Data Service
Create src/main/java/com/alnafi/camel/transactions/service/TestDataService.java:

package com.alnafi.camel.transactions.service;

import com.alnafi.camel.transactions.model.Order;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.camel.ProducerTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Service
public class TestDataService {

    @Autowired
    private ProducerTemplate producerTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    public void sendValidOrder() throws Exception {
        Order order = new Order("John Doe", "Laptop", 2, new BigDecimal("999.99"));
        String orderJson = objectMapper.writeValueAsString(order);
        producerTemplate.sendBody("jms:queue:orders", orderJson);
    }

    public void sendInvalidOrder() throws Exception {
        Order order = new Order("Jane Smith", "NonExistentProduct", 1, new BigDecimal("100.00"));
        String orderJson = objectMapper.writeValueAsString(order);
        producerTemplate.sendBody("jms:queue:orders", orderJson);
    }

    public void sendInsufficientInventoryOrder() throws Exception {
        Order order = new Order("Bob Johnson", "Monitor", 20, new BigDecimal("299.99"));
        String orderJson = objectMapper.writeValueAsString(order);
        producerTemplate.sendBody("jms:queue:orders", orderJson);
    }

    public void sendInvalidDataOrder() throws Exception {
        Order order = new Order("", "Laptop", -1, new BigDecimal("-50.00"));
        String orderJson = objectMapper.writeValueAsString(order);
        producerTemplate.sendBody("jms:queue:orders", orderJson);
    }
}
Subtask 3.2: Create REST Controller for Testing
Create src/main/java/com/alnafi/camel/transactions/controller/TestController.java:

package com.alnafi.camel.transactions.controller;

import com.alnafi.camel.transactions.service.TestDataService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import javax.sql.DataSource;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/test")
public class TestController {

    @Autowired
    private TestDataService testDataService;

    @Autowired
    private DataSource xaDataSource;

    @PostMapping("/send-valid-order")
    public ResponseEntity<String> sendValidOrder() {
        try {
            testDataService.sendValidOrder();
            return ResponseEntity.ok("Valid order sent successfully");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error sending order: " + e.getMessage());
        }
    }

    @PostMapping("/send-invalid-order")
    public ResponseEntity<String> sendInvalidOrder() {
        try {
            testDataService.sendInvalidOrder();
            return ResponseEntity.ok("Invalid order sent successfully");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error sending order: " + e.getMessage());
        }
    }

    @PostMapping("/send-insufficient-inventory-order")
    public ResponseEntity<String> sendInsufficientInventoryOrder() {
        try {
            testDataService.sendInsufficientInventoryOrder();
            return ResponseEntity.ok("Insufficient inventory order sent successfully");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error sending order: " + e.getMessage());
        }
    }

    @PostMapping("/send-invalid-data-order")
    public ResponseEntity<String> sendInvalidDataOrder() {
        try {
            testDataService.sendInvalidDataOrder();
            return ResponseEntity.ok("Invalid data order sent successfully");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error sending order: " + e.getMessage());
        }
    }

    @GetMapping("/orders")
    public ResponseEntity<List<Map<String, Object>>> getOrders() {
        JdbcTemplate jdbcTemplate = new JdbcTemplate(xaDataSource);
        List<Map<String, Object>> orders = jdbcTemplate.queryForList("SELECT * FROM orders ORDER BY created_at DESC");
        return ResponseEntity.ok(orders);
    }

    @GetMapping("/inventory")
    public ResponseEntity<List<Map<String, Object>>> getInventory() {
        JdbcTemplate jdbcTemplate = new JdbcTemplate(xaDataSource);
        List<Map<String, Object>> inventory = jdbcTemplate.queryForList("SELECT * FROM inventory ORDER BY product_name");
        return ResponseEntity.ok(inventory);
    }

    @GetMapping("/audit-log")
    public ResponseEntity<List<Map<String, Object>>> getAuditLog() {
        JdbcTemplate jdbcTemplate = new JdbcTemplate(xaDataSource);
        List<Map<String, Object>> auditLog = jdbcTemplate.queryForList("SELECT * FROM audit_log ORDER BY created_at DESC LIMIT 50");
        return ResponseEntity.ok(auditLog);
    }

    @PostMapping("/reset-data")
    public ResponseEntity<String> resetData() {
        try {
            JdbcTemplate jdbcTemplate = new JdbcTemplate(xaDataSource);
            
            // Clear existing data
            jdbcTemplate.execute("DELETE FROM orders");
            jdbcTemplate.execute("DELETE FROM audit_log");
            jdbcTemplate.execute("UPDATE inventory SET available_quantity = CASE " +
                "WHEN product_name = 'Laptop' THEN 10 " +
                "WHEN product_name = 'Mouse' THEN 50 " +
                "WHEN product_name = 'Keyboard' THEN 25 " +
                "WHEN product_name = 'Monitor' THEN 8 " +
                "ELSE available_quantity END, reserved_quantity = 0");
            
            return ResponseEntity.ok("Test data reset successfully");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error resetting data: " + e.getMessage());
        }
    }
}
Subtask 3.3: Create Database Initialization Component
Create src/main/java/com/alnafi/camel/transactions/config/DatabaseInitializer.java:

package com.alnafi.camel.transactions.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.util.FileCopyUtils;

import javax.sql.DataSource;
import java.nio.charset.StandardCharsets;

@Component
public class DatabaseInitializer implements CommandLineRunner {

    @Autowired
    private DataSource xaDataSource;

    @Override
    public void run(String... args) throws Exception {
        JdbcTemplate jdbcTemplate = new JdbcTemplate(xaDataSource);
        
        // Read and execute schema.sql
        ClassPathResource resource = new ClassPathResource("schema.sql");
        byte[] binaryData = FileCopyUtils.copyToByteArray(resource.getInputStream());
        String sql = new String(binaryData, StandardCharsets.UTF_8);
        
        // Split by semicolon and execute each statement
        String[] statements = sql.split(";");
        for (String statement : statements) {
            if (!statement.trim().isEmpty()) {
                jdbcTemplate.execute(statement.trim());
            }
        }
        
        System.out.println("Database initialized successfully");
    }
}
Subtask 3
