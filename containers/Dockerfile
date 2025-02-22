FROM nvcr.io/nvidia/l4t-base:r36.2.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-pip \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get clean

RUN pip install --no-cache-dir --verbose jupyter jupyterlab && \
	pip install --no-cache-dir --verbose jupyterlab_widgets	

# create new user
RUN useradd -m -s /bin/bash persephone 

RUN mkdir -p /home/persephone/.jupyter && \
	mkdir -p /home/persephone/logs && \
	# touch /home/persephone/logs/jupyter.log && \
    chown -R persephone:persephone /home/persephone

# switch to new user
USER persephone
WORKDIR /home/persephone

RUN jupyter lab --generate-config

EXPOSE 8888

CMD bash -c 'echo "allow 10 sec for JupyterLab to start @ http://$(hostname -I | cut -d" " -f1):8888 (no password)"; \
              echo "JupyterLab logging location: /home/persephone/logs/jupyter.log"; \
              jupyter lab --ip=0.0.0.0 --port=8888 --NotebookApp.token="" --NotebookApp.password="" --no-browser &> /home/persephone/logs/jupyter.log'