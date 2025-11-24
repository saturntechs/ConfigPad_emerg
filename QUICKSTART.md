# Quick Start Guide - Azure Deployment

## 🚀 Fastest Way to Deploy to Azure

### Prerequisites
```bash
# 1. Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 2. Login to Azure
az login

# 3. Install Docker (if not already installed)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### Deploy in 3 Steps

#### Step 1: Prepare Configuration
```bash
cd /app

# Copy environment templates
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# Edit backend/.env if needed (default works for most cases)
# Edit frontend/.env - Update REACT_APP_BACKEND_URL after deployment
```

#### Step 2: Run Deployment Script
```bash
cd azure
chmod +x app-service-deploy.sh
./app-service-deploy.sh
```

**This will take 10-15 minutes.** The script will:
- ✅ Create all Azure resources
- ✅ Build and deploy your containers
- ✅ Set up database (Cosmos DB)
- ✅ Configure networking

#### Step 3: Access Your Application

After deployment completes, you'll see:
```
✅ Deployment complete!

🔗 Backend URL: https://configpad-backend.azurewebsites.net
🔗 Frontend URL: https://configpad-frontend.azurewebsites.net
```

Test it:
```bash
curl https://configpad-backend.azurewebsites.net/api/
```

Open your browser:
```
https://configpad-frontend.azurewebsites.net
```

---

## 🌐 Configure Custom Domain (app.configpad.com)

### Step 1: Add DNS Records

Go to your domain provider (GoDaddy, Namecheap, etc.) and add:

**For Frontend:**
- **Type**: CNAME
- **Name**: app
- **Value**: configpad-frontend.azurewebsites.net
- **TTL**: 300

**For Backend (optional separate subdomain):**
- **Type**: CNAME
- **Name**: api
- **Value**: configpad-backend.azurewebsites.net
- **TTL**: 300

### Step 2: Configure in Azure Portal

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **configpad-frontend** App Service
3. Click **Custom domains** → **Add custom domain**
4. Enter: `app.configpad.com`
5. Click **Validate** → **Add**

### Step 3: Add SSL Certificate

1. In the same App Service, go to **TLS/SSL settings**
2. Click **Private Key Certificates**
3. Click **Create App Service Managed Certificate**
4. Select your domain: `app.configpad.com`
5. Click **Create**
6. Go to **Bindings** → **Add TLS/SSL Binding**
7. Select your domain and the certificate

### Step 4: Update Frontend Environment

```bash
# Update frontend to use custom backend URL
az webapp config appsettings set \
  --resource-group configpad-rg \
  --name configpad-frontend \
  --settings REACT_APP_BACKEND_URL="https://configpad-backend.azurewebsites.net"

# Or if using api subdomain:
az webapp config appsettings set \
  --resource-group configpad-rg \
  --name configpad-frontend \
  --settings REACT_APP_BACKEND_URL="https://api.configpad.com"
```

### Step 5: Update CORS

```bash
az webapp config appsettings set \
  --resource-group configpad-rg \
  --name configpad-backend \
  --settings CORS_ORIGINS="https://app.configpad.com"
```

**Done!** 🎉 Your app is now live at `https://app.configpad.com`

---

## 🔧 Local Testing Before Deployment

### Test with Docker Compose

```bash
cd /app

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Test backend
curl http://localhost:8001/api/

# Open frontend
open http://localhost

# Stop services
docker-compose down
```

---

## 📊 Monitor Your Application

### View Logs

```bash
# Backend logs
az webapp log tail --name configpad-backend --resource-group configpad-rg

# Frontend logs
az webapp log tail --name configpad-frontend --resource-group configpad-rg
```

### Check Application Health

```bash
# Backend health
curl https://configpad-backend.azurewebsites.net/api/

# Frontend health
curl -I https://configpad-frontend.azurewebsites.net
```

---

## 💰 Cost Management

### Check Your Spending

```bash
# View resource costs
az consumption usage list --resource-group configpad-rg
```

### Set Up Budget Alerts

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Cost Management + Billing**
3. Click **Budgets** → **Add**
4. Set monthly budget (e.g., $50)
5. Configure email alerts at 80% and 100%

### Reduce Costs

```bash
# Scale down to free/shared tier (development only)
az appservice plan update \
  --name configpad-plan \
  --resource-group configpad-rg \
  --sku F1

# Or delete when not in use
az group delete --name configpad-rg --yes
```

---

## 🔄 Update Your Application

### Rebuild and Redeploy

```bash
cd /app

# Make your code changes
# Then rebuild and push

# Backend
cd backend
docker build -t configpadacr.azurecr.io/backend:latest .
docker push configpadacr.azurecr.io/backend:latest

# Frontend
cd ../frontend
docker build -t configpadacr.azurecr.io/frontend:latest .
docker push configpadacr.azurecr.io/frontend:latest

# Restart services
az webapp restart --name configpad-backend --resource-group configpad-rg
az webapp restart --name configpad-frontend --resource-group configpad-rg
```

---

## 🆘 Troubleshooting

### App won't start
```bash
# Check logs
az webapp log tail --name configpad-backend --resource-group configpad-rg

# Check configuration
az webapp config appsettings list --name configpad-backend --resource-group configpad-rg
```

### Database connection issues
```bash
# Verify MongoDB connection string
az cosmosdb keys list \
  --name configpad-cosmos \
  --resource-group configpad-rg \
  --type connection-strings
```

### Frontend can't reach backend
```bash
# Test backend directly
curl https://configpad-backend.azurewebsites.net/api/

# Check frontend environment
az webapp config appsettings list --name configpad-frontend --resource-group configpad-rg | grep BACKEND_URL
```

---

## 📚 Additional Resources

- **Full Documentation**: See [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Azure Portal**: https://portal.azure.com
- **Azure CLI Reference**: https://docs.microsoft.com/cli/azure/
- **Docker Documentation**: https://docs.docker.com/

---

## 🎯 Next Steps

1. ✅ Deploy using the script above
2. ✅ Configure custom domain
3. ✅ Set up SSL certificate
4. ✅ Configure monitoring alerts
5. ⚙️ Set up CI/CD pipeline (optional)
6. ⚙️ Enable auto-scaling (optional)
7. ⚙️ Configure backup strategy (optional)

**Need help?** Check the full [DEPLOYMENT.md](./DEPLOYMENT.md) guide for detailed instructions.
