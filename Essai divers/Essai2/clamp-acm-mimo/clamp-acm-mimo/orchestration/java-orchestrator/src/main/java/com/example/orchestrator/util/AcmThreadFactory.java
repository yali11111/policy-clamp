package com.example.orchestrator.util;

import java.util.concurrent.ThreadFactory;

public class AcmThreadFactory implements ThreadFactory {

    @Override
    public Thread newThread(Runnable r) {

        Thread thread = new Thread(r);
        thread.setName("acm-worker-thread");

        return thread;
    }
}
