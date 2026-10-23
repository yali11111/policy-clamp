package org.example.ran.predictor;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(
        scanBasePackages = {
                "org.example.ran.predictor",
                "org.onap.policy.ran.common"
        }
)
public class RanPredictorApplication {

    public static void main(String[] args) {
        SpringApplication.run(
                RanPredictorApplication.class,
                args
        );
    }
}
