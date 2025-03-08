# Containers for the Jetson Nano


### Running Scripts

To run the scripts, you first have to give them execution permissions
```
chmod +x start.sh build.sh
```

Then you can just run 
```
./start.sh
```
To build and run the container

The jupyter lab will be accessible at the IP address on your terminal screen 


### Stopping and Removing a container

To stop an active container (it is running in detached mode so it will always be running in the background automatically), use 
```
sudo docker stop jetson_jupyter
```

To remove the container (this will delete all of the containers contents, so be careful), run
```
sudo docker rm jetson_jupyter
```

### Container maintenance (+ get container id)

To see all of the containers which are currently running, run
```
sudo docker ps
```

To see existing containers (running and stopped)
```
sudo docker ps -a
```

The container id is going to be a hash under the column "CONTAINER ID" (or just the first value in the row)



### Starting containers

To run a container with gpu and host networking passed through (in interactive mode, with automatic self removal)
```
sudo docker run -it --rm --network=host --runtime=nvidia <container name/id>
```

### Enter already running container environment

Can also "enter" a container environment that is built on top of some linux distribution (ubuntu, etc) can run
```
sudo docker exec <container name/id>
```

### Copy file from Unix like OS (only works for mac + linux) to Jetson

Run the following command
```
scp /path/to/file jet@<ip>:/path/to/destination
```
Where **/path/to/file** is the file location on your local machine (can use the command ```pwd``` to check the path to a file)

And **/path/to/destination** is where you want the file to be placed



# Resources 

A [random branch](https://github.com/dusty-nv/jetson-containers/blob/bc8d0264ef25aa0d1d25a54e4658f491d2fa130f/Dockerfile.ml) that we are modelling our docker files on.

All the [containers](https://catalog.ngc.nvidia.com/containers?filters=&orderBy=scoreDESC&query=l4t&page=&pageSize=) available for jetson devices

[Jetson AI lab](https://github.com/dusty-nv/jetson-inference?tab=readme-ov-file#jetson-ai-lab) is an intro course for the jetson

