FROM python:3.10-slim

# Install nginx and RTMP module
RUN apt-get update && \
    apt-get install -y nginx libnginx-mod-rtmp && \
    apt-get clean

# install python libs
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Copy rest of files
COPY nginx.conf /etc/nginx/nginx.conf
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

# Copy and allow start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]