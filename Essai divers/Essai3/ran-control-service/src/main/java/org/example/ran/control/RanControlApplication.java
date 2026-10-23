package org.example.ran.control;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(
        scanBasePackages = {
                "org.example.ran.control",
                "org.onap.policy.ran.common"
        }
)
public class RanControlApplication {

    public static void main(String[] args) {
        SpringApplication.run(
                RanControlApplication.class,
                args
        );
    }
}
