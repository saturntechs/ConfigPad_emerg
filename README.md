# ConfigPad Application

## 📋 Overview

Full-stack application with FastAPI backend, React frontend, and MongoDB database.

**Stack:**
- **Backend**: FastAPI (Python 3.11)
- **Frontend**: React 19 with Tailwind CSS
- **Database**: MongoDB
- **Deployment**: Azure-ready with Docker support

---

## 🚀 Quick Start

### Local Development

#### Prerequisites
- Python 3.11+
- Node.js 18+
- Yarn
- MongoDB

#### Setup

```bash
# Install backend dependencies
cd backend
pip install -r requirements.txt

# Install frontend dependencies
cd ../frontend
yarn install

# Start MongoDB (if not already running)
mongod

# Start backend (in backend directory)
uvicorn server:app --host 0.0.0.0 --port 8001 --reload

# Start frontend (in frontend directory)
yarn start
```

Access the application:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8001/api/
- **API Docs**: http://localhost:8001/docs

---

## 🐳 Docker Deployment

### Using Docker Compose (Recommended)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

Access the application:
- **Frontend**: http://localhost
- **Backend API**: http://localhost:8001/api/

---

## ☁️ Azure Deployment

### Quick Deploy to Azure

See **[QUICKSTART.md](./QUICKSTART.md)** for fastest deployment path.

For comprehensive deployment guide, see **[DEPLOYMENT.md](./DEPLOYMENT.md)**.

### Supported Azure Services

1. **Azure App Service** (Recommended) - Managed PaaS
2. **Azure Container Instances** - Simple container hosting
3. **Azure Kubernetes Service (AKS)** - Production orchestration
4. **Azure Virtual Machines** - Full control

---

## 📁 Project Structure

```
/app/
├── backend/                 # FastAPI backend
│   ├── server.py           # Main application
│   ├── requirements.txt    # Python dependencies
│   ├── Dockerfile         # Backend Docker config
│   ├── .env               # Environment variables
│   └── .env.example       # Environment template
├── frontend/               # React frontend
│   ├── src/
│   │   ├── App.js         # Main component
│   │   └── index.js       # Entry point
│   ├── public/            # Static assets
│   ├── package.json       # Node dependencies
│   ├── Dockerfile         # Frontend Docker config
│   ├── nginx.conf         # Nginx configuration
│   ├── .env              # Environment variables
│   └── .env.example      # Environment template
├── azure/                 # Azure deployment files
│   ├── app-service-deploy.sh
│   ├── container-instances-deploy.sh
│   └── kubernetes/
│       └── deployment.yaml
├── docker-compose.yml     # Docker Compose config
├── DEPLOYMENT.md         # Full deployment guide
├── QUICKSTART.md         # Quick start guide
└── README.md            # This file
```

---

## 🔧 Configuration

### Backend Environment Variables

```bash
# MongoDB Configuration
MONGO_URL=mongodb://localhost:27017
DB_NAME=test_database

# CORS Configuration
CORS_ORIGINS=*
```

For Azure Cosmos DB:
```bash
MONGO_URL=mongodb://<account>.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb&retrywrites=false
DB_NAME=test_database
```

### Frontend Environment Variables

```bash
# Backend URL
REACT_APP_BACKEND_URL=http://localhost:8001

# For production
REACT_APP_BACKEND_URL=https://configpad-backend.azurewebsites.net

# For custom domain
REACT_APP_BACKEND_URL=https://api.configpad.com
```

---

## 📡 API Endpoints

### Health Check
```bash
GET /api/
Response: {"message": "Hello World"}
```

### Create Status Check
```bash
POST /api/status
Body: {"client_name": "test"}
Response: {
  "id": "uuid",
  "client_name": "test",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### Get Status Checks
```bash
GET /api/status
Response: [
  {
    "id": "uuid",
    "client_name": "test",
    "timestamp": "2025-01-15T10:30:00Z"
  }
]
```

### API Documentation
Interactive API docs available at: `http://localhost:8001/docs`

---

## 🧪 Testing

### Backend Testing

```bash
cd backend

# Test API endpoint
curl http://localhost:8001/api/

# Test status check creation
curl -X POST http://localhost:8001/api/status \
  -H "Content-Type: application/json" \
  -d '{"client_name": "test"}'

# Get all status checks
curl http://localhost:8001/api/status
```

### Frontend Testing

Open browser to `http://localhost:3000` and check:
- Page loads successfully
- Console shows "Hello World" message from API
- No errors in browser console

---

## 🎯 Custom Domain Setup

To use `app.configpad.com`:

1. Deploy to Azure (see QUICKSTART.md)
2. Configure DNS records at your domain provider
3. Add custom domain in Azure Portal
4. Configure SSL certificate
5. Update environment variables

Detailed instructions in [DEPLOYMENT.md](./DEPLOYMENT.md#custom-domain-configuration).

---

## 🔐 Security

### Production Checklist

- [ ] Enable HTTPS/SSL
- [ ] Configure proper CORS origins (not `*`)
- [ ] Use environment variables for secrets
- [ ] Enable database authentication
- [ ] Implement API rate limiting
- [ ] Add authentication/authorization
- [ ] Regular security updates
- [ ] Enable logging and monitoring

---

## 📊 Monitoring

### Azure Monitoring

```bash
# View backend logs
az webapp log tail --name configpad-backend --resource-group configpad-rg

# View frontend logs
az webapp log tail --name configpad-frontend --resource-group configpad-rg
```

### Docker Logs

```bash
# View all logs
docker-compose logs -f

# View specific service
docker-compose logs -f backend
docker-compose logs -f frontend
```

---

## 🛠️ Development

### Adding New Features

1. **Backend**: Add routes in `backend/server.py`
2. **Frontend**: Add components in `frontend/src/`
3. **Database**: Models defined using Pydantic in `server.py`

### Hot Reload

Both backend and frontend support hot reload:
- Backend: Changes auto-reload with `--reload` flag
- Frontend: Changes auto-refresh in browser

---

## 💰 Cost Estimation (Azure)

**Basic Setup (~$42/month):**
- App Service Plan (B1): ~$13/month
- Azure Container Registry: ~$5/month
- Cosmos DB (400 RU/s): ~$24/month

**Production Setup (~$109/month):**
- AKS Cluster (2 nodes): ~$60/month
- Load Balancer: ~$20/month
- Cosmos DB: ~$24/month
- ACR: ~$5/month

See [DEPLOYMENT.md](./DEPLOYMENT.md#cost-estimation) for details.

---

## 🆘 Troubleshooting

### Issue: Backend won't start

```bash
# Check Python version
python --version

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

### Issue: Frontend build fails

```bash
# Clear cache
rm -rf node_modules yarn.lock
yarn install
```

### Issue: Database connection failed

```bash
# Check MongoDB is running
mongosh

# Verify connection string
echo $MONGO_URL
```

### Issue: CORS errors

Update backend `CORS_ORIGINS` environment variable to match your frontend URL.

---

## 📚 Documentation

- **[QUICKSTART.md](./QUICKSTART.md)** - Fast Azure deployment
- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Comprehensive deployment guide
- **[API Documentation](http://localhost:8001/docs)** - Interactive API docs

---

## 🤝 Support

### Azure Resources
- [Azure Portal](https://portal.azure.com)
- [Azure Documentation](https://docs.microsoft.com/azure/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)

### Application Stack
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [React Documentation](https://react.dev/)
- [MongoDB Documentation](https://docs.mongodb.com/)

---

## 📝 License

MIT License - feel free to use this project for your own purposes.

---

## 🎉 Getting Started

**Choose your path:**

1. **Local Development**: Follow [Quick Start](#-quick-start) above
2. **Docker Testing**: Use `docker-compose up -d`
3. **Azure Deployment**: See [QUICKSTART.md](./QUICKSTART.md)

**Ready to deploy to Azure?**

```bash
cd azure
./app-service-deploy.sh
```

**That's it!** 🚀 Your application will be live on Azure in 10-15 minutes.
