package main

deny[msg] {
  input.apiVersion == "template.openshift.io/v1"
  input.kind == "Template"
  obj := input.objects[_]
  msg := _deny with input as obj
}

deny[msg] {
  input.apiVersion != "template.openshift.io/v1"
  input.kind != "Template"
  obj := input.objects[_]
  msg := _deny
}

warn[msg] {
  input.apiVersion == "template.openshift.io/v1"
  input.kind == "Template"
  obj := input.objects[_]
  msg := _warn with input as obj
}

warn[msg] {
  input.apiVersion != "template.openshift.io/v1"
  input.kind != "Template"
  obj := input.objects[_]
  msg := _warn
}