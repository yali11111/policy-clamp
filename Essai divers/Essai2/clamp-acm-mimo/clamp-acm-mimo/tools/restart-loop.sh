#!/bin/bash
kubectl rollout restart deployment/java-orchestrator
kubectl rollout restart deployment/beam-optimizer
kubectl rollout restart deployment/policy-engine
