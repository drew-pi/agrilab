#!/bin/bash

set -e

# Start nginx in background
nginx

# Start Flask
python3 /app.py