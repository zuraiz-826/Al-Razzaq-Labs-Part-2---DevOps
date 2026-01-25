Lab 9: Asynchronous Messaging with Apache Kafka
Objectives
By the end of this lab, you will be able to:

Set up Apache Kafka integration with Apache Camel
Create Camel routes to produce messages to Kafka topics
Create Camel routes to consume messages from Kafka topics
Test end-to-end Kafka message flow using Camel
Understand asynchronous messaging patterns in cloud-native integration
Configure Kafka producers and consumers with proper error handling
Prerequisites
Before starting this lab, you should have:

Basic understanding of Apache Camel concepts and routing
Familiarity with Java programming and Maven build tool
Knowledge of messaging concepts (producers, consumers, topics)
Understanding of JSON data format
Basic Linux command-line skills
Required Knowledge Areas:
Apache Camel: Routes, endpoints, and processors
Messaging Patterns: Publish-subscribe, point-to-point
Java Development: Basic syntax and Maven project structure
JSON: Data serialization and deserialization
Lab Environment Setup
Good News! Al Nafi provides ready-to-use Linux-based cloud machines for this lab. Simply click Start Lab and you'll have access to a pre-configured environment with all necessary tools installed.

Pre-installed Tools:
OpenJDK 11
Apache Maven 3.8+
Apache Kafka 2.8+
Apache Camel 3.20+
VS Code or Vim text editor
Task 1: Set up Apache Kafka Integration with Camel
Subtask 1.1: Start Kafka Services
First, let's start the Kafka ecosystem components.

Open a terminal in your cloud machine

Start Zookeeper (required for Kafka):

cd /opt/kafka
bin/zookeeper-server-start.sh config/zookeeper.properties &
Wait 10 seconds, then start Kafka server:
bin/kafka-server-start.sh config/server.properties &
Verify Kafka is running:
jps | grep -E "(Kafka|QuorumPeerMain)"
You should see both Kafka and Zookeeper processes running.

Subtask 1.2: Create Kafka Topics
Create a topic for order processing:
bin/kafka-topics.sh --create --topic order-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
Create a topic for notifications:
bin/kafka-topics.sh --create --topic notification-events --bootstrap-server localhost:9092 --partitions 2 --replication-factor 1
List all topics to verify creation:
bin/kafka-topics.sh --list --bootstrap-server localhost:9092
Subtask 1.3: Create Maven Project Structure
Navigate to your workspace:
cd ~/workspace
Create a new Maven project:
mvn archetype:generate -DgroupId=com.alnafi.kafka.lab \
  -DartifactId=kafka-camel-integration \
  -DarchetypeArtifactId=maven-archetype-quickstart \
  -DinteractiveMode=false
Navigate to the project directory:
cd kafka-camel-integration
Update the pom.xml file with Kafka and Camel dependencies:
cat > pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.alnafi.kafka.lab</groupId>
    <artifactId>kafka-camel-integration</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <camel.version>3.20.2</camel.version>
        <kafka.version>3.4.0</kafka.version>
    </properties>
    
    <dependencies>
        <!-- Camel Core -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-core</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel Kafka Component -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-kafka</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel Jackson for JSON -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-jackson</artifactId>
            <version>${camel.version}</version>
        </dependency>
        
        <!-- Camel Timer Component -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-timer</artifactId>
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
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>exec-maven-plugin</artifactId>
                <version>3.1.0</version>
                <configuration>
                    <mainClass>com.alnafi.kafka.lab.KafkaCamelApplication</mainClass>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF
Create the directory structure:
mkdir -p src/main/java/com/alnafi/kafka/lab
mkdir -p src/main/resources
Task 2: Create Routes to Produce and Consume Messages via Kafka
Subtask 2.1: Create Data Models
Create an Order model class:
cat > src/main/java/com/alnafi/kafka/lab/Order.java << 'EOF'
package com.alnafi.kafka.lab;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class Order {
    @JsonProperty("orderId")
    private String orderId;
    
    @JsonProperty("customerId")
    private String customerId;
    
    @JsonProperty("productName")
    private String productName;
    
    @JsonProperty("quantity")
    private int quantity;
    
    @JsonProperty("price")
    private double price;
    
    @JsonProperty("timestamp")
    private String timestamp;
    
    public Order() {
        this.timestamp = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
    }
    
    public Order(String orderId, String customerId, String productName, int quantity, double price) {
        this();
        this.orderId = orderId;
        this.customerId = customerId;
        this.productName = productName;
        this.quantity = quantity;
        this.price = price;
    }
    
    // Getters and Setters
    public String getOrderId() { return orderId; }
    public void setOrderId(String orderId) { this.orderId = orderId; }
    
    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }
    
    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }
    
    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    
    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }
    
    public String getTimestamp() { return timestamp; }
    public void setTimestamp(String timestamp) { this.timestamp = timestamp; }
    
    @Override
    public String toString() {
        return String.format("Order{orderId='%s', customerId='%s', productName='%s', quantity=%d, price=%.2f, timestamp='%s'}",
                orderId, customerId, productName, quantity, price, timestamp);
    }
}
EOF
Subtask 2.2: Create Producer Route
Create the producer route class:
cat > src/main/java/com/alnafi/kafka/lab/OrderProducerRoute.java << 'EOF'
package com.alnafi.kafka.lab;

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.dataformat.JsonLibrary;
import java.util.Random;

public class OrderProducerRoute extends RouteBuilder {
    
    private final Random random = new Random();
    private final String[] products = {"Laptop", "Smartphone", "Tablet", "Headphones", "Monitor"};
    private final String[] customers = {"CUST001", "CUST002", "CUST003", "CUST004", "CUST005"};
    
    @Override
    public void configure() throws Exception {
        
        // Route to generate and send orders to Kafka
        from("timer:orderGenerator?period=5000")
            .routeId("order-producer-route")
            .log("Generating new order...")
            .process(exchange -> {
                // Create a random order
                String orderId = "ORD" + System.currentTimeMillis();
                String customerId = customers[random.nextInt(customers.length)];
                String productName = products[random.nextInt(products.length)];
                int quantity = random.nextInt(5) + 1;
                double price = (random.nextDouble() * 1000) + 100;
                
                Order order = new Order(orderId, customerId, productName, quantity, price);
                exchange.getIn().setBody(order);
                exchange.getIn().setHeader("orderId", orderId);
                exchange.getIn().setHeader("customerId", customerId);
            })
            .marshal().json(JsonLibrary.Jackson)
            .log("Sending order to Kafka: ${body}")
            .to("kafka:order-events?brokers=localhost:9092&keySerializer=org.apache.kafka.common.serialization.StringSerializer&valueSerializer=org.apache.kafka.common.serialization.StringSerializer")
            .log("Order sent successfully");
            
        // Route to handle high-value orders (> $500)
        from("kafka:order-events?brokers=localhost:9092&groupId=high-value-processor&keyDeserializer=org.apache.kafka.common.serialization.StringDeserializer&valueDeserializer=org.apache.kafka.common.serialization.StringDeserializer")
            .routeId("high-value-order-processor")
            .unmarshal().json(JsonLibrary.Jackson, Order.class)
            .filter(simple("${body.price} > 500"))
            .log("Processing high-value order: ${body}")
            .process(exchange -> {
                Order order = exchange.getIn().getBody(Order.class);
                String notification = String.format(
                    "HIGH VALUE ALERT: Order %s for customer %s - Amount: $%.2f",
                    order.getOrderId(), order.getCustomerId(), order.getPrice()
                );
                exchange.getIn().setBody(notification);
                exchange.getIn().setHeader("alertType", "HIGH_VALUE");
                exchange.getIn().setHeader("orderId", order.getOrderId());
            })
            .to("kafka:notification-events?brokers=localhost:9092&keySerializer=org.apache.kafka.common.serialization.StringSerializer&valueSerializer=org.apache.kafka.common.serialization.StringSerializer")
            .log("High-value notification sent: ${body}");
    }
}
EOF
Subtask 2.3: Create Consumer Routes
Create the consumer route class:
cat > src/main/java/com/alnafi/kafka/lab/OrderConsumerRoute.java << 'EOF'
package com.alnafi.kafka.lab;

import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.dataformat.JsonLibrary;

public class OrderConsumerRoute extends RouteBuilder {
    
    @Override
    public void configure() throws Exception {
        
        // Route to consume all orders and log them
        from("kafka:order-events?brokers=localhost:9092&groupId=order-logger&keyDeserializer=org.apache.kafka.common.serialization.StringDeserializer&valueDeserializer=org.apache.kafka.common.serialization.StringDeserializer")
            .routeId("order-consumer-route")
            .log("Received order from Kafka: ${body}")
            .unmarshal().json(JsonLibrary.Jackson, Order.class)
            .process(exchange -> {
                Order order = exchange.getIn().getBody(Order.class);
                System.out.println("=== ORDER PROCESSED ===");
                System.out.println("Order ID: " + order.getOrderId());
                System.out.println("Customer: " + order.getCustomerId());
                System.out.println("Product: " + order.getProductName());
                System.out.println("Quantity: " + order.getQuantity());
                System.out.println("Price: $" + String.format("%.2f", order.getPrice()));
                System.out.println("Timestamp: " + order.getTimestamp());
                System.out.println("========================");
            });
            
        // Route to consume notifications
        from("kafka:notification-events?brokers=localhost:9092&groupId=notification-processor&keyDeserializer=org.apache.kafka.common.serialization.StringDeserializer&valueDeserializer=org.apache.kafka.common.serialization.StringDeserializer")
            .routeId("notification-consumer-route")
            .log("Received notification: ${body}")
            .process(exchange -> {
                String notification = exchange.getIn().getBody(String.class);
                String alertType = exchange.getIn().getHeader("alertType", String.class);
                String orderId = exchange.getIn().getHeader("orderId", String.class);
                
                System.out.println("*** NOTIFICATION ALERT ***");
                System.out.println("Type: " + alertType);
                System.out.println("Order ID: " + orderId);
                System.out.println("Message: " + notification);
                System.out.println("***************************");
            });
            
        // Route to process orders by customer (example of partitioned consumption)
        from("kafka:order-events?brokers=localhost:9092&groupId=customer-processor&keyDeserializer=org.apache.kafka.common.serialization.StringDeserializer&valueDeserializer=org.apache.kafka.common.serialization.StringDeserializer")
            .routeId("customer-order-processor")
            .unmarshal().json(JsonLibrary.Jackson, Order.class)
            .choice()
                .when(simple("${body.customerId} == 'CUST001'"))
                    .log("VIP Customer order received: ${body}")
                    .process(exchange -> {
                        Order order = exchange.getIn().getBody(Order.class);
                        System.out.println("🌟 VIP CUSTOMER ORDER 🌟");
                        System.out.println("Applying 10% discount for " + order.getCustomerId());
                        order.setPrice(order.getPrice() * 0.9);
                        System.out.println("New price: $" + String.format("%.2f", order.getPrice()));
                    })
                .otherwise()
                    .log("Regular customer order: ${body.customerId}");
    }
}
EOF
Subtask 2.4: Create Main Application Class
Create the main application class:
cat > src/main/java/com/alnafi/kafka/lab/KafkaCamelApplication.java << 'EOF'
package com.alnafi.kafka.lab;

import org.apache.camel.CamelContext;
import org.apache.camel.impl.DefaultCamelContext;

public class KafkaCamelApplication {
    
    public static void main(String[] args) throws Exception {
        System.out.println("Starting Kafka-Camel Integration Application...");
        
        // Create Camel Context
        CamelContext camelContext = new DefaultCamelContext();
        
        try {
            // Add routes
            camelContext.addRoutes(new OrderProducerRoute());
            camelContext.addRoutes(new OrderConsumerRoute());
            
            // Start the context
            camelContext.start();
            
            System.out.println("Application started successfully!");
            System.out.println("Producer will generate orders every 5 seconds");
            System.out.println("Consumers are listening for messages");
            System.out.println("Press Ctrl+C to stop the application");
            
            // Keep the application running
            Thread.sleep(Long.MAX_VALUE);
            
        } catch (Exception e) {
            System.err.println("Error starting application: " + e.getMessage());
            e.printStackTrace();
        } finally {
            // Stop the context
            camelContext.stop();
            System.out.println("Application stopped.");
        }
    }
}
EOF
Subtask 2.5: Create Logging Configuration
Create logging configuration:
cat > src/main/resources/simplelogger.properties << 'EOF'
org.slf4j.simpleLogger.defaultLogLevel=INFO
org.slf4j.simpleLogger.log.org.apache.camel=INFO
org.slf4j.simpleLogger.log.org.apache.kafka=WARN
org.slf4j.simpleLogger.showDateTime=true
org.slf4j.simpleLogger.dateTimeFormat=yyyy-MM-dd HH:mm:ss
EOF
Task 3: Test the Kafka Message Flow
Subtask 3.1: Compile the Application
Compile the Maven project:
mvn clean compile
Verify compilation was successful:
echo "Compilation status: $?"
If you see "Compilation status: 0", the compilation was successful.

Subtask 3.2: Run the Application
Start the Camel-Kafka application:
mvn exec:java -Dexec.mainClass="com.alnafi.kafka.lab.KafkaCamelApplication"
You should see output similar to:

Starting Kafka-Camel Integration Application...
Application started successfully!
Producer will generate orders every 5 seconds
Consumers are listening for messages
Press Ctrl+C to stop the application
Observe the message flow for about 2-3 minutes. You should see:
Orders being generated every 5 seconds
Orders being consumed and processed
High-value order notifications (for orders > $500)
VIP customer processing (for CUST001)
Subtask 3.3: Monitor Kafka Topics
Open a new terminal (keep the application running in the first terminal)

Monitor the order-events topic:

cd /opt/kafka
bin/kafka-console-consumer.sh --topic order-events --from-beginning --bootstrap-server localhost:9092
Open another terminal and monitor the notification-events topic:
cd /opt/kafka
bin/kafka-console-consumer.sh --topic notification-events --from-beginning --bootstrap-server localhost:9092
Subtask 3.4: Test Message Production Manually
Open another terminal and create a manual producer:
cd /opt/kafka
bin/kafka-console-producer.sh --topic order-events --bootstrap-server localhost:9092
Send a test message (type this and press Enter):
{"orderId":"TEST001","customerId":"CUST001","productName":"Test Product","quantity":2,"price":750.00,"timestamp":"2024-01-15T10:30:00"}
Send another high-value order:
{"orderId":"TEST002","customerId":"CUST003","productName":"Premium Laptop","quantity":1,"price":1200.00,"timestamp":"2024-01-15T10:31:00"}
Exit the producer by pressing Ctrl+C
Subtask 3.5: Verify Consumer Groups
List consumer groups:
cd /opt/kafka
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
You should see:

order-logger
high-value-processor
notification-processor
customer-processor
Check consumer group details:
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group order-logger --describe
Subtask 3.6: Test Error Handling
Stop Kafka temporarily to test error handling:
cd /opt/kafka
bin/kafka-server-stop.sh
Observe the application behavior - it should show connection errors but continue trying to reconnect

Restart Kafka:

bin/kafka-server-start.sh config/server.properties &
Verify the application reconnects and continues processing
Subtask 3.7: Performance Testing
Check topic partition details:
cd /opt/kafka
bin/kafka-topics.sh --describe --topic order-events --bootstrap-server localhost:9092
Monitor consumer lag:
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group order-logger --describe
Stop the application by pressing Ctrl+C in the main terminal
Troubleshooting Common Issues
Issue 1: Kafka Connection Refused
Problem: Application shows "Connection refused" errors Solution:

# Check if Kafka is running
jps | grep Kafka

# If not running, start Kafka services
cd /opt/kafka
bin/zookeeper-server-start.sh config/zookeeper.properties &
sleep 10
bin/kafka-server-start.sh config/server.properties &
Issue 2: Topic Not Found
Problem: "Topic does not exist" errors Solution:

# Recreate topics
cd /opt/kafka
bin/kafka-topics.sh --create --topic order-events --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
bin/kafka-topics.sh --create --topic notification-events --bootstrap-server localhost:9092 --partitions 2 --replication-factor 1
Issue 3: Maven Compilation Errors
Problem: Dependency resolution failures Solution:

# Clean and reinstall dependencies
mvn clean
mvn dependency:resolve
mvn compile
Issue 4: JSON Serialization Errors
Problem: Jackson serialization failures Solution: Verify that the Order class has proper getters/setters and default constructor

Key Concepts Learned
Asynchronous Messaging
Messages are sent and received independently
Producers don't wait for consumers to process messages
Enables loose coupling between system components
Apache Kafka Integration
Topics: Named streams of records
Partitions: Scalability mechanism for topics
Consumer Groups: Load balancing for message consumption
Brokers: Kafka server instances
Camel-Kafka Components
Producer Configuration: Serializers, brokers, topic routing
Consumer Configuration: Deserializers, group IDs, offset management
Error Handling: Retry mechanisms and dead letter queues
Message Patterns Implemented
Publish-Subscribe: Multiple consumers for same topic
Content-Based Routing: Different processing based on message content
Message Filtering: Processing only relevant messages
Message Transformation: JSON serialization/deserialization
Conclusion
Congratulations! You have successfully completed Lab 9: Asynchronous Messaging with Apache Kafka. In this lab, you accomplished the following:

What You Built:
Kafka Integration: Set up Apache Kafka with Apache Camel for enterprise messaging
Producer Routes: Created routes that generate and send order messages to Kafka topics
Consumer Routes: Implemented multiple consumer patterns including filtering and content-based routing
Message Flow Testing: Verified end-to-end message processing with monitoring and error handling
Key Skills Developed:
Asynchronous Messaging: Understanding of decoupled, event-driven architecture
Kafka Operations: Topic management, consumer groups, and partition strategies
Camel Integration: Advanced routing patterns with Kafka components
JSON Processing: Message serialization and deserialization
Error Handling: Resilient messaging with connection recovery
Real-World Applications:
This lab simulates common enterprise scenarios such as:

E-commerce Order Processing: Handling order events asynchronously
Notification Systems: Triggering alerts based on business rules
Customer Segmentation: Different processing for VIP vs regular customers
High-Volume Data Processing: Scalable message processing with partitioning
Certification Relevance:
The skills you've learned directly support the Red Hat Certified Specialist in Cloud-native Integration exam objectives, particularly:

Implementing asynchronous messaging patterns
Configuring Kafka integration with Camel
Managing message routing and transformation
Handling errors and monitoring message flows
Next Steps:
Explore Kafka Streams for real-time data processing
Implement schema registry for message evolution
Add monitoring with Kafka Connect and metrics
Practice with different serialization formats (Avro, Protobuf)
You now have hands-on experience with enterprise-grade asynchronous messaging using Apache Kafka and Camel - essential skills for modern cloud-native integration solutions!
