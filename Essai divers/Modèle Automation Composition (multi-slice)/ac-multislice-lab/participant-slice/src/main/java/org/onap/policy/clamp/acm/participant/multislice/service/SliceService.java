package org.onap.policy.clamp.acm.participant.multislice.service;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.onap.policy.clamp.acm.participant.multislice.models.SliceConfiguration;
import org.onap.policy.clamp.acm.participant.multislice.models.SlicePriority;
import org.onap.policy.clamp.acm.participant.multislice.models.SliceStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Orchestration métier des slices du laboratoire.
 *
 * Cette classe ne remplace pas le gestionnaire de cycle de vie ONAP ACM.
 * Elle expose les opérations métier qui seront appelées par le handler ACM.
 */
@Service
public class SliceService {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(SliceService.class);

    private final QuotaManager quotaManager;
    private final KubernetesClient kubernetesClient;
    private final Scaler scaler;

    private final Map<String, SliceStatus> statuses =
            new ConcurrentHashMap<>();

    private final Map<String, SliceConfiguration> configurations =
            new ConcurrentHashMap<>();

    public SliceService(
            QuotaManager quotaManager,
            KubernetesClient kubernetesClient,
            Scaler scaler) {
        this.quotaManager = quotaManager;
        this.kubernetesClient = kubernetesClient;
        this.scaler = scaler;
    }

    /**
     * Valide et enregistre une configuration.
     *
     * Cette opération n'effectue aucun déploiement Kubernetes.
     */
    public SliceStatus register(SliceConfiguration configuration) {
        quotaManager.validate(configuration);

        String sliceId = configuration.getSliceId();

        SliceConfiguration existing =
                configurations.putIfAbsent(sliceId, configuration);

        if (existing != null) {
            throw new IllegalArgumentException(
                    "Une slice portant cet identifiant existe déjà : "
                            + sliceId);
        }

        statuses.put(sliceId, SliceStatus.CREATED);

        LOGGER.info(
                "Slice enregistrée : id={}, type={}, priorité={}",
                sliceId,
                configuration.getSliceType().externalName(),
                SlicePriority.forType(configuration.getSliceType()).value());

        return SliceStatus.CREATED;
    }

    /**
     * Passe une slice enregistrée à l'état RUNNING.
     *
     * Si Kubernetes est désactivé, aucune opération externe n'est exécutée.
     * Dans ce mode, RUNNING représente uniquement un état simulé du
     * laboratoire et non la disponibilité d'un workload réel.
     */
    public SliceStatus deploy(String sliceId) {
        SliceConfiguration configuration = requireConfiguration(sliceId);

        setStatus(sliceId, SliceStatus.VALIDATING);

        try {
            quotaManager.validate(configuration);

            if (kubernetesClient.isEnabled()) {
                setStatus(sliceId, SliceStatus.DEPLOYING);

                scaler.scale(
                        configuration.getNamespace(),
                        configuration.getDeploymentName(),
                        configuration.getReplicas());
            }

            setStatus(sliceId, SliceStatus.RUNNING);

            LOGGER.info(
                    "Traitement de déploiement terminé : id={}, "
                            + "kubernetesEnabled={}",
                    sliceId,
                    kubernetesClient.isEnabled());

            return SliceStatus.RUNNING;
        } catch (RuntimeException exception) {
            setStatus(sliceId, SliceStatus.FAILED);
            LOGGER.error("Échec du traitement de la slice {}", sliceId,
                    exception);
            throw exception;
        }
    }

    /**
     * Arrête logiquement une slice.
     *
     * En mode Kubernetes, le nombre de replicas du Deployment existant
     * est ramené à zéro. Cela ne supprime pas le Deployment.
     */
    public SliceStatus undeploy(String sliceId) {
        SliceConfiguration configuration = requireConfiguration(sliceId);

        setStatus(sliceId, SliceStatus.STOPPING);

        try {
            if (kubernetesClient.isEnabled()) {
                scaler.scale(
                        configuration.getNamespace(),
                        configuration.getDeploymentName(),
                        0);
            }

            setStatus(sliceId, SliceStatus.STOPPED);

            LOGGER.info("Slice arrêtée : {}", sliceId);
            return SliceStatus.STOPPED;
        } catch (RuntimeException exception) {
            setStatus(sliceId, SliceStatus.FAILED);
            LOGGER.error("Échec de l'arrêt de la slice {}", sliceId,
                    exception);
            throw exception;
        }
    }

    public SliceStatus getStatus(String sliceId) {
        SliceStatus status = statuses.get(sliceId);

        if (status == null) {
            throw new IllegalArgumentException(
                    "Slice inconnue : " + sliceId);
        }

        return status;
    }

    public SliceConfiguration getConfiguration(String sliceId) {
        return requireConfiguration(sliceId);
    }

    public Map<String, SliceStatus> getAllStatuses() {
        return Map.copyOf(statuses);
    }

    /**
     * Supprime l'enregistrement local.
     *
     * Cette opération ne supprime aucune ressource Kubernetes.
     */
    public void forget(String sliceId) {
        SliceStatus status = statuses.get(sliceId);

        if (status == SliceStatus.RUNNING
                || status == SliceStatus.DEPLOYING
                || status == SliceStatus.STOPPING) {
            throw new IllegalStateException(
                    "Arrêter la slice avant de supprimer son enregistrement.");
        }

        configurations.remove(sliceId);
        statuses.remove(sliceId);
    }

    private SliceConfiguration requireConfiguration(String sliceId) {
        if (sliceId == null || sliceId.isBlank()) {
            throw new IllegalArgumentException(
                    "L'identifiant de slice est obligatoire.");
        }

        SliceConfiguration configuration = configurations.get(sliceId);

        if (configuration == null) {
            throw new IllegalArgumentException(
                    "Slice inconnue : " + sliceId);
        }

        return configuration;
    }

    private void setStatus(String sliceId, SliceStatus status) {
        statuses.put(sliceId, status);
    }
}
