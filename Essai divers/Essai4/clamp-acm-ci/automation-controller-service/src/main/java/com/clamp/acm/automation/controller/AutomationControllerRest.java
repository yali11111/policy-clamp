package com.clamp.acm.automation.controller;

import com.clamp.acm.automation.model.AutomationRequest;
import com.clamp.acm.automation.model.AutomationResponse;
import com.clamp.acm.automation.service.AutomationService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/automation")
public class AutomationControllerRest {

    private final AutomationService automationService;

    public AutomationControllerRest(
            AutomationService automationService) {
        this.automationService = automationService;
    }

    @PostMapping("/requests")
    public ResponseEntity<?> submit(
            @RequestBody AutomationRequest request) {
        try {
            AutomationResponse response =
                    automationService.submit(request);

            return ResponseEntity.accepted().body(response);
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(
                    Map.of("error", ex.getMessage()));
        }
    }

    @GetMapping("/requests")
    public List<AutomationResponse> findAll() {
        return automationService.findAll();
    }

    @GetMapping("/requests/{id}")
    public ResponseEntity<AutomationResponse> findById(
            @PathVariable String id) {

        AutomationResponse response =
                automationService.findById(id);

        if (response == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(response);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleUnexpectedError(
            Exception exception) {

        return ResponseEntity.status(
                        HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of(
                        "error",
                        "Internal server error"));
    }
}
