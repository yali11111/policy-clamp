package com.example.orchestrator;

import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/kpi")
public class KpiController {

    @PostMapping
    public void publish(@RequestBody Object metric) {

        System.out.println("Received KPI : " + metric);

    }

    @GetMapping
    public List<Object> list() {

        return List.of();

    }
}
