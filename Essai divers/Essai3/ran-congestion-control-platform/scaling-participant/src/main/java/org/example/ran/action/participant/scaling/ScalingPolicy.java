package org.example.ran.action.participant.scaling;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class ScalingPolicy {

    private final int minimumReplicas;
    private final int maximumReplicas;
    private final int maximumStep;

    public ScalingPolicy(
            @Value("${ran.scaling.minimum-replicas:1}")
            int minimumReplicas,
            @Value("${ran.scaling.maximum-replicas:10}")
            int maximumReplicas,
            @Value("${ran.scaling.maximum-step:2}")
            int maximumStep) {

        if (minimumReplicas < 0) {
            throw new IllegalArgumentException(
                    "minimumReplicas must be >= 0");
        }

        if (maximumReplicas < 1
                || maximumReplicas < minimumReplicas) {
            throw new IllegalArgumentException(
                    "Invalid replica limits");
        }

        if (maximumStep < 1) {
            throw new IllegalArgumentException(
                    "maximumStep must be >= 1");
        }

        this.minimumReplicas = minimumReplicas;
        this.maximumReplicas = maximumReplicas;
        this.maximumStep = maximumStep;
    }

    public int minimumReplicas() {
        return minimumReplicas;
    }

    public int maximumReplicas() {
        return maximumReplicas;
    }

    public int maximumStep() {
        return maximumStep;
    }

    public boolean isValidTarget(int replicas) {
        return replicas >= minimumReplicas
                && replicas <= maximumReplicas;
    }

    public boolean isValidStep(int step) {
        return step >= 1 && step <= maximumStep;
    }
}
