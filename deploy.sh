# set -x
set -e

# Set Global Variables
MAIN_BICEP_TEMPL_NAME="main.bicep"
SUB_DEPLOYMENT_PREFIX="userManagedIdentityDemo"
LOCATION="westeurope"

RG_NAME="testRG01000001"

az bicep build --file ${MAIN_BICEP_TEMPL_NAME}

az deployment group create \
    --name ${SUB_DEPLOYMENT_PREFIX}"-Deployment" \
    --resource-group ${RG_NAME} \
    --template-file ${MAIN_BICEP_TEMPL_NAME}
    # --location ${LOCATION} \


# az group delete --name tstnks --yes --no-wait