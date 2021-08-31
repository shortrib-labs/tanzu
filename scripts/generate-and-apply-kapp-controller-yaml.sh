#!/bin/bash -e

TKG_LAB_DIR=$(yq e .tkg-lab-directory $PARAMS_YAML)
CLUSTER_NAME=${1}

mkdir -p generated/$CLUSTER_NAME/kapp-controller/

cp ${TKG_LAB_DIR}/tkg-extensions/extensions/kapp-controller-config.yaml generated/$CLUSTER_NAME/kapp-controller/kapp-controller-config.yaml

export CA_BUNDLE="$(cat ${TKG_LAB_DIR}/keys/letsencrypt-ca.pem)"

# fancy `yq` expression sets the value if we're working with the config, 
# otherwise just passes the document through
yq e -i '(. | select(.metadata.name == "kapp-controller-config") ) | .data.caCerts = strenv(CA_BUNDLE)' generated/$CLUSTER_NAME/kapp-controller/kapp-controller-config.yaml

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
kubectl apply -f ${TKG_LAB_DIR}/tkg-extensions/extensions/kapp-controller.yaml -f generated/$CLUSTER_NAME/kapp-controller/kapp-controller-config.yaml 
