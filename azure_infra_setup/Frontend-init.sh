#!/bin/bash

sudo apt-get update -y
#sudo apt-get install -y ansible unzip

sudo apt install docker.io -y

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to Docker group (optional)
sudo usermod -aG docker ubuntu

# Pull and run a Docker container
sudo docker run -d -p 8080:8080 --name frontend navchakravarthy/frontend:latest
