FROM python:3.10-slim

# Install nginx and RTMP module
RUN apt-get update && \
    apt-get install -y nginx libnginx-mod-rtmp && \
    apt-get clean

# Install Flask
RUN pip install flask

# Copy files
COPY nginx.conf /etc/nginx/nginx.conf
COPY start.sh /start.sh
COPY app.py /app.py
COPY templates/ /templates/

# Create HLS output directory
RUN mkdir -p /var/www/hls

# Expose ports

# rtmp ingest
EXPOSE 1935
# nginx http for hls
EXPOSE 8080
# flask service
EXPOSE 5000

# make start.sh executable
RUN chmod +x start.sh

# Start script
CMD ["bash", "/start.sh"]