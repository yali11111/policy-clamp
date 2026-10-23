package org.example.ran.scaling;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(
        scanBasePackages = {
                "org.example.ran.scaling"
        }
)
public class ScalingParticipantApplication {

    public static void main(String[] args) {
        SpringApplication.run(
                ScalingParticipantApplication.class,
                args
        );
    }
}
