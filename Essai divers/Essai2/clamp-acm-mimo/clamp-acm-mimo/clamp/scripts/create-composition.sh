#!/bin/bash

curl -X POST \
http://localhost:30258/onap/clamp/acm/v2/compositions \
-H "Content-Type: application/json" \
-d @../tosca/automation-composition.yaml
