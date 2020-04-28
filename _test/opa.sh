#!/usr/bin/env bash

template_dirs="
  basic-dotnet-core/.openshift
  basic-nginx/.openshift
  basic-spring-boot-tekton/.openshift
  basic-spring-boot/.openshift
  basic-tomcat/.openshift
  blue-green-spring/.openshift
  cucumber-selenium-grid/applier/projects
  cucumber-selenium-grid/applier/templates
  jenkins-s2i
  multi-cluster-multi-branch-jee/.openshift
  multi-cluster-spring-boot/image-mirror-example/.applier/projects
  multi-cluster-spring-boot/image-mirror-example/.applier/templates
  multi-cluster-spring-boot/skopeo-example/.applier/projects
  multi-cluster-spring-boot/skopeo-example/.applier/templates
  secure-spring-boot/.openshift-applier/templates
"
for dir in $template_dirs; do
  echo "testing: $dir"
  conftest test $dir
done