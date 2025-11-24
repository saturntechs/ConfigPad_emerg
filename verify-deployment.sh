#!/bin/bash

# Deployment Verification Script
# Tests Azure deployment to ensure everything is working

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="${1:-https://configpad-backend.azurewebsites.net}"
FRONTEND_URL="${2:-https://configpad-frontend.azurewebsites.net}"

echo "=================================================="
echo "🔍 Azure Deployment Verification"
echo "=================================================="
echo ""
echo "Backend URL: $BACKEND_URL"
echo "Frontend URL: $FRONTEND_URL"
echo ""

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
        FAILED=1
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
}

FAILED=0

# Test 1: Backend Health Check
echo "📡 Testing backend health..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/api/" 2>/dev/null || echo "000")
if [ "$RESPONSE" = "200" ]; then
    print_status 0 "Backend API is responding (HTTP 200)"
else
    print_status 1 "Backend API returned HTTP $RESPONSE (expected 200)"
fi

# Test 2: Backend API Response
echo ""
echo "📦 Testing backend API response..."
BACKEND_DATA=$(curl -s "$BACKEND_URL/api/" 2>/dev/null || echo "")
if echo "$BACKEND_DATA" | grep -q "Hello World"; then
    print_status 0 "Backend returns correct response"
else
    print_status 1 "Backend response doesn't contain expected data"
    echo "   Response: $BACKEND_DATA"
fi

# Test 3: Frontend Accessibility
echo ""
echo "🌐 Testing frontend accessibility..."
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL" 2>/dev/null || echo "000")
if [ "$FRONTEND_RESPONSE" = "200" ]; then
    print_status 0 "Frontend is accessible (HTTP 200)"
else
    print_status 1 "Frontend returned HTTP $FRONTEND_RESPONSE (expected 200)"
fi

# Test 4: Backend OpenAPI Docs
echo ""
echo "📚 Testing API documentation..."
DOCS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/docs" 2>/dev/null || echo "000")
if [ "$DOCS_RESPONSE" = "200" ]; then
    print_status 0 "API documentation is accessible"
else
    print_status 1 "API documentation returned HTTP $DOCS_RESPONSE"
fi

# Test 5: HTTPS/SSL
echo ""
echo "🔒 Testing HTTPS/SSL..."
if [[ "$BACKEND_URL" == https://* ]]; then
    if curl -s --head "$BACKEND_URL/api/" | grep -q "HTTP/"; then
        print_status 0 "HTTPS is enabled for backend"
    else
        print_status 1 "HTTPS test failed for backend"
    fi
else
    print_warning "Backend is not using HTTPS (using HTTP)"
fi

if [[ "$FRONTEND_URL" == https://* ]]; then
    if curl -s --head "$FRONTEND_URL" | grep -q "HTTP/"; then
        print_status 0 "HTTPS is enabled for frontend"
    else
        print_status 1 "HTTPS test failed for frontend"
    fi
else
    print_warning "Frontend is not using HTTPS (using HTTP)"
fi

# Test 6: Create Status Check (API Functionality)
echo ""
echo "✍️  Testing API functionality (create status check)..."
CREATE_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/status" \
    -H "Content-Type: application/json" \
    -d '{"client_name": "verification-test"}' \
    2>/dev/null || echo "")

if echo "$CREATE_RESPONSE" | grep -q "verification-test"; then
    print_status 0 "Can create status check via API"
    
    # Extract ID for cleanup (if JSON parsing available)
    if command -v jq &> /dev/null; then
        STATUS_ID=$(echo "$CREATE_RESPONSE" | jq -r '.id' 2>/dev/null || echo "")
        if [ ! -z "$STATUS_ID" ]; then
            echo "   Created status check with ID: $STATUS_ID"
        fi
    fi
else
    print_status 1 "Failed to create status check"
    echo "   Response: $CREATE_RESPONSE"
fi

# Test 7: Get Status Checks (API Functionality)
echo ""
echo "📋 Testing API functionality (get status checks)..."
GET_RESPONSE=$(curl -s "$BACKEND_URL/api/status" 2>/dev/null || echo "")
if [ ! -z "$GET_RESPONSE" ] && [ "$GET_RESPONSE" != "null" ]; then
    print_status 0 "Can retrieve status checks via API"
    
    # Count records if jq is available
    if command -v jq &> /dev/null; then
        COUNT=$(echo "$GET_RESPONSE" | jq 'length' 2>/dev/null || echo "?")
        echo "   Found $COUNT status check(s)"
    fi
else
    print_status 1 "Failed to retrieve status checks"
fi

# Test 8: Response Time
echo ""
echo "⏱️  Testing response time..."
START_TIME=$(date +%s%N)
curl -s "$BACKEND_URL/api/" > /dev/null 2>&1
END_TIME=$(date +%s%N)
RESPONSE_TIME=$(( (END_TIME - START_TIME) / 1000000 ))

if [ $RESPONSE_TIME -lt 2000 ]; then
    print_status 0 "Response time is acceptable (${RESPONSE_TIME}ms < 2000ms)"
elif [ $RESPONSE_TIME -lt 5000 ]; then
    print_warning "Response time is slow (${RESPONSE_TIME}ms)"
else
    print_status 1 "Response time is too slow (${RESPONSE_TIME}ms > 5000ms)"
fi

# Summary
echo ""
echo "=================================================="
echo "📊 Verification Summary"
echo "=================================================="

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo "Your Azure deployment is working correctly!"
    echo ""
    echo "🔗 Access your application:"
    echo "   Backend API: $BACKEND_URL/api/"
    echo "   API Docs: $BACKEND_URL/docs"
    echo "   Frontend: $FRONTEND_URL"
    echo ""
    exit 0
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    echo ""
    echo "Please review the errors above and check:"
    echo "  1. Azure resources are properly deployed"
    echo "  2. Environment variables are correctly set"
    echo "  3. Database connection is working"
    echo "  4. CORS is properly configured"
    echo ""
    echo "For troubleshooting, run:"
    echo "  az webapp log tail --name configpad-backend --resource-group configpad-rg"
    echo ""
    exit 1
fi
