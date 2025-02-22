FROM nvcr.io/nvidia/l4t-base:r36.2.0

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-pip \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get clean

RUN pip install --no-cache-dir --verbose jupyter jupyterlab && \
	pip install --no-cache-dir --verbose jupyterlab_widgets	

RUN jupyter lab --generate-config

CMD /bin/bash -c "jupyter lab --ip 0.0.0.0 --port 8888 --allow-root &> /var/log/jupyter.log" & \
	echo "allow 10 sec for JupyterLab to start @ http://$(hostname -I | cut -d' ' -f1):8888 (password nvidia)" && \
	echo "JupterLab logging location:  /var/log/jupyter.log  (inside the container)" && \
	/bin/bash