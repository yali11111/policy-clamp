package org.onap.policy.clamp.acm.participant.multislice.service;

import org.springframework.stereotype.Service;

/**
 * Service de mise à l'échelle d'un Deployment.
 */
@Service
public class Scaler {

    private final KubernetesClient kubernetesClient;
    private final QuotaManager quotaManager;

    public Scaler(
            KubernetesClient kubernetesClient,
            QuotaManager quotaManager) {
        this.kubernetesClient = kubernetesClient;
        this.quotaManager = quotaManager;
    }

    /**
     * Applique le nombre de replicas demandé.
     *
     * Les quotas doivent être validés par l'appelant avant le scaling.
     */
    public void scale(
            String namespace,
            String deploymentName,
            int replicas) {

        if (replicas < 0
                || replicas > quotaManager.getMaxReplicas()) {
            throw new IllegalArgumentException(
                    "Nombre de replicas hors limites : " + replicas);
        }

        if (!kubernetesClient.isEnabled()) {
            throw new IllegalStateException(
                    "Scaling impossible : Kubernetes est désactivé.");
        }

        kubernetesClient.scale(
                namespace,
                deploymentName,
                replicas);
    }
}
