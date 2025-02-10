ARG BASE_IMAGE=nvcr.io/nvidia/l4t-base:r32.4.4

FROM ${BASE_IMAGE}

#
# apt packages
#
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
		libopenmpi3 \
		openmpi-bin \
		openmpi-common \
		protobuf-compiler \
		libprotoc-dev \
		llvm-9 \
		llvm-9-dev \
		libffi-dev \
		libsndfile1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustc --version && \
    pip3 install setuptools-rust

#
# JupyterLab
#
RUN pip3 install --no-cache-dir --verbose jupyter jupyterlab && \
    pip3 install --no-cache-dir --verbose jupyterlab_widgets

RUN jupyter lab --generate-config
RUN python3 -c "from notebook.auth.security import set_password; set_password('nvidia', '/root/.jupyter/jupyter_notebook_config.json')"

CMD /bin/bash -c "jupyter lab --ip 0.0.0.0 --port 8888 --allow-root &> /var/log/jupyter.log" & \
	echo "allow 10 sec for JupyterLab to start @ http://$(hostname -I | cut -d' ' -f1):8888 (password nvidia)" && \
	echo "JupterLab logging location:  /var/log/jupyter.log  (inside the container)" && \
	/bin/bash

# vulnerability fixed in: 0.18.3 (GHSA-v3c5-jqr6-7qm8 - https://github.com/advisories/GHSA-v3c5-jqr6-7qm8)
RUN pip3 install --upgrade --verbose future && \
pip3 show future