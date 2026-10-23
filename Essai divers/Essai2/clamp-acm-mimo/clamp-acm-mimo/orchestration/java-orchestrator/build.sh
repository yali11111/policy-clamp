#!/bin/bash

echo "Compilation du projet Java..."

mvn clean package -DskipTests

echo "Build terminé."
echo "Image Docker :"

echo "docker build -t java-orchestrator ."
