# retry
# ======
#
# Summary: Retry a command
#
# Usage: retry <retries> <command>
#
# Options:
#   <retries>       number of retries
#   <command>       command to retry
# Globals:
#   none
# Returns:
#   integer - exit code of command, if it fails.
retry() {
  local retries=$1
  shift

  local count=0
  until "$@"; do
    exit=$?
    wait=$((2 ** $count))
    count=$(($count + 1))

    if [ $count -lt $retries ]; then
      echo "Retry $count/$retries exited $exit, retrying in $wait seconds..."
      sleep $wait
    else
      echo "Retry $count/$retries exited $exit, no more retries left."
      return $exit
    fi
  done

  return 0
}