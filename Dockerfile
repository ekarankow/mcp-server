FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY pyproject.toml uv.lock ./
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir "mcp[cli]" httpx

# Optional: install uv tool if you want to run server via uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Copy the application code
COPY . .

# Create entrypoint.sh
RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
    echo 'set -e' >> /app/entrypoint.sh && \
    echo 'if [ -z "$FINANCIAL_DATASETS_API_KEY" ]; then' >> /app/entrypoint.sh && \
    echo '  echo "ERROR: FINANCIAL_DATASETS_API_KEY is not set"' >> /app/entrypoint.sh && \
    echo '  exit 1' >> /app/entrypoint.sh && \
    echo 'fi' >> /app/entrypoint.sh && \
    echo 'echo "Starting MCP Server with API Key: $FINANCIAL_DATASETS_API_KEY"' >> /app/entrypoint.sh && \
    echo 'if [ "$USE_UV" = "1" ]; then' >> /app/entrypoint.sh && \
    echo '  exec uv run server.py' >> /app/entrypoint.sh && \
    echo 'else' >> /app/entrypoint.sh && \
    echo '  exec python server.py' >> /app/entrypoint.sh && \
    echo 'fi' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

# Create non-root user (optional, safer)
RUN useradd -m mcp && chown -R mcp /app
USER mcp

EXPOSE 3000

ENTRYPOINT ["/app/entrypoint.sh"]
