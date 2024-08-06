#!/usr/bin/env bash
set -e

if [ -z "$1" ]
then
    echo 'Error: Registry-mirror url required.'
    exit 1
fi

MIRROR_URL="$(echo $1 | rev | cut -d "/" -f1 | rev)"
lsb_dist=''
command_exists() {
    command -v "$@" > /dev/null 2>&1
}
if command_exists lsb_release; then
    lsb_dist="$(lsb_release -si)"
    lsb_version="$(lsb_release -rs)"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/lsb-release ]; then
    lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
    lsb_version="$(. /etc/lsb-release && echo "$DISTRIB_RELEASE")"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/debian_version ]; then
    lsb_dist='debian'
fi
if [ -z "$lsb_dist" ] && [ -r /etc/fedora-release ]; then
    lsb_dist='fedora'
fi
if [ -z "$lsb_dist" ] && [ -r /etc/os-release ]; then
    lsb_dist="$(. /etc/os-release && echo "$ID")"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/centos-release ]; then
    lsb_dist="$(cat /etc/*-release | head -n1 | cut -d " " -f1)"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/rocky-release ]; then
    lsb_dist="$(cat /etc/*-release | head -n1 | cut -d " " -f1)"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/redhat-release ]; then
    lsb_dist='rhel'
fi
lsb_dist="$(echo $lsb_dist | cut -d " " -f1)"
podman_version="$(podman -v | awk '{print $3}')"
podman_major_version="$(echo $podman_version| cut -d "." -f1)"
podman_minor_version="$(echo $podman_version| cut -d "." -f2)"
lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
podman_REGISTRIES_CONFIG_FILE="/etc/containers/registries.conf.d/000-registries.conf"

set_prefix(){
    if sudo test -f ${podman_REGISTRIES_CONFIG_FILE}
    then
        sudo cp  ${podman_REGISTRIES_CONFIG_FILE} "${podman_REGISTRIES_CONFIG_FILE}.bak"
        sudo echo -e "[[registry]]\\nperfix = \"docker.io\"\nlocation = \"${MIRROR_URL}\"\n" >> ${podman_REGISTRIES_CONFIG_FILE}
    else
        sudo echo -e "[[registry]]\\nperfix = \"docker.io\"\nlocation = \"${MIRROR_URL}\"\n" > ${podman_REGISTRIES_CONFIG_FILE}        
    fi
}

set_prefix(){
    if sudo test -f ${podman_REGISTRIES_CONFIG_FILE}
    then
        sudo cp  ${podman_REGISTRIES_CONFIG_FILE} "${podman_REGISTRIES_CONFIG_FILE}.bak"
        sudo echo -e "[[registry]]\\nperfix = \"docker.io\"\nlocation = \"${MIRROR_URL}\"\n" >> ${podman_REGISTRIES_CONFIG_FILE}
    else
        sudo echo -e "[[registry]]\\nperfix = \"docker.io\"\nlocation = \"${MIRROR_URL}\"\n" > ${podman_REGISTRIES_CONFIG_FILE}        
    fi
}


no_need_set_prefix(){
	if [ "$podman_major_version" -eq 2 ] && [ "$podman_minor_version" -lt 0 ] 
	then
		echo "podman version < 2.0"
		return 0
	else
		echo "podman version >= 2.0"
		return 1
	fi
}

set_mirror(){
    if [ "$podman_major_version" -eq 1 ] && [ "$podman_minor_version" -lt 6 ]
        then
            echo "please upgrade your podman to v1.6 or later"
            exit 1
    fi

    case "$lsb_dist" in
        centos)
        if grep "CentOS release 6" /etc/*-release > /dev/null
	then
            echo "How dare you want to install it on 6.x ?"
            exit 0
        else
            if no_need_set_prefix; then
                sudo echo -e "[[docker.io]]\\nlocation = \"${MIRROR_URL}\"\n" > ${podman_REGISTRIES_CONFIG_FILE}
            else
                set_prefix
            fi
            echo "Success."
            echo "You are free to"
            exit 0
        fi
    ;;
        rhel)
        if grep "CentOS release 6" /etc/*-release > /dev/null
	then
            echo "How dare you want to install it on 6.x ?"
            exit 0
        else
            if no_need_set_prefix; then
                sudo echo -e "[[docker.io]]\\nlocation = \"${MIRROR_URL}\"\n" > ${podman_REGISTRIES_CONFIG_FILE}
            else
                set_prefix
            fi
            echo "Success."
            echo "You are free to"
            exit 0
        fi
    ;;
        rocky)
        if grep "Rocky release 6" /etc/rocky-release > /dev/null
	then
            echo "Are you kidding me? 6.x ?"
            exit 0
        else
            if no_need_set_prefix; then
                sudo echo -e "[[docker.io]]\\nlocation = \"${MIRROR_URL}\"\n" > ${podman_REGISTRIES_CONFIG_FILE}
            else
                set_prefix
            fi
            echo "Success."
            echo "Your dockerhub is free to go"
            exit 0
        fi
    ;;
        fedora)
        if grep "Fedora release" /etc/fedora-release > /dev/null
        then
            if no_need_set_prefix; then
                sudo echo -e "[[docker.io]]\\nlocation = \"${MIRROR_URL}\"\n" > ${podman_REGISTRIES_CONFIG_FILE}
            else
                set_prefix
            fi
            echo "Success."
            echo "Your dockerhub is free to go"
            exit 0
        else
            echo "Error: Set mirror failed, please set registry-mirror manually please."
            exit 1
        fi
    ;;
        ubuntu)
        v1=`echo ${lsb_version} | cut -d "." -f1`
        if [ "$v1" -ge 16 ]; then
            if no_need_set_prefix; then
                sudo echo -e "[[docker.io]]\\nlocation = \"${MIRROR_URL}\"\n" > ${podman_REGISTRIES_CONFIG_FILE}
            else
                set_prefix
            fi
            echo "Success."
            echo "Your dockerhub is free to go"
            exit 0
        else
            if no_need_set_prefix; then
                sudo echo -e "[[docker.io]]\\nlocation = \"${MIRROR_URL}\"\n" > ${podman_REGISTRIES_CONFIG_FILE}
            else
                set_prefix
            fi
        fi
        echo "Success."
        echo "Your dockerhub is free to go"
        exit 0
    ;;
        debian)
        if no_need_set_prefix; then
            sudo echo -e "[[docker.io]]\\nlocation = \"${MIRROR_URL}\"\n" > ${podman_REGISTRIES_CONFIG_FILE}
        else
            set_prefix
        fi
        echo "Success."
        echo "Your dockerhub is free to go"
        exit 0
    ;;
        arch)
        if grep "Arch Linux" /etc/os-release > /dev/null
        then
            if no_need_set_prefix; then
                sudo echo -e "[[docker.io]]\\nlocation = \"${MIRROR_URL}\"\n" > ${podman_REGISTRIES_CONFIG_FILE}
            else
                set_prefix
            fi
            echo "Success."
            echo "Your dockerhub is free to go"
            exit 0
        else
            echo "Error: Set mirror failed, please set registry-mirror manually please."
            exit 1
        fi
    ;;
        suse)
        if grep "openSUSE Leap" /etc/os-release > /dev/null
        then
            if no_need_set_prefix; then
                sudo echo -e "[[docker.io]]\\nlocation = \"${MIRROR_URL}\"\n" > ${podman_REGISTRIES_CONFIG_FILE}
            else
                set_prefix
            fi
            echo "Success."
            echo "Your dockerhub is free to go"
            exit 0
        else
            echo "Error: Set mirror failed, please set registry-mirror manually please."
            exit 1
        fi
    esac
    echo "Error: Unsupported OS, please set registry-mirror manually."
    exit 1
}
set_mirror


