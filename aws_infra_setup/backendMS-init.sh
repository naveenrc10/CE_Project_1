#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y ansible unzip

sudo snap install aws-cli --classic
sudo snap install docker --classic

sudo docker run -d -p 8080:8080 navchakravarthy/backendapi:latest