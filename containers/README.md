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


### Resources 

A [random branch](https://github.com/dusty-nv/jetson-containers/blob/bc8d0264ef25aa0d1d25a54e4658f491d2fa130f/Dockerfile.ml) that we are modelling our docker files on.

