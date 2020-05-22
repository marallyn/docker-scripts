## Docker Scripts

I use these scripts to open docker containers with my most used settings.
Currently there are three scripts for the languages I most often use:

```
phpcli, nodecli and gocli
```

Without any arguments, the 'latest' image is used, so

```
phpcli
```

is essentially like executing

```
docker run [flags] php:latest bash
```

You can change the image version with the -v flag and the os flavor with the -o
flag. For example

```
phpcli -v 7.2 -o stretch
phpcli -v 7 -o alpine
```

### The Docker Command

This is what the docker command looks like;

```
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
```

-   wdir is calculated by taking the trailing directory off pwd
-   command_arr is basically a call to bash with a custom bashrc that has some
    useful aliases that I like
-   the prompt is derived from the image name and working dir so if I am using
    php:latest in the project /home/jeff/src/arctic the prompt will be:

```
[php:latest] /arctic $
```

-   the docker command also sets the current user as the user in the container
    so you don't end up with root files in your project directory

#### common.sh

All of the functions are stored in common.sh
