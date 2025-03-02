FROM nvcr.io/nvidia/l4t-tensorrt:r8.2.1-runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-pip \
        python3-dev \
        python3-matplotlib \
        build-essential \
        gfortran \
        git \
        cmake \
        curl \
        libopenblas-dev \
        liblapack-dev \
        libblas-dev \
        libhdf5-serial-dev \
        hdf5-tools \
        libhdf5-dev \
        zlib1g-dev \
        zip \
        libjpeg8-dev \
        openmpi-bin \
        openmpi-common \
        protobuf-compiler \
        libprotoc-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create a non-root user (persephone)
RUN useradd -m -s /bin/bash persephone 

# Ensure the home directory exists and has the right permissions
RUN mkdir -p /home/persephone/.local /home/persephone/.jupyter /home/persephone/logs /home/persephone/notebooks && \
    touch /home/persephone/logs/jupyter.log && \
    chown -R persephone:persephone /home/persephone

# Switch to persephone user for installing Python packages
USER persephone
WORKDIR /home/persephone

# Upgrade pip and ensure all packages are installed in ~/.local/
RUN pip install --no-cache-dir --upgrade pip --user && \
    pip install --no-cache-dir --user jupyter jupyterlab jupyterlab_widgets

ENV JP_VERSION=46 # If fails, try JP_VERSION=464
ENV TF_VERSION=2.7.0 
ENV NV_VERSION=22.1

RUN pip3 install --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v$JP_VERSION tensorflow==$TF_VERSION+nv$NV_VERSION

# Set environment variables to ensure the user's local bin directory is used
ENV PATH="/home/persephone/.local/bin:${PATH}" \
    PYTHONUSERBASE="/home/persephone/.local"

# Generate Jupyter config
RUN jupyter lab --generate-config

# Expose Jupyter port
EXPOSE 8888

# Start JupyterLab as persephone user
CMD bash -c 'echo "allow 10 sec for JupyterLab to start @ http://$(hostname -I | cut -d" " -f1):8888 (no password)"; \
              echo "JupyterLab logging location: /home/persephone/logs/jupyter.log"; \
              jupyter lab --ip=0.0.0.0 --port=8888 --NotebookApp.token="" --NotebookApp.password="" --no-browser &> /home/persephone/logs/jupyter.log'