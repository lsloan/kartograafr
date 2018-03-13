#!/bin/bash

# This script customizes a docker container for specific application
# environments (dev, qa, prod) and then starts cron so that the
# processing is done periodically.  It also makes environment
# variables available to cron jobs in a Docker environment. It should
# be invoked as the entry command in a Docker file.

# The script is Docker and cron centric. This version is specific to
# kartograafr but could be generalized.

# This script needs to be invoked directly by the Dockerfile. It allows:

# - Using environment variables to specify last minute configuration
# of the container.  E.g. If CONFIG_TYPE is set to DEV it will find a
# corresponding the Python configuration file and cron tab in the
# image and install them. The configuration file is expected to be
# found in: ${APP_DIR}/configuration/configOpenShift${CONFIG_TYPE}.py.
# The cron tab is expected to be found at:
# ${APP_DIR}/rootdir_etc_cron.d/kartograafr.${CONFIG_TYPE}.

# - It can inject Docker environment variables into a cron job.  See note
# below on usage.  This is NOT used currently for kartograafr.

# INJECTING EXISTING ENVIRONMENT VARIABLES INTO A CRON JOB.

# The capture_env function below will make a copy of the initial environment
# variables (into the script STARTUP_ENV_VARS.sh) to allow including
# them in a cron job environment.  To access the env variables for a
# cron job prefix the command for the specific cron entry with:
# "source /root/STARTUP_ENV_VARS.sh && "

# For example the cron tab line should look something like the following:
# * * * * * source /root/STARTUP_ENV_VARS.sh && echo "HI FROM CRON" > /proc/1/fd/1 2>&1

function capture_env {
    # Gather/format/store the environment variables for later use. This would run only when 
    # (This could be more selective if necessary.)
    env | sed 's/^\(.*\)$/export \1/g' \
        | sed 's/=/="/' \
        | sed 's/$/"/' \
              >| /root/STARTUP_ENV_VARS.sh
    chmod a+wr /root/STARTUP_ENV_VARS.sh
}

# This function is a debugging aid: Print a file to stdout.
function show_file {
    local SHOW_FILE=$1
    echo "================ VIEW FILE: ${SHOW_FILE} ================"
    cat ${SHOW_FILE}
    echo "================ END OF FILE: ${SHOW_FILE} ==============="
}

##############################

# Default to a safe DEV configuration.  It can be overridden by
# setting the environment variable.

CONFIG_TYPE=${CONFIG_TYPE:-DEV}

function configure_docker_image {

    echo "CONFIG_TYPE: ${CONFIG_TYPE}"
    
    ## require that a configuration type be specified.
    if [ -z "${CONFIG_TYPE}" ]; then
        echo "Must specify container runtime configuration via CONFIG_TYPE environment variable: DEV, PROD ...."
        exit 1;
    fi
    
    ######## Find the specific configuration file.
    REQUIRED_FILE=${APP_DIR}/configuration/configOpenShift${CONFIG_TYPE}.py
    if [[ ! -e ${REQUIRED_FILE} ]] ; then
        echo "File does not exist: ${REQUIRED_FILE}"
        exit 1;
    fi

    # Link the configuration file over any existing config.py file.
    ln -sf ${REQUIRED_FILE} ${APP_DIR}/config.py

    echo "$o: linking ${REQUIRED_FILE} as ${APP_DIR}/config.py"
    
    #show_file ${APP_DIR}/config.py

    ####### Use the configuration type specific cron file.
    REQUIRED_FILE=${APP_DIR}/rootdir_etc_cron.d/kartograafr.${CONFIG_TYPE}
    #    if [[ ! -e ${REQUIRED_FILE}.${CONFIG_TYPE} ]] ; then
    if [[ ! -e ${REQUIRED_FILE} ]] ; then
        echo "File does not exist: ${REQUIRED_FILE}"
        exit 1;
    fi

    echo "$0: Use cron tab ${REQUIRED_FILE}"
    cp ${REQUIRED_FILE} /etc/cron.d/kartograafr
    crontab /etc/cron.d/kartograafr

    show_file /etc/cron.d/kartograafr

    echo "$0: END OF DOCKER CONFIGURATION SETUP FOR ${CONFIG_TYPE} at: " $(date)

}

################ Configure application and start cron ##########
# Do not need to capture env for kartograafr cron jobs as yet.
#capture_env

# Start out with these default environment settings suitable for
# starting cron.  These values will NOT be inherited by jobs started
# by cron.

SHELL=/bin/sh
PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LANG=C.UTF-8
LOG_DIR=/var/log
APP_DIR=/usr/local/apps/kartograafr
SECRETS_DIR=/opt/secrets

# Now setup the desired configuration files.
configure_docker_image

## run cron in the forground so the container keeps running.
cron -f
#end
