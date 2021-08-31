#!/bin/bash -e

TKG_LAB_DIR=$(yq e .tkg-lab-directory $PARAMS_YAML)
CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
export KEYCLOAK_FQDN=$(yq e .keycloak.fqdn $PARAMS_YAML)
export KEYCLOAK_URL=https://$KEYCLOAK_FQDN
KEYCLOAK_NAMESPACE=$(yq e .keycloak.namespace $PARAMS_YAML)
export ADMIN_USER=arceus
export ADMIN_PASSWORD=$(yq e .keycloak.admin-password $PARAMS_YAML)

mkdir -p generated/$CLUSTER_NAME/keycloak/

cp keycloak/keycloak-values-contour-template.yaml generated/$CLUSTER_NAME/keycloak/keycloak-values-contour.yaml

yq e -i ".auth.adminUser = env(ADMIN_USER)" generated/$CLUSTER_NAME/keycloak/keycloak-values-contour.yaml 
yq e -i ".auth.adminPassword = env(ADMIN_PASSWORD)" generated/$CLUSTER_NAME/keycloak/keycloak-values-contour.yaml 
yq e -i ".ingress.hostname = env(KEYCLOAK_FQDN)" generated/$CLUSTER_NAME/keycloak/keycloak-values-contour.yaml 

# NOTE: Through testing setting the OIDC CA in values.yaml did not work as expected, 
#       so we are mounting the let's encrypt CA onto the worker pods via ytt overlay
helm template keycloak bitnami/keycloak -f generated/$CLUSTER_NAME/keycloak/keycloak-values-contour.yaml --namespace $KEYCLOAK_NAMESPACE | 
  ytt -f - -f ${TKG_LAB_DIR}/overlay/trust-certificate --ignore-unknown-comments \
    --data-value certificate="$(cat ${TKG_LAB_DIR}/keys/letsencrypt-ca.pem)" \
    --data-value ca=letsencrypt > generated/$CLUSTER_NAME/keycloak/helm-manifest.yaml

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

kubectl create namespace $(yq e .keycloak.namespace ${PARAMS_YAML}) --dry-run=client -o yaml | kubectl apply -f -
kapp deploy -a keycloak  \
  -f generated/$CLUSTER_NAME/keycloak/helm-manifest.yaml \
  -n $KEYCLOAK_NAMESPACE \
  -y
 
