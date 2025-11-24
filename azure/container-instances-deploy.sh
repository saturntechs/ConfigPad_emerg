#!/bin/bash

# Azure Container Instances Deployment Script
# Prerequisites: Azure CLI installed and logged in (az login)

set -e

# Configuration
RESOURCE_GROUP="configpad-rg"
LOCATION="eastus"
MONGODB_CONTAINER="mongodb-instance"
BACKEND_CONTAINER="backend-instance"
FRONTEND_CONTAINER="frontend-instance"
ACR_NAME="configpadacr"

echo "🚀 Starting Azure Container Instances deployment..."

# Create resource group
echo "📦 Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure Container Registry
echo "📦 Creating Azure Container Registry..."
az acr create --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME --sku Basic

# Login to ACR
az acr login --name $ACR_NAME

# Build and push images
echo "🔨 Building and pushing images..."
cd backend
docker build -t $ACR_NAME.azurecr.io/backend:latest .
docker push $ACR_NAME.azurecr.io/backend:latest
cd ../frontend
docker build -t $ACR_NAME.azurecr.io/frontend:latest .
docker push $ACR_NAME.azurecr.io/frontend:latest
cd ..

# Enable admin access to ACR
az acr update -n $ACR_NAME --admin-enabled true

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)

echo "📝 Deploying container group..."

# Deploy multi-container group
az container create \
  --resource-group $RESOURCE_GROUP \
  --name configpad-app \
  --image mongo:7.0 \
  --cpu 2 \
  --memory 4 \
  --port 80 8001 27017 \
  --dns-name-label configpad-app \
  --restart-policy Always

echo "✅ Deployment complete!"
echo ""
echo "🔗 Application URL: http://configpad-app.$LOCATION.azurecontainer.io"
echo ""
echo "📝 Note: For production, consider using Azure Kubernetes Service (AKS) for better orchestration"