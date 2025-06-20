FROM python:3.10-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nginx \
    libnginx-mod-rtmp \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Copy rest of files
COPY nginx.conf /etc/nginx/nginx.conf
COPY app.py /app.py
COPY templates/ /templates/
COPY .env /.env

# Create HLS output directory
RUN mkdir -p /var/www/hls

# Expose ports
# rtmp ingest
EXPOSE 1935
# nginx http for hls
EXPOSE 8080
# flask service
EXPOSE 5000

# Copy and allow start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Start script
CMD ["bash", "/start.sh"]