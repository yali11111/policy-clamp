package org.onap.policy.clamp.acm.runtime.state;

public class AcInstanceStateResolver {

    public String resolve(boolean deployed, boolean running) {

        if (!deployed) {
            return "NOT_DEPLOYED";
        }

        if (running) {
            return "RUNNING";
        }

        return "STOPPED";
    }
}
