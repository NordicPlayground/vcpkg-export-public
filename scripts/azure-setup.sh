#! /usr/bin/env bash

export AZURE_DEVOPS_ORGANIZATION_URL=https://dev.azure.com/NordicSemiconductor/

az config set core.only_show_errors=true --only-show-errors
az config set extension.use_dynamic_install=yes_without_prompt
az devops configure --defaults organization=$AZURE_DEVOPS_ORGANIZATION_URL project="Wayland"

if [ -z ${ARTIFACT_ARCH+x} ]; then
    echo "ARTIFACT_ARCH not set, needs to be set"
    exit -1
fi

export WAYLAND_ENV_FILE="$HOME/.waylandrc"
rm -f $WAYLAND_ENV_FILE

if [ -z ${VCPKG_TRIPLET+x} ]; then
    echo "VCPKG_TRIPLET must be specified"
    exit -1
fi

echo "export VCPKG_TRIPLET=$VCPKG_TRIPLET" >> $WAYLAND_ENV_FILE

# Figure out if it is an Azure Agent or if it is a developer workstation
if [ -z ${AGENT_VERSION+x} ]; then
    echo "This is not an Azure DevOps build agent, faking environment variables for developer workstation"

    if [ -z ${WAYLAND_PERSONAL_USER_PAT+x} ]; then
        echo "WAYLAND_PERSONAL_USER_PAT must be set"
        exit -1
    fi

    export SOURCE_ROOT_DIR=`git rev-parse --show-toplevel`
    if [ -z ${SOURCE_ROOT_DIR+x} ]; then
        echo "Not able to determine source root dir"
        exit -1
    fi
    echo "export SYSTEM_DEFAULTWORKINGDIRECTORY=$SOURCE_ROOT_DIR" >> $WAYLAND_ENV_FILE
    echo "export BUILD_BUILDID=1" >> $WAYLAND_ENV_FILE
    echo "export WAYLAND_AZ_USER_PAT=$WAYLAND_PERSONAL_USER_PAT" >> $WAYLAND_ENV_FILE

    # Use temporary directory for artifact staging directory
    export BUILD_ARTIFACTSTAGINGDIRECTORY=`mktemp -d`
    echo "export BUILD_ARTIFACTSTAGINGDIRECTORY=$BUILD_ARTIFACTSTAGINGDIRECTORY" >> $WAYLAND_ENV_FILE

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        export AGENT_OS="Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        export AGENT_OS="macos"
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        export AGENT_OS=windows_nt
    elif [[ "$OSTYPE" == "msys" ]]; then
        export AGENT_OS="windows_nt"
    elif [[ "$OSTYPE" == "win32" ]]; then
        export AGENT_OS="windows_nt"
    else
        echo "Unknown OS, exiting"
        exit -1
    fi
else
    echo "This is an Azure DevOps build agent, using provided environment variables"
fi

export OS_NAME="$(tr [A-Z] [a-z] <<< "$AGENT_OS")"
echo "export OS_NAME=$OS_NAME" >> $WAYLAND_ENV_FILE
echo "export ARTIFACT_ARCH="$(tr [A-Z] [a-z] <<< "$ARTIFACT_ARCH")"" >> $WAYLAND_ENV_FILE
echo "export OS_ARCH="$OS_NAME-$ARTIFACT_ARCH"" >> $WAYLAND_ENV_FILE

echo "Variables exported to $WAYLAND_ENV_FILE"
