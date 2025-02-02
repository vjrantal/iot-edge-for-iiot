#!/usr/bin/env bash

function show_help() {
   # Display Help
   echo "Run this script to populate your Azure Container Registry (ACR) with required container images to use IoT Edge in nested configuration."
   echo
   echo "Syntax: ./import_acr.sh [-flag parameter]"
   echo ""
   echo "List of optional flags:"
   echo "-h      Print this help."
   echo "-c      Path to configuration file with path to file with ACR credentials information. Default: ../config.txt."
   echo "-s      Azure subscription ID to use to deploy resources. Default: use current subscription of Azure CLI."
   echo
}

#global variable
scriptFolder=$(dirname "$(readlink -f "$0")")

# Default settings
configFilePath="${scriptFolder}/../config.txt"

# Get arguments
while :; do
    case $1 in
        -h|-\?|--help)
            show_help
            exit;;
        -c=?*)
            configFilePath=${1#*=}
            if [ ! -f "${configFilePath}" ]; then
              echo "Configuration file not found. Exiting."
              exit 1
            fi;;
        -c=)
            echo "Missing configuration file path. Exiting."
            exit;;
        -s=?*)
            subscription=${1#*=}
            ;;
        -s=)
            echo "Missing subscription id. Exiting."
            exit;;
        --)
            shift
            break;;
        *)
            break
    esac
    shift
done


# Prepare CLI
if [ ! -z $subscription ]; then
    az account set --subscription $subscription
fi

# Parse the configuration file to get the ACR credentials info
source ${scriptFolder}/parseConfigFile.sh $configFilePath
# Verifying that the ACR environment variable file is here
if [ -z $acrEnvFilePath ]; then
    echo ".Env file with Azure Container Registry (ACR) credentials is missing from the configuration file. Please verify your configuration file. Exiting."
    exit 1
fi
acrEnvFilePath="${scriptFolder}/$acrEnvFilePath"

echo "==========================================================="
echo "==          Import container images to your ACR          =="
echo "==========================================================="
echo ""

# Get ACR name
source $acrEnvFilePath
if [ -z $ACR_ADDRESS ]; then
    echo "ACR_ADDRESS value is missing. Please verify your ACR.env file. Exiting."
    exit 1
fi
acrName="${ACR_ADDRESS/.azurecr.io/}"

echo "Importing container images to ACR ${acrName}"
echo ""
echo "edgeAgent..."
az acr import --name $acrName --force --source mcr.microsoft.com/azureiotedge-agent:1.2.0-rc4 --image azureiotedge-agent:1.2.0-rc4
echo "edgeHub..."
az acr import --name $acrName --force --source mcr.microsoft.com/azureiotedge-hub:1.2.0-rc4 --image azureiotedge-hub:1.2.0-rc4
echo "diagnostics..."
az acr import --name $acrName --force --source mcr.microsoft.com/azureiotedge-diagnostics:1.2.0-rc4 --image azureiotedge-diagnostics:1.2.0-rc4
echo "API proxy..."
az acr import --name $acrName --force --source mcr.microsoft.com/azureiotedge-api-proxy:latest --image azureiotedge-api-proxy:latest
echo "Simulated temperature sensor..."
az acr import --name $acrName --force --source mcr.microsoft.com/azureiotedge-simulated-temperature-sensor:1.0 --image azureiotedge-simulated-temperature-sensor:1.0
echo "...done"
echo ""
