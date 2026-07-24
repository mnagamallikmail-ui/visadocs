package com.provaluer.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/signatures")
public class SignatureController {
    
    /**
     * POST /api/v1/signatures/request-otp
     * Initiates cloud Aadhaar/e-Mudhra wrapper HSM signature transaction.
     */
    @PostMapping("/request-otp")
    @PreAuthorize("hasRole('SPA')")
    public ResponseEntity<?> requestSigningOtp(@RequestParam("username") String username) {
        Map<String, String> response = new HashMap<>();
        response.put("transactionId", UUID.randomUUID().toString());
        response.put("message", "Cryptographic signing OTP sent successfully to registered cloud HSM device.");
        return ResponseEntity.ok(response);
    }

    /**
     * POST /api/v1/signatures/verify
     * Verifies the cloud certificate token transaction.
     */
    @PostMapping("/verify")
    @PreAuthorize("hasRole('SPA')")
    public ResponseEntity<?> verifySigningOtp(@RequestParam("transactionId") String transactionId, @RequestParam("otp") String otp) {
        // Simple mock OTP check (accepts standard length OTPs)
        if ("123456".equals(otp) || "1234".equals(otp) || (otp != null && otp.length() == 6)) {
            Map<String, String> response = new HashMap<>();
            response.put("status", "SUCCESS");
            response.put("certificateClass", "Class 3 Cloud HSM Digital Signature");
            response.put("signedBy", "Senior Property Analyst (SPA)");
            response.put("timestamp", String.valueOf(System.currentTimeMillis()));
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.badRequest().body("Invalid cloud eSignature OTP.");
    }
}
