#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ ! -f $DIR/../.env ]; then
    echo ".env file not found!"
    exit;
fi

if [ ! -f $DIR/../composer.json ]; then
    echo "composer.json not found! Please create a new file with an empty JSON object in it."
    exit;
fi

DOCKERCOMPOSEFILE="$DIR/docker-compose.yml"

trap "exit 1" TERM
export TOP_PID=$$
exitIfError() {
    $@ || (
        echo "Command '$@' failed"
        kill -s TERM $TOP_PID
    )
}

title() {
    echo "====== $(date +%H:%M:%S) $@ ======"
}

function runWorkspace() {
    USERID=$(id -u)
    GROUPID=$(id -g)

    if [[ "$(uname)" == "Darwin" ]]; then
        USERNAME=$(id -un)
        GROUPNAME=$(id -gn)
        PASSWDFILE=$DIR/storage/fake-mac-passwd-file
        GROUPFILE=$DIR/storage/fake-mac-group-file

        cp /etc/passwd $PASSWDFILE
        echo "$USERNAME:x:$USERID:$GROUPID:$USERNAME:$HOME:/bin/bash" >> $PASSWDFILE

        cp /etc/group $GROUPFILE
        echo "$GROUPNAME:x:$GROUPID:" >> $GROUPFILE
    else
        PASSWDFILE=/etc/passwd
        GROUPFILE=/etc/group
    fi

    CMD_ARGS="$@"

    runDockerCompose \
        run --rm \
        -u "${USERID}:${GROUPID}" \
        -w $(pwd) \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v $(pwd):$(pwd) \
        -v ${HOME}/.docker:${HOME}/.docker:ro \
        -v ${HOME}/.ssh:${HOME}/.ssh:ro \
        -v ${HOME}/.gitconfig:${HOME}/.gitconfig:ro \
        -v ${PASSWDFILE}:/etc/passwd:ro \
        -v ${GROUPFILE}:/etc/group:ro \
        ${RUN_ARGS} \
        workspace \
        ${CMD_ARGS}

    return $?
}

function runDockerCompose() {
    docker-compose \
        --file $DOCKERCOMPOSEFILE \
        ${PRE_ARGS} \
        "$@"

    return $?
}

while (( "$#" )); do
    DIRECT=0
    TTY=1
    # Allowed flags for calling ./workspace
    if [[ "$1" == "--direct" ]]; then
        DIRECT=1
        shift
    elif [[ "$1" == "--tty" ]]; then
        TTY=1
        shift
    elif [[ "$1" == "--no-tty" ]]; then
        TTY=0
        shift
    else
        break
    fi
done

# Compile run args
RUN_ARGS=""
if [[ $SERVICEPORTS -gt 0 ]]; then
    RUN_ARGS="${RUN_ARGS} --service-ports"
fi
if [[ $TTY -eq 0 ]]; then
    RUN_ARGS="${RUN_ARGS} -T"
fi

# Run command direct, or boot up everything
if [[ ${DIRECT} -eq 0 ]]; then
    # Run test-dev (and it's dependencies)
    exitIfError runDockerCompose up -d mysql fpm nginx

    # Make writable dirs writable
    # runDockerCompose exec -T fpm chmod -R a+rw storage

    # Install php libraries
    runWorkspace composer install -o --prefer-dist
fi

# Run command inside workspace container
title "running: $@"
runWorkspace "$@"

exit $?
