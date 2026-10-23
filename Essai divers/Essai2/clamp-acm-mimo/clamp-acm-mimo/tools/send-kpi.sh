#!/bin/bash
echo "Sending KPI events..."
curl -X POST http://localhost:8085/api/kpi \
  -H "Content-Type: application/json" \
  -d @kpi.json
