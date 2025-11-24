# Azure Migration Checklist

## ✅ Pre-Migration Preparation

### 1. Code Preparation
- [x] Created Dockerfiles for backend and frontend
- [x] Created docker-compose.yml for local testing
- [x] Created .env.example files with Azure configurations
- [x] Removed hardcoded Emergent-specific URLs
- [x] Made application portable and cloud-agnostic

### 2. Azure Account Setup
- [ ] Create Azure account (if not already have one)
- [ ] Install Azure CLI on your machine
- [ ] Login to Azure: `az login`
- [ ] Choose subscription: `az account set --subscription <subscription-id>`
- [ ] Verify: `az account show`

### 3. Domain Configuration
- [ ] Have access to domain registrar for app.configpad.com
- [ ] Able to add DNS records (A or CNAME)
- [ ] Consider DNS propagation time (can take up to 48 hours)

### 4. Choose Deployment Method
Select one based on your needs:
- [ ] **Option A**: Azure App Service (Recommended - easiest)
- [ ] **Option B**: Azure Container Instances (Simple, low cost)
- [ ] **Option C**: Azure Kubernetes Service (Production scale)
- [ ] **Option D**: Azure Virtual Machine (Full control)

---

## 🚀 Migration Steps

### Phase 1: Local Testing (DO THIS FIRST!)

#### Test with Docker Compose
```bash
cd /app

# Create environment files from templates
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# Start all services
docker-compose up -d

# Check if services are running
docker-compose ps

# View logs
docker-compose logs -f

# Test backend
curl http://localhost:8001/api/

# Test frontend - open browser
open http://localhost
```

**Checklist:**
- [ ] MongoDB container starts successfully
- [ ] Backend container starts successfully
- [ ] Frontend container starts successfully
- [ ] Backend API responds: `curl http://localhost:8001/api/`
- [ ] Frontend loads in browser at http://localhost
- [ ] Frontend can communicate with backend (check browser console)
- [ ] No errors in logs: `docker-compose logs`

**If local testing fails, DO NOT proceed to Azure deployment!**

---

### Phase 2: Azure Deployment

#### Option A: Azure App Service Deployment

**Prerequisites Check:**
- [ ] Azure CLI installed: `az --version`
- [ ] Logged into Azure: `az account show`
- [ ] Docker is running: `docker ps`

**Deployment:**
```bash
cd /app/azure
./app-service-deploy.sh
```

**Wait Time:** 10-15 minutes

**Expected Output:**
```
✅ Deployment complete!

🔗 Backend URL: https://configpad-backend.azurewebsites.net
🔗 Frontend URL: https://configpad-frontend.azurewebsites.net
```

**Post-Deployment Verification:**
- [ ] Backend responds: `curl https://configpad-backend.azurewebsites.net/api/`
- [ ] Frontend loads: Visit `https://configpad-frontend.azurewebsites.net`
- [ ] Frontend can reach backend (check browser console for API calls)
- [ ] Create a status check via API
- [ ] Verify data persists in Cosmos DB

**Test Commands:**
```bash
# Test backend health
curl https://configpad-backend.azurewebsites.net/api/

# Test status creation
curl -X POST https://configpad-backend.azurewebsites.net/api/status \
  -H "Content-Type: application/json" \
  -d '{"client_name": "test"}'

# Get all status checks
curl https://configpad-backend.azurewebsites.net/api/status
```

---

### Phase 3: Custom Domain Configuration

#### Prerequisites:
- [ ] Application successfully deployed on Azure
- [ ] Have access to domain registrar for app.configpad.com
- [ ] Backend and frontend URLs noted from deployment

#### DNS Configuration

**Step 1: Add DNS Records**

Go to your domain registrar (GoDaddy, Namecheap, Cloudflare, etc.):

**For Frontend (app.configpad.com):**
```
Type: CNAME
Name: app
Value: configpad-frontend.azurewebsites.net
TTL: 300
```

**For Backend API (optional - api.configpad.com):**
```
Type: CNAME
Name: api
Value: configpad-backend.azurewebsites.net
TTL: 300
```

**Step 2: Wait for DNS Propagation**
- [ ] Wait 5-10 minutes minimum
- [ ] Check propagation: `nslookup app.configpad.com`
- [ ] Verify: `dig app.configpad.com`

**Step 3: Configure in Azure Portal**

1. [ ] Go to [Azure Portal](https://portal.azure.com)
2. [ ] Navigate to Resource Group: `configpad-rg`
3. [ ] Click on `configpad-frontend` App Service
4. [ ] In left menu, click **Custom domains**
5. [ ] Click **Add custom domain**
6. [ ] Enter: `app.configpad.com`
7. [ ] Click **Validate**
8. [ ] Once validated, click **Add**

**Step 4: Configure SSL Certificate**

1. [ ] In same App Service, go to **TLS/SSL settings**
2. [ ] Click **Private Key Certificates (.pfx)**
3. [ ] Click **Create App Service Managed Certificate**
4. [ ] Select domain: `app.configpad.com`
5. [ ] Click **Create** (takes 2-3 minutes)
6. [ ] Go to **Bindings** tab
7. [ ] Click **Add TLS/SSL Binding**
8. [ ] Select your domain and certificate
9. [ ] Click **Add Binding**

**Step 5: Update Backend CORS**

```bash
az webapp config appsettings set \
  --resource-group configpad-rg \
  --name configpad-backend \
  --settings CORS_ORIGINS="https://app.configpad.com"
```

**Step 6: Test Custom Domain**

- [ ] Visit: `https://app.configpad.com`
- [ ] Verify SSL certificate (should see lock icon)
- [ ] Test functionality (create status check)
- [ ] Check browser console for errors
- [ ] Verify API calls work

---

### Phase 4: Post-Deployment Configuration

#### Security Hardening

**CORS Configuration:**
```bash
# Update CORS to only allow your domain
az webapp config appsettings set \
  --resource-group configpad-rg \
  --name configpad-backend \
  --settings CORS_ORIGINS="https://app.configpad.com"
```

**Checklist:**
- [ ] CORS configured with actual domain (not `*`)
- [ ] HTTPS enabled for all endpoints
- [ ] Database connection uses SSL
- [ ] Environment variables properly set
- [ ] Secrets not hardcoded in code

#### Monitoring Setup

**Enable Application Insights:**
```bash
# Create Application Insights
az monitor app-insights component create \
  --app configpad-insights \
  --location eastus \
  --resource-group configpad-rg

# Get instrumentation key
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app configpad-insights \
  --resource-group configpad-rg \
  --query instrumentationKey -o tsv)

# Configure backend
az webapp config appsettings set \
  --resource-group configpad-rg \
  --name configpad-backend \
  --settings APPINSIGHTS_INSTRUMENTATIONKEY="$INSTRUMENTATION_KEY"
```

**Checklist:**
- [ ] Application Insights configured
- [ ] Log streaming enabled
- [ ] Alerts configured for errors
- [ ] Performance monitoring active

#### Backup Configuration

**Enable backups:**
- [ ] Cosmos DB automatic backups (enabled by default)
- [ ] Configure backup retention period
- [ ] Test restore procedure
- [ ] Document backup/restore process

---

## 🔍 Verification & Testing

### Functional Testing

**Backend Tests:**
```bash
BACKEND_URL="https://configpad-backend.azurewebsites.net"

# Test 1: Health check
curl $BACKEND_URL/api/

# Test 2: Create status check
curl -X POST $BACKEND_URL/api/status \
  -H "Content-Type: application/json" \
  -d '{"client_name": "production-test"}'

# Test 3: Get all status checks
curl $BACKEND_URL/api/status

# Test 4: Check OpenAPI docs
curl $BACKEND_URL/docs
```

**Checklist:**
- [ ] All endpoints respond correctly
- [ ] Response times are acceptable (< 2 seconds)
- [ ] Error handling works properly
- [ ] Database queries return correct data

**Frontend Tests:**
- [ ] Page loads successfully
- [ ] All assets load (images, CSS, JS)
- [ ] API calls work from browser
- [ ] Console shows no errors
- [ ] Responsive design works on mobile
- [ ] Forms submit correctly
- [ ] Data displays properly

### Performance Testing

```bash
# Test backend performance
ab -n 100 -c 10 https://configpad-backend.azurewebsites.net/api/

# Or use curl
time curl https://configpad-backend.azurewebsites.net/api/
```

**Checklist:**
- [ ] Response time < 2 seconds
- [ ] Can handle 10 concurrent requests
- [ ] No errors under load
- [ ] Database queries optimized

### Security Testing

**Checklist:**
- [ ] HTTPS enforced (HTTP redirects to HTTPS)
- [ ] SSL certificate valid
- [ ] Security headers present
- [ ] CORS properly configured
- [ ] No sensitive data in logs
- [ ] Environment variables secure
- [ ] Database requires authentication

---

## 📊 Monitoring & Maintenance

### Daily Checks
- [ ] Application accessible via custom domain
- [ ] No errors in Application Insights
- [ ] Response times normal
- [ ] Database healthy

### Weekly Checks
- [ ] Review error logs
- [ ] Check resource usage
- [ ] Review cost/spending
- [ ] Update dependencies if needed

### Monthly Checks
- [ ] Security updates
- [ ] SSL certificate renewal (auto, but verify)
- [ ] Database backup verification
- [ ] Performance optimization
- [ ] Cost optimization review

---

## 💰 Cost Monitoring

### Set Up Budget Alerts

```bash
# Create budget
az consumption budget create \
  --budget-name configpad-monthly-budget \
  --amount 100 \
  --time-grain Monthly \
  --start-date $(date +%Y-%m-01) \
  --end-date $(date +%Y-12-31 -d '+1 year') \
  --resource-group configpad-rg
```

**Checklist:**
- [ ] Budget alerts configured
- [ ] Email notifications set up
- [ ] Regular cost reviews scheduled
- [ ] Resource scaling plan in place

### Cost Tracking
- [ ] Monitor daily costs in Azure Portal
- [ ] Review Cost Analysis weekly
- [ ] Optimize unused resources
- [ ] Consider reserved instances for savings

---

## 🔄 CI/CD Setup (Optional)

### GitHub Actions Setup

**Prerequisites:**
- [ ] Code in GitHub repository
- [ ] Azure Service Principal created

**Create Service Principal:**
```bash
az ad sp create-for-rbac \
  --name "configpad-github-actions" \
  --role contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/configpad-rg \
  --sdk-auth
```

**Add to GitHub Secrets:**
- [ ] `AZURE_CREDENTIALS` - Output from above command
- [ ] `ACR_USERNAME` - Container registry username
- [ ] `ACR_PASSWORD` - Container registry password

**Checklist:**
- [ ] GitHub Actions workflow configured
- [ ] Automated builds on push
- [ ] Automated deployments to Azure
- [ ] Rollback procedure documented

---

## 📝 Documentation

**Essential Documents Created:**
- [x] README.md - Project overview
- [x] DEPLOYMENT.md - Comprehensive deployment guide
- [x] QUICKSTART.md - Fast deployment guide
- [x] MIGRATION_CHECKLIST.md - This file
- [x] .env.example files - Environment templates

**Team Documentation:**
- [ ] Access credentials documented (use password manager!)
- [ ] Deployment procedures documented
- [ ] Troubleshooting guide created
- [ ] Contact information for support

---

## 🆘 Troubleshooting Common Issues

### Issue: Deployment script fails

**Check:**
```bash
# Verify Azure CLI
az --version

# Verify login
az account show

# Verify Docker
docker --version
docker ps
```

### Issue: Backend can't connect to database

**Check:**
```bash
# View backend logs
az webapp log tail --name configpad-backend --resource-group configpad-rg

# Check connection string
az webapp config appsettings list \
  --name configpad-backend \
  --resource-group configpad-rg | grep MONGO_URL
```

### Issue: Frontend shows CORS errors

**Fix:**
```bash
# Update CORS settings
az webapp config appsettings set \
  --resource-group configpad-rg \
  --name configpad-backend \
  --settings CORS_ORIGINS="https://app.configpad.com"

# Restart backend
az webapp restart --name configpad-backend --resource-group configpad-rg
```

### Issue: Custom domain not working

**Check:**
- [ ] DNS records configured correctly: `nslookup app.configpad.com`
- [ ] DNS propagated: Wait 10-30 minutes
- [ ] Custom domain added in Azure Portal
- [ ] SSL certificate configured
- [ ] HTTPS binding added

### Issue: High costs

**Optimize:**
```bash
# Scale down to B1 tier
az appservice plan update \
  --name configpad-plan \
  --resource-group configpad-rg \
  --sku B1

# Or delete when not needed
az group delete --name configpad-rg --yes
```

---

## ✅ Final Migration Checklist

### Pre-Production
- [ ] Local Docker testing successful
- [ ] Azure resources created
- [ ] Application deployed to Azure
- [ ] Backend and frontend accessible
- [ ] Database connected and working
- [ ] All environment variables configured

### Production
- [ ] Custom domain configured (app.configpad.com)
- [ ] SSL certificate installed
- [ ] CORS properly configured
- [ ] Security headers added
- [ ] Monitoring enabled
- [ ] Backups configured
- [ ] Budget alerts set up

### Post-Production
- [ ] Documentation complete
- [ ] Team trained on new infrastructure
- [ ] Support procedures documented
- [ ] Monitoring dashboards created
- [ ] Incident response plan ready

---

## 🎉 Success Criteria

Your migration is successful when:
- ✅ Application accessible at https://app.configpad.com
- ✅ SSL certificate valid (green lock in browser)
- ✅ All features working correctly
- ✅ No console errors
- ✅ API calls successful
- ✅ Data persisting in database
- ✅ Response times acceptable
- ✅ Costs within budget
- ✅ Monitoring active
- ✅ Team can access and manage

---

## 📞 Support Resources

### Azure Support
- **Azure Portal**: https://portal.azure.com
- **Azure Status**: https://status.azure.com
- **Azure Support**: https://azure.microsoft.com/support/

### Documentation
- **Azure App Service**: https://docs.microsoft.com/azure/app-service/
- **Azure Cosmos DB**: https://docs.microsoft.com/azure/cosmos-db/
- **Azure CLI**: https://docs.microsoft.com/cli/azure/

### Community
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/azure
- **Azure Reddit**: https://reddit.com/r/AZURE
- **Azure Forums**: https://docs.microsoft.com/answers/products/azure

---

**Good luck with your migration!** 🚀

If you encounter any issues not covered in this checklist, refer to the full [DEPLOYMENT.md](./DEPLOYMENT.md) guide.
