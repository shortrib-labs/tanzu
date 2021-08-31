#!/bin/bash -e

TKG_LAB_DIR=$(yq e .tkg-lab-directory $PARAMS_YAML)
CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
export OPENLDAP_FQDN=$(yq e .openldap.fqdn $PARAMS_YAML)
export OPENLDAP_URL=https://$OPENLDAP_FQDN
OPENLDAP_NAMESPACE=$(yq e .openldap.namespace $PARAMS_YAML)
export ADMIN_PASSWORD=$(yq e .openldap.admin-password $PARAMS_YAML)
export CONFIG_PASSWORD=$(yq e .openldap.config-password $PARAMS_YAML)
export LDAP_ORGANIZATION=$(yq e .openldap.organization $PARAMS_YAML)
export LDAP_DOMAIN=$(yq e .openldap.domain $PARAMS_YAML) 

mkdir -p generated/$CLUSTER_NAME/openldap/

cp openldap/openldap-values-template.yaml generated/$CLUSTER_NAME/openldap/openldap-values.yaml

yq e -i ".adminPassword = env(ADMIN_PASSWORD)" generated/$CLUSTER_NAME/openldap/openldap-values.yaml 
yq e -i ".configPassword = env(CONFIG_PASSWORD)" generated/$CLUSTER_NAME/openldap/openldap-values.yaml 
yq e -i ".env.LDAP_ORGANIZATION = env(LDAP_ORGANIZATION)" generated/$CLUSTER_NAME/openldap/openldap-values.yaml 
yq e -i ".env.LDAP_DOMAIN = env(LDAP_DOMAIN)" generated/$CLUSTER_NAME/openldap/openldap-values.yaml 

# Geek Cookbook seems a pretty reputable place to grab this from
# helm repo add geek-cookbook https://geek-cookbook.github.io/charts/

# NOTE: Through testing setting the OIDC CA in values.yaml did not work as expected, 
#       so we are mounting the let's encrypt CA onto the worker pods via ytt overlay
helm template openldap geek-cookbook/openldap -f generated/$CLUSTER_NAME/openldap/openldap-values.yaml --namespace $OPENLDAP_NAMESPACE | 
  ytt -f - -f ${TKG_LAB_DIR}/overlay/trust-certificate --ignore-unknown-comments \
    --data-value certificate="$(cat ${TKG_LAB_DIR}/keys/trusted-certificates/*.pem)" \
    --data-value ca=letsencrypt > generated/$CLUSTER_NAME/openldap/helm-manifest.yaml

kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME

kubectl create namespace $(yq e .openldap.namespace ${PARAMS_YAML}) --dry-run=client -o yaml | kubectl apply -f -
kapp deploy -a openldap  \
  -f generated/$CLUSTER_NAME/openldap/helm-manifest.yaml \
  -n $OPENLDAP_NAMESPACE \
  -y
