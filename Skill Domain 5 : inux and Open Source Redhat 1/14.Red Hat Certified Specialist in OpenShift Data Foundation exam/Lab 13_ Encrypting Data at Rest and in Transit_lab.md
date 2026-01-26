Lab 13: Encrypting Data at Rest and in Transit
Objectives
By the end of this lab, you will be able to:

Configure encryption for Persistent Volume Claims (PVCs) in OpenShift Data Foundation
Set up TLS encryption for data in transit
Verify and validate encryption configurations
Understand the importance of data security in cloud-native environments
Apply encryption policies for both stored and transmitted data
Prerequisites
Before starting this lab, you should have:

Basic understanding of Kubernetes and OpenShift concepts
Familiarity with Persistent Volumes and Persistent Volume Claims
Knowledge of TLS/SSL certificates and encryption concepts
Experience with command-line interface operations
Understanding of YAML configuration files
Lab Environment
Ready-to-Use Cloud Machines: Al Nafi provides pre-configured Linux-based cloud machines with OpenShift Data Foundation already installed. Simply click Start Lab to begin - no need to build your own virtual machine or install software.

Your lab environment includes:

OpenShift cluster with Data Foundation operator
Command-line tools (oc, kubectl)
Sample applications and data
Pre-configured storage classes
Task 1: Configure Encryption for PVCs
Subtask 1.1: Examine Current Storage Classes
First, let's examine the existing storage classes and understand the current encryption status.

Connect to your lab environment and open a terminal

List available storage classes:

oc get storageclass
Examine the default ODF storage class details:
oc describe storageclass ocs-storagecluster-ceph-rbd
Check for encryption parameters:
oc get storageclass ocs-storagecluster-ceph-rbd -o yaml
Subtask 1.2: Create an Encrypted Storage Class
Now we'll create a new storage class with encryption enabled.

Create a new encrypted storage class configuration:
cat > encrypted-storageclass.yaml << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ocs-storagecluster-ceph-rbd-encrypted
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: openshift-storage.rbd.csi.ceph.com
parameters:
  clusterID: openshift-storage
  pool: ocs-storagecluster-cephblockpool
  imageFeatures: layering
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: openshift-storage
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: openshift-storage
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
  csi.storage.k8s.io/node-stage-secret-namespace: openshift-storage
  encrypted: "true"
  encryptionKMSID: vault
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF
Apply the encrypted storage class:
oc apply -f encrypted-storageclass.yaml
Verify the storage class was created:
oc get storageclass | grep encrypted
Subtask 1.3: Create an Encrypted PVC
Now let's create a PVC that uses our encrypted storage class.

Create a PVC with encryption:
cat > encrypted-pvc.yaml << EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: encrypted-data-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: ocs-storagecluster-ceph-rbd-encrypted
EOF
Apply the PVC configuration:
oc apply -f encrypted-pvc.yaml
Check the PVC status:
oc get pvc encrypted-data-pvc
Wait for the PVC to be bound:
oc get pvc encrypted-data-pvc -w
Subtask 1.4: Deploy an Application Using Encrypted Storage
Let's deploy a test application that uses our encrypted PVC.

Create a test application deployment:
cat > encrypted-app.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: encrypted-data-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: encrypted-data-app
  template:
    metadata:
      labels:
        app: encrypted-data-app
    spec:
      containers:
      - name: data-container
        image: registry.redhat.io/ubi8/ubi:latest
        command: ["/bin/bash"]
        args: ["-c", "while true; do echo 'Encrypted data test' >> /data/test.txt; sleep 30; done"]
        volumeMounts:
        - name: encrypted-storage
          mountPath: /data
      volumes:
      - name: encrypted-storage
        persistentVolumeClaim:
          claimName: encrypted-data-pvc
EOF
Deploy the application:
oc apply -f encrypted-app.yaml
Verify the deployment:
oc get deployment encrypted-data-app
oc get pods -l app=encrypted-data-app
Task 2: Set Up Encryption for Data in Transit Using TLS
Subtask 2.1: Create TLS Certificates
We'll create TLS certificates for securing data in transit.

Create a private key:
openssl genrsa -out server.key 2048
Create a certificate signing request:
openssl req -new -key server.key -out server.csr -subj "/CN=secure-app.default.svc.cluster.local/O=MyOrg"
Generate a self-signed certificate:
openssl x509 -req -in server.csr -signkey server.key -out server.crt -days 365
Create a Kubernetes secret with the TLS certificate:
oc create secret tls secure-app-tls --cert=server.crt --key=server.key
Verify the secret was created:
oc get secret secure-app-tls
oc describe secret secure-app-tls
Subtask 2.2: Deploy a Secure Application with TLS
Now we'll deploy an application that uses TLS for encrypted communication.

Create a secure web application:
cat > secure-app.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-web-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-web-app
  template:
    metadata:
      labels:
        app: secure-web-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 443
        - containerPort: 80
        volumeMounts:
        - name: tls-certs
          mountPath: /etc/nginx/ssl
          readOnly: true
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: tls-certs
        secret:
          secretName: secure-app-tls
      - name: nginx-config
        configMap:
          name: nginx-tls-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-tls-config
  namespace: default
data:
  default.conf: |
    server {
        listen 80;
        return 301 https://\$server_name\$request_uri;
    }
    
    server {
        listen 443 ssl;
        server_name secure-app.default.svc.cluster.local;
        
        ssl_certificate /etc/nginx/ssl/tls.crt;
        ssl_certificate_key /etc/nginx/ssl/tls.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        
        location /health {
            return 200 "Healthy with TLS\n";
            add_header Content-Type text/plain;
        }
    }
EOF
Deploy the secure application:
oc apply -f secure-app.yaml
Create a service for the secure application:
cat > secure-service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: secure-app-service
  namespace: default
spec:
  selector:
    app: secure-web-app
  ports:
  - name: https
    port: 443
    targetPort: 443
    protocol: TCP
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  type: ClusterIP
EOF
Apply the service configuration:
oc apply -f secure-service.yaml
Subtask 2.3: Create a Secure Route
Let's create an OpenShift route with TLS termination.

Create a secure route:
cat > secure-route.yaml << EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: secure-app-route
  namespace: default
spec:
  host: secure-app-$(oc whoami).apps.cluster.local
  to:
    kind: Service
    name: secure-app-service
    weight: 100
  port:
    targetPort: https
  tls:
    termination: passthrough
    insecureEdgeTerminationPolicy: Redirect
EOF
Apply the route configuration:
oc apply -f secure-route.yaml
Get the route URL:
oc get route secure-app-route
Task 3: Verify Encryption Configurations
Subtask 3.1: Verify Data at Rest Encryption
Let's verify that our data at rest is properly encrypted.

Check the encrypted PVC details:
oc describe pvc encrypted-data-pvc
Examine the persistent volume:
PV_NAME=$(oc get pvc encrypted-data-pvc -o jsonpath='{.spec.volumeName}')
oc describe pv $PV_NAME
Check the application pod and verify data writing:
POD_NAME=$(oc get pods -l app=encrypted-data-app -o jsonpath='{.items[0].metadata.name}')
oc exec $POD_NAME -- ls -la /data
oc exec $POD_NAME -- cat /data/test.txt
Verify encryption parameters in the storage class:
oc get storageclass ocs-storagecluster-ceph-rbd-encrypted -o yaml | grep -A 5 -B 5 encrypted
Subtask 3.2: Verify Data in Transit Encryption
Now let's verify that our TLS configuration is working properly.

Check the secure application pod status:
oc get pods -l app=secure-web-app
Verify TLS certificate is mounted:
SECURE_POD=$(oc get pods -l app=secure-web-app -o jsonpath='{.items[0].metadata.name}')
oc exec $SECURE_POD -- ls -la /etc/nginx/ssl/
Test the TLS configuration from within the cluster:
oc run test-client --image=curlimages/curl:latest --rm -it --restart=Never -- sh
Inside the test pod, run:

curl -k https://secure-app-service.default.svc.cluster.local/health
curl -v -k https://secure-app-service.default.svc.cluster.local/health 2>&1 | grep -i tls
exit
Verify the route is using HTTPS:
ROUTE_URL=$(oc get route secure-app-route -o jsonpath='{.spec.host}')
echo "Route URL: https://$ROUTE_URL"
Subtask 3.3: Test Encryption End-to-End
Let's perform comprehensive testing of both encryption types.

Create a test script to verify encryption:
cat > verify-encryption.sh << 'EOF'
#!/bin/bash

echo "=== Encryption Verification Script ==="
echo

echo "1. Checking encrypted PVC status:"
oc get pvc encrypted-data-pvc -o wide

echo
echo "2. Checking encrypted storage class:"
oc get storageclass ocs-storagecluster-ceph-rbd-encrypted

echo
echo "3. Verifying data is being written to encrypted volume:"
POD_NAME=$(oc get pods -l app=encrypted-data-app -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$POD_NAME" ]; then
    echo "Pod: $POD_NAME"
    oc exec $POD_NAME -- wc -l /data/test.txt
else
    echo "No encrypted data app pod found"
fi

echo
echo "4. Checking TLS secret:"
oc get secret secure-app-tls -o yaml | grep -A 2 -B 2 "tls.crt\|tls.key"

echo
echo "5. Verifying secure application:"
SECURE_POD=$(oc get pods -l app=secure-web-app -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$SECURE_POD" ]; then
    echo "Secure pod: $SECURE_POD"
    oc exec $SECURE_POD -- nginx -t
else
    echo "No secure web app pod found"
fi

echo
echo "6. Testing internal HTTPS connectivity:"
oc run curl-test --image=curlimages/curl:latest --rm --restart=Never -- curl -k -s -o /dev/null -w "%{http_code}" https://secure-app-service.default.svc.cluster.local/health

echo
echo "=== Verification Complete ==="
EOF
Make the script executable and run it:
chmod +x verify-encryption.sh
./verify-encryption.sh
Subtask 3.4: Monitor Encryption Status
Let's set up monitoring to continuously verify our encryption configurations.

Create a monitoring script:
cat > monitor-encryption.sh << 'EOF'
#!/bin/bash

echo "Starting encryption monitoring..."
echo "Press Ctrl+C to stop"

while true; do
    clear
    echo "=== Encryption Status Monitor ==="
    echo "Time: $(date)"
    echo
    
    echo "Encrypted PVC Status:"
    oc get pvc encrypted-data-pvc --no-headers
    
    echo
    echo "Secure App Pods:"
    oc get pods -l app=secure-web-app --no-headers
    
    echo
    echo "TLS Secret Age:"
    oc get secret secure-app-tls --no-headers
    
    echo
    echo "Data Growth (encrypted volume):"
    POD_NAME=$(oc get pods -l app=encrypted-data-app -o jsonpath='{.items[0].metadata.name}')
    if [ ! -z "$POD_NAME" ]; then
        oc exec $POD_NAME -- du -sh /data/ 2>/dev/null || echo "Data directory not accessible"
    fi
    
    sleep 10
done
EOF
Run the monitoring script (optional - run in background):
chmod +x monitor-encryption.sh
# Run this in a separate terminal if desired
# ./monitor-encryption.sh
Troubleshooting Tips
Common Issues and Solutions
Issue 1: PVC stuck in Pending state

Solution: Check if the storage class exists and has the correct parameters
oc describe pvc encrypted-data-pvc
oc get storageclass
Issue 2: TLS certificate errors

Solution: Verify certificate format and secret creation
oc describe secret secure-app-tls
openssl x509 -in server.crt -text -noout
Issue 3: Application pods not starting

Solution: Check pod logs and events
oc describe pod <pod-name>
oc logs <pod-name>
Issue 4: Route not accessible

Solution: Verify route configuration and DNS resolution
oc describe route secure-app-route
oc get route
Cleanup (Optional)
If you want to clean up the resources created in this lab:

# Delete applications
oc delete deployment encrypted-data-app secure-web-app

# Delete PVC
oc delete pvc encrypted-data-pvc

# Delete services and routes
oc delete service secure-app-service
oc delete route secure-app-route

# Delete secrets and configmaps
oc delete secret secure-app-tls
oc delete configmap nginx-tls-config

# Delete storage class
oc delete storageclass ocs-storagecluster-ceph-rbd-encrypted

# Clean up local files
rm -f encrypted-*.yaml secure-*.yaml *.crt *.key *.csr *.sh
Conclusion
Congratulations! You have successfully completed Lab 13: Encrypting Data at Rest and in Transit. In this lab, you accomplished the following:

Key Achievements:

Configured encryption for data at rest by creating encrypted storage classes and PVCs in OpenShift Data Foundation
Implemented TLS encryption for data in transit using certificates and secure application configurations
Verified encryption configurations through comprehensive testing and monitoring
Applied security best practices for both stored and transmitted data in a cloud-native environment
Why This Matters: Data encryption is critical for maintaining security and compliance in modern cloud environments. By encrypting data at rest, you protect stored information from unauthorized access even if physical storage is compromised. TLS encryption for data in transit ensures that information moving between services remains secure from interception or tampering.

Real-World Applications:

Compliance Requirements: Many industries require encryption for sensitive data (HIPAA, PCI-DSS, GDPR)
Zero-Trust Security: Encryption supports zero-trust architectures by assuming no implicit trust
Multi-Tenant Environments: Encryption provides isolation between different tenants or applications
Hybrid Cloud Security: Ensures consistent security posture across on-premises and cloud environments
Next Steps:

Explore advanced encryption features like key rotation and hardware security modules (HSMs)
Learn about encryption key management and certificate lifecycle management
Study integration with external key management systems
Practice implementing encryption in CI/CD pipelines
You now have practical experience with implementing comprehensive encryption strategies in OpenShift Data Foundation, a valuable skill for the Red Hat Certified Specialist in OpenShift Data Foundation exam and real-world cloud security implementations.
