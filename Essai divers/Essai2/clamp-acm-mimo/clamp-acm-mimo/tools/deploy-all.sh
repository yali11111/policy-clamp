#!/bin/bash

echo "Deploy Kafka..."
docker compose -f kafka/docker-compose-kafka.yaml up -d

echo "Deploy ML..."
kubectl apply -f k8s/helm/python.yaml

echo "Deploy Java..."
kubectl apply -f k8s/helm/java.yaml

echo "Deploy RIC..."
kubectl apply -f k8s/helm/ric.yaml
