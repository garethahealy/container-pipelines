package main

# https://docs.openshift.com/container-platform/4.2/release_notes/ocp-4-2-release-notes.html#ocp-4-2-deprecated-features

_deny = msg {
  contains(input.apiVersion, "servicecatalog.k8s.io/v1beta1")

  msg := sprintf("%s/%s: servicecatalog.k8s.io/v1beta1 is deprecated.", [input.kind, input.metadata.name])
}

_deny = msg {
  contains(input.apiVersion, "automationbroker.io/v1alpha1")

  msg := sprintf("%s/%s: automationbroker.io/v1alpha1 is deprecated.", [input.kind, input.metadata.name])
}

_deny = msg {
  contains(input.apiVersion, "osb.openshift.io/v1")

  msg := sprintf("%s/%s: osb.openshift.io/v1 is deprecated.", [input.kind, input.metadata.name])
}

_deny = msg {
  contains(input.apiVersion, "operatorsources.operators.coreos.com/v1")

  msg := sprintf("%s/%s: operatorsources.operators.coreos.com/v1 is deprecated.", [input.kind, input.metadata.name])
}

_deny = msg {
  contains(input.apiVersion, "catalogsourceconfigs.operators.coreos.com/v2")

  msg := sprintf("%s/%s: catalogsourceconfigs.operators.coreos.com/v2 is deprecated.", [input.kind, input.metadata.name])
}

_deny = msg {
  contains(input.apiVersion, "catalogsourceconfigs.operators.coreos.com/v1")

  msg := sprintf("%s/%s: catalogsourceconfigs.operators.coreos.com/v1 is deprecated.", [input.kind, input.metadata.name])
}