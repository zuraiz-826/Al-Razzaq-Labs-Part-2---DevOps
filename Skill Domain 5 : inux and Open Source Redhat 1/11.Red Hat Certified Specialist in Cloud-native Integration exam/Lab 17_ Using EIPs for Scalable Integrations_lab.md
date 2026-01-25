Lab 17: Using EIPs for Scalable Integrations
Objectives
By the end of this lab, you will be able to:

Understand and implement Enterprise Integration Patterns (EIPs) using Apache Camel
Configure and use the Splitter pattern to divide large messages into smaller, manageable parts
Implement the Aggregator pattern to combine related messages based on correlation IDs and time windows
Deploy the Recipient List pattern for dynamic message routing to multiple endpoints
Build scalable integration solutions that can handle high-volume message processing
Apply best practices for message correlation and error handling in distributed systems
Prerequisites
Before starting this lab, you should have:

Basic understanding of Java programming concepts
Familiarity with Maven build tool
Knowledge of XML and JSON message formats
Understanding of messaging concepts (queues, topics, routing)
Basic command-line interface skills
Familiarity with REST API concepts
Lab Environment Setup
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to access your environment - no need to build your own VM or install software.

Your cloud machine includes:

OpenJDK 11
Apache Maven 3.8+
Apache Camel 3.20+
Visual Studio Code with Java extensions
curl and other networking tools
Task 1: Set up Splitter to Divide Messages
Subtask 1.1: Create the Project Structure
First, let's create a new Maven project for our EIP implementations.

Open the terminal in your cloud machine
Create a new directory for the project:
mkdir camel-eip-lab
cd camel-eip-lab
Create the Maven project structure:
mvn archetype:generate -DgroupId=com.alnafi.camel.eip \
  -DartifactId=camel-eip-patterns \
  -DarchetypeArtifactId=maven-archetype-quickstart \
  -DinteractiveMode=false
Navigate to the project directory:
cd camel-eip-patterns
Subtask 1.2: Configure Maven Dependencies
Open the pom.xml file:
code pom.xml
Replace the content with the following configuration:
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.alnafi.camel.eip</groupId>
    <artifactId>camel-eip-patterns</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <camel.version>3.20.2</camel.version>
        <slf4j.version>1.7.36</slf4j.version>
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
            <artifactId>camel-jackson</artifactId>
            <version>${camel.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-jetty</artifactId>
            <version>${camel.version}</version>
        </dependency>
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
Save the file and compile the project:
mvn clean compile
Subtask 1.3: Implement the Splitter Pattern
Create the package structure:
mkdir -p src/main/java/com/alnafi/camel/eip/splitter
mkdir -p src/main/resources
Create a data model for orders. Create src/main/java/com/alnafi/camel/eip/splitter/Order.java:
package com.alnafi.camel.eip.splitter;

import java.util.List;

public class Order {
    private String orderId;
    private String customerId;
    private List<OrderItem> items;
    
    public Order() {}
    
    public Order(String orderId, String customerId, List<OrderItem> items) {
        this.orderId = orderId;
        this.customerId = customerId;
        this.items = items;
    }
    
    // Getters and setters
    public String getOrderId() { return orderId; }
    public void setOrderId(String orderId) { this.orderId = orderId; }
    
    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }
    
    public List<OrderItem> getItems() { return items; }
    public void setItems(List<OrderItem> items) { this.items = items; }
    
    @Override
    public String toString() {
        return "Order{orderId='" + orderId + "', customerId='" + customerId + 
               "', items=" + items + "}";
    }
}
Create src/main/java/com/alnafi/camel/eip/splitter/OrderItem.java:
package com.alnafi.camel.eip.splitter;

public class OrderItem {
    private String productId;
    private String productName;
    private int quantity;
    private double price;
    
    public OrderItem() {}
    
    public OrderItem(String productId, String productName, int quantity, double price) {
        this.productId = productId;
        this.productName = productName;
        this.quantity = quantity;
        this.price = price;
    }
    
    // Getters and setters
    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }
    
    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }
    
    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    
    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }
    
    @Override
    public String toString() {
        return "OrderItem{productId='" + productId + "', productName='" + productName + 
               "', quantity=" + quantity + ", price=" + price + "}";
    }
}
Create the Splitter route. Create src/main/java/com/alnafi/camel/eip/splitter/SplitterRoute.java:
package com.alnafi.camel.eip.splitter;

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.dataformat.JsonLibrary;
import java.util.Arrays;
import java.util.List;

public class SplitterRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Route to create sample order data
        from("timer:orderGenerator?period=10000&repeatCount=3")
            .routeId("order-generator")
            .log("Generating sample order...")
            .process(exchange -> {
                // Create sample order with multiple items
                List<OrderItem> items = Arrays.asList(
                    new OrderItem("P001", "Laptop", 2, 999.99),
                    new OrderItem("P002", "Mouse", 3, 29.99),
                    new OrderItem("P003", "Keyboard", 2, 79.99),
                    new OrderItem("P004", "Monitor", 1, 299.99)
                );
                
                Order order = new Order("ORD-" + System.currentTimeMillis(), 
                                      "CUST-001", items);
                exchange.getIn().setBody(order);
                exchange.getIn().setHeader("originalOrderId", order.getOrderId());
            })
            .marshal().json(JsonLibrary.Jackson)
            .log("Created order: ${body}")
            .to("direct:splitOrder");
        
        // Splitter route - splits order into individual items
        from("direct:splitOrder")
            .routeId("order-splitter")
            .log("Splitting order into individual items...")
            .unmarshal().json(JsonLibrary.Jackson, Order.class)
            .split(simple("${body.items}"))
                .streaming() // Enable streaming for better memory usage
                .parallelProcessing() // Process splits in parallel
                .log("Processing item: ${body}")
                .process(exchange -> {
                    OrderItem item = exchange.getIn().getBody(OrderItem.class);
                    String originalOrderId = exchange.getIn().getHeader("originalOrderId", String.class);
                    
                    // Add correlation information for later aggregation
                    exchange.getIn().setHeader("correlationId", originalOrderId);
                    exchange.getIn().setHeader("itemId", item.getProductId());
                    
                    log.info("Split item - OrderID: {}, ProductID: {}, Product: {}", 
                            originalOrderId, item.getProductId(), item.getProductName());
                })
                .to("direct:processItem")
            .end()
            .log("Order splitting completed");
        
        // Individual item processing route
        from("direct:processItem")
            .routeId("item-processor")
            .log("Processing individual item: ${header.itemId}")
            .process(exchange -> {
                OrderItem item = exchange.getIn().getBody(OrderItem.class);
                
                // Simulate item processing (inventory check, pricing, etc.)
                Thread.sleep(1000); // Simulate processing time
                
                // Calculate total price for this item
                double totalPrice = item.getQuantity() * item.getPrice();
                exchange.getIn().setHeader("itemTotal", totalPrice);
                
                log.info("Processed item {} - Total: ${}", item.getProductId(), totalPrice);
            })
            .to("direct:aggregateItems");
    }
}
Subtask 1.4: Test the Splitter Implementation
Create the main application class. Create src/main/java/com/alnafi/camel/eip/SplitterApplication.java:
package com.alnafi.camel.eip;

import com.alnafi.camel.eip.splitter.SplitterRoute;
import org.apache.camel.main.Main;

public class SplitterApplication {
    
    public static void main(String[] args) throws Exception {
        Main main = new Main();
        
        // Add our route
        main.addRouteBuilder(new SplitterRoute());
        
        // Configure Camel context
        main.configure().setName("SplitterEIPDemo");
        
        System.out.println("Starting Splitter EIP Demo...");
        System.out.println("The application will generate sample orders and split them into individual items.");
        System.out.println("Press Ctrl+C to stop the application.");
        
        // Run the application
        main.run(args);
    }
}
Compile and run the splitter demo:
mvn clean compile exec:java -Dexec.mainClass="com.alnafi.camel.eip.SplitterApplication"
Observe the output showing orders being split into individual items. You should see logs indicating:
Order generation
Order splitting into individual items
Parallel processing of items
Correlation IDs being set for aggregation
Task 2: Implement Aggregator to Combine Messages
Subtask 2.1: Create Aggregation Strategy
Create the aggregation package:
mkdir -p src/main/java/com/alnafi/camel/eip/aggregator
Create a custom aggregation strategy. Create src/main/java/com/alnafi/camel/eip/aggregator/OrderAggregationStrategy.java:
package com.alnafi.camel.eip.aggregator;

import com.alnafi.camel.eip.splitter.OrderItem;
import org.apache.camel.AggregationStrategy;
import org.apache.camel.Exchange;
import java.util.ArrayList;
import java.util.List;

public class OrderAggregationStrategy implements AggregationStrategy {
    
    @Override
    public Exchange aggregate(Exchange oldExchange, Exchange newExchange) {
        OrderItem newItem = newExchange.getIn().getBody(OrderItem.class);
        
        if (oldExchange == null) {
            // First message - create new aggregated order
            AggregatedOrder aggregatedOrder = new AggregatedOrder();
            aggregatedOrder.setOrderId(newExchange.getIn().getHeader("correlationId", String.class));
            aggregatedOrder.setItems(new ArrayList<>());
            aggregatedOrder.getItems().add(newItem);
            aggregatedOrder.setTotalAmount(newExchange.getIn().getHeader("itemTotal", Double.class));
            aggregatedOrder.setItemCount(1);
            
            newExchange.getIn().setBody(aggregatedOrder);
            return newExchange;
        } else {
            // Subsequent messages - add to existing aggregation
            AggregatedOrder aggregatedOrder = oldExchange.getIn().getBody(AggregatedOrder.class);
            aggregatedOrder.getItems().add(newItem);
            
            Double itemTotal = newExchange.getIn().getHeader("itemTotal", Double.class);
            aggregatedOrder.setTotalAmount(aggregatedOrder.getTotalAmount() + itemTotal);
            aggregatedOrder.setItemCount(aggregatedOrder.getItemCount() + 1);
            
            return oldExchange;
        }
    }
}
Create the aggregated order model. Create src/main/java/com/alnafi/camel/eip/aggregator/AggregatedOrder.java:
package com.alnafi.camel.eip.aggregator;

import com.alnafi.camel.eip.splitter.OrderItem;
import java.util.List;

public class AggregatedOrder {
    private String orderId;
    private List<OrderItem> items;
    private double totalAmount;
    private int itemCount;
    private long aggregationStartTime;
    private long aggregationEndTime;
    
    public AggregatedOrder() {
        this.aggregationStartTime = System.currentTimeMillis();
    }
    
    // Getters and setters
    public String getOrderId() { return orderId; }
    public void setOrderId(String orderId) { this.orderId = orderId; }
    
    public List<OrderItem> getItems() { return items; }
    public void setItems(List<OrderItem> items) { this.items = items; }
    
    public double getTotalAmount() { return totalAmount; }
    public void setTotalAmount(double totalAmount) { this.totalAmount = totalAmount; }
    
    public int getItemCount() { return itemCount; }
    public void setItemCount(int itemCount) { this.itemCount = itemCount; }
    
    public long getAggregationStartTime() { return aggregationStartTime; }
    public void setAggregationStartTime(long aggregationStartTime) { 
        this.aggregationStartTime = aggregationStartTime; 
    }
    
    public long getAggregationEndTime() { return aggregationEndTime; }
    public void setAggregationEndTime(long aggregationEndTime) { 
        this.aggregationEndTime = aggregationEndTime; 
    }
    
    public long getAggregationDuration() {
        return aggregationEndTime - aggregationStartTime;
    }
    
    @Override
    public String toString() {
        return "AggregatedOrder{" +
                "orderId='" + orderId + '\'' +
                ", itemCount=" + itemCount +
                ", totalAmount=" + totalAmount +
                ", aggregationDuration=" + getAggregationDuration() + "ms" +
                '}';
    }
}
Subtask 2.2: Implement Aggregator Route
Create the aggregator route. Create src/main/java/com/alnafi/camel/eip/aggregator/AggregatorRoute.java:
package com.alnafi.camel.eip.aggregator;

import org.apache.camel.builder.RouteBuilder;

public class AggregatorRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Aggregator route - combines split items back into complete orders
        from("direct:aggregateItems")
            .routeId("item-aggregator")
            .log("Aggregating item: ${header.itemId} for order: ${header.correlationId}")
            .aggregate(header("correlationId"), new OrderAggregationStrategy())
                .completionTimeout(5000) // Complete aggregation after 5 seconds
                .completionSize(4) // Complete when 4 items are aggregated (matches our sample)
                .log("Aggregation completed for order: ${header.correlationId}")
                .process(exchange -> {
                    AggregatedOrder order = exchange.getIn().getBody(AggregatedOrder.class);
                    order.setAggregationEndTime(System.currentTimeMillis());
                    
                    log.info("Order aggregation completed: {}", order);
                    log.info("Items aggregated: {}", order.getItemCount());
                    log.info("Total amount: ${}", order.getTotalAmount());
                    log.info("Aggregation took: {}ms", order.getAggregationDuration());
                })
                .to("direct:finalizeOrder")
            .end();
        
        // Final order processing route
        from("direct:finalizeOrder")
            .routeId("order-finalizer")
            .log("Finalizing aggregated order: ${body.orderId}")
            .process(exchange -> {
                AggregatedOrder order = exchange.getIn().getBody(AggregatedOrder.class);
                
                // Apply business rules (discounts, taxes, etc.)
                if (order.getTotalAmount() > 1000) {
                    double discount = order.getTotalAmount() * 0.1; // 10% discount
                    order.setTotalAmount(order.getTotalAmount() - discount);
                    log.info("Applied 10% discount: ${}", discount);
                }
                
                // Add tax
                double tax = order.getTotalAmount() * 0.08; // 8% tax
                order.setTotalAmount(order.getTotalAmount() + tax);
                
                log.info("Final order total with tax: ${}", order.getTotalAmount());
            })
            .to("direct:sendToRecipients");
    }
}
Subtask 2.3: Create Complete Application with Aggregator
Create a combined application. Create src/main/java/com/alnafi/camel/eip/SplitterAggregatorApplication.java:
package com.alnafi.camel.eip;

import com.alnafi.camel.eip.aggregator.AggregatorRoute;
import com.alnafi.camel.eip.splitter.SplitterRoute;
import org.apache.camel.main.Main;

public class SplitterAggregatorApplication {
    
    public static void main(String[] args) throws Exception {
        Main main = new Main();
        
        // Add our routes
        main.addRouteBuilder(new SplitterRoute());
        main.addRouteBuilder(new AggregatorRoute());
        
        // Configure Camel context
        main.configure().setName("SplitterAggregatorEIPDemo");
        
        System.out.println("Starting Splitter-Aggregator EIP Demo...");
        System.out.println("The application will:");
        System.out.println("1. Generate sample orders");
        System.out.println("2. Split orders into individual items");
        System.out.println("3. Process items individually");
        System.out.println("4. Aggregate items back into complete orders");
        System.out.println("Press Ctrl+C to stop the application.");
        
        // Run the application
        main.run(args);
    }
}
Test the combined splitter-aggregator:
mvn clean compile exec:java -Dexec.mainClass="com.alnafi.camel.eip.SplitterAggregatorApplication"
Task 3: Use Recipient List for Dynamic Message Dispatch
Subtask 3.1: Create Recipient List Implementation
Create the recipient list package:
mkdir -p src/main/java/com/alnafi/camel/eip/recipientlist
Create a recipient list resolver. Create src/main/java/com/alnafi/camel/eip/recipientlist/OrderRecipientListResolver.java:
package com.alnafi.camel.eip.recipientlist;

import com.alnafi.camel.eip.aggregator.AggregatedOrder;
import org.apache.camel.Exchange;
import java.util.ArrayList;
import java.util.List;

public class OrderRecipientListResolver {
    
    public static String resolveRecipients(Exchange exchange) {
        AggregatedOrder order = exchange.getIn().getBody(AggregatedOrder.class);
        List<String> recipients = new ArrayList<>();
        
        // Always send to order processing system
        recipients.add("direct:orderProcessing");
        
        // Send to inventory system if order contains physical items
        if (containsPhysicalItems(order)) {
            recipients.add("direct:inventoryUpdate");
        }
        
        // Send to shipping system for orders over $50
        if (order.getTotalAmount() > 50) {
            recipients.add("direct:shippingArrangement");
        }
        
        // Send to finance system for orders over $500
        if (order.getTotalAmount() > 500) {
            recipients.add("direct:financeApproval");
        }
        
        // Send to customer notification system
        recipients.add("direct:customerNotification");
        
        // Send to analytics system
        recipients.add("direct:analyticsProcessing");
        
        String recipientList = String.join(",", recipients);
        System.out.println("Recipients for order " + order.getOrderId() + ": " + recipientList);
        
        return recipientList;
    }
    
    private static boolean containsPhysicalItems(AggregatedOrder order) {
        // Simple logic - assume all items are physical for this demo
        return order.getItemCount() > 0;
    }
}
Subtask 3.2: Create Recipient List Route
Create the recipient list route. Create src/main/java/com/alnafi/camel/eip/recipientlist/RecipientListRoute.java:
package com.alnafi.camel.eip.recipientlist;

import org.apache.camel.builder.RouteBuilder;

public class RecipientListRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Recipient List route - dynamically routes messages to multiple endpoints
        from("direct:sendToRecipients")
            .routeId("recipient-list-router")
            .log("Determining recipients for order: ${body.orderId}")
            .recipientList(method(OrderRecipientListResolver.class, "resolveRecipients"))
                .parallelProcessing() // Process recipients in parallel
                .stopOnException() // Stop if any recipient fails
                .timeout(10000) // 10 second timeout
            .log("Message sent to all recipients for order: ${body.orderId}");
        
        // Order Processing System
        from("direct:orderProcessing")
            .routeId("order-processing-system")
            .log("ORDER PROCESSING: Processing order ${body.orderId}")
            .process(exchange -> {
                Thread.sleep(500); // Simulate processing time
                log.info("Order {} has been processed and saved to database", 
                        exchange.getIn().getBody().toString());
            });
        
        // Inventory Update System
        from("direct:inventoryUpdate")
            .routeId("inventory-update-system")
            .log("INVENTORY: Updating inventory for order ${body.orderId}")
            .process(exchange -> {
                Thread.sleep(300); // Simulate processing time
                log.info("Inventory updated for order {}", 
                        exchange.getIn().getBody().toString());
            });
        
        // Shipping Arrangement System
        from("direct:shippingArrangement")
            .routeId("shipping-arrangement-system")
            .log("SHIPPING: Arranging shipping for order ${body.orderId}")
            .process(exchange -> {
                Thread.sleep(700); // Simulate processing time
                log.info("Shipping arranged for order {}", 
                        exchange.getIn().getBody().toString());
            });
        
        // Finance Approval System
        from("direct:financeApproval")
            .routeId("finance-approval-system")
            .log("FINANCE: Processing finance approval for order ${body.orderId}")
            .process(exchange -> {
                Thread.sleep(1000); // Simulate processing time
                log.info("Finance approval completed for order {}", 
                        exchange.getIn().getBody().toString());
            });
        
        // Customer Notification System
        from("direct:customerNotification")
            .routeId("customer-notification-system")
            .log("NOTIFICATION: Sending notification for order ${body.orderId}")
            .process(exchange -> {
                Thread.sleep(200); // Simulate processing time
                log.info("Customer notification sent for order {}", 
                        exchange.getIn().getBody().toString());
            });
        
        // Analytics Processing System
        from("direct:analyticsProcessing")
            .routeId("analytics-processing-system")
            .log("ANALYTICS: Processing analytics data for order ${body.orderId}")
            .process(exchange -> {
                Thread.sleep(400); // Simulate processing time
                log.info("Analytics data processed for order {}", 
                        exchange.getIn().getBody().toString());
            });
    }
}
Subtask 3.3: Create Complete EIP Application
Create the final comprehensive application. Create src/main/java/com/alnafi/camel/eip/CompleteEIPApplication.java:
package com.alnafi.camel.eip;

import com.alnafi.camel.eip.aggregator.AggregatorRoute;
import com.alnafi.camel.eip.recipientlist.RecipientListRoute;
import com.alnafi.camel.eip.splitter.SplitterRoute;
import org.apache.camel.main.Main;

public class CompleteEIPApplication {
    
    public static void main(String[] args) throws Exception {
        Main main = new Main();
        
        // Add all our routes
        main.addRouteBuilder(new SplitterRoute());
        main.addRouteBuilder(new AggregatorRoute());
        main.addRouteBuilder(new RecipientListRoute());
        
        // Configure Camel context
        main.configure().setName("CompleteEIPDemo");
        
        System.out.println("=".repeat(80));
        System.out.println("Starting Complete EIP Demo Application");
        System.out.println("=".repeat(80));
        System.out.println("This application demonstrates three key Enterprise Integration Patterns:");
        System.out.println("1. SPLITTER: Divides large orders into individual items");
        System.out.println("2. AGGREGATOR: Combines processed items back into complete orders");
        System.out.println("3. RECIPIENT LIST: Routes orders to multiple systems dynamically");
        System.out.println();
        System.out.println("Watch the logs to see the complete message flow:");
        System.out.println("Order Generation → Splitting → Processing → Aggregation → Distribution");
        System.out.println();
        System.out.println("Press Ctrl+C to stop the application.");
        System.out.println("=".repeat(80));
        
        // Run the application
        main.run(args);
    }
}
Test the complete EIP implementation:
mvn clean compile exec:java -Dexec.mainClass="com.alnafi.camel.eip.CompleteEIPApplication"
Subtask 3.4: Create REST API for Testing
Create a REST endpoint for testing. Create src/main/java/com/alnafi/camel/eip/rest/EIPRestRoute.java:
mkdir -p src/main/java/com/alnafi/camel/eip/rest
package com.alnafi.camel.eip.rest;

import com.alnafi.camel.eip.splitter.Order;
import com.alnafi.camel.eip.splitter.OrderItem;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.dataformat.JsonLibrary;
import org.apache.camel.model.rest.RestBindingMode;
import java.util.Arrays;
import java.util.List;

public class EIPRestRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Configure REST
        restConfiguration()
            .component("jetty")
            .host("0.0.0.0")
            .port(8080)
            .bindingMode(RestBindingMode.json);
        
        // REST API endpoints
        rest("/api/eip")
            .description("EIP Demo REST API")
            
            .post("/order")
                .description("Submit an order for EIP processing")
                .type(Order.class)
                .to("direct:processRestOrder")
                
            .get("/sample")
                .description("Generate a sample order")
                .to("direct:generateSampleOrder");
        
        // Process REST order
        from("direct:processRestOrder")
            .routeId("rest-order-processor")
            .log("Received order via REST API: ${body}")
            .process(exchange -> {
                Order order = exchange.getIn().getBody(Order.class);
                exchange.getIn().setHeader("originalOrderId", order.getOrderId());
            })
            .to("direct:splitOrder")
            .setBody(constant("Order submitted for processing"));
        
        // Generate sample order
        from("direct:generateSampleOrder")
            .routeId("sample-order-generator")
            .process(exchange -> {
                List<OrderItem>
