#!/bin/bash
# Test script for MCP-Ollama

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testing MCP-Ollama server...${NC}\n"

# Check if containers are running
echo -e "Checking Docker containers..."
if docker ps | grep -q mcp-ollama && docker ps | grep -q ollama; then
    echo -e "${GREEN}✓ Both containers are running${NC}"
else
    echo -e "${RED}✗ One or both containers are not running${NC}"
    echo -e "Please start the containers with: docker-compose up -d"
    exit 1
fi

# Test network connectivity between containers
echo -e "\nTesting network connectivity..."
if docker exec mcp-ollama ping -c 1 ollama >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Network connectivity to Ollama container is working${NC}"
else
    echo -e "${RED}✗ Network connectivity issue between containers${NC}"
    echo -e "Please check your Docker network configuration"
    exit 1
fi

# Test Ollama API access
echo -e "\nTesting Ollama API access..."
if docker exec mcp-ollama curl -s ollama:11434/api/tags >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Ollama API is accessible${NC}"
else
    echo -e "${RED}✗ Cannot access Ollama API${NC}"
    echo -e "Please ensure Ollama service is running correctly"
    exit 1
fi

# Test list_models function
echo -e "\nTesting list_models function..."
RESULT=$(docker exec mcp-ollama python -c "from src.mcp_ollama.server import list_models; print(list_models())")
if [[ $RESULT == *"models"* ]]; then
    echo -e "${GREEN}✓ list_models function is working${NC}"
    echo -e "Available models: $RESULT"
else
    echo -e "${RED}✗ list_models function failed${NC}"
    echo -e "Error output: $RESULT"
    exit 1
fi

# If no models are available, pull a model
if [[ $RESULT == *"[]"* ]]; then
    echo -e "\n${YELLOW}No models found. Pulling llama2 model...${NC}"
    docker exec ollama ollama pull llama2
    echo -e "\nRe-testing list_models function..."
    RESULT=$(docker exec mcp-ollama python -c "from src.mcp_ollama.server import list_models; print(list_models())")
    echo -e "Available models: $RESULT"
fi

# Test MCP server directly by checking if it starts correctly
echo -e "\nTesting MCP server startup..."
docker exec -d mcp-ollama python -m src.mcp_ollama
sleep 2
if docker exec mcp-ollama ps aux | grep -q "[p]ython -m src.mcp_ollama"; then
    echo -e "${GREEN}✓ MCP server started successfully${NC}"
else
    echo -e "${RED}✗ MCP server failed to start${NC}"
    exit 1
fi

# Clean up - stop the server
docker exec mcp-ollama pkill -f "python -m src.mcp_ollama"

echo -e "\n${GREEN}All tests passed successfully!${NC}"
echo -e "\nTo test with Claude Desktop, add the following to your Claude Desktop config file:"
echo -e "macOS: ~/Library/Application Support/Claude/claude_desktop_config.json"
echo -e "Windows: %APPDATA%\\Claude\\claude_desktop_config.json"
echo -e "\nConfiguration:"
echo -e '{
  "mcpServers": {
    "ollama": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-ollama", "python", "-m", "src.mcp_ollama"]
    }
  }
}'

exit 0