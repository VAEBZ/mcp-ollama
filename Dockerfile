# Use Alpine Linux for an ultra-lightweight container
FROM python:3.13-alpine

# Set working directory
WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install system dependencies
RUN apk add --no-cache \
    gcc \
    musl-dev \
    python3-dev \
    libffi-dev \
    openssl-dev \
    cargo

# Install Poetry
RUN pip install --no-cache-dir poetry

# Copy only dependency files to cache the dependencies
COPY pyproject.toml LICENSE ./
COPY README.md ./

# Configure Poetry to not use virtualenvs in Docker
RUN poetry config virtualenvs.create false

# Install dependencies
RUN poetry install --no-interaction --no-ansi

# Copy source files
COPY src/ ./src/

# Expose the port if needed (adjust if the server uses a specific port)
EXPOSE 8000

# Command to run the server with the correct module path
CMD ["python", "-m", "src.mcp_ollama"]