Lab 16: Ceph Monitoring with Prometheus and Grafana
Objectives
By the end of this lab, you will be able to:

• Set up and configure Prometheus to collect metrics from a Ceph storage cluster • Install and configure Grafana to create visual dashboards for Ceph monitoring • Integrate Grafana with Prometheus as a data source • Create custom monitoring alerts for critical Ceph cluster events • Build comprehensive dashboards to monitor Ceph cluster health, performance, and capacity • Understand key Ceph metrics and their significance for cluster management • Implement best practices for monitoring distributed storage systems

Prerequisites
Before starting this lab, you should have:

• Basic understanding of Ceph storage architecture and components • Familiarity with Linux command line operations • Knowledge of YAML configuration files • Understanding of basic networking concepts • Experience with containerized applications (Docker/Podman) • Basic knowledge of monitoring concepts and metrics

Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines for this lab. Simply click "Start Lab" to access your environment - no need to build your own VM or install additional software.

Your lab environment includes: • CentOS Stream 9 or Ubuntu 22.04 LTS machines • Pre-installed Ceph cluster (3 nodes minimum) • Docker/Podman container runtime • Network connectivity between all nodes • Sufficient storage and memory resources

Task 1: Set up Prometheus for Monitoring Ceph Metrics
Subtask 1.1: Install and Configure Prometheus
First, let's install Prometheus using containers for easy management.

Step 1: Create a dedicated directory structure for monitoring tools

sudo mkdir -p /opt/monitoring/{prometheus,grafana,alertmanager}
sudo mkdir -p /opt/monitoring/prometheus/{data,config}
sudo mkdir -p /opt/monitoring/grafana/{data,dashboards,provisioning}
sudo chown -R $USER:$USER /opt/monitoring
Step 2: Create Prometheus configuration file

cat > /opt/monitoring/prometheus/config/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "ceph_alerts.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'ceph-mgr'
    static_configs:
      - targets: ['ceph-mon1:9283', 'ceph-mon2:9283', 'ceph-mon3:9283']
    scrape_interval: 5s
    metrics_path: /metrics

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['ceph-mon1:9100', 'ceph-mon2:9100', 'ceph-mon3:9100', 'ceph-osd1:9100', 'ceph-osd2:9100', 'ceph-osd3:9100']
    scrape_interval: 5s

  - job_name: 'ceph-exporter'
    static_configs:
      - targets: ['ceph-mon1:9128']
    scrape_interval: 30s
EOF
Step 3: Start Prometheus container

sudo podman run -d \
  --name prometheus \
  --restart unless-stopped \
  -p 9090:9090 \
  -v /opt/monitoring/prometheus/config:/etc/prometheus:Z \
  -v /opt/monitoring/prometheus/data:/prometheus:Z \
  --user root \
  prom/prometheus:latest \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.console.templates=/etc/prometheus/consoles \
  --storage.tsdb.retention.time=30d \
  --web.enable-lifecycle
Subtask 1.2: Enable Ceph Manager Prometheus Module
Step 1: Enable the Prometheus module on your Ceph cluster

sudo ceph mgr module enable prometheus
Step 2: Configure the Prometheus module

# Set the port for Prometheus metrics (default is 9283)
sudo ceph config set mgr mgr/prometheus/server_port 9283

# Set the server address (bind to all interfaces)
sudo ceph config set mgr mgr/prometheus/server_addr 0.0.0.0

# Enable cache for better performance
sudo ceph config set mgr mgr/prometheus/cache true
Step 3: Verify the Prometheus module is running

sudo ceph mgr services
You should see output similar to:

{
    "prometheus": "http://ceph-mon1:9283/"
}
Step 4: Test metrics endpoint

curl http://localhost:9283/metrics | head -20
Subtask 1.3: Install Node Exporter on All Ceph Nodes
Node Exporter provides system-level metrics that are crucial for monitoring Ceph nodes.

Step 1: Create a script to install Node Exporter

cat > install_node_exporter.sh << 'EOF'
#!/bin/bash

# Download and install Node Exporter
NODE_EXPORTER_VERSION="1.6.1"
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

tar xvfz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
sudo chown root:root /usr/local/bin/node_exporter

# Create systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null << 'EOL'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=nobody
Group=nobody
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.listen-address=:9100

[Install]
WantedBy=multi-user.target
EOL

# Start and enable the service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Verify service is running
sudo systemctl status node_exporter
EOF

chmod +x install_node_exporter.sh
Step 2: Run the installation script on all Ceph nodes

# Run locally first
./install_node_exporter.sh

# Copy and run on other nodes (replace with your actual node IPs)
for node in ceph-mon2 ceph-mon3 ceph-osd1 ceph-osd2 ceph-osd3; do
    scp install_node_exporter.sh $node:/tmp/
    ssh $node "chmod +x /tmp/install_node_exporter.sh && sudo /tmp/install_node_exporter.sh"
done
Step 3: Verify Node Exporter is working on all nodes

for port in 9100; do
    echo "Testing Node Exporter on port $port"
    curl -s http://localhost:$port/metrics | grep "node_" | head -5
done
Task 2: Integrate Grafana with Prometheus for Visual Dashboards
Subtask 2.1: Install and Configure Grafana
Step 1: Create Grafana configuration directory structure

mkdir -p /opt/monitoring/grafana/provisioning/{datasources,dashboards}
Step 2: Create Grafana datasource configuration

cat > /opt/monitoring/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
    jsonData:
      timeInterval: "5s"
EOF
Step 3: Create dashboard provisioning configuration

cat > /opt/monitoring/grafana/provisioning/dashboards/dashboard.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'Ceph Dashboards'
    orgId: 1
    folder: 'Ceph'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF
Step 4: Start Grafana container

sudo podman run -d \
  --name grafana \
  --restart unless-stopped \
  -p 3000:3000 \
  -v /opt/monitoring/grafana/data:/var/lib/grafana:Z \
  -v /opt/monitoring/grafana/provisioning:/etc/grafana/provisioning:Z \
  -v /opt/monitoring/grafana/dashboards:/var/lib/grafana/dashboards:Z \
  --user root \
  -e "GF_SECURITY_ADMIN_PASSWORD=admin123" \
  -e "GF_USERS_ALLOW_SIGN_UP=false" \
  grafana/grafana:latest
Step 5: Wait for Grafana to start and verify access

# Wait for Grafana to be ready
sleep 30

# Test Grafana access
curl -s http://localhost:3000/api/health
Subtask 2.2: Create Ceph Monitoring Dashboards
Step 1: Create a comprehensive Ceph cluster overview dashboard

cat > /opt/monitoring/grafana/dashboards/ceph-cluster-overview.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Ceph Cluster Overview",
    "tags": ["ceph", "storage"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Cluster Health Status",
        "type": "stat",
        "targets": [
          {
            "expr": "ceph_health_status",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "mappings": [
              {
                "options": {
                  "0": {
                    "text": "HEALTH_OK",
                    "color": "green"
                  },
                  "1": {
                    "text": "HEALTH_WARN",
                    "color": "yellow"
                  },
                  "2": {
                    "text": "HEALTH_ERR",
                    "color": "red"
                  }
                },
                "type": "value"
              }
            ]
          }
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        }
      },
      {
        "id": 2,
        "title": "Total Cluster Capacity",
        "type": "stat",
        "targets": [
          {
            "expr": "ceph_cluster_total_bytes",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "bytes"
          }
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        }
      },
      {
        "id": 3,
        "title": "Cluster Usage",
        "type": "piechart",
        "targets": [
          {
            "expr": "ceph_cluster_total_used_bytes",
            "refId": "A",
            "legendFormat": "Used"
          },
          {
            "expr": "ceph_cluster_total_bytes - ceph_cluster_total_used_bytes",
            "refId": "B",
            "legendFormat": "Available"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "bytes"
          }
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 8
        }
      },
      {
        "id": 4,
        "title": "OSD Status",
        "type": "stat",
        "targets": [
          {
            "expr": "ceph_osd_up",
            "refId": "A",
            "legendFormat": "OSDs Up: {{osd}}"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 8
        }
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
EOF
Step 2: Create an OSD performance dashboard

cat > /opt/monitoring/grafana/dashboards/ceph-osd-performance.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Ceph OSD Performance",
    "tags": ["ceph", "osd", "performance"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "OSD Read IOPS",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(ceph_osd_op_r_total[5m])",
            "refId": "A",
            "legendFormat": "OSD {{osd}} Read IOPS"
          }
        ],
        "yAxes": [
          {
            "label": "IOPS",
            "min": 0
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        }
      },
      {
        "id": 2,
        "title": "OSD Write IOPS",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(ceph_osd_op_w_total[5m])",
            "refId": "A",
            "legendFormat": "OSD {{osd}} Write IOPS"
          }
        ],
        "yAxes": [
          {
            "label": "IOPS",
            "min": 0
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        }
      },
      {
        "id": 3,
        "title": "OSD Latency",
        "type": "graph",
        "targets": [
          {
            "expr": "ceph_osd_apply_latency_ms",
            "refId": "A",
            "legendFormat": "OSD {{osd}} Apply Latency"
          },
          {
            "expr": "ceph_osd_commit_latency_ms",
            "refId": "B",
            "legendFormat": "OSD {{osd}} Commit Latency"
          }
        ],
        "yAxes": [
          {
            "label": "Milliseconds",
            "min": 0
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 24,
          "x": 0,
          "y": 8
        }
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
EOF
Step 3: Access Grafana and verify dashboards

echo "Grafana is available at: http://localhost:3000"
echo "Username: admin"
echo "Password: admin123"
Open your web browser and navigate to http://localhost:3000. Log in with the credentials above and verify that:

Prometheus datasource is configured and working
Dashboards are loaded in the "Ceph" folder
Metrics are being displayed correctly
Subtask 2.3: Configure Advanced Dashboard Features
Step 1: Create a pool-specific monitoring dashboard

cat > /opt/monitoring/grafana/dashboards/ceph-pools.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Ceph Pools Monitoring",
    "tags": ["ceph", "pools"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Pool Usage by Pool",
        "type": "graph",
        "targets": [
          {
            "expr": "ceph_pool_stored_bytes",
            "refId": "A",
            "legendFormat": "Pool {{pool_id}} - {{name}}"
          }
        ],
        "yAxes": [
          {
            "label": "Bytes",
            "min": 0
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 24,
          "x": 0,
          "y": 0
        }
      },
      {
        "id": 2,
        "title": "Pool Objects Count",
        "type": "graph",
        "targets": [
          {
            "expr": "ceph_pool_objects",
            "refId": "A",
            "legendFormat": "Pool {{pool_id}} - {{name}}"
          }
        ],
        "yAxes": [
          {
            "label": "Objects",
            "min": 0
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 8
        }
      },
      {
        "id": 3,
        "title": "Pool Read/Write Operations",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(ceph_pool_rd_total[5m])",
            "refId": "A",
            "legendFormat": "Pool {{pool_id}} Reads"
          },
          {
            "expr": "rate(ceph_pool_wr_total[5m])",
            "refId": "B",
            "legendFormat": "Pool {{pool_id}} Writes"
          }
        ],
        "yAxes": [
          {
            "label": "Operations/sec",
            "min": 0
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 8
        }
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
EOF
Step 2: Restart Grafana to load new dashboards

sudo podman restart grafana
sleep 30
Task 3: Create Custom Monitoring Alerts for Ceph
Subtask 3.1: Install and Configure Alertmanager
Step 1: Create Alertmanager configuration

cat > /opt/monitoring/alertmanager/alertmanager.yml << 'EOF'
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'ceph-alerts@yourdomain.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://localhost:5001/webhook'
    send_resolved: true

- name: 'email-alerts'
  email_configs:
  - to: 'admin@yourdomain.com'
    subject: 'Ceph Alert: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      {{ end }}

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOF
Step 2: Start Alertmanager container

sudo podman run -d \
  --name alertmanager \
  --restart unless-stopped \
  -p 9093:9093 \
  -v /opt/monitoring/alertmanager:/etc/alertmanager:Z \
  prom/alertmanager:latest \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/alertmanager
Subtask 3.2: Create Ceph-Specific Alert Rules
Step 1: Create comprehensive Ceph alert rules

cat > /opt/monitoring/prometheus/config/ceph_alerts.yml << 'EOF'
groups:
- name: ceph-cluster-alerts
  rules:
  - alert: CephClusterErrorState
    expr: ceph_health_status == 2
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Ceph cluster is in ERROR state"
      description: "Ceph cluster health is in ERROR state for more than 5 minutes. Immediate attention required."

  - alert: CephClusterWarningState
    expr: ceph_health_status == 1
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "Ceph cluster is in WARNING state"
      description: "Ceph cluster health is in WARNING state for more than 10 minutes."

  - alert: CephOSDDown
    expr: ceph_osd_up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Ceph OSD {{ $labels.osd }} is down"
      description: "OSD {{ $labels.osd }} has been down for more than 1 minute."

  - alert: CephOSDNearFull
    expr: ceph_osd_utilization > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Ceph OSD {{ $labels.osd }} is nearly full"
      description: "OSD {{ $labels.osd }} is {{ $value }}% full."

  - alert: CephOSDFull
    expr: ceph_osd_utilization > 95
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Ceph OSD {{ $labels.osd }} is full"
      description: "OSD {{ $labels.osd }} is {{ $value }}% full. Immediate action required."

  - alert: CephMonitorDown
    expr: up{job="ceph-mgr"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Ceph Monitor is down"
      description: "Ceph Monitor {{ $labels.instance }} has been down for more than 1 minute."

  - alert: CephPGsInconsistent
    expr: ceph_pg_inconsistent > 0
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Ceph has inconsistent PGs"
      description: "{{ $value }} PGs are in an inconsistent state."

  - alert: CephPGsDown
    expr: ceph_pg_down > 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Ceph has PGs in down state"
      description: "{{ $value }} PGs are in down state."

- name: ceph-performance-alerts
  rules:
  - alert: CephHighLatency
    expr: ceph_osd_apply_latency_ms > 100
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High latency on Ceph OSD {{ $labels.osd }}"
      description: "OSD {{ $labels.osd }} has high apply latency: {{ $value }}ms"

  - alert: CephLowIOPS
    expr: rate(ceph_osd_op_total[5m]) < 10
    for: 10m
    labels:
      severity: info
    annotations:
      summary: "Low IOPS on Ceph cluster"
      description: "Ceph cluster IOPS is below 10 ops/sec for 10 minutes."

- name: ceph-capacity-alerts
  rules:
  - alert: CephClusterNearFull
    expr: (ceph_cluster_total_used_bytes / ceph_cluster_total_bytes) * 100 > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Ceph cluster is nearly full"
      description: "Ceph cluster is {{ $value }}% full."

  - alert: CephClusterFull
    expr: (ceph_cluster_total_used_bytes / ceph_cluster_total_bytes) * 100 > 90
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Ceph cluster is critically full"
      description: "Ceph cluster is {{ $value }}% full. Immediate expansion required."
EOF
Step 2: Reload Prometheus configuration

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
Step 3: Verify alert rules are loaded

# Check if rules are loaded
curl -s http://localhost:9090/api/v1/rules | jq '.data.groups[].name'
Subtask 3.3: Test Alert Functionality
Step 1: Create a simple webhook receiver for testing

cat > /tmp/webhook_receiver.py << 'EOF'
#!/usr/bin/env python3
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
import logging

logging.basicConfig(level=logging.INFO)

class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        try:
            alert_data = json.loads(post_data.decode('utf-8'))
            print(f"Received alert: {json.dumps(alert_data, indent=2)}")
            
            for alert in alert_data.get('alerts', []):
                status = alert.get('status', 'unknown')
                alertname = alert.get('labels', {}).get('alertname', 'unknown')
                summary = alert.get('annotations', {}).get('summary', 'No summary')
                
                print(f"Alert: {alertname} - Status: {status}")
                print(f"Summary: {summary}")
                print("-" * 50)
                
        except json.JSONDecodeError:
            print("Failed to decode JSON")
        
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'OK')

if __name__ == '__main__':
    server = HTTPServer(('localhost', 5001), WebhookHandler)
    print("Webhook receiver listening on http://localhost:5001")
    server.serve_forever()
EOF

chmod +x /tmp/webhook_receiver.py
Step 2: Start the webhook receiver in background

python3 /tmp/webhook_receiver.py &
WEBHOOK_PID=$!
echo "Webhook receiver started with PID: $WEBHOOK_PID"
Step 3: Simulate an alert condition (optional)

# You can simulate high OSD usage by creating a test file
# This is for demonstration purposes only
echo "To test alerts, you can:"
echo "1. Stop an OSD: sudo systemctl stop ceph-osd@0"
echo "2. Fill up storage space"
echo "3. Wait for alerts to trigger"
echo ""
echo "Check active alerts at: http://localhost:9090/alerts"
echo "Check Alertmanager at: http://localhost:9093"
Subtask 3.4: Configure Alert Notification Channels
Step 1: Update Alertmanager configuration with multiple notification channels

cat > /opt/monitoring/alertmanager/alertmanager.yml << 'EOF'
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'ceph-alerts@yourdomain.com'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default-receiver'
  routes:
  - match:
      severity: critical
    receiver: 'critical-alerts'
  - match:
      severity: warning
    receiver: 'warning-alerts'

receivers:
- name: 'default-receiver'
  webhook_configs:
  - url: 'http://localhost:5001/webhook'
    send_resolved: true

- name: 'critical-alerts'
  webhook_configs:
  - url: 'http://localhost:5001/webhook'
    send_resolved: true
  email_configs:
  - to: 'admin@yourdomain.com'
    subject: 'CRITICAL: Ceph Alert - {{ .GroupLabels.alertname }}'
    body: |
      CRITICAL ALERT TRIGGERED
      
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      Severity: {{ .Labels.severity }}
      Instance: {{ .Labels.instance }}
      Time: {{ .StartsAt }}
      {{ end }}

- name: 'warning-alerts'
  webhook_configs:
  - url: 'http://localhost:5001/webhook'
    send_resolved: true

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
EOF
Step 2: Restart Alertmanager with new configuration

sudo podman restart alertmanager
sleep 10
Step 3: Verify Alertmanager configuration

curl -s http://localhost:9093/api/v1/status | jq '.data.configYAML'
Verification and Testing
Step 1: Verify All Services Are Running
echo "Checking service status..."
echo "=========================="

# Check Prometheus
if curl -s http://localhost:9090/api/v1/query?query=up | grep -q "success"; then
    echo "✓ Prometheus is running and accessible"
else
    echo "✗ Prometheus is not responding"
fi

# Check Grafana
if curl -s http://localhost:3000/api/health | grep -q "ok"; then
    echo "✓ Grafana is running and accessible"
else
    echo "✗ Grafana is not responding"
fi

# Check Alertmanager
if curl -s http://localhost:9093/api/v1/status | grep -q "success"; then
    echo "✓ Alertmanager is running and accessible"
else
    echo "✗ Alertmanager is not responding"
fi

# Check Ceph metrics
if curl -s http://localhost:9283/metrics | grep -q "ceph_"; then
    echo "✓ Ceph metrics are being exported"
else
    echo "✗ Ceph metrics are not available"
fi
Step 2: Test Metric Collection
echo "Testing metric collection..."
echo "============================"

# Test some key Ceph metrics
curl -s "http://localhost:9090/api/v1/query?query=ceph_health_
