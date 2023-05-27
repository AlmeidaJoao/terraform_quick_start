#!/bin/bash 
sudo yum install docker -y
sudo systemctl start docker
sudo docker pull uzyexe/tetris
sudo docker run -d -p 80:80 uzyexe/tetris