#!/bin/bash -xe
set -xe

#To run GUI applications from inside docker, install https://www.xquartz.org/
#launch xquarts, under preferences, security tab, check "Allow connections from network clients"
#and run command 'xhost +localhost' on your macos before running this script
#https://gist.github.com/cschiewek/246a244ba23da8b9f0e7b11a68bf3285

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $script_dir/version.sh
source $script_dir/helper-functions.sh

function installDocker()
{
   local docker_installed=$(which docker)
   if [ "$docker_installed" == "" ]; then
   	sudo apt install -y docker.io
      sudo chmod 666 /var/run/docker.sock
      sudo groupadd docker && true
      sudo usermod -aG docker ${USER}
   fi
}

function loadDockerImage()
{
   local docker_loaded=$(docker image ls artifact-server:$dockertag| grep "artifact-server")
   if [ "$docker_loaded" == "" ]; then
      if [ ! -f "$(pwd)/out/artifact-server_$dockertag.tar.gz" ]; then
         echo "Cannot find $(pwd)/out/artifact-server_$dockertag.tar.gz . Perhaps you need to run ./build-docker.sh"
         exit -1
      fi
   	docker load < "out/artifact-server_$dockertag.tar.gz"
   fi
}

function main()
{
   local build=""
   local interactive=""
   local stop="false"
   parseArgs $@
   installDocker
   loadDockerImage
   
   export DOCKER_HOST=""
   local dockerimage="artifact-server:$dockertag"
   local containerid=$(docker ps -aqf "name=artifact-server")
   if [ "$containerid" == "" ]; then
      containerid=$(docker ps -a | grep $dockerimage | head -n1 | cut -d " " -f1)
   fi

   if [ "$containerid" != "" ]; then
      if [ "$stop" == "true" ] || [ "$stop" == "yes" ]; then
         docker stop $containerid
      else
         docker exec -it $containerid /bin/bash
      fi
      exit 0
   fi

	local script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

	sudo rm -fr /datadisk/nextgen/www
	sudo mkdir -p /datadisk/nextgen/www-db
	
	pushd /datadisk/nextgen/
	sudo ln -sf $script_dir/in/www .
	popd

	local workdir="$script_dir/tmp"
	mkdir -p $workdir
   sudo chown -R $(id -u):$(id -g) $workdir
	rm -fr $workdir/*

   copyUsersFromHostToContainer workdir="$workdir"

	cp -f $script_dir/helper-functions.sh $workdir/run.sh
	echo "configureMediaWiki" >> $workdir/run.sh
	echo "sudo service php8.1-fpm start" >> $workdir/run.sh
	echo "sudo service nginx start" >> $workdir/run.sh
   echo "/usr/bin/delete-old-files.sh &" >> $workdir/run.sh
	if [[ "$interactive" != "yes" && "$interactive" != "true" ]]; then
		echo "sleep infinity" >> $workdir/run.sh
	fi

	echo "welcome" >> $workdir/run.sh
	chmod +x $workdir/run.sh

	local cmd_run_in_docker=""
	local cmd_run_in_docker="bash -c /tmp/run.sh; bash"

   xhost + && true
   local container_name="jambamamba-artifact-server"
   local params=$(dockerParams dockerimage="$dockerimage" container_name="$container_name" interactive_terminal="$interactive")
   time docker run $params bash -c "$cmd_run_in_docker"

}

export DOCKER_HOST=""
main $@




