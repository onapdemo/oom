#!/bin/bash

#set -x

if [ "$#" -ne 1 ]; then
  echo "$0 namespace"
  exit 1
fi

namespace=$1

components=$(helm list -aq --namespace $namespace)
COMPONENTS=($components)

kubectl delete ns $namespace
kubectl delete storageclass $(kubectl get storageclass -o=jsonpath='{.items[*].metadata.name}')
kubectl delete pv $(kubectl get pv -o=jsonpath='{.items[*].metadata.name}')

kubectl delete clusterrolebinding $namespace-binding
rm -fr /dockerdata-nfs/*


for i in ${COMPONENTS[@]}; do
  echo "Deleting $i ..."
  helm del --purge  $i
  echo "Deleting $i Done"
done
