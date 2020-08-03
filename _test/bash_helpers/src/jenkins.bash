# download_jenkins_logs
# =======================
#
# Summary: Download Jenkins logs for JenkinsPipeline BuildConfigs which dont match the expected Build phase
#
# Usage: download_jenkins_logs <build_configs> <expected_phase> <namespace> <jenkins_url> <oc_token>
#
# Options:
#   <build_configs>     Space separated list of JenkinsPipeline BuildConfigs
#   <expected_phase>    Expected Build phase, i.e.: Complete
#   <namespace>         OCP namespace
#   <jenkins_url>       Jenkins URL to download logs from, i.e: oc get route jenkins -n ${namespace} -o jsonpath='{.spec.host}'
#   <oc_token>          Jenkins user OCP token, i.e.: oc whoami --show-token
# Globals:
#   TOP_PID - expects to be set
# Returns:
#   none
download_jenkins_logs() {
  local build_configs=$1
  local expected_phase=$2
  local namespace=$3
  local jenkins_url=$4
  local oc_token=$5

  echo "Checking JenkinsPipeline BuildConfigs which should have an expected phase of '${expected_phase}'..."

  for pipeline in ${build_configs}; do
    local build_number=$(get_build_number_for ${pipeline} ${namespace})
    local build="${pipeline}-${build_number}"

    local phase=$(get_build_phase_for ${build} ${namespace})
    if [[ "${expected_phase}" != "${phase}" ]]; then
      echo "Downloading Jenkins logs for ${build} as phase '${phase}' does not match expected '${expected_phase}'..."
      curl -k -sS -H "Authorization: Bearer ${oc_token}" "https://${jenkins_url}/blue/rest/organizations/jenkins/pipelines/${namespace}/pipelines/${namespace}-${pipeline}/runs/${build_number}/log/?start=0&download=true" -o "${build}.log" || kill -s TERM $TOP_PID

      echo ""
      echo "## START LOGS: ${build}"
      cat "${build}.log"
      echo "## END LOGS: ${build}"
      echo ""
    fi
  done
}