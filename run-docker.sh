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
      if [ ! -f "/home/$USER/Downloads/artifact-server_$dockertag.tar.gz" ]; then
         echo "You need to download artifact-server:$dockertag.tar.gz into /home/$USER/Downloads/"
         exit -1
      fi
   	docker load < "/home/$USER/Downloads/artifact-server_$dockertag.tar.gz"
   fi
}

function replaceSlashWithHyphen()
{
   parseArgs $@
   if [ "$job_name" != "" ]; then 
      job_name=$(echo $job_name | sed -r 's/\//_/g');
      job_name=$(echo $job_name | sed -r 's/%2F/_/g'); 
   fi
}

function main()
{
   local build=""
   local interactive=""
   local stop="no"
   parseArgs $@
   installDocker
   loadDockerImage
   
   export DOCKER_HOST=""
   local dockerimage="artifact-server:$dockertag"
   replaceSlashWithHyphen job_name="$job_name"
   containerid=$(docker ps -aqf "name=$dockerimage")
   if [ "$containerid" == "" ]; then
      containerid=$(docker ps -a | grep $dockerimage | head -n1 | cut -d " " -f1)
   fi

   if [ "$containerid" != "" ]; then
      #local container_id=$(docker ps -a -q -n 1)
      # echo "Container already running! container id: $container_id. Do you want to stop this container? <yes|no>"
      # read yesno
      # if [ "$yesno" == "yes" ]; then docker stop $container_id; return 0; fi
      if [ "$stop" == "true" ] || [ "$stop" == "yes" ]; then
         docker stop $containerid
      else
         docker exec -it $containerid /bin/bash
      fi
   elif [ "$stop" != "yes" ] && [ "$stop" != "true" ]; then
	local script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
	
	sudo mkdir -p /datadisk/nextgen/www
	sudo mkdir -p /datadisk/nextgen/www-db
	
	sudo rm -fr /datadisk/nextgen/www
	sudo mkdir -p /datadisk/nextgen/
	pushd /datadisk/nextgen/
	sudo ln -sf $script_dir/in/www .
	popd

	local workdir="$script_dir/tmp"
	mkdir -p $workdir
	rm -fr $workdir/*

	sudo cp /etc/passwd $workdir/etc.passwd
	sudo cp /etc/group $workdir/etc.group
	sudo cp /etc/shadow $workdir/etc.shadow
	sudo cp /etc/sudoers $workdir/etc.sudoers
	#         sudo cp -r /etc/sudoers.d $workdir/etc.sudoers.d

	cp -f $script_dir/helper-functions.sh $workdir/run.sh
	echo "configureSshServer" >> $workdir/run.sh
	echo "installMediaWiki" >> $workdir/run.sh
	echo "sudo service php8.1-fpm start" >> $workdir/run.sh
	echo "sudo service nginx start" >> $workdir/run.sh
	if [ "$interactive" != "yes" ]; then
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
   fi
}

export DOCKER_HOST=""
main $@


