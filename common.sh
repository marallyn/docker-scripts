# builds the command to be run in the container
# default is bash with a custom bashrc
# if alpine, command is just sh
build_command() {
    wdir=$1
    os=$2

    # create the command array
    if [ "$os" = "alpine" ]; then
        command_arr=( "sh" )
    else
        command_arr=( "bash" "--rcfile" "/$wdir/.bashrc" "-i" )
    fi

    echo ${command_arr[@]}
}

# copies our favorite bashrc into place for use byt the container
# it also appends the prompt definition so we can easily tell what container we are in
copy_bashrc() {
    image=$1

    # move our custom bashrc to tmp so we can modify it and use it in the container
    cp ~/docker-scripts/bashrc /tmp/bashrc

    # change the prompt so we know what image we are using
    echo "PS1=\"\[\e[91m\][${image}]\[\e[00m\] \w $ \"" >> /tmp/bashrc
}

# calls docker run with all the flags that I commonly use
# usage:
#   docker_run $working_dir $image $command
docker_run() {
    # pull the args into variables
    # we are shitfing them, because we want to access all of them, one at a time
    wdir=$1;shift
    image=$1;shift

    command_arr=()

    # the rest of the args make up the command to run in the docker image
    while [ -n "$1" ]
    do
        command_arr+=($1)
        shift
    done

    docker run \
        -i \
        --rm \
        -t \
        -u `id -u`:`id -g` \
        -v `pwd`:"/$wdir" \
        -v /tmp/bashrc:"/$wdir/.bashrc" \
        -w "/$wdir" \
        "$image" \
        "${command_arr[@]}"
}

# constructs and returns the image name from a base_image, version and os
# if version is latest, we set os='', because latest images don't include an os flavor
image_name() {
    base_image=$1
    version=$2
    os=$3

    if [ "$version" = "latest" ]; then
        # the latest tag does not have os options
        image="$base_image:$version"
        os=""
    else
        image="$base_image:$version-$os"
    fi

    # os may change, so we return it
    echo $image $os
}

open_cli() {
    language=$1;shift
    default_version=$1;shift
    default_os=$1;shift
    echo "default_version: $default_version"
    echo "default_os: $default_os"
    echo "script: $0"

    # process the args into an array, and assign vars
    result=( $(process_args $0 $default_version $default_os $@) )
    version=${result[0]}
    os=${result[1]}

    # initialize variables
    wdir=$(working_dir)

    # get the image name (os may change, so it is returned as well)
    result=( $(image_name $language $version $os) )
    image=${result[0]}
    os=${result[1]}

    # build the command array
    command_arr=( $(build_command $wdir $os) )

    # move bashrc into place and append PS1
    copy_bashrc $image

    echo "language: $language"
    echo "version: $version"
    echo "os: $os"
    echo "image: $image"
    echo "wdir: $wdir"
    echo "commad: ${command_arr[@]}"
    # runs a long docker command using the calculated vars
    docker_run "/$wdir" $image ${command_arr[@]}
}

# processes the command line arguments
# shows help if requested
# assigns and returns os and version vars
process_args() {
    script_name=$1;shift
    version=$1;shift
    os=$1;shift

    while getopts ":ho:v:" opt; do
        case "$opt" in
            h )
                show_help $script_name
                exit 1;;
            o )
                os="$OPTARG";;
            v )
                version=$OPTARG;;
            \? )
                echo "Invalid option: $OPTARG" >&2
                exit 1;;
            : )
                echo "Invalid option: '-$OPTARG' requires an argument" >&2
                exit 1;;
        esac
    done

    echo $version $os
}

# show some help
show_help() {
    # get just the script name
    script_name=$(working_dir $1)

    echo "
    Opens a bash shell using a docker image with the specified php version and os flavor.

    Usage:
        $script_name [options]

    Options:
        -h                Display this help message.
        -o <os flavor>    Specify the os flavor. Default=buster
        -v <php version>  Specify the image version. Default=latest

    Exceptions:
        If -o alpine is specified, sh is used instead of bash
        If -v latest is specified, -o is ignored
"
} >&2

# returns the suggested working dir for the container
# looks at pwd (or $1 if supplied) and pulls the last directory off the end
# if path == /home/jeff/src/arctic, result => arctic
# if path is / or contains some crazy character, app is returned
working_dir() {
    # use $1 if supplied, otherwise work on pwd
    if [ -n "$1" ]
    then
        path=$1
    else
        path=$(pwd)
    fi

    # the regular legal dir and file chars
    regex="/([a-zA-Z0-9\-]+)$"

    if [[ $path =~ $regex ]]
    then
        wdir=${BASH_REMATCH[1]}
    else
        wdir="app"
    fi

    echo $wdir
}
