package com.provaluer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class ProValuerApplication {
    public static void main(String[] args) {
        SpringApplication.run(ProValuerApplication.class, args);
    }
}
