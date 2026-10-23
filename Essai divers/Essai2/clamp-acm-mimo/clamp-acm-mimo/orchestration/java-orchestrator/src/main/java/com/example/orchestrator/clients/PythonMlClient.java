package com.example.orchestrator.clients;

import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class PythonMlClient {

    private final RestTemplate restTemplate = new RestTemplate();

    public String predict(Object metric) {

        String url = "http://beam-optimizer:8000/predict";

        return restTemplate.postForObject(
                url,
                metric,
                String.class
        );
    }
}
