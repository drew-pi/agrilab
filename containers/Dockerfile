FROM ubuntu:latest

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

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
