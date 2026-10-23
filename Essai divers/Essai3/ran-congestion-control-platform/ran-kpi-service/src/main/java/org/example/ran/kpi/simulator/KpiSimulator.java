package org.example.ran.kpi.simulator;

import org.example.ran.kpi.producer.RanKpiProducer;
import org.onap.policy.ran.common.RanKpi;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.concurrent.ThreadLocalRandom;

/**
 * Simulate des KPI de plusieurs cellules.
 *
 * Le profil de congestion permet de produire des scénarios
 * normaux, chargés ou critiques.
 */
@Component
@ConditionalOnProperty(
        name = "ran.simulator.enabled",
        havingValue = "true",
        matchIfMissing = true
)
public class KpiSimulator {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(KpiSimulator.class);

    private final RanKpiProducer producer;
    private final String nodeId;
    private final int numberOfCells;
    private final String profile;

    public KpiSimulator(
            RanKpiProducer producer,
            @Value("${ran.simulator.node-id:gnb-001}") String nodeId,
            @Value("${ran.simulator.cells:3}") int numberOfCells,
            @Value("${ran.simulator.profile:random}") String profile) {

        if (numberOfCells < 1 || numberOfCells > 1000) {
            throw new IllegalArgumentException(
                    "ran.simulator.cells must be between 1 and 1000");
        }

        this.producer = producer;
        this.nodeId = nodeId;
        this.numberOfCells = numberOfCells;
        this.profile = profile.toLowerCase();
    }

    @Scheduled(
            fixedDelayString = "${ran.simulator.interval-ms:2000}"
    )
    public void generateKpis() {
        for (int i = 1; i <= numberOfCells; i++) {
            try {
                RanKpi kpi = generateForCell(i);

                producer.publish(kpi).whenComplete((ignored, error) -> {
                    if (error != null) {
                        LOGGER.error(
                                "KPI publication failed for cell {}",
                                kpi.cellId(),
                                error
                        );
                    }
                });
            } catch (RuntimeException exception) {
                LOGGER.error(
                        "Could not generate KPI for cell index {}",
                        i,
                        exception
                );
            }
        }
    }

    private RanKpi generateForCell(int index) {
        ThreadLocalRandom random = ThreadLocalRandom.current();

        double prb;
        double latency;
        double loss;

        switch (profile) {
            case "normal" -> {
                prb = random.nextDouble(20.0, 65.0);
                latency = random.nextDouble(5.0, 25.0);
                loss = random.nextDouble(0.0, 0.5);
            }
            case "congested" -> {
                prb = random.nextDouble(82.0, 96.0);
                latency = random.nextDouble(40.0, 100.0);
                loss = random.nextDouble(1.0, 5.0);
            }
            case "critical" -> {
                prb = random.nextDouble(96.0, 100.0);
                latency = random.nextDouble(100.0, 250.0);
                loss = random.nextDouble(5.0, 15.0);
            }
            default -> {
                prb = random.nextDouble(10.0, 100.0);
                latency = random.nextDouble(5.0, 150.0);
                loss = random.nextDouble(0.0, 8.0);
            }
        }

        double downlink = Math.max(
                0.0,
                (100.0 - prb) * random.nextDouble(1.0, 3.0)
        );

        double uplink = Math.max(
                0.0,
                (100.0 - prb) * random.nextDouble(0.3, 1.2)
        );

        int users = random.nextInt(10, 501);

        return new RanKpi(
                null,
                null,
                "ran-kpi-service",
                "00101",
                nodeId,
                "cell-" + index,
                "default",
                prb,
                downlink,
                uplink,
                latency,
                loss,
                users,
                random.nextDouble(-15.0, 30.0),
                true
        );
    }
}
