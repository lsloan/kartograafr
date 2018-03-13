# Development script to build and run kartograafr in Docker locally (e.g. a laptop).
# This isn't used for OpenShift.
# OpenShift builds will be a different workflow, but inside docker
# it doesn't matter if this is running on OSX or OpenShift.

#set -x
# Terminate if there is any error.
set -e

TAG=kart-dev-p3-esri

### Docker file
DOCKER_FILE=./Dockerfile

# Setup a configuration type to identify the configuration files and the
# Docker tag.
CONFIG_TYPE=${CONFIG_TYPE:-DEV}

# Use configuration type to generate a docker tag
TAG=$(echo ${CONFIG_TYPE} | tr '[:upper:]' '[:lower:]')
TAG=kart-${TAG}

########### Setup docker environment volume mappings.
HOST_LOG=${PWD}/tmp/log
CONTAINER_LOG=/var/log/kartograafr
V_LOG=" -v ${HOST_LOG}:${CONTAINER_LOG} "

HOST_SECRETS=$(pwd)/OPT/SECRETS
CONTAINER_SECRETS=/opt/secrets
V_SECRETS=" -v ${HOST_SECRETS}:${CONTAINER_SECRETS} "
############

# Add environment variable to pass to Docker container
DOCKER_ENV=" -e CONFIG_TYPE=${CONFIG_TYPE} "

## Merge all the variable Docker arguments.
DOCKER_ARGS=" ${V_LOG} ${V_SECRETS} ${DOCKER_ENV}"

####

   docker build -f ${DOCKER_FILE} -t $TAG . \
&& docker run -it ${DOCKER_ARGS} --rm --name ${TAG}-run ${TAG} 2>&1

echo "log directory: "
echo -n "Done at: "
date
#end
