# Contrats d'evenements CLAMP ACM CI

## Convention generale

- Format : JSON UTF-8.
- Horodatage : ISO-8601 UTC.
- Les identifiants d'evenements doivent etre uniques.
- Les consommateurs doivent tolerer les champs optionnels inconnus.
- Les producteurs ne doivent pas publier de secrets ou de donnees
  personnelles dans les attributs.
- Toute evolution incompatible necessite une strategie de migration.

## Topic acm.metrics

Cle Kafka recommandee : target.

Exemple :

{
  "eventId": "evt-001",
  "source": "monitoring-service",
  "target": "demo-cell-001",
  "timestamp": "2026-01-01T12:00:00Z",
  "metrics": {
    "cpuUtilizationPct": 65.0,
    "latencyMs": 20.0,
    "throughputMbps": 100.0
  },
  "attributes": {
    "origin": "scheduled-monitoring"
  }
}

Unites :

- cpuUtilizationPct : pourcentage, de 0 a 100.
- latencyMs : millisecondes.
- throughputMbps : megabits par seconde.

Les noms des metriques sont sensibles a la casse.

## Topic acm.policy-decisions

Cle Kafka recommandee : target.

Exemple :

{
  "decisionId": "decision-001",
  "sourceEventId": "evt-001",
  "policyId": "default-observation",
  "target": "demo-cell-001",
  "decision": "NO_ACTION",
  "reason": "Metrics are within configured thresholds",
  "timestamp": "2026-01-01T12:00:01Z",
  "evidence": {
    "cpuUtilizationPct": "65.0",
    "latencyMs": "20.0"
  }
}

Valeurs possibles de decision :

- NO_ACTION
- MANUAL_REVIEW
- SCALE_OUT_REQUESTED
- SCALE_IN_REQUESTED
- TRAFFIC_STEERING_REQUESTED

## Securite des decisions

Une decision Kafka est une demande ou une recommandation,
pas une preuve d'autorisation.

Avant toute action, le service d'automatisation doit :

1. Valider la decision et la cible.
2. Appliquer une liste d'actions autorisees.
3. Verifier les limites operationnelles.
4. Refuser les commandes inconnues ou mal formees.
5. Enregistrer le resultat et l'identifiant de correlation.

Les actions sur une infrastructure ONAP reelle doivent etre
protegees par une authentification, des autorisations et une
validation operationnelle explicites.
