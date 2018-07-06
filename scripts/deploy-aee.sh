#!/bin/bash

set -x

usage() {
  cat <<EOF
Usage: $0 [PARAMs]
-u                     : Display usage
-r [RELEASE]           : HELM release name (required)
-n [NAMESPACE]         : Kubernetes namespace (required)
-f [VALUES FILE]       : HELM global values file
-v [ADDITIONAL PARAMS] : HELM additional parameters (better put them in the global values file)
-a [APP]               : Specify a specific ONAP component (default: all)
-p [PULL-POLICY]       : Image pull policy
-l [LOCATION]          : Location of oom project
-m                     : Skip making components
EOF
}

repository='nexus3.onap.org:10001'

pullPolicy=Always

additionalParams=" --set global.repository=${repository}"

globalValuesFile=""

singleComponent="false"

make="true"

scriptDir=$(dirname "$0")
location="$scriptDir/.."

namespace=""
releaseName=""

while getopts ":r:n:p:u:a:l:v:f:m" PARAM; do
  case $PARAM in
    u)
      usage
      exit 1
      ;;
    r)
      releaseName=${OPTARG}
      if [[ -z $releaseName ]]; then
        usage
        exit 1
      fi
      ;;
    n)
      namespace=${OPTARG}
      if [[ -z $namespace ]]; then
        usage
        exit 1
      fi
      ;;
    p)
      PP=${OPTARG}
      if [[ -z $PP ]]; then
        usage
        exit 1
      fi
      pullPolicy=$PP
      additionalParams="$additionalParams,global.pullPolicy=$pullPolicy"
      ;;
    v)
      ADDITINAL_VALUES=${OPTARG}
      additionalParams="$additionalParams,$ADDITINAL_VALUES"
      ;;
    f)
      HELM_VALUES_FILEPATH=${OPTARG}
      globalValuesFile=" -f $HELM_VALUES_FILEPATH"
      ;;
    m)
      make="false"
      ;;
    l)
      location=${OPTARG}
      ;;
    a)
      APP=${OPTARG}
      if [[ -z $APP ]]; then
        usage
        exit 1
      fi
      singleComponent="true"
      COMPONENTS=($APP)
      ;;
    ?)
      usage
      exit
      ;;
  esac
done

if [[ -z $namespace || -z $releaseName ]]; then
  usage
  exit 1
fi


# Check whether local helm repo is running and if not, make it run.
runningHelm=$(ps ax | grep "helm serve"| grep -v grep)
if [ -z "$runningHelm" ]; then
  pushd $HOME
  nohup helm serve &
  helm repo add local 'http://127.0.0.1:8879'
  popd
fi

# Make all components charts
if [ "true" == "$make" ]; then
  pushd $location/kubernetes
  make clean
  make all
  popd
fi

if [ "false" == $singleComponent ]; then
  # Create the list of components
  components=$(cat $location/kubernetes/onap/requirements.yaml | grep name: | grep -v common | awk '{print $3}')
  COMPONENTS=($components)
#  COMPONENTS+=(aai-aee)

  # Deploy onap with no other components
  helm upgrade -i $releaseName --namespace $namespace local/onap -f $location/kubernetes/onap/resources/environments/disable-allcharts.yaml ${additionalParams}
fi

# Deploy the components.
for i in ${COMPONENTS[@]}; do
  echo "Deploying $i ..."
  helm upgrade -i $releaseName-$i --namespace $namespace local/$i ${additionalParams}${globalValuesFile}
  echo "Deploying $i Done"
done

