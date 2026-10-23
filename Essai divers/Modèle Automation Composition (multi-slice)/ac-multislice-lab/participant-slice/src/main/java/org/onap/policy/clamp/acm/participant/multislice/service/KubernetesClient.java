package org.onap.policy.clamp.acm.participant.multislice.service;

import io.fabric8.kubernetes.api.model.ObjectMeta;
import io.fabric8.kubernetes.api.model.apps.Deployment;
import io.fabric8.kubernetes.client.KubernetesClientException;
import io.fabric8.kubernetes.client.KubernetesClientBuilder;
import java.util.Objects;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Façade Kubernetes.
 *
 * L'intégration est désactivée par défaut. Lorsque celle-ci est
 * désactivée, aucune connexion au cluster n'est créée.
 */
@Component
public class KubernetesClient implements AutoCloseable {

    private final boolean enabled;
    private final io.fabric8.kubernetes.client.KubernetesClient client;

    public KubernetesClient(
            @Value("${slice.kubernetes.enabled:false}") boolean enabled) {

        this.enabled = enabled;
        this.client = enabled
                ? new KubernetesClientBuilder().build()
                : null;
    }

    public boolean isEnabled() {
        return enabled;
    }

    /**
     * Retourne le Deployment existant.
     *
     * Aucun Deployment n'est créé implicitement.
     */
    public Deployment requireDeployment(
            String namespace,
            String deploymentName) {

        requireEnabled();
        validateName(namespace, "namespace");
        validateName(deploymentName, "deploymentName");

        Deployment deployment = client.apps()
                .deployments()
                .inNamespace(namespace)
                .withName(deploymentName)
                .get();

        if (deployment == null) {
            throw new IllegalArgumentException(
                    "Deployment introuvable : "
                            + namespace + "/" + deploymentName);
        }

        return deployment;
    }

    /**
     * Met à jour les replicas d'un Deployment existant.
     */
    public void scale(
            String namespace,
            String deploymentName,
            int replicas) {

        requireEnabled();

        if (replicas < 0) {
            throw new IllegalArgumentException(
                    "Le nombre de replicas ne peut pas être négatif.");
        }

        Deployment deployment =
                requireDeployment(namespace, deploymentName);

        client.apps()
                .deployments()
                .inNamespace(namespace)
                .withName(deploymentName)
                .scale(replicas);

        Objects.requireNonNull(deployment.getMetadata());
    }

    /**
     * Retourne le nombre de replicas désiré.
     */
    public int getDesiredReplicas(
            String namespace,
            String deploymentName) {

        Deployment deployment =
                requireDeployment(namespace, deploymentName);

        if (deployment.getSpec() == null
                || deployment.getSpec().getReplicas() == null) {
            return 0;
        }

        return deployment.getSpec().getReplicas();
    }

    private void requireEnabled() {
        if (!enabled || client == null) {
            throw new IllegalStateException(
                    "Kubernetes est désactivé. "
                            + "Définir slice.kubernetes.enabled=true "
                            + "pour activer cette intégration.");
        }
    }

    private void validateName(String value, String property) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(
                    property + " est obligatoire.");
        }
    }

    @Override
    public void close() {
        if (client != null) {
            client.close();
        }
    }
}
