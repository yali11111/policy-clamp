#!/bin/bash

curl -X POST \
http://localhost:30258/onap/clamp/acm/v2/compositions/{id}/prime
