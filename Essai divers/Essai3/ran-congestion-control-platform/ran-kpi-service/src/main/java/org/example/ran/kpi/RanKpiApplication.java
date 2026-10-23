package org.example.ran.kpi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication(scanBasePackages = {
        "org.example.ran.kpi",
        "org.onap.policy.ran.common"
})
@EnableScheduling
public class RanKpiApplication {

    public static void main(String[] args) {
        SpringApplication.run(RanKpiApplication.class, args);
    }
}
