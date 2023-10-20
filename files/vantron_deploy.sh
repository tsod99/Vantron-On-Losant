#!/bin/bash

read -p "Enter device ID: " device_id
read -p "Enter access key: " access_key
read -p "Enter access secret: " access_secret

echo "**************************************************************************"

if [[ -z $device_id ]]; then
  echo "ERROR: Device ID is empty"
  exit 1
fi
echo "DEVICE ID: " $device_id

if [[ -z $access_key ]]; then
  echo "ERROR: Access key is empty"
  exit 1
fi
echo "ACCESS KEY: " $access_key

if [[ -z $access_secret ]]; then
  echo "ERROR: Access secret is empty"
  exit 1
fi
echo "ACCESS SECRET: " $access_secret

function echo_success()
{
    echo -e "\033[1;32m$1\033[0m"
}

# Check the docker service status and download the Losant edge agent docker image
docker_status=`/etc/init.d/dockerd status`
if [[ $docker_status == *"running"* ]]; then
  echo_success "Downloading the Losant edge agent docker image now, please wait for a while..."
  docker_image=`docker images`
  if [[ $docker_image == *"losant/edge-agent"* ]]; then
    echo_success "Losant edge agent docker image exists already, moving to the next step"
  else
    docker pull losant/edge-agent:latest-alpine
    docker_image=`docker images`
    if [[ $docker_image == *"losant/edge-agent"* ]]; then
      echo_success "Losant edge agent docker image has been downloaded successfully"
    else
      echo "ERROR: Failed to download the Losant docker image!"
      exit 1
    fi
  fi
else
  echo "ERROR: Docker service is not started!"
  exit 1
fi


# Make local directory and create needed files
mkdir -p /mnt/USER_SPACE/pipe
touch /mnt/USER_SPACE/pipe/output.txt
if [[ ! -p /mnt/USER_SPACE/pipe/mypipe ]]; then
  mkfifo /mnt/USER_SPACE/pipe/mypipe
fi  


# Get the needed files from the cloud
echo_success "Downloading needed scripts from AWS S3 bucket..."
if [[ -f /mnt/USER_SPACE/pipe/execpipe.sh ]]; then
  wget https://raw.githubusercontent.com/tsod99/Vantron-On-Losant/master/files/execpipe.sh -P /mnt/USER_SPACE/pipe
fi
if [[ -f /mnt/USER_SPACE/pipe/test.lua ]]; then
  wget https://raw.githubusercontent.com/tsod99/Vantron-On-Losant/master/files/test.lua -P /mnt/USER_SPACE/pipe
fi
if [[ -f /etc/init.d/execpipe ]]; then
  wget https://raw.githubusercontent.com/tsod99/Vantron-On-Losant/master/files/execpipe -P /etc/init.d
fi

# Give the proper permission to the files
chmod 777 -R /mnt/USER_SPACE/pipe

# Set execpipe to start on reboot
chmod +x /etc/init.d/execpipe
/etc/init.d/execpipe enable
service_status=`ps | grep execpipe`
if [[ $service_status != *"/mnt/USER_SPACE/pipe/execpipe.sh"* ]]; then
  /etc/init.d/execpipe start
fi

# Start the docker container
MAX_FLOW_RUN_TIME=300000

docker_ps=`docker ps -a`
if [[ $docker_ps == *"docs-agent"* ]]; then
  echo_success "Losant docker container is already running"
else
  docker run -d --restart always --name docs-agent \
  -e 'DEVICE_ID='$device_id \
  -e 'ACCESS_KEY='$access_key \
  -e 'ACCESS_SECRET='$access_secret \
  -e 'MAX_FLOW_RUN_TIME='$MAX_FLOW_RUN_TIME \
  -v /mnt/USER_SPACE/pipe:/hostpipe \
  losant/edge-agent:latest-alpine
  
  echo_success "*******************************************************************************************************"
  echo_success "* Docker container started successfully, your device will be connected to Losant server after a while *"
  echo_success "*******************************************************************************************************"

fi