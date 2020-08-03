# get_count_build_phases_for
# ===========================
#
# Summary: Gets a count of Builds which have a phase
#
# Usage: get_count_build_phases_for <build_name> <namespace> <phase>
#
# Options:
#   <build_name>       Build name
#   <namespace>        OCP namespace
#   <phase>            Build phase, i.e.: New
# Globals:
#   TOP_PID - expects to be set
# Returns:
#   none
get_count_build_phases_for() {
  local build_name=$1
  local namespace=$2
  local phase=$3

  result=$(retry 5 oc get build ${build_name} -o json -n ${namespace} | jq "select(.status.phase == \"${phase}\") | .metadata.name") || kill -s TERM $TOP_PID
  echo ${result} | wc -w
}

# get_build_phase_for
# ====================
#
# Summary: Gets the last Build number for a BuildConfig
#
# Usage: get_build_phase_for <build_config> <namespace>
#
# Options:
#   <build_name>       Build name
#   <namespace>        OCP namespace
# Globals:
#   TOP_PID - expects to be set
# Returns:
#   none
get_build_phase_for() {
  local build_name=$1
  local namespace=$2

  local result=$(retry 5 oc get builds ${build_name} -o jsonpath="{.status.phase}" -n ${namespace}) || kill -s TERM $TOP_PID
  echo ${result}
}

# get_build_number_for
# =====================
#
# Summary: Gets the last Build number for a BuildConfig
#
# Usage: get_build_number_for <build_config> <namespace>
#
# Options:
#   <build_config>     BuildConfig name
#   <namespace>        OCP namespace
# Globals:
#   TOP_PID - expects to be set
# Returns:
#   none
get_build_number_for() {
  local build_config=$1
  local namespace=$2

  local result=$(retry 5 oc get buildconfig ${build_config} -o jsonpath="{.status.lastVersion}" -n ${namespace}) || kill -s TERM $TOP_PID
  echo ${result}
}

# wait_for_build_to_complete
# ===========================
#
# Summary: Wait until the build has completed
#
# Usage: wait_for_build_to_complete <build_name> <namespace>
#
# Options:
#   <build_name>       Build name
#   <namespace>        OCP namespace
# Globals:
#   none
# Returns:
#   none
wait_for_build_to_complete() {
  local build_name=$1
  local namespace=$2

  echo ""
  echo "Waiting for build/${build_name} to start..."

  local new_builds=1
  local pending_builds=1
  while [[ ${new_builds} -ne 0 || ${pending_builds} -ne 0 ]]; do
    new_builds=$(get_count_build_phases_for "${build_name}" $namespace "New")
    pending_builds=$(get_count_build_phases_for "${build_name}" $namespace "Pending")

    echo "Build is new or pending..."
    sleep 5
  done

  echo ""
  echo "Waiting for build/${build_name} to complete..."

  local running_builds=1
  while [[ ${running_builds} -ne 0 ]]; do
    running_builds=$(get_count_build_phases_for "${build_name}" $namespace "Running")

    echo "Build is running..."
    sleep 5
  done
}

# check_build_failed
# ===================
#
# Summary: Checks if the Build is failed and downloads the logs
#
# Usage: check_build_failed <build_name> <namespace>
#
# Options:
#   <build_name>       Build name
#   <namespace>        OCP namespace
# Globals:
#   TOP_PID - expects to be set
# Returns:
#   none
check_build_failed(){
  local build_name=$1
  local namespace=$2

  if [[ $(get_count_build_phases_for "${build_name}" $namespace "Failed") -ne 0 ]]; then
    echo ""
    echo "Found failed builds, printing report and downloading logs."
    retry 5 oc get build ${build_name} -n ${namespace} -o custom-columns=NAME:.metadata.name,TYPE:.spec.strategy.type,FROM:.spec.source.type,STATUS:.status.phase,REASON:.status.reason
    echo ""

    local bc_name=$(retry 5 oc get build ${build_name} -o jsonpath="{.metadata.annotations.openshift\.io/build-config\.name}" -n ${namespace}) || kill -s TERM $TOP_PID
    local build_type=$(retry 5 oc get build ${build_name} -o jsonpath="{.spec.strategy.type}" -n ${namespace}) || kill -s TERM $TOP_PID
    if [[ $build_type == "JenkinsPipeline" ]]; then
      download_jenkins_logs ${bc_name} "Complete" $namespace "$(oc get route jenkins -n ${namespace} -o jsonpath='{.spec.host}')" "$(oc whoami --show-token)"
    else
      download_build_logs ${bc_name} "Complete" $namespace
    fi

    exit 1
  fi
}

# download_build_logs
# =====================
#
# Summary: Download logs for BuildConfigs which dont match the expected Build phase
#
# Usage: download_build_logs <build_configs> <expected_phase> <namespace>
#
# Options:
#   <build_configs>     Space separated list of JenkinsPipeline BuildConfigs
#   <expected_phase>    Expected Build phase, i.e.: Complete
#   <namespace>         OCP namespace
# Globals:
#   none
# Returns:
#   none
download_build_logs() {
  local build_configs=$1
  local expected_phase=$2
  local namespace=$3

  echo "Checking BuildConfigs which should have an expected phase of '${expected_phase}'..."

  for bc in ${build_configs}; do
    build_number=$(get_build_number_for ${bc} ${namespace})
    build="${bc}-${build_number}"

    phase=$(get_build_phase_for ${build} ${namespace})
    if [[ "${expected_phase}" != "${phase}" ]]; then
      echo "Downloading logs for ${build} as phase '${phase}' does not match expected '${expected_phase}'..."
      oc logs build/${build} -n ${namespace} > ${build}.log

      echo "## START LOGS: ${build}"
      cat ${build}.log
      echo "## END LOGS: ${build}"
      echo ""
    fi
  done
}