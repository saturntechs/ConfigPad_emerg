# Azure Deployment Guide for ConfigPad Application

This guide provides step-by-step instructions for deploying your FastAPI + React + MongoDB application to Microsoft Azure.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Deployment Options](#deployment-options)
3. [Option A: Azure App Service (Recommended for Beginners)](#option-a-azure-app-service)
4. [Option B: Azure Container Instances](#option-b-azure-container-instances)
5. [Option C: Azure Kubernetes Service (AKS)](#option-c-azure-kubernetes-service)
6. [Option D: Azure Virtual Machines](#option-d-azure-virtual-machines)
7. [Custom Domain Configuration](#custom-domain-configuration)
8. [Environment Variables](#environment-variables)
9. [Database Options](#database-options)

---

## Prerequisites

Before deploying to Azure, ensure you have:

1. **Azure Account**: [Sign up for Azure](https://azure.microsoft.com/free/)
2. **Azure CLI**: [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
3. **Docker**: [Install Docker](https://docs.docker.com/get-docker/)
4. **Git**: For version control
5. **Node.js & Yarn**: For local frontend builds (if needed)

### Login to Azure
```bash
az login
```

---

## Deployment Options

### Comparison Table

| Option | Complexity | Cost | Scalability | Best For |
|--------|-----------|------|-------------|----------|
| **App Service** | Low | $$ | Medium | Simple deployments, managed service |
| **Container Instances** | Low | $ | Low | Testing, small apps |
| **AKS (Kubernetes)** | High | $$$ | High | Production, microservices |
| **Virtual Machines** | Medium | $$ | Medium | Full control, custom setup |

---

## Option A: Azure App Service

**Best for**: Quick deployment with managed infrastructure

### Step 1: Prepare Your Application

1. Update frontend environment variable for production:
```bash
# Edit frontend/.env
REACT_APP_BACKEND_URL=https://configpad-backend.azurewebsites.net
```

2. Ensure Docker is running:
```bash
docker --version
```

### Step 2: Deploy Using the Script

```bash
cd /app/azure
chmod +x app-service-deploy.sh
./app-service-deploy.sh
```

This script will:
- ✅ Create Azure Resource Group
- ✅ Create Azure Container Registry (ACR)
- ✅ Build and push Docker images
- ✅ Create Cosmos DB with MongoDB API
- ✅ Deploy backend and frontend to App Service
- ✅ Configure all environment variables

### Step 3: Verify Deployment

After deployment completes, you'll see URLs like:
- Backend: `https://configpad-backend.azurewebsites.net`
- Frontend: `https://configpad-frontend.azurewebsites.net`

Test the backend:
```bash
curl https://configpad-backend.azurewebsites.net/api/
```

### Step 4: Configure Custom Domain (app.configpad.com)

1. Go to Azure Portal → Your Frontend App Service
2. Navigate to **Custom domains**
3. Click **Add custom domain**
4. Enter `app.configpad.com`
5. Add the required DNS records to your domain provider:
   - **Type**: CNAME
   - **Name**: app
   - **Value**: configpad-frontend.azurewebsites.net

6. Add SSL certificate:
   - Navigate to **TLS/SSL settings**
   - Click **Private Key Certificates (.pfx)**
   - Upload your certificate or use **App Service Managed Certificate** (free)

### Step 5: Update Backend CORS

Once your custom domain is configured, update CORS:
```bash
az webapp config appsettings set \
  --resource-group configpad-rg \
  --name configpad-backend \
  --settings CORS_ORIGINS="https://app.configpad.com"
```

---

## Option B: Azure Container Instances

**Best for**: Simple containerized deployment without orchestration

### Deploy

```bash
cd /app
chmod +x azure/container-instances-deploy.sh
./azure/container-instances-deploy.sh
```

This creates a multi-container group with MongoDB, Backend, and Frontend.

**Note**: Container Instances are best for development/testing. For production, use App Service or AKS.

---

## Option C: Azure Kubernetes Service (AKS)

**Best for**: Production-grade, scalable deployments

### Step 1: Create AKS Cluster

```bash
# Create resource group
az group create --name configpad-rg --location eastus

# Create AKS cluster
az aks create \
  --resource-group configpad-rg \
  --name configpad-aks \
  --node-count 2 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group configpad-rg --name configpad-aks
```

### Step 2: Create Container Registry and Build Images

```bash
# Create ACR
az acr create --resource-group configpad-rg --name configpadacr --sku Basic

# Login to ACR
az acr login --name configpadacr

# Build and push images
cd backend
docker build -t configpadacr.azurecr.io/backend:latest .
docker push configpadacr.azurecr.io/backend:latest

cd ../frontend
docker build -t configpadacr.azurecr.io/frontend:latest .
docker push configpadacr.azurecr.io/frontend:latest
```

### Step 3: Connect AKS to ACR

```bash
az aks update \
  --name configpad-aks \
  --resource-group configpad-rg \
  --attach-acr configpadacr
```

### Step 4: Deploy to Kubernetes

```bash
cd /app/azure/kubernetes
kubectl apply -f deployment.yaml
```

### Step 5: Get External IP

```bash
kubectl get services -n configpad

# Wait for EXTERNAL-IP to be assigned to frontend service
# This is your public IP address
```

### Step 6: Configure Custom Domain

Point your DNS A record for `app.configpad.com` to the EXTERNAL-IP.

---

## Option D: Azure Virtual Machines

**Best for**: Full control over infrastructure

### Step 1: Create Virtual Machine

```bash
az vm create \
  --resource-group configpad-rg \
  --name configpad-vm \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --size Standard_B2s
```

### Step 2: Open Ports

```bash
az vm open-port --port 80 --resource-group configpad-rg --name configpad-vm
az vm open-port --port 443 --resource-group configpad-rg --name configpad-vm
az vm open-port --port 8001 --resource-group configpad-rg --name configpad-vm
```

### Step 3: SSH into VM

```bash
# Get VM IP
VM_IP=$(az vm show -d -g configpad-rg -n configpad-vm --query publicIps -o tsv)

# SSH into VM
ssh azureuser@$VM_IP
```

### Step 4: Install Dependencies on VM

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again for docker group to take effect
exit
ssh azureuser@$VM_IP
```

### Step 5: Deploy Application

```bash
# Clone your repository or copy files
git clone <your-repo-url>
cd <your-repo>

# Or use SCP to copy files
# On your local machine:
# scp -r /app azureuser@$VM_IP:/home/azureuser/

# Start services
docker-compose up -d

# Check logs
docker-compose logs -f
```

### Step 6: Setup Nginx Reverse Proxy (Optional)

```bash
# Install Nginx
sudo apt install nginx -y

# Create Nginx config
sudo nano /etc/nginx/sites-available/configpad
```

Add this configuration:
```nginx
server {
    listen 80;
    server_name app.configpad.com;

    location /api {
        proxy_pass http://localhost:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/configpad /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## Custom Domain Configuration

### For app.configpad.com

1. **DNS Configuration**:
   - Go to your domain registrar (e.g., GoDaddy, Namecheap, Cloudflare)
   - Add DNS record:
     - **Type**: A or CNAME
     - **Name**: app
     - **Value**: Your Azure service IP/URL
     - **TTL**: 300

2. **SSL Certificate**:
   - Use Azure App Service Managed Certificate (free)
   - Or use Let's Encrypt for VM deployments
   - Or upload your own certificate

### Let's Encrypt SSL (for VM deployments)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get certificate
sudo certbot --nginx -d app.configpad.com

# Auto-renewal is configured automatically
```

---

## Environment Variables

### Backend (.env)

```bash
# For Cosmos DB (MongoDB API)
MONGO_URL=mongodb://<account>.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb&retrywrites=false
DB_NAME=test_database

# For self-hosted MongoDB
MONGO_URL=mongodb://mongodb:27017
DB_NAME=test_database

# CORS
CORS_ORIGINS=https://app.configpad.com
```

### Frontend (.env)

```bash
# Production backend URL
REACT_APP_BACKEND_URL=https://configpad-backend.azurewebsites.net

# Or with custom domain
REACT_APP_BACKEND_URL=https://api.configpad.com

# Or with VM
REACT_APP_BACKEND_URL=https://app.configpad.com
```

---

## Database Options

### Option 1: Azure Cosmos DB (MongoDB API) - Recommended

**Pros**: Fully managed, global distribution, automatic backups, 99.999% SLA

```bash
# Create Cosmos DB
az cosmosdb create \
  --name configpad-cosmos \
  --resource-group configpad-rg \
  --kind MongoDB \
  --locations regionName=eastus

# Get connection string
az cosmosdb keys list \
  --name configpad-cosmos \
  --resource-group configpad-rg \
  --type connection-strings \
  --query "connectionStrings[0].connectionString" -o tsv
```

**Cost**: Starts at ~$24/month for 400 RU/s

### Option 2: MongoDB on Azure VM

**Pros**: Full control, lower cost for small deployments

1. Create VM and install MongoDB:
```bash
# Install MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
```

2. Configure MongoDB for remote access (if needed):
```bash
sudo nano /etc/mongod.conf
# Change bindIp from 127.0.0.1 to 0.0.0.0
sudo systemctl restart mongod
```

### Option 3: Container-based MongoDB

Already configured in `docker-compose.yml`. Data persists in named volume.

---

## Monitoring and Logs

### Azure App Service

```bash
# View backend logs
az webapp log tail --name configpad-backend --resource-group configpad-rg

# View frontend logs
az webapp log tail --name configpad-frontend --resource-group configpad-rg
```

### Kubernetes

```bash
# View pod logs
kubectl logs -f deployment/backend -n configpad
kubectl logs -f deployment/frontend -n configpad

# View all pods
kubectl get pods -n configpad
```

### Docker Compose (VM)

```bash
# View logs
docker-compose logs -f

# View specific service
docker-compose logs -f backend
```

---

## Scaling

### Azure App Service

```bash
# Scale up (increase instance size)
az appservice plan update \
  --name configpad-plan \
  --resource-group configpad-rg \
  --sku P1V2

# Scale out (increase instance count)
az appservice plan update \
  --name configpad-plan \
  --resource-group configpad-rg \
  --number-of-workers 3
```

### Kubernetes

```bash
# Scale deployment
kubectl scale deployment backend --replicas=5 -n configpad
kubectl scale deployment frontend --replicas=3 -n configpad
```

---

## Cost Estimation

### App Service Deployment (Monthly)

- **App Service Plan (B1)**: ~$13/month
- **Azure Container Registry (Basic)**: ~$5/month
- **Cosmos DB (400 RU/s)**: ~$24/month
- **Total**: ~$42/month

### AKS Deployment (Monthly)

- **AKS Cluster (2 nodes, Standard_B2s)**: ~$60/month
- **Azure Container Registry (Basic)**: ~$5/month
- **Load Balancer**: ~$20/month
- **Cosmos DB**: ~$24/month
- **Total**: ~$109/month

### VM Deployment (Monthly)

- **VM (Standard_B2s)**: ~$30/month
- **Managed Disk (30 GB)**: ~$5/month
- **Public IP**: ~$3/month
- **Total**: ~$38/month

---

## Troubleshooting

### Issue: Backend not connecting to database

**Solution**: Check connection string and ensure database is accessible
```bash
az webapp config appsettings list --name configpad-backend --resource-group configpad-rg
```

### Issue: Frontend getting CORS errors

**Solution**: Update backend CORS_ORIGINS environment variable
```bash
az webapp config appsettings set \
  --resource-group configpad-rg \
  --name configpad-backend \
  --settings CORS_ORIGINS="https://app.configpad.com"
```

### Issue: Container won't start

**Solution**: Check logs
```bash
az webapp log tail --name configpad-backend --resource-group configpad-rg
```

---

## Next Steps

1. ✅ Deploy application using your preferred method
2. ✅ Configure custom domain (app.configpad.com)
3. ✅ Set up SSL certificate
4. ✅ Configure monitoring and alerts
5. ✅ Set up automated backups
6. ✅ Implement CI/CD pipeline (Azure DevOps or GitHub Actions)

---

## Support

For Azure-specific issues:
- [Azure Documentation](https://docs.microsoft.com/azure/)
- [Azure Support](https://azure.microsoft.com/support/)

For application issues:
- Check application logs
- Review environment variables
- Verify database connectivity

---

## Security Checklist

- [ ] Enable HTTPS/SSL for all services
- [ ] Configure proper CORS origins (not *)
- [ ] Use managed identities for Azure resources
- [ ] Enable Azure Security Center
- [ ] Set up network security groups
- [ ] Enable database encryption at rest
- [ ] Implement API authentication if needed
- [ ] Regular security updates for containers
- [ ] Set up Azure Key Vault for secrets
- [ ] Enable logging and monitoring

---

**Congratulations!** 🎉 Your application is now ready for Azure deployment!
