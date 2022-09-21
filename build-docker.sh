#!/bin/bash -xe
set -xe

source "version.sh"
source helper-functions.sh

function downloadBaseImage()
{
   parseArgs $@

   local ubuntuimage="ubuntu-focal-oci-amd64-root.tar.gz"
   local ubuntuurl="https://partner-images.canonical.com/oci/focal/20220826/"
   #local ubuntuimage="ubuntu-jammy-oci-amd64-root.tar.gz"
   #local ubuntuurl="https://partner-images.canonical.com/oci/jammy/20220815/"

   mkdir -p ../out
   pushd ../out
   if [ ! -f "$ubuntuimage" ]; then
      wget --no-check-certificate $ubuntuurl$ubuntuimage
   fi
   # docker system prune -af
   local imagesha=$(docker import $ubuntuimage | sed -r "s/sha256:([0-9a-f]{12}).*/\1/g")
   echo "imported image $imagesha"
   popd

   local imageid=""
   #print ../out docker image id's
   imageid=$(docker image ls -q | grep $imagesha)

   if [ "$imageid" != "$imagesha" ]; then
      echo "could not find imageid $imageid for base image: $ubuntuimage";
      exit -1
   fi

   rm -f /tmp/docker.images
   docker tag $imageid ubuntu-minimal:focal
}

function saveImageAsTarGz()
{
   local dockerimage=""
   local artifacts_dir=""
   parseArgs $@

   mkdir -p ../out
   rm -fr ../out/steno-docker-image.tar.gz
   sudo apt install -y pv
   docker save $dockerimage | pigz --stdout --best > ../out/$dockerimage.tar.gz
   #docker load < "../out/steno-docker-image.tar.gz"
   echo "image is ready: ../out/$dockerimage.tar.gz"

   if [ -d "$artifacts_dir" ]; then
      cp ../out/$dockerimage.tar.gz $artifacts_dir/
   fi
}

function checkDockerIsInstalled()
{
   parseArgs $@

   local dockerpath=$(which docker)
   if [ "$dockerpath" == "" ]; then
      echo "Docker is not installed!"
      echo "Will try to install Docker"
      sudo ls
      sudo apt install -y containerd docker.io
      sudo usermod -aG docker $USER
      sudo chmod 666 /var/run/docker.sock
      sudo systemctl enable docker.service
      sudo systemctl enable containerd.service
      docker run hello-world
   fi
}

function main()
{
   export DOCKER_HOST=""
   local artifacts_dir=""
   parseArgs $@

   checkDockerIsInstalled
   downloadBaseImage  

   local dockerimage="artifact-server:$dockertag"
   local workdir="tmp"

   mkdir -p $workdir
   sudo rm -fr $workdir/*
   cp helper-functions.sh $workdir/run.sh
   
   mkdir -p in
   cp -r ~/.ssh in/

   echo "
\$@" >> $workdir/run.sh
   chmod +x $workdir/run.sh

   mkdir -p tmp
   if [ ! -f mediawiki-1.38.2.zip ]; then
      pushd tmp/
      wget https://releases.wikimedia.org/mediawiki/1.38/mediawiki-1.38.2.zip
      popd
   fi
   
   #docker build -t <hub-user>/<repo-name>[:<tag>] .
   docker build \
      --no-cache \
      --build-arg USER=${USER} \
      --build-arg WORKDIR=${HOME} \
      --memory="8g" --memory-swap="-1" \
      --progress=plain -t $dockerimage .

   saveImageAsTarGz dockerimage="$dockerimage" artifacts_dir="$artifacts_dir"
   rm -fr $workdir
}

time main $@
