# set -x
set -e

# Set Global Variables
MAIN_BICEP_TEMPL_NAME="main.bicep"
SUB_DEPLOYMENT_PREFIX="userManagedIdentityDemo"
LOCATION="westeurope"

RG_NAME=""


az deployment group create \
    --name ${SUB_DEPLOYMENT_PREFIX}"-Deployment" \
    --resource-group ${RG_NAME} \
    --location ${LOCATION} \
    --template-file ${MAIN_BICEP_TEMPL_NAME}


