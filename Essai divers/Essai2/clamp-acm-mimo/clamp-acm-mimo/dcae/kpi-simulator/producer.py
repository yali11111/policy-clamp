import json
from kafka import KafkaProducer

producer = KafkaProducer(
    bootstrap_servers="localhost:9092"
)

with open("sample-events.json") as f:
    events = json.load(f)

for event in events:
    producer.send(
        "kpi-topic",
        json.dumps(event).encode("utf-8")
    )

print("KPI events sent.")
