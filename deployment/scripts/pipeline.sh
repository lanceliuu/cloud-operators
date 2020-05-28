#!/usr/bin/env bash
set -eE -o pipefail

WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

source $WORKSPACE/scripts/spruce_merge.sh

function printerr() {
    local str=$1
    RED='\033[0;31m'
    NC='\033[0m'
    printf "$RED[ERROR] $str$NC\n"
}

function usage() {
   printf "Usage: \n  $0 [folder-of-properties.yml]\n"
}


function deploy_ibm_cloud_operator(){
    # apply and patch CRDs
    kubectl apply -f ${WORKSPACE}/../config/crds/
    kubectl patch CustomResourceDefinition bindings.ibmcloud.ibm.com -p '{"metadata":{"annotations":{"servicebindingoperator.redhat.io/status.secretName":"binding:env:object:secret","servicebindingoperator.redhat.io/spec.serviceName": "binding:env:attribute"}}}' 

    # apply serviceaccount role and rolebinidng
    kubectl apply -f sa-role-binding.yaml

    # apply deployment
    kubectl apply -f deployment.yaml

    # rollout deployment 
    # FIXME: currently we have hard coded namespace ibm-service-binding. Change it when we have it defined in properties.yml
    if ! kubectl -n ibm-service-binding rollout status deploy ibmcloud-operator --timeout=10m; then
        kubectl -n ibm-service-binding describe deploy ibmcloud-operator
        if [ ! -z $( kubectl -n ibm-service-binding get pods -lapp=ibmcloud-operator -ojson |jq '.items|length') ]; then
            kubectl -n ibm-service-binding logs -lapp=ibmcloud-operator --tail 50
        fi
        exit 1
    fi
}

if [ $# -lt 1 ]; then
  printerr "Invalid argument"
  usage
  exit 1
fi

##################################################################
# Start of main function
##################################################################
merge "$@"
deploy_ibm_cloud_operator
