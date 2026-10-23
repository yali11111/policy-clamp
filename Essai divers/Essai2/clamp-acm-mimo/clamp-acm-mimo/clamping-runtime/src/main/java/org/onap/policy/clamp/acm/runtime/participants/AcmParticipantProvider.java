package org.onap.policy.clamp.acm.runtime.participants;

import java.util.List;

public class AcmParticipantProvider {

    public List<String> getParticipants() {

        return List.of(
                "monitoring-participant",
                "policy-participant",
                "automation-participant"
        );
    }
}
