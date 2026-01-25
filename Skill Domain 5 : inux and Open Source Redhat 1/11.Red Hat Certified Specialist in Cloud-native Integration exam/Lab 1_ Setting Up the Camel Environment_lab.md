Lab 1: Setting Up the Camel Environment
Objectives
By the end of this lab, you will be able to:

Install Apache Camel and its required components (ActiveMQ and Karaf) on a Linux system
Configure a basic Camel context for integration development
Create and execute a simple Camel route to verify the installation
Understand the fundamental components of the Camel integration framework
Validate the complete setup through practical testing
Prerequisites
Before starting this lab, you should have:

Basic understanding of Linux command-line operations
Familiarity with Java concepts and terminology
Knowledge of XML and basic configuration files
Understanding of enterprise integration patterns (helpful but not required)
Basic networking concepts (ports, localhost, etc.)
Technical Requirements:

Java 11 or higher (OpenJDK recommended)
Minimum 2GB RAM available
At least 2GB free disk space
Internet connection for downloading components
Lab Environment Setup
Good News! Al Nafi provides you with a pre-configured Linux-based cloud machine. Simply click Start Lab and you'll have access to a ready-to-use environment. No need to build your own virtual machine or worry about initial system configuration.

Your cloud machine comes with:

Ubuntu 20.04 LTS or CentOS 8
OpenJDK 11 pre-installed
Network access configured
Terminal access ready
Task 1: Install Apache Camel and Required Components
Subtask 1.1: Verify Java Installation
First, let's confirm that Java is properly installed and configured on your system.

Open a terminal window
Check the Java version:
java -version
Verify the Java compiler:
javac -version
Check the JAVA_HOME environment variable:
echo $JAVA_HOME
If JAVA_HOME is not set, configure it:

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/.bashrc
source ~/.bashrc
Subtask 1.2: Create Working Directory Structure
Organize your workspace for the Camel environment:

mkdir -p ~/camel-lab
cd ~/camel-lab
mkdir -p downloads bin config logs
Subtask 1.3: Download and Install Apache Karaf
Apache Karaf serves as the OSGi runtime container for Camel.

Download Karaf:
cd ~/camel-lab/downloads
wget https://archive.apache.org/dist/karaf/4.4.3/apache-karaf-4.4.3.tar.gz
Extract Karaf:
tar -xzf apache-karaf-4.4.3.tar.gz
mv apache-karaf-4.4.3 ~/camel-lab/karaf
Set Karaf environment variables:
export KARAF_HOME=~/camel-lab/karaf
echo 'export KARAF_HOME=~/camel-lab/karaf' >> ~/.bashrc
echo 'export PATH=$PATH:$KARAF_HOME/bin' >> ~/.bashrc
source ~/.bashrc
Subtask 1.4: Download and Install Apache ActiveMQ
ActiveMQ will serve as our message broker for Camel routes.

Download ActiveMQ:
cd ~/camel-lab/downloads
wget https://archive.apache.org/dist/activemq/5.17.2/apache-activemq-5.17.2-bin.tar.gz
Extract ActiveMQ:
tar -xzf apache-activemq-5.17.2-bin.tar.gz
mv apache-activemq-5.17.2 ~/camel-lab/activemq
Set ActiveMQ environment variables:
export ACTIVEMQ_HOME=~/camel-lab/activemq
echo 'export ACTIVEMQ_HOME=~/camel-lab/activemq' >> ~/.bashrc
echo 'export PATH=$PATH:$ACTIVEMQ_HOME/bin' >> ~/.bashrc
source ~/.bashrc
Subtask 1.5: Download Apache Camel
Download Camel distribution:
cd ~/camel-lab/downloads
wget https://archive.apache.org/dist/camel/apache-camel/3.20.7/apache-camel-3.20.7.tar.gz
Extract Camel:
tar -xzf apache-camel-3.20.7.tar.gz
mv apache-camel-3.20.7 ~/camel-lab/camel
Set Camel environment variables:
export CAMEL_HOME=~/camel-lab/camel
echo 'export CAMEL_HOME=~/camel-lab/camel' >> ~/.bashrc
echo 'export PATH=$PATH:$CAMEL_HOME/bin' >> ~/.bashrc
source ~/.bashrc
Task 2: Set Up a Basic Camel Context
Subtask 2.1: Start ActiveMQ Broker
Before creating Camel routes, we need a running message broker.

Start ActiveMQ in the background:
cd $ACTIVEMQ_HOME
./bin/activemq start
Verify ActiveMQ is running:
./bin/activemq status
Check the web console (optional):
Open a web browser and navigate to: http://localhost:8161/admin
Default credentials: admin/admin
Subtask 2.2: Start Karaf Container
Start Karaf:
cd $KARAF_HOME
./bin/karaf
You should see the Karaf console prompt:

        __ __                  ____      
       / //_/____ __________ _/ __/      
      / ,<  / __ `/ ___/ __ `/ /_        
     / /| |/ /_/ / /  / /_/ / __/        
    /_/ |_|\__,_/_/   \__,_/_/           

  Apache Karaf (4.4.3)

Hit '<tab>' for a list of available commands
and '[cmd] --help' for help on a specific command.
Hit '<ctrl-d>' or type 'system:shutdown' to shutdown Karaf.

karaf@root()>
Subtask 2.3: Install Camel Features in Karaf
Within the Karaf console, install the necessary Camel features:

Add Camel feature repository:
feature:repo-add camel 3.20.7
Install core Camel features:
feature:install camel-core
feature:install camel-blueprint
feature:install camel-jms
feature:install camel-activemq
Verify installed features:
feature:list | grep camel
Subtask 2.4: Create Basic Camel Context Configuration
Open a new terminal (keep Karaf running in the first terminal)
Create a blueprint configuration file:
mkdir -p ~/camel-lab/config
cd ~/camel-lab/config
Create the blueprint XML file:
cat > camel-context.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<blueprint xmlns="http://www.osgi.org/xmlns/blueprint/v1.0.0"
           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
           xmlns:camel="http://camel.apache.org/schema/blueprint"
           xsi:schemaLocation="
           http://www.osgi.org/xmlns/blueprint/v1.0.0 
           https://www.osgi.org/xmlns/blueprint/v1.0.0/blueprint.xsd
           http://camel.apache.org/schema/blueprint 
           https://camel.apache.org/schema/blueprint/camel-blueprint.xsd">

    <!-- ActiveMQ Connection Factory -->
    <bean id="activemq" class="org.apache.activemq.camel.component.ActiveMQComponent">
        <property name="brokerURL" value="tcp://localhost:61616"/>
    </bean>

    <!-- Camel Context -->
    <camelContext id="camel-lab-context" xmlns="http://camel.apache.org/schema/blueprint">
        
        <!-- Simple File to JMS Route -->
        <route id="file-to-jms-route">
            <from uri="file:~/camel-lab/input?noop=true"/>
            <log message="Processing file: ${header.CamelFileName}"/>
            <to uri="activemq:queue:test.queue"/>
        </route>

        <!-- JMS to File Route -->
        <route id="jms-to-file-route">
            <from uri="activemq:queue:test.queue"/>
            <log message="Received message: ${body}"/>
            <to uri="file:~/camel-lab/output"/>
        </route>

    </camelContext>

</blueprint>
EOF
Task 3: Verify the Setup by Running a Simple Camel Route
Subtask 3.1: Deploy the Camel Route
Copy the blueprint file to Karaf's deploy directory:
cp ~/camel-lab/config/camel-context.xml $KARAF_HOME/deploy/
In the Karaf console, verify the bundle is deployed:
bundle:list | grep camel-context
Check route status:
camel:route-list
Subtask 3.2: Create Test Directories and Files
Create input and output directories:
mkdir -p ~/camel-lab/input ~/camel-lab/output
Create a test file:
echo "Hello from Apache Camel! This is a test message." > ~/camel-lab/input/test-message.txt
Subtask 3.3: Test the Route Execution
Monitor the Karaf console for log messages showing file processing

Check if the message was processed:

ls -la ~/camel-lab/output/
Verify the content was transferred:
cat ~/camel-lab/output/test-message.txt
Subtask 3.4: Monitor Route Statistics
In the Karaf console, check route performance:

camel:route-info file-to-jms-route
camel:route-info jms-to-file-route
Subtask 3.5: Test with Multiple Files
Create additional test files:
for i in {1..5}; do
    echo "Test message number $i - $(date)" > ~/camel-lab/input/message-$i.txt
done
Watch the processing in real-time:
watch -n 2 "ls -la ~/camel-lab/output/"
Troubleshooting Common Issues
Issue 1: Java Not Found
Problem: Command not found errors for Java Solution:

sudo apt update
sudo apt install openjdk-11-jdk
Issue 2: Port Already in Use
Problem: ActiveMQ fails to start due to port conflicts Solution:

netstat -tulpn | grep :61616
sudo kill -9 <process_id>
Issue 3: Permission Denied
Problem: Cannot write to directories Solution:

chmod 755 ~/camel-lab/input ~/camel-lab/output
Issue 4: Karaf Console Not Responding
Problem: Karaf appears frozen Solution:

Press Ctrl+C to interrupt current command
Type system:shutdown to restart cleanly
Verification Checklist
Confirm your setup is working by checking these items:

 Java version 11 or higher is installed
 ActiveMQ is running and accessible on port 61616
 Karaf console is operational
 Camel features are installed in Karaf
 Blueprint bundle is deployed successfully
 Routes are listed and show as "Started"
 Test files are processed from input to output directory
 Log messages appear in Karaf console during processing
Conclusion
Congratulations! You have successfully set up a complete Apache Camel integration environment. Here's what you accomplished:

Key Achievements:

Installed Core Components: You set up Apache Camel, ActiveMQ, and Karaf, creating a robust integration platform
Configured Runtime Environment: You established proper environment variables and directory structures for organized development
Created Integration Routes: You built and deployed your first Camel routes that demonstrate file-to-JMS and JMS-to-file integration patterns
Verified Functionality: You tested the complete message flow and confirmed all components work together seamlessly
Why This Matters: This foundation prepares you for enterprise integration scenarios where you'll need to connect different systems, transform data, and route messages reliably. The skills you've developed here are directly applicable to:

Cloud-native Integration: Essential for Red Hat Certified Specialist certification
Microservices Communication: Connecting distributed applications
Legacy System Integration: Bridging old and new technologies
Real-time Data Processing: Handling streaming data and events
Next Steps: With your environment ready, you can now explore advanced Camel features like:

Complex routing patterns and transformations
Error handling and retry mechanisms
REST API integration
Database connectivity
Cloud service integration
Your Camel environment is now ready for advanced integration development and testing scenarios!
