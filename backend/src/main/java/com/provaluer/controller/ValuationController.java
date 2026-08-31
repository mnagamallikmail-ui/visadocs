package com.provaluer.controller;

import com.provaluer.dto.PlaceholderCatalogItemDTO;
import com.provaluer.dto.SaveValuationRequest;
import com.provaluer.dto.ValuationBundleResponse;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.ValuationEngineService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class ValuationController {

    @Autowired
    private ValuationEngineService valuationEngineService;

    @GetMapping("/orders/{orderId}/valuation")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'PA', 'SPA', 'CLIENT')")
    public ResponseEntity<ValuationBundleResponse> getValuation(@PathVariable Long orderId) {
        return ResponseEntity.ok(valuationEngineService.getValuationBundle(orderId));
    }

    @PostMapping("/orders/{orderId}/valuation")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'PA', 'SPA')")
    public ResponseEntity<ValuationBundleResponse> saveValuation(
            @PathVariable Long orderId,
            @RequestBody SaveValuationRequest request,
            @AuthenticationPrincipal UserDetailsImpl user) {
        return ResponseEntity.ok(valuationEngineService.saveValuation(orderId, request, user, "manual_edit"));
    }

    @PostMapping("/orders/{orderId}/valuation/finalize")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'SPA')")
    public ResponseEntity<ValuationBundleResponse> finalizeValuation(
            @PathVariable Long orderId,
            @RequestBody(required = false) Map<String, String> body,
            @AuthenticationPrincipal UserDetailsImpl user) {
        String notes = body != null ? body.get("versionNotes") : "Report finalized";
        return ResponseEntity.ok(valuationEngineService.finalizeValuation(orderId, user, notes, null, null));
    }

    @PostMapping("/admin/orders/{orderId}/valuation/lock")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<ValuationBundleResponse> lockValuation(
            @PathVariable Long orderId,
            @AuthenticationPrincipal UserDetailsImpl user) {
        return ResponseEntity.ok(valuationEngineService.lockValuation(orderId, user));
    }

    @PostMapping("/admin/orders/{orderId}/valuation/unlock")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    public ResponseEntity<ValuationBundleResponse> unlockValuation(
            @PathVariable Long orderId,
            @RequestBody(required = false) Map<String, String> body,
            @AuthenticationPrincipal UserDetailsImpl user) {
        String reason = body != null ? body.get("reason") : "Super Admin unlock";
        return ResponseEntity.ok(valuationEngineService.unlockValuation(orderId, user, reason));
    }

    @GetMapping("/templates/placeholder-catalog")
    public ResponseEntity<List<PlaceholderCatalogItemDTO>> getPlaceholderCatalog() {
        return ResponseEntity.ok(valuationEngineService.getPlaceholderCatalog());
    }
}
