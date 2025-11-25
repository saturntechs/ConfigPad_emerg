#!/bin/bash

# Single Command Azure Deployment
# Copy and paste this entire script into Azure Cloud Shell

set -e

echo "🚀 Setting up ConfigPad deployment..."

# Configuration
RESOURCE_GROUP="configpad-rg"
LOCATION="eastus"
BACKEND_APP_NAME="configpad-backend"
FRONTEND_APP_NAME="configpad-frontend"
COSMOS_ACCOUNT="configpad-cosmos"
DB_NAME="test_database"
ACR_NAME="configpadacr"

# Create project directory
mkdir -p ~/configpad-deploy
cd ~/configpad-deploy

echo "📁 Creating project structure..."

# Create backend directory and files
mkdir -p backend
cat > backend/server.py << 'EOF'
from fastapi import FastAPI, APIRouter
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field, ConfigDict
from typing import List
import uuid
from datetime import datetime, timezone


ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

# Create the main app without a prefix
app = FastAPI()

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")


# Define Models
class StatusCheck(BaseModel):
    model_config = ConfigDict(extra="ignore")
    
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    client_name: str
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class StatusCheckCreate(BaseModel):
    client_name: str

# Add your routes to the router instead of directly to app
@api_router.get("/")
async def root():
    return {"message": "Hello World"}

@api_router.post("/status", response_model=StatusCheck)
async def create_status_check(input: StatusCheckCreate):
    status_dict = input.model_dump()
    status_obj = StatusCheck(**status_dict)
    
    # Convert to dict and serialize datetime to ISO string for MongoDB
    doc = status_obj.model_dump()
    doc['timestamp'] = doc['timestamp'].isoformat()
    
    _ = await db.status_checks.insert_one(doc)
    return status_obj

@api_router.get("/status", response_model=List[StatusCheck])
async def get_status_checks():
    # Exclude MongoDB's _id field from the query results
    status_checks = await db.status_checks.find({}, {"_id": 0}).to_list(1000)
    
    # Convert ISO string timestamps back to datetime objects
    for check in status_checks:
        if isinstance(check['timestamp'], str):
            check['timestamp'] = datetime.fromisoformat(check['timestamp'])
    
    return status_checks

# Include the router in the main app
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
EOF

cat > backend/requirements.txt << 'EOF'
fastapi==0.110.1
uvicorn==0.25.0
python-dotenv>=1.0.1
pymongo==4.5.0
pydantic>=2.6.4
motor==3.3.1
EOF

cat > backend/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 8001

# Run the application
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8001"]
EOF

# Create frontend directory and files
mkdir -p frontend/src frontend/public

cat > frontend/package.json << 'EOF'
{
  "name": "frontend",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "axios": "^1.8.4",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "react-router-dom": "^7.5.1",
    "react-scripts": "5.0.1"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test"
  },
  "browserslist": {
    "production": [">0.2%", "not dead", "not op_mini all"],
    "development": ["last 1 chrome version", "last 1 firefox version", "last 1 safari version"]
  }
}
EOF

cat > frontend/src/index.js << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

cat > frontend/src/App.js << 'EOF'
import { useEffect } from "react";
import "./App.css";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import axios from "axios";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

const Home = () => {
  const helloWorldApi = async () => {
    try {
      const response = await axios.get(`${API}/`);
      console.log(response.data.message);
    } catch (e) {
      console.error(e, `errored out requesting / api`);
    }
  };

  useEffect(() => {
    helloWorldApi();
  }, []);

  return (
    <div>
      <header className="App-header">
        <a
          className="App-link"
          href="https://emergent.sh"
          target="_blank"
          rel="noopener noreferrer"
        >
          <img src="https://avatars.githubusercontent.com/in/1201222?s=120&u=2686cf91179bbafbc7a71bfbc43004cf9ae1acea&v=4" />
        </a>
        <p className="mt-5">Building something incredible on Azure!</p>
      </header>
    </div>
  );
};

function App() {
  return (
    <div className="App">
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Home />}>
            <Route index element={<Home />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </div>
  );
}

export default App;
EOF

cat > frontend/src/App.css << 'EOF'
.App {
  text-align: center;
}

.App-header {
  background-color: #282c34;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  font-size: calc(10px + 2vmin);
  color: white;
}

.App-link {
  color: #61dafb;
}

.App-link img {
  width: 120px;
  height: 120px;
  border-radius: 50%;
}

.mt-5 {
  margin-top: 2rem;
}
EOF

cat > frontend/src/index.css << 'EOF'
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
EOF

cat > frontend/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta name="description" content="ConfigPad Application" />
    <title>ConfigPad App</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOF

cat > frontend/nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF

cat > frontend/Dockerfile << 'EOF'
# Build stage
FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY package.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build argument for backend URL
ARG REACT_APP_BACKEND_URL=http://localhost:8001
ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built assets from build stage
COPY --from=build /app/build /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

echo "✅ Project files created!"
echo ""
echo "🚀 Starting Azure deployment..."
echo ""

# Create resource group
echo "📦 Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure Container Registry
echo "📦 Creating Azure Container Registry..."
az acr create --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME --sku Basic

# Login to ACR
echo "🔑 Logging into Container Registry..."
az acr login --name $ACR_NAME

# Build and push backend image
echo "🔨 Building and pushing backend image..."
cd backend
az acr build --registry $ACR_NAME --image backend:latest .
cd ..

# Build and push frontend image
echo "🔨 Building and pushing frontend image..."
cd frontend
az acr build --registry $ACR_NAME \
  --image frontend:latest \
  --build-arg REACT_APP_BACKEND_URL=https://$BACKEND_APP_NAME.azurewebsites.net \
  .
cd ..

# Create Cosmos DB account with MongoDB API
echo "🗄️  Creating Cosmos DB with MongoDB API (this takes 5-10 minutes)..."
az cosmosdb create \
  --name $COSMOS_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --kind MongoDB \
  --locations regionName=$LOCATION \
  --default-consistency-level Session

# Create database
echo "📊 Creating database..."
az cosmosdb mongodb database create \
  --account-name $COSMOS_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --name $DB_NAME

# Get MongoDB connection string
echo "🔑 Retrieving connection string..."
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

# Configure ACR credentials for backend
az webapp config container set \
  --name $BACKEND_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name $ACR_NAME.azurecr.io/backend:latest \
  --docker-registry-server-url https://$ACR_NAME.azurecr.io

# Configure backend app settings
echo "⚙️  Configuring backend settings..."
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

# Configure ACR credentials for frontend
az webapp config container set \
  --name $FRONTEND_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name $ACR_NAME.azurecr.io/frontend:latest \
  --docker-registry-server-url https://$ACR_NAME.azurecr.io

# Configure frontend port
echo "⚙️  Configuring frontend settings..."
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $FRONTEND_APP_NAME \
  --settings WEBSITES_PORT=80

echo ""
echo "=============================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=============================================="
echo ""
echo "🔗 Backend URL: https://$BACKEND_APP_NAME.azurewebsites.net"
echo "🔗 Frontend URL: https://$FRONTEND_APP_NAME.azurewebsites.net"
echo "🔗 API Docs: https://$BACKEND_APP_NAME.azurewebsites.net/docs"
echo ""
echo "📝 Next steps:"
echo "1. Test backend: curl https://$BACKEND_APP_NAME.azurewebsites.net/api/"
echo "2. Open frontend in browser: https://$FRONTEND_APP_NAME.azurewebsites.net"
echo "3. Configure custom domain (app.configpad.com) in Azure Portal if needed"
echo ""
echo "💰 Monthly cost estimate: ~\$42/month"
echo "   - App Service Plan (B1): ~\$13/month"
echo "   - Container Registry: ~\$5/month"
echo "   - Cosmos DB: ~\$24/month"
echo ""
echo "🗑️  To delete everything and stop charges:"
echo "   az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo ""
