#!/bin/bash

# connect to ec2-data

# deploying database
cd $HOME/project/db

docker build -t tienda-db .

docker run \
    --rm \
    --detach \
    --name tienda-db \
    --publish 3306:3306 \
    --volume dbdata:/var/lib/mysql \
    tienda-db

# connect to ec2-backend

# deploying backend
cd $HOME/project/backend

export DB_HOST_IP=10.0.4.XXX

docker build -t tienda-backend .

docker run \
    --rm \
    --detach \
    --name tienda-backend \
    --publish 3001:3001 \
    --env DB_HOST=$DB_HOST_IP \
    --env DB_USER=root \
    --env DB_PASSWORD=admin123 \
    --env DB_NAME=tienda_perritos \
    --env DB_PORT=3306 \
    tienda-backend

# on ec2-web (the Bastion)

# deploying frontend
cd $HOME/project/frontend

## MODIFY THE IP ON default.conf WITH BACKEND IP
vi default.conf

docker build -t tienda-frontend .

docker run \
    --rm \
    --detach \
    --name tienda-frontend \
    --publish 80:80 \
    tienda-frontend
