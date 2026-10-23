package org.example.ran.networkconfig;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(
        scanBasePackages = {
                "org.example.ran.networkconfig"
        }
)
public class NetworkConfigParticipantApplication {

    public static void main(String[] args) {
        SpringApplication.run(
                NetworkConfigParticipantApplication.class,
                args
        );
    }
}
