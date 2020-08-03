#!/usr/bin/env bash

trap "exit 1" TERM
export TOP_PID=$$

REPO_SLUG="${2:-https://github.com/garethahealy/container-pipelines}"
BRANCH="${3:-testing-wip}"

# shellcheck disable=SC1090
source "$(pwd)/../_test/bash_helpers/load.bash"

applier() {
  echo "applier - $(pwd)"
  ansible-galaxy install -r requirements.yml -p galaxy
  ansible-playbook -i ./.applier/ galaxy/openshift-applier/playbooks/openshift-cluster-seed.yml \
    -e sb_source_repository_url=${REPO_SLUG} \
    -e sb_source_repository_ref=${BRANCH} \
    -e oc_token="$(oc whoami --show-token)"
}

test() {
  echo "test - $(pwd)"

  local build_namespace="basic-nginx-build"
  local build_pipline="basic-nginx-pipeline"
  local build_number=$(get_build_number_for "${build_pipline}" "${build_namespace}")
  if [[ -n $build_number ]]; then
    wait_for_build_to_complete "${build_pipline}-${build_number}" $build_namespace
  fi

  local build_name=$(oc start-build ${build_pipline} -n ${build_namespace} -o name | cut -d'/' -f2)

  wait_for_build_to_complete "${build_name}" "${build_namespace}"
  check_build_failed "${build_name}" "${build_namespace}"

  echo "Test complete"
}

cleanup() {
  echo "cleanup - $(pwd)"
  oc delete project/basic-nginx-build project/basic-nginx-dev project/basic-nginx-stage project/basic-nginx-prod  --ignore-not-found
}

# Process arguments
case $1 in
  applier)
    applier
    ;;
  test)
    test
    ;;
  cleanup)
    cleanup
    ;;
  *)
    echo "Not an option"
    exit 1
esac