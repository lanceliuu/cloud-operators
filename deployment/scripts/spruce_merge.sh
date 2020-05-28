#!/usr/bin/env bash
set -eE -o pipefail

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

function merge() {

    if [[ -z "$1" ]]; then
      echo "Missing the property yaml filepath. Please provide the right path."
      exit 42
    fi 

    local properties_path=$1/properties.yml

    NAMESPACE=$(goml get -f ${properties_path} -p 'environment.namespace')

    if [ $NAMESPACE = "null" ]; then
       echo "failed to get target namespace"
       exit 42
    fi

    export NAMESPACE


    if ! [ -e $properties_path ];then
      echo "property file $properties_path does not exist."
      exit 43 
    fi
    
    echo "Spruce merging the files"


    spruce merge --prune environment ${properties_path} ${WORKSPACE}/006_deployment.yaml | tee deployment.yaml  
    
    spruce fan   --prune environment ${properties_path} ${WORKSPACE}/003_serviceaccount.yaml \
                                                        ${WORKSPACE}/004_manager_role.yaml \
                                                        ${WORKSPACE}/005_rbac_role_binding.yaml | tee sa-role-binding.yaml

}
