package org.example.ran.action;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(
        scanBasePackages = {
                "org.example.ran.action",
                "org.onap.policy.ran.common"
        }
)
public class RanActionApplication {

    public static void main(String[] args) {
        SpringApplication.run(
                RanActionApplication.class,
                args
        );
    }
}
