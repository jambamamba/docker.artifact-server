#!/bin/bash -e
set -e

function deleteOldFiles()
{
   local file_prefix="$1"
   ls -tl | grep "${file_prefix}" > /tmp/files
   local num_files_to_keep=4
   local counter=0
   while read -r line; do
      if [ "$(echo $line | grep ${file_prefix})" != "" ]; then
         filename=$(echo $line | sed -r "s/.*(${file_prefix}.*)/\1/g")
         if [ $counter -ge $num_files_to_keep ]; then
            rm -f $filename
         fi
         let counter=counter+1
      fi
   done </tmp/files
}

function main()
{
   pushd /var/www/html/artifacts
      deleteOldFiles "fsl-image-gui-imx8mm-var-dart"
      deleteOldFiles "var-image-swu-imx8mm-var-dart"
      deleteOldFiles "steno-docker-image"
      pushd ova
         deleteOldFiles "nextgen-simulator"
         deleteOldFiles "nextgen-dev"
      popd
      deleteOldFiles "sdk"
      deleteOldFiles "rislib"
      deleteOldFiles "audiolibs"
      deleteOldFiles "cJSON"
      deleteOldFiles "cpython"
      deleteOldFiles "curl"
      deleteOldFiles "lvgl"
   popd
}

main
