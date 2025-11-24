#!/bin/bash

# Azure App Service Deployment Script
# Prerequisites: Azure CLI installed and logged in (az login)

set -e

# Configuration
RESOURCE_GROUP="configpad-rg"
LOCATION="eastus"
BACKEND_APP_NAME="configpad-backend"
FRONTEND_APP_NAME="configpad-frontend"
COSMOS_ACCOUNT="configpad-cosmos"
DB_NAME="test_database"
ACR_NAME="configpadacr"

echo "🚀 Starting Azure deployment..."

# Create resource group
echo "📦 Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure Container Registry
echo "📦 Creating Azure Container Registry..."
az acr create --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME --sku Basic

# Login to ACR
az acr login --name $ACR_NAME

# Build and push backend image
echo "🔨 Building and pushing backend image..."
cd backend
docker build -t $ACR_NAME.azurecr.io/backend:latest .
docker push $ACR_NAME.azurecr.io/backend:latest
cd ..

# Build frontend with production backend URL
echo "🔨 Building and pushing frontend image..."
cd frontend
docker build --build-arg REACT_APP_BACKEND_URL=https://$BACKEND_APP_NAME.azurewebsites.net \
  -t $ACR_NAME.azurecr.io/frontend:latest .
docker push $ACR_NAME.azurecr.io/frontend:latest
cd ..

# Create Cosmos DB account with MongoDB API
echo "🗄️  Creating Cosmos DB with MongoDB API..."
az cosmosdb create \
  --name $COSMOS_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --kind MongoDB \
  --locations regionName=$LOCATION \
  --default-consistency-level Session

# Create database
az cosmosdb mongodb database create \
  --account-name $COSMOS_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --name $DB_NAME

# Get MongoDB connection string
MONGO_CONNECTION=$(az cosmosdb keys list \
  --name $COSMOS_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --type connection-strings \
  --query "connectionStrings[0].connectionString" -o tsv)

echo "📝 Connection string retrieved"

# Create App Service Plan
echo "📦 Creating App Service Plan..."
az appservice plan create \
  --name configpad-plan \
  --resource-group $RESOURCE_GROUP \
  --is-linux \
  --sku B1

# Create Backend Web App
echo "🌐 Creating Backend Web App..."
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan configpad-plan \
  --name $BACKEND_APP_NAME \
  --deployment-container-image-name $ACR_NAME.azurecr.io/backend:latest

# Configure backend app settings
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_APP_NAME \
  --settings \
    MONGO_URL="$MONGO_CONNECTION" \
    DB_NAME="$DB_NAME" \
    CORS_ORIGINS="*" \
    WEBSITES_PORT=8001

# Enable container logging
az webapp log config \
  --name $BACKEND_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --docker-container-logging filesystem

# Create Frontend Web App
echo "🌐 Creating Frontend Web App..."
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan configpad-plan \
  --name $FRONTEND_APP_NAME \
  --deployment-container-image-name $ACR_NAME.azurecr.io/frontend:latest

# Configure frontend port
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $FRONTEND_APP_NAME \
  --settings WEBSITES_PORT=80

echo "✅ Deployment complete!"
echo ""
echo "🔗 Backend URL: https://$BACKEND_APP_NAME.azurewebsites.net"
echo "🔗 Frontend URL: https://$FRONTEND_APP_NAME.azurewebsites.net"
echo ""
echo "📝 Next steps:"
echo "1. Configure custom domain (app.configpad.com) in Azure Portal"
echo "2. Set up SSL certificate"
echo "3. Update frontend REACT_APP_BACKEND_URL if using custom domain"
echo "4. Configure CORS_ORIGINS in backend to match your domain"