Lab 20: End-to-End Integration with Camel Routes
Objectives
By the end of this lab, students will be able to:

Design and implement a comprehensive integration solution using Apache Camel
Connect multiple heterogeneous systems including databases, REST APIs, and file systems
Apply Enterprise Integration Patterns (EIPs) for complex routing and message transformations
Configure error handling and monitoring for production-ready integration solutions
Implement content-based routing, message filtering, and data transformation patterns
Build resilient integration flows with retry mechanisms and dead letter queues
Prerequisites
Before starting this lab, students should have:

Basic understanding of Java programming concepts
Familiarity with Maven build tool
Knowledge of REST API concepts
Understanding of database operations (SQL basics)
Experience with Linux command line operations
Basic knowledge of XML and JSON data formats
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to access your environment. No need to build your own VM or install software.

Your cloud machine includes:

OpenJDK 11
Apache Maven 3.8+
Apache Camel 3.20+
PostgreSQL 14
curl and other networking tools
Text editors (nano, vim)
Task 1: Design Integration Architecture
Subtask 1.1: Understanding the Integration Scenario
In this lab, we will build an Order Processing Integration System that connects:

File System: Receives order files in CSV format
Database: Stores customer and product information
REST API: External inventory service
Message Queue: Processes order notifications
File Output: Generates processed order reports
The integration flow will:

Monitor a directory for incoming order files
Validate and transform order data
Enrich orders with customer and product details from database
Check inventory availability via REST API
Route orders based on business rules
Generate confirmation files and notifications
Subtask 1.2: Create Project Structure
Connect to your cloud machine and create the project structure:

# Create project directory
mkdir -p ~/camel-integration-lab
cd ~/camel-integration-lab

# Create Maven project structure
mkdir -p src/main/java/com/alnafi/integration
mkdir -p src/main/resources
mkdir -p src/test/java
mkdir -p data/input
mkdir -p data/output
mkdir -p data/processed
mkdir -p data/error
Subtask 1.3: Create Maven Configuration
Create the pom.xml file:

nano pom.xml
Add the following content:

<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.alnafi</groupId>
    <artifactId>camel-integration-lab</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <camel.version>3.20.2</camel.version>
        <postgresql.version>42.5.4</postgresql.version>
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
        
        <!-- File Component -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-file</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- HTTP Component -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-http</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- JDBC Component -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-jdbc</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- JSON Processing -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-jackson</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- CSV Processing -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-csv</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Bean Validation -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-bean-validator</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- PostgreSQL Driver -->
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <version>${postgresql.version}</version>
        </dependency>
        
        <!-- Connection Pool -->
        <dependency>
            <groupId>com.zaxxer</groupId>
            <artifactId>HikariCP</artifactId>
            <version>5.0.1</version>
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
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>exec-maven-plugin</artifactId>
                <version>3.1.0</version>
                <configuration>
                    <mainClass>com.alnafi.integration.IntegrationApplication</mainClass>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
Task 2: Database Setup and Configuration
Subtask 2.1: Initialize PostgreSQL Database
Start PostgreSQL service and create the database:

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql << EOF
CREATE DATABASE integration_lab;
CREATE USER camel_user WITH PASSWORD 'camel_pass';
GRANT ALL PRIVILEGES ON DATABASE integration_lab TO camel_user;
\q
EOF
Subtask 2.2: Create Database Schema
Connect to the database and create tables:

psql -h localhost -U camel_user -d integration_lab << EOF
-- Customers table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    customer_code VARCHAR(20) UNIQUE NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_code VARCHAR(20) UNIQUE NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders table
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id INTEGER REFERENCES customers(customer_id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(12,2),
    status VARCHAR(20) DEFAULT 'PENDING',
    processed_at TIMESTAMP
);

-- Order items table
CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(12,2) NOT NULL
);

-- Insert sample data
INSERT INTO customers (customer_code, customer_name, email, phone, address) VALUES
('CUST001', 'Tech Solutions Inc', 'orders@techsolutions.com', '555-0101', '123 Tech Street, Silicon Valley, CA'),
('CUST002', 'Global Retail Corp', 'purchasing@globalretail.com', '555-0102', '456 Commerce Ave, New York, NY'),
('CUST003', 'Manufacturing Plus', 'orders@mfgplus.com', '555-0103', '789 Industrial Blvd, Detroit, MI');

INSERT INTO products (product_code, product_name, unit_price, category) VALUES
('PROD001', 'Wireless Mouse', 29.99, 'Electronics'),
('PROD002', 'USB Keyboard', 49.99, 'Electronics'),
('PROD003', 'Monitor Stand', 79.99, 'Accessories'),
('PROD004', 'Webcam HD', 89.99, 'Electronics'),
('PROD005', 'Desk Lamp', 39.99, 'Office Supplies');

\q
EOF
Subtask 2.3: Create Database Configuration
Create database configuration file:

nano src/main/resources/database.properties
Add the following content:

# Database Configuration
db.url=jdbc:postgresql://localhost:5432/integration_lab
db.username=camel_user
db.password=camel_pass
db.driver=org.postgresql.Driver

# Connection Pool Settings
db.pool.maxPoolSize=10
db.pool.minIdle=2
db.pool.connectionTimeout=30000
db.pool.idleTimeout=600000
db.pool.maxLifetime=1800000
Task 3: Implement Core Integration Components
Subtask 3.1: Create Data Models
Create the Order data model:

nano src/main/java/com/alnafi/integration/model/Order.java
package com.alnafi.integration.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public class Order {
    private String orderNumber;
    private String customerCode;
    private LocalDateTime orderDate;
    private List<OrderItem> items;
    private BigDecimal totalAmount;
    private String status;
    
    // Customer details (enriched)
    private String customerName;
    private String customerEmail;
    
    // Constructors
    public Order() {}
    
    public Order(String orderNumber, String customerCode) {
        this.orderNumber = orderNumber;
        this.customerCode = customerCode;
        this.orderDate = LocalDateTime.now();
        this.status = "PENDING";
    }
    
    // Getters and Setters
    public String getOrderNumber() { return orderNumber; }
    public void setOrderNumber(String orderNumber) { this.orderNumber = orderNumber; }
    
    public String getCustomerCode() { return customerCode; }
    public void setCustomerCode(String customerCode) { this.customerCode = customerCode; }
    
    public LocalDateTime getOrderDate() { return orderDate; }
    public void setOrderDate(LocalDateTime orderDate) { this.orderDate = orderDate; }
    
    public List<OrderItem> getItems() { return items; }
    public void setItems(List<OrderItem> items) { this.items = items; }
    
    public BigDecimal getTotalAmount() { return totalAmount; }
    public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }
    
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    
    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }
    
    public String getCustomerEmail() { return customerEmail; }
    public void setCustomerEmail(String customerEmail) { this.customerEmail = customerEmail; }
    
    @Override
    public String toString() {
        return "Order{" +
                "orderNumber='" + orderNumber + '\'' +
                ", customerCode='" + customerCode + '\'' +
                ", totalAmount=" + totalAmount +
                ", status='" + status + '\'' +
                '}';
    }
}
Create the OrderItem model:

nano src/main/java/com/alnafi/integration/model/OrderItem.java
package com.alnafi.integration.model;

import java.math.BigDecimal;

public class OrderItem {
    private String productCode;
    private String productName;
    private Integer quantity;
    private BigDecimal unitPrice;
    private BigDecimal lineTotal;
    
    // Constructors
    public OrderItem() {}
    
    public OrderItem(String productCode, Integer quantity, BigDecimal unitPrice) {
        this.productCode = productCode;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
        this.lineTotal = unitPrice.multiply(BigDecimal.valueOf(quantity));
    }
    
    // Getters and Setters
    public String getProductCode() { return productCode; }
    public void setProductCode(String productCode) { this.productCode = productCode; }
    
    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }
    
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    
    public BigDecimal getUnitPrice() { return unitPrice; }
    public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }
    
    public BigDecimal getLineTotal() { return lineTotal; }
    public void setLineTotal(BigDecimal lineTotal) { this.lineTotal = lineTotal; }
    
    public void calculateLineTotal() {
        if (quantity != null && unitPrice != null) {
            this.lineTotal = unitPrice.multiply(BigDecimal.valueOf(quantity));
        }
    }
}
Subtask 3.2: Create Data Processing Beans
Create the CSV processor:

nano src/main/java/com/alnafi/integration/processor/CsvOrderProcessor.java
package com.alnafi.integration.processor;

import com.alnafi.integration.model.Order;
import com.alnafi.integration.model.OrderItem;
import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class CsvOrderProcessor implements Processor {
    private static final Logger logger = LoggerFactory.getLogger(CsvOrderProcessor.class);
    
    @Override
    public void process(Exchange exchange) throws Exception {
        @SuppressWarnings("unchecked")
        List<Map<String, String>> csvData = exchange.getIn().getBody(List.class);
        
        if (csvData == null || csvData.isEmpty()) {
            throw new IllegalArgumentException("CSV data is empty");
        }
        
        // Group CSV rows by order number
        String orderNumber = null;
        String customerCode = null;
        List<OrderItem> items = new ArrayList<>();
        
        for (Map<String, String> row : csvData) {
            if (orderNumber == null) {
                orderNumber = row.get("order_number");
                customerCode = row.get("customer_code");
            }
            
            // Create order item
            OrderItem item = new OrderItem();
            item.setProductCode(row.get("product_code"));
            item.setQuantity(Integer.parseInt(row.get("quantity")));
            item.setUnitPrice(new BigDecimal(row.get("unit_price")));
            item.calculateLineTotal();
            
            items.add(item);
        }
        
        // Create order
        Order order = new Order(orderNumber, customerCode);
        order.setItems(items);
        
        // Calculate total amount
        BigDecimal totalAmount = items.stream()
                .map(OrderItem::getLineTotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        order.setTotalAmount(totalAmount);
        
        logger.info("Processed order: {} with {} items, total: {}", 
                   orderNumber, items.size(), totalAmount);
        
        exchange.getIn().setBody(order);
    }
}
Create the customer enrichment processor:

nano src/main/java/com/alnafi/integration/processor/CustomerEnrichmentProcessor.java
package com.alnafi.integration.processor;

import com.alnafi.integration.model.Order;
import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Map;

public class CustomerEnrichmentProcessor implements Processor {
    private static final Logger logger = LoggerFactory.getLogger(CustomerEnrichmentProcessor.class);
    
    @Override
    public void process(Exchange exchange) throws Exception {
        Order order = exchange.getIn().getBody(Order.class);
        
        // Get customer data from previous enrichment step
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> customerData = 
            (List<Map<String, Object>>) exchange.getProperty("customerData");
        
        if (customerData != null && !customerData.isEmpty()) {
            Map<String, Object> customer = customerData.get(0);
            order.setCustomerName((String) customer.get("customer_name"));
            order.setCustomerEmail((String) customer.get("email"));
            
            logger.info("Enriched order {} with customer data: {}", 
                       order.getOrderNumber(), order.getCustomerName());
        } else {
            logger.warn("No customer data found for customer code: {}", 
                       order.getCustomerCode());
            throw new IllegalStateException("Customer not found: " + order.getCustomerCode());
        }
        
        exchange.getIn().setBody(order);
    }
}
Subtask 3.3: Create Inventory Service Simulator
Create a simple HTTP server to simulate inventory service:

nano src/main/java/com/alnafi/integration/service/InventoryServiceSimulator.java
package com.alnafi.integration.service;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.util.HashMap;
import java.util.Map;

public class InventoryServiceSimulator {
    private static final Logger logger = LoggerFactory.getLogger(InventoryServiceSimulator.class);
    private HttpServer server;
    
    // Simulated inventory data
    private final Map<String, Integer> inventory = new HashMap<>();
    
    public InventoryServiceSimulator() {
        // Initialize inventory
        inventory.put("PROD001", 100);
        inventory.put("PROD002", 50);
        inventory.put("PROD003", 25);
        inventory.put("PROD004", 75);
        inventory.put("PROD005", 200);
    }
    
    public void start() throws IOException {
        server = HttpServer.create(new InetSocketAddress(8080), 0);
        server.createContext("/inventory/check", new InventoryHandler());
        server.setExecutor(null);
        server.start();
        logger.info("Inventory service simulator started on port 8080");
    }
    
    public void stop() {
        if (server != null) {
            server.stop(0);
            logger.info("Inventory service simulator stopped");
        }
    }
    
    class InventoryHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("GET".equals(exchange.getRequestMethod())) {
                String query = exchange.getRequestURI().getQuery();
                String productCode = extractProductCode(query);
                
                if (productCode != null && inventory.containsKey(productCode)) {
                    int availableQty = inventory.get(productCode);
                    String response = String.format(
                        "{\"productCode\":\"%s\",\"availableQuantity\":%d,\"status\":\"AVAILABLE\"}", 
                        productCode, availableQty);
                    
                    exchange.getResponseHeaders().set("Content-Type", "application/json");
                    exchange.sendResponseHeaders(200, response.length());
                    
                    try (OutputStream os = exchange.getResponseBody()) {
                        os.write(response.getBytes());
                    }
                    
                    logger.info("Inventory check for {}: {} available", productCode, availableQty);
                } else {
                    String response = "{\"error\":\"Product not found\"}";
                    exchange.sendResponseHeaders(404, response.length());
                    
                    try (OutputStream os = exchange.getResponseBody()) {
                        os.write(response.getBytes());
                    }
                }
            } else {
                exchange.sendResponseHeaders(405, 0);
            }
        }
        
        private String extractProductCode(String query) {
            if (query != null && query.startsWith("productCode=")) {
                return query.substring("productCode=".length());
            }
            return null;
        }
    }
}
Task 4: Implement Enterprise Integration Patterns
Subtask 4.1: Create Main Integration Route
Create the main Camel route:

nano src/main/java/com/alnafi/integration/route/OrderProcessingRoute.java
package com.alnafi.integration.route;

import com.alnafi.integration.model.Order;
import com.alnafi.integration.processor.CsvOrderProcessor;
import com.alnafi.integration.processor.CustomerEnrichmentProcessor;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.apache.camel.Exchange;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.component.jdbc.JdbcComponent;
import org.apache.camel.model.dataformat.CsvDataFormat;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.sql.DataSource;
import java.io.InputStream;
import java.util.Properties;

public class OrderProcessingRoute extends RouteBuilder {
    private static final Logger logger = LoggerFactory.getLogger(OrderProcessingRoute.class);
    
    @Override
    public void configure() throws Exception {
        // Configure database connection
        configureDatabase();
        
        // Configure CSV data format
        CsvDataFormat csvFormat = new CsvDataFormat();
        csvFormat.setUseMaps(true);
        csvFormat.setHeader(new String[]{"order_number", "customer_code", "product_code", "quantity", "unit_price"});
        
        // Global error handler
        errorHandler(deadLetterChannel("file:data/error")
                .maximumRedeliveries(3)
                .redeliveryDelay(5000)
                .retryAttemptedLogLevel(org.apache.camel.LoggingLevel.WARN));
        
        // Main order processing route
        from("file:data/input?move=../processed&moveFailed=../error")
                .routeId("order-file-processor")
                .log("Processing order file: ${header.CamelFileName}")
                .unmarshal(csvFormat)
                .process(new CsvOrderProcessor())
                .to("direct:enrich-customer")
                .to("direct:validate-inventory")
                .to("direct:route-order")
                .log("Order processing completed: ${body.orderNumber}");
        
        // Customer enrichment route
        from("direct:enrich-customer")
                .routeId("customer-enrichment")
                .log("Enriching customer data for: ${body.customerCode}")
                .enrich("direct:lookup-customer", (original, resource) -> {
                    original.setProperty("customerData", resource.getIn().getBody());
                    return original;
                })
                .process(new CustomerEnrichmentProcessor());
        
        // Customer lookup route
        from("direct:lookup-customer")
                .routeId("customer-lookup")
                .setBody(simple("SELECT customer_name, email, phone, address FROM customers WHERE customer_code = '${body.customerCode}'"))
                .to("jdbc:dataSource")
                .log("Customer lookup result: ${body}");
        
        // Inventory validation route
        from("direct:validate-inventory")
                .routeId("inventory-validation")
                .log("Validating inventory for order: ${body.orderNumber}")
                .split(simple("${body.items}"))
                .setHeader("productCode", simple("${body.productCode}"))
                .setHeader("requiredQty", simple("${body.quantity}"))
                .to("http://localhost:8080/inventory/check?productCode=${header.productCode}")
                .unmarshal().json()
                .choice()
                    .when(simple("${body[availableQuantity]} >= ${header.requiredQty}"))
                        .log("Inventory available for ${header.productCode}: ${body[availableQuantity]}")
                    .otherwise()
                        .log("Insufficient inventory for ${header.productCode}")
                        .throwException(new IllegalStateException("Insufficient inventory"))
                .end()
                .aggregate(header("CamelFileName"))
                .completionTimeout(10000)
                .to("direct:inventory-validated");
        
        // Order routing based on business rules
        from("direct:route-order")
                .routeId("order-routing")
                .choice()
                    .when(simple("${body.totalAmount} > 1000"))
                        .log("High-value order: ${body.orderNumber}")
                        .to("direct:high-value-processing")
                    .when(simple("${body.totalAmount} > 500"))
                        .log("Medium-value order: ${body.orderNumber}")
                        .to("direct:medium-value-processing")
                    .otherwise()
                        .log("Standard order: ${body.orderNumber}")
                        .to("direct:standard-processing")
                .end();
        
        // High-value order processing
        from("direct:high-value-processing")
                .routeId("high-value-processing")
                .log("Processing high-value order: ${body.orderNumber}")
                .to("direct:save-order")
                .to("direct:send-priority-notification")
                .to("direct:generate-report");
        
        // Medium-value order processing
        from("direct:medium-value-processing")
                .routeId("medium-value-processing")
                .log("Processing medium-value order: ${body.orderNumber}")
                .to("direct:save-order")
                .to("direct:send-notification")
                .to("direct:generate-report");
        
        // Standard order processing
        from("direct:standard-processing")
                .routeId("standard-processing")
                .log("Processing standard order: ${body.orderNumber}")
                .to("direct:save-order")
                .to("direct:generate-report");
        
        // Save order to database
        from("direct:save-order")
                .routeId("save-order")
                .log("Saving order to database: ${body.orderNumber}")
                .process(exchange -> {
                    Order order = exchange.getIn().getBody(Order.class);
                    order.setStatus("PROCESSED");
                })
                .setBody(simple("INSERT INTO orders (order_number, customer_id, total_amount, status) " +
                               "SELECT '${body.orderNumber}', customer_id, ${body.totalAmount}, '${body.status}' " +
                               "FROM customers WHERE customer_code = '${body.customerCode}'"))
                .to("jdbc:dataSource")
                .log("Order saved successfully");
        
        // Generate order report
        from("direct:generate-report")
                .routeId("generate-report")
                .log("Generating report for order: ${body.orderNumber}")
                .process(exchange -> {
                    Order order = exchange.getIn().getBody(Order.class);
                    StringBuilder report = new StringBuilder();
                    report.append("ORDER CONFIRMATION\n");
                    report.append("==================\n");
                    report.append("Order Number: ").append(order.getOrderNumber()).append("\n");
                    report.append("Customer: ").append(order.getCustomerName()).append("\n");
                    report.append("Email: ").append(order.getCustomerEmail()).append("\n");
                    report.append("Total Amount: $").append(order.getTotalAmount()).append("\n");
                    report.append("Status: ").append(order.getStatus()).append("\n");
                    report.append("\nITEMS:\n");
                    order.getItems().forEach(item -> {
                        report.append("- ").append(item.getProductCode())
                              .append(" x").append(item.getQuantity())
                              .append(" @ $").append(item.getUnitPrice())
                              .append(" = $").append(item.getLineTotal()).append("\n");
                    });
                    
                    exchange.getIn().setBody(report.toString());
                    exchange.getIn().setHeader(Exchange.FILE_NAME, 
                                             "order_" + order.getOrderNumber() + "_confirmation.txt");
                })
                .to("file:data/output")
                .log("Report generated: ${header.CamelFileName}");
        
        // Notification routes
        from("direct:send-priority-notification")
                .routeId("priority-notification")
                .log("Sending priority notification for order: ${body.orderNumber}")
                .setBody(simple("PRIORITY: Order ${body.orderNumber} processed - Amount: $${body.totalAmount}"))
                .to("file:data/output?fileName=priority_notification_${date:now:yyyyMMdd_HHmmss}.txt");
        
        from("direct:send-notification")
                .routeId("standard-notification")
                .log("Sending standard notification for order: ${body.orderNumber}")
                .setBody(simple("Order ${body.orderNumber} processed - Amount: $${body.totalAmount}"))
                .to("file:data/output?fileName=notification_${date:now:yyyyMMdd_HHmmss}.txt");
    }
    
    private void configureDatabase() throws Exception {
        // Load database properties
        Properties props = new Properties();
        try (InputStream is = getClass().getClassLoader().getResourceAsStream("database.properties")) {
            props.load(is);
        }
        
