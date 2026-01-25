Lab 3: Defining Routes with XML DSL
Objectives
By the end of this lab, students will be able to:

Understand the fundamentals of Apache Camel XML DSL (Domain Specific Language)
Create and configure Camel routes using XML configuration
Implement basic message transformation and routing logic
Test and validate XML-based Camel routes using the Camel context
Deploy and run XML DSL routes in a Spring Boot application
Debug and troubleshoot XML-based integration patterns
Prerequisites
Before starting this lab, students should have:

Basic understanding of XML syntax and structure
Familiarity with Apache Camel concepts from previous labs
Knowledge of Java development fundamentals
Understanding of Maven build tool
Basic command-line interface skills
Completion of Lab 1 (Introduction to Apache Camel) and Lab 2 (Basic Routing)
Required Software
Java 11 or higher
Apache Maven 3.6+
Text editor or IDE (VS Code, IntelliJ IDEA, or Eclipse)
Apache Camel 3.x
Spring Boot 2.7+
Ready-to-Use Cloud Machines
Al Nafi provides pre-configured Linux-based cloud machines with all necessary tools installed. Simply click Start Lab to access your development environment. No need to build your own VM or install software manually.

Your cloud machine includes:

Ubuntu 20.04 LTS
OpenJDK 11
Apache Maven 3.8.6
VS Code with Java extensions
All required dependencies pre-installed
Task 1: Setting Up the Project Structure
Subtask 1.1: Create Maven Project
Open the terminal in your cloud machine
Navigate to your home directory and create a new Maven project:
cd ~
mvn archetype:generate -DgroupId=com.alnafi.camel.xmldsl \
  -DartifactId=camel-xml-dsl-lab \
  -DarchetypeArtifactId=maven-archetype-quickstart \
  -DinteractiveMode=false
Navigate to the project directory:
cd camel-xml-dsl-lab
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

    <groupId>com.alnafi.camel.xmldsl</groupId>
    <artifactId>camel-xml-dsl-lab</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <name>Camel XML DSL Lab</name>
    <description>Lab 3: Defining Routes with XML DSL</description>

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

        <!-- Camel Components -->
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-file</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-timer</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-log</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-jackson</artifactId>
        </dependency>

        <!-- Testing Dependencies -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-test-spring-junit5</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <version>${spring.boot.version}</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>repackage</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
Save the file and update dependencies:
mvn clean compile
Subtask 1.3: Create Directory Structure
Create the necessary directory structure:
mkdir -p src/main/resources
mkdir -p src/main/resources/camel
mkdir -p src/test/java/com/alnafi/camel/xmldsl
mkdir -p data/input
mkdir -p data/output
mkdir -p data/processed
Task 2: Create a Basic XML DSL Route
Subtask 2.1: Create the Main Application Class
Create the main Spring Boot application class:
mkdir -p src/main/java/com/alnafi/camel/xmldsl
code src/main/java/com/alnafi/camel/xmldsl/CamelXmlDslApplication.java
Add the following content:
package com.alnafi.camel.xmldsl;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class CamelXmlDslApplication {

    public static void main(String[] args) {
        SpringApplication.run(CamelXmlDslApplication.class, args);
    }
}
Subtask 2.2: Create Your First XML DSL Route
Create a basic XML DSL route configuration file:
code src/main/resources/camel/file-processing-route.xml
Add the following XML DSL route definition:
<?xml version="1.0" encoding="UTF-8"?>
<routes xmlns="http://camel.apache.org/schema/spring"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="
        http://camel.apache.org/schema/spring
        http://camel.apache.org/schema/spring/camel-spring.xsd">

    <!-- Route 1: Basic File Processing Route -->
    <route id="fileProcessingRoute">
        <description>Basic file processing route using XML DSL</description>
        
        <!-- Consumer: Monitor input directory for new files -->
        <from uri="file:data/input?noop=true&amp;delay=5000"/>
        
        <!-- Log the incoming message -->
        <log message="Processing file: ${header.CamelFileName}"/>
        
        <!-- Add custom header -->
        <setHeader name="ProcessedTimestamp">
            <simple>${date:now:yyyy-MM-dd HH:mm:ss}</simple>
        </setHeader>
        
        <!-- Transform message body to uppercase -->
        <transform>
            <simple>${bodyAs(String).toUpperCase()}</simple>
        </transform>
        
        <!-- Log the transformation -->
        <log message="File content transformed to uppercase"/>
        
        <!-- Producer: Write to output directory -->
        <to uri="file:data/output"/>
        
        <!-- Log completion -->
        <log message="File ${header.CamelFileName} processed successfully at ${header.ProcessedTimestamp}"/>
    </route>

</routes>
Subtask 2.3: Configure Application Properties
Create the application properties file:
code src/main/resources/application.properties
Add the following configuration:
# Application Configuration
spring.application.name=camel-xml-dsl-lab
server.port=8080

# Camel Configuration
camel.springboot.name=CamelXmlDslLab
camel.springboot.main-run-controller=true
camel.springboot.duration-max-messages=0
camel.springboot.duration-max-idle-seconds=0

# Enable Camel XML routes auto-discovery
camel.springboot.xml-routes=classpath:camel/*.xml

# Logging Configuration
logging.level.com.alnafi.camel.xmldsl=INFO
logging.level.org.apache.camel=INFO
logging.pattern.console=%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n
Task 3: Implement Advanced Transformation and Routing
Subtask 3.1: Create a Content-Based Router
Create an advanced XML DSL route with content-based routing:
code src/main/resources/camel/content-based-router.xml
Add the following XML configuration:
<?xml version="1.0" encoding="UTF-8"?>
<routes xmlns="http://camel.apache.org/schema/spring"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="
        http://camel.apache.org/schema/spring
        http://camel.apache.org/schema/spring/camel-spring.xsd">

    <!-- Route 2: Content-Based Router with Message Transformation -->
    <route id="contentBasedRouter">
        <description>Content-based routing with message transformation</description>
        
        <!-- Timer-based trigger every 30 seconds -->
        <from uri="timer:contentRouter?period=30000"/>
        
        <!-- Generate sample data -->
        <setBody>
            <simple>{"orderId": "${random(1000,9999)}", "customerType": "${random(1,3)}", "amount": ${random(100,1000)}, "timestamp": "${date:now:yyyy-MM-dd'T'HH:mm:ss}"}</simple>
        </setBody>
        
        <!-- Log the generated order -->
        <log message="Generated order: ${body}"/>
        
        <!-- Parse customer type for routing decision -->
        <setHeader name="CustomerType">
            <jsonpath>$.customerType</jsonpath>
        </setHeader>
        
        <!-- Content-based routing -->
        <choice>
            <when>
                <simple>${header.CustomerType} == '1'</simple>
                <log message="Processing PREMIUM customer order"/>
                <setHeader name="Priority">
                    <constant>HIGH</constant>
                </setHeader>
                <setHeader name="Discount">
                    <constant>0.15</constant>
                </setHeader>
                <to uri="direct:premiumProcessing"/>
            </when>
            <when>
                <simple>${header.CustomerType} == '2'</simple>
                <log message="Processing STANDARD customer order"/>
                <setHeader name="Priority">
                    <constant>MEDIUM</constant>
                </setHeader>
                <setHeader name="Discount">
                    <constant>0.05</constant>
                </setHeader>
                <to uri="direct:standardProcessing"/>
            </when>
            <otherwise>
                <log message="Processing BASIC customer order"/>
                <setHeader name="Priority">
                    <constant>LOW</constant>
                </setHeader>
                <setHeader name="Discount">
                    <constant>0.0</constant>
                </setHeader>
                <to uri="direct:basicProcessing"/>
            </otherwise>
        </choice>
    </route>

    <!-- Premium Customer Processing Route -->
    <route id="premiumProcessing">
        <from uri="direct:premiumProcessing"/>
        
        <log message="Premium processing: Applying ${header.Discount} discount"/>
        
        <!-- Transform JSON to include processing info -->
        <setBody>
            <simple>{"originalOrder": ${body}, "customerTier": "PREMIUM", "priority": "${header.Priority}", "discount": ${header.Discount}, "processedAt": "${date:now:yyyy-MM-dd'T'HH:mm:ss}"}</simple>
        </setBody>
        
        <to uri="file:data/output/premium?fileName=premium-order-${date:now:yyyyMMdd-HHmmss}-${random(1000,9999)}.json"/>
        <log message="Premium order saved successfully"/>
    </route>

    <!-- Standard Customer Processing Route -->
    <route id="standardProcessing">
        <from uri="direct:standardProcessing"/>
        
        <log message="Standard processing: Applying ${header.Discount} discount"/>
        
        <setBody>
            <simple>{"originalOrder": ${body}, "customerTier": "STANDARD", "priority": "${header.Priority}", "discount": ${header.Discount}, "processedAt": "${date:now:yyyy-MM-dd'T'HH:mm:ss}"}</simple>
        </setBody>
        
        <to uri="file:data/output/standard?fileName=standard-order-${date:now:yyyyMMdd-HHmmss}-${random(1000,9999)}.json"/>
        <log message="Standard order saved successfully"/>
    </route>

    <!-- Basic Customer Processing Route -->
    <route id="basicProcessing">
        <from uri="direct:basicProcessing"/>
        
        <log message="Basic processing: No discount applied"/>
        
        <setBody>
            <simple>{"originalOrder": ${body}, "customerTier": "BASIC", "priority": "${header.Priority}", "discount": ${header.Discount}, "processedAt": "${date:now:yyyy-MM-dd'T'HH:mm:ss}"}</simple>
        </setBody>
        
        <to uri="file:data/output/basic?fileName=basic-order-${date:now:yyyyMMdd-HHmmss}-${random(1000,9999)}.json"/>
        <log message="Basic order saved successfully"/>
    </route>

</routes>
Subtask 3.2: Create Error Handling Route
Create an error handling route:
code src/main/resources/camel/error-handling-route.xml
Add the following XML configuration:
<?xml version="1.0" encoding="UTF-8"?>
<routes xmlns="http://camel.apache.org/schema/spring"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="
        http://camel.apache.org/schema/spring
        http://camel.apache.org/schema/spring/camel-spring.xsd">

    <!-- Route 3: Error Handling and Dead Letter Channel -->
    <route id="errorHandlingRoute" errorHandlerRef="myErrorHandler">
        <description>Demonstrates error handling in XML DSL</description>
        
        <from uri="timer:errorDemo?period=45000"/>
        
        <!-- Generate random scenario -->
        <setHeader name="Scenario">
            <simple>${random(1,4)}</simple>
        </setHeader>
        
        <log message="Testing error scenario: ${header.Scenario}"/>
        
        <choice>
            <when>
                <simple>${header.Scenario} == '1'</simple>
                <setBody>
                    <constant>Success: Normal processing completed</constant>
                </setBody>
                <log message="Normal processing: ${body}"/>
            </when>
            <when>
                <simple>${header.Scenario} == '2'</simple>
                <throwException exceptionType="java.lang.IllegalArgumentException" message="Simulated validation error"/>
            </when>
            <when>
                <simple>${header.Scenario} == '3'</simple>
                <throwException exceptionType="java.io.IOException" message="Simulated I/O error"/>
            </when>
            <otherwise>
                <throwException exceptionType="java.lang.RuntimeException" message="Simulated runtime error"/>
            </otherwise>
        </choice>
        
        <to uri="file:data/output/success?fileName=success-${date:now:yyyyMMdd-HHmmss}.txt"/>
    </route>

    <!-- Error Handler Configuration -->
    <errorHandler id="myErrorHandler" type="DeadLetterChannel" 
                  deadLetterUri="direct:errorProcessor"
                  useOriginalMessage="true">
        <redeliveryPolicy maximumRedeliveries="2" 
                         redeliveryDelay="1000" 
                         retryAttemptedLogLevel="WARN"/>
    </errorHandler>

    <!-- Error Processing Route -->
    <route id="errorProcessor">
        <from uri="direct:errorProcessor"/>
        
        <log message="Error occurred: ${exception.message}" loggingLevel="ERROR"/>
        
        <setHeader name="ErrorTimestamp">
            <simple>${date:now:yyyy-MM-dd HH:mm:ss}</simple>
        </setHeader>
        
        <setHeader name="ErrorType">
            <simple>${exception.class.simpleName}</simple>
        </setHeader>
        
        <setBody>
            <simple>Error Report:
Timestamp: ${header.ErrorTimestamp}
Error Type: ${header.ErrorType}
Error Message: ${exception.message}
Original Body: ${body}
            </simple>
        </setBody>
        
        <to uri="file:data/output/errors?fileName=error-${date:now:yyyyMMdd-HHmmss}.txt"/>
        <log message="Error logged to file system"/>
    </route>

</routes>
Task 4: Testing the XML DSL Routes
Subtask 4.1: Create Test Data Files
Create sample input files for testing:
echo "Hello World! This is a test file for XML DSL routing." > data/input/test1.txt
echo "Apache Camel makes integration easy and powerful." > data/input/test2.txt
echo "XML DSL provides declarative route configuration." > data/input/test3.txt
Subtask 4.2: Create Unit Tests
Create a test class for the XML DSL routes:
code src/test/java/com/alnafi/camel/xmldsl/XmlDslRouteTest.java
Add the following test code:
package com.alnafi.camel.xmldsl;

import org.apache.camel.CamelContext;
import org.apache.camel.EndpointInject;
import org.apache.camel.ProducerTemplate;
import org.apache.camel.component.mock.MockEndpoint;
import org.apache.camel.test.spring.junit5.CamelSpringBootTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.annotation.DirtiesContext;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;

import static org.junit.jupiter.api.Assertions.*;

@CamelSpringBootTest
@SpringBootTest(classes = CamelXmlDslApplication.class)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
public class XmlDslRouteTest {

    @Autowired
    private CamelContext camelContext;

    @Autowired
    private ProducerTemplate producerTemplate;

    @Test
    public void testCamelContextStartup() {
        assertNotNull(camelContext);
        assertTrue(camelContext.getStatus().isStarted());
    }

    @Test
    public void testRouteDefinitions() {
        // Verify that our XML routes are loaded
        assertTrue(camelContext.getRoutes().size() > 0);
        
        // Check for specific route IDs
        boolean fileProcessingRouteExists = camelContext.getRoutes().stream()
            .anyMatch(route -> "fileProcessingRoute".equals(route.getId()));
        assertTrue(fileProcessingRouteExists, "File processing route should be loaded");
        
        boolean contentBasedRouterExists = camelContext.getRoutes().stream()
            .anyMatch(route -> "contentBasedRouter".equals(route.getId()));
        assertTrue(contentBasedRouterExists, "Content-based router should be loaded");
    }

    @Test
    public void testDirectRouteProcessing() throws Exception {
        // Test premium processing route
        String testOrder = "{\"orderId\": \"12345\", \"customerType\": \"1\", \"amount\": 500}";
        
        String result = producerTemplate.requestBody("direct:premiumProcessing", testOrder, String.class);
        
        assertNotNull(result);
        assertTrue(result.contains("PREMIUM"));
        assertTrue(result.contains("0.15")); // Premium discount
    }
}
Subtask 4.3: Run the Application
Build and run the application:
mvn clean compile
mvn spring-boot:run
In a new terminal window, monitor the output directories:
# Watch for new files in output directories
watch -n 2 'find data/output -type f -name "*.txt" -o -name "*.json" | head -10'
Observe the console output to see the routes in action. You should see:
File processing messages
Content-based routing decisions
Error handling demonstrations
Timer-triggered route executions
Subtask 4.4: Verify Route Functionality
Check that files are being processed:
ls -la data/output/
View the content of processed files:
cat data/output/*.txt
Check the different customer tier processing:
ls -la data/output/premium/
ls -la data/output/standard/
ls -la data/output/basic/
Examine error handling:
ls -la data/output/errors/
cat data/output/errors/*.txt
Subtask 4.5: Run Unit Tests
Execute the unit tests:
mvn test
View test results:
mvn surefire-report:report
Task 5: Advanced XML DSL Features
Subtask 5.1: Create Message Aggregation Route
Create an aggregation route:
code src/main/resources/camel/aggregation-route.xml
Add the following XML configuration:
<?xml version="1.0" encoding="UTF-8"?>
<routes xmlns="http://camel.apache.org/schema/spring"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="
        http://camel.apache.org/schema/spring
        http://camel.apache.org/schema/spring/camel-spring.xsd">

    <!-- Route 4: Message Aggregation -->
    <route id="messageAggregationRoute">
        <description>Demonstrates message aggregation in XML DSL</description>
        
        <from uri="timer:aggregationDemo?period=10000"/>
        
        <!-- Generate multiple messages -->
        <split>
            <simple>1,2,3,4,5</simple>
            <setBody>
                <simple>{"messageId": "${body}", "data": "Sample data ${body}", "timestamp": "${date:now:yyyy-MM-dd'T'HH:mm:ss}"}</simple>
            </setBody>
            <setHeader name="BatchId">
                <simple>${date:now:yyyyMMddHHmm}</simple>
            </setHeader>
            <to uri="direct:aggregateMessages"/>
        </split>
    </route>

    <!-- Aggregation Route -->
    <route id="aggregationProcessor">
        <from uri="direct:aggregateMessages"/>
        
        <aggregate strategyRef="myAggregationStrategy" completionSize="5" completionTimeout="15000">
            <correlationExpression>
                <header>BatchId</header>
            </correlationExpression>
            
            <log message="Aggregating message: ${body}"/>
            
            <to uri="direct:processAggregatedBatch"/>
        </aggregate>
    </route>

    <!-- Process Aggregated Batch -->
    <route id="processAggregatedBatch">
        <from uri="direct:processAggregatedBatch"/>
        
        <log message="Processing aggregated batch with ${header.CamelAggregatedSize} messages"/>
        
        <setHeader name="AggregatedTimestamp">
            <simple>${date:now:yyyy-MM-dd HH:mm:ss}</simple>
        </setHeader>
        
        <transform>
            <simple>{"batchId": "${header.BatchId}", "messageCount": ${header.CamelAggregatedSize}, "aggregatedAt": "${header.AggregatedTimestamp}", "messages": ${body}}</simple>
        </transform>
        
        <to uri="file:data/output/aggregated?fileName=batch-${header.BatchId}.json"/>
        <log message="Aggregated batch saved successfully"/>
    </route>

</routes>
Subtask 5.2: Create Aggregation Strategy Bean
Create a custom aggregation strategy:
code src/main/java/com/alnafi/camel/xmldsl/MyAggregationStrategy.java
Add the following code:
package com.alnafi.camel.xmldsl;

import org.apache.camel.AggregationStrategy;
import org.apache.camel.Exchange;
import org.springframework.stereotype.Component;

@Component("myAggregationStrategy")
public class MyAggregationStrategy implements AggregationStrategy {

    @Override
    public Exchange aggregate(Exchange oldExchange, Exchange newExchange) {
        if (oldExchange == null) {
            // First message in the aggregation
            newExchange.getIn().setBody("[" + newExchange.getIn().getBody(String.class) + "]");
            return newExchange;
        }

        // Subsequent messages - append to the array
        String oldBody = oldExchange.getIn().getBody(String.class);
        String newBody = newExchange.getIn().getBody(String.class);
        
        // Remove the closing bracket and add the new message
        String aggregatedBody = oldBody.substring(0, oldBody.length() - 1) + "," + newBody + "]";
        
        oldExchange.getIn().setBody(aggregatedBody);
        return oldExchange;
    }
}
Task 6: Monitoring and Management
Subtask 6.1: Add JMX Monitoring
Update the application properties to enable JMX:
code src/main/resources/application.properties
Add the following JMX configuration:
# JMX Configuration
camel.springboot.jmx-enabled=true
spring.jmx.enabled=true
management.endpoints.web.exposure.include=health,info,camelroutes,metrics
management.endpoint.health.show-details=always
Subtask 6.2: Create Health Check Route
Create a health monitoring route:
code src/main/resources/camel/health-check-route.xml
Add the following XML configuration:
<?xml version="1.0" encoding="UTF-8"?>
<routes xmlns="http://camel.apache.org/schema/spring"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="
        http://camel.apache.org/schema/spring
        http://camel.apache.org/schema/spring/camel-spring.xsd">

    <!-- Route 5: Health Check and Monitoring -->
    <route id="healthCheckRoute">
        <description>Health check and system monitoring route</description>
        
        <from uri="timer:healthCheck?period=60000"/>
        
        <setBody>
            <simple>{"timestamp": "${date:now:yyyy-MM-dd'T'HH:mm:ss}", "status": "healthy", "activeRoutes": ${camelContext.routes.size()}, "uptime": "${camelContext.uptime}"}</simple>
        </setBody>
        
        <log message="Health check: ${body}"/>
        
        <to uri="file:data/output/health?fileName=health-${date:now:yyyyMMdd-HH}.json"/>
    </route>

</routes>
Troubleshooting Tips
Common Issues and Solutions
Issue 1: Routes not loading

Symptom: Application starts but no routes are active
Solution: Check the camel.springboot.xml-routes property in application.properties
Verification: Look for "Started X routes" in the startup logs
Issue 2: File permissions

Symptom: Cannot write to output directories
Solution: Ensure directories exist and have proper permissions
chmod 755 data/
chmod 755 data/output/
Issue 3: XML parsing errors

Symptom: Application fails to start with XML parsing exceptions
Solution: Validate XML syntax and namespace declarations
Tool: Use xmllint to validate XML files
xmllint --noout src/main/resources/camel/*.xml
Issue 4: Dependency conflicts

Symptom: ClassNotFoundException or NoSuchMethodError
Solution: Check Maven dependency tree for conflicts
mvn dependency:tree
Issue 5: Route testing issues

Symptom: Unit tests fail or routes don't behave as expected
Solution: Enable debug logging and use Camel test utilities
logging.level.org.apache.camel=DEBUG
Performance Optimization Tips
Use appropriate polling intervals for file and timer components
Configure thread pools for high-throughput scenarios
Implement proper error handling to prevent route failures
Use streaming for large file processing
Monitor JVM metrics and adjust heap size if needed
Conclusion
In this comprehensive lab, you have successfully:

Created XML DSL routes using Apache Camel's declarative configuration approach
Implemented content-based routing with conditional logic and message transformation
Configured error handling with dead letter channels and retry policies
Built message aggregation patterns to combine multiple messages into batches
Added monitoring and health checks to ensure route reliability
Tested routes using both manual testing and automated unit tests
Key Concepts Mastered
XML DSL Syntax: Understanding of Camel's XML-
