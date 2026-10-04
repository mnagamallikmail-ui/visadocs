package com.provaluer.controller;

import com.provaluer.dto.*;
import com.provaluer.model.OrderInvoice;
import com.provaluer.repository.OrderInvoiceRepository;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.DeliveryService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

@RestController
@CrossOrigin(origins = "*", maxAge = 3600)
public class DeliveryController {

    @Autowired
    private DeliveryService deliveryService;

    @Autowired
    private OrderInvoiceRepository orderInvoiceRepository;

    /**
     * 1. POST /delivery/orders/{id}/evaluate-gate
     * Commercial Clearance & Delivery Gate: SNAPSHOT_CREATED → DELIVERY_READY
     */
    @PostMapping({"/delivery/orders/{id}/evaluate-gate", "/api/v1/delivery/orders/{id}/evaluate-gate"})
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> evaluateGate(
            @PathVariable Long id,
            @RequestBody(required = false) EvaluateGateRequest request,
            @AuthenticationPrincipal UserDetailsImpl principal,
            HttpServletRequest httpRequest) {
        String ip = extractClientIp(httpRequest);
        Map<String, Object> result = deliveryService.evaluateGate(id, request, principal, ip);
        return ResponseEntity.ok(result);
    }

    /**
     * 2. POST /delivery/orders/{id}/release
     * Delivery Release: DELIVERY_READY → FINAL_DELIVERY
     */
    @PostMapping({"/delivery/orders/{id}/release", "/api/v1/delivery/orders/{id}/release"})
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> releaseOrder(
            @PathVariable Long id,
            @RequestBody(required = false) ReleaseOrderRequest request,
            @AuthenticationPrincipal UserDetailsImpl principal,
            HttpServletRequest httpRequest) {
        String ip = extractClientIp(httpRequest);
        Map<String, Object> result = deliveryService.releaseOrder(id, request, principal, ip);
        return ResponseEntity.ok(result);
    }

    /**
     * 3. GET /client/delivery/orders/{refCode}
     * Client Deliverables Portal View
     */
    @GetMapping({"/client/delivery/orders/{refCode}", "/api/v1/client/delivery/orders/{refCode}"})
    @PreAuthorize("hasAnyRole('CLIENT', 'SUPER_ADMIN', 'ADMIN', 'PA', 'SPA')")
    public ResponseEntity<ClientDeliverableResponse> getClientDeliverable(
            @PathVariable String refCode,
            @AuthenticationPrincipal UserDetailsImpl principal) {
        ClientDeliverableResponse response = deliveryService.getClientDeliverable(refCode, principal);
        return ResponseEntity.ok(response);
    }

    /**
     * 4. POST /client/delivery/orders/{refCode}/generate-token
     * Generate single-use, 15-minute download token
     */
    @PostMapping({"/client/delivery/orders/{refCode}/generate-token", "/api/v1/client/delivery/orders/{refCode}/generate-token"})
    @PreAuthorize("hasAnyRole('CLIENT', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> generateDownloadToken(
            @PathVariable String refCode,
            @RequestBody(required = false) GenerateTokenRequest request,
            @AuthenticationPrincipal UserDetailsImpl principal,
            HttpServletRequest httpRequest) {
        String ip = extractClientIp(httpRequest);
        String ua = httpRequest.getHeader(HttpHeaders.USER_AGENT);
        Map<String, Object> tokenInfo = deliveryService.generateDownloadToken(refCode, request, principal, ip, ua);
        return ResponseEntity.ok(tokenInfo);
    }

    /**
     * 5. GET /client/delivery/stream?token=...
     * Stream Deliverable Binary via Ephemeral Token
     */
    @GetMapping({"/client/delivery/stream", "/api/v1/client/delivery/stream"})
    public ResponseEntity<byte[]> streamDeliverable(
            @RequestParam(value = "token", required = false) String token,
            HttpServletRequest httpRequest) {
        if (token == null || token.isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing required download token");
        }
        String ip = extractClientIp(httpRequest);
        String ua = httpRequest.getHeader(HttpHeaders.USER_AGENT);
        DeliveryService.StreamResult streamResult = deliveryService.streamDeliverable(token, ip, ua);

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + streamResult.getFilename() + "\"")
                .contentType(MediaType.parseMediaType(streamResult.getContentType()))
                .contentLength(streamResult.getContent().length)
                .body(streamResult.getContent());
    }

    /**
     * 6. POST /client/delivery/orders/{refCode}/acknowledge
     * Client Acknowledgement: VIEWED, DOWNLOADED, ACCEPTED, CLARIFICATION_REQUESTED
     */
    @PostMapping({"/client/delivery/orders/{refCode}/acknowledge", "/api/v1/client/delivery/orders/{refCode}/acknowledge"})
    @PreAuthorize("hasAnyRole('CLIENT', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> acknowledgeDelivery(
            @PathVariable String refCode,
            @RequestBody AcknowledgeDeliveryRequest request,
            @AuthenticationPrincipal UserDetailsImpl principal,
            HttpServletRequest httpRequest) {
        String ip = extractClientIp(httpRequest);
        String ua = httpRequest.getHeader(HttpHeaders.USER_AGENT);
        Map<String, Object> result = deliveryService.acknowledgeDelivery(refCode, request, principal, ip, ua);
        return ResponseEntity.ok(result);
    }

    /**
     * 7. POST /delivery/orders/{id}/close
     * Project Closure & 10-Year Archival Lock: CLIENT_DOWNLOADED → CLOSED
     */
    @PostMapping({"/delivery/orders/{id}/close", "/api/v1/delivery/orders/{id}/close"})
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> closeOrder(
            @PathVariable Long id,
            @RequestBody(required = false) CloseOrderRequest request,
            @AuthenticationPrincipal UserDetailsImpl principal,
            HttpServletRequest httpRequest) {
        String ip = extractClientIp(httpRequest);
        Map<String, Object> result = deliveryService.closeOrder(id, request, principal, ip);
        return ResponseEntity.ok(result);
    }

    /**
     * 8. GET /delivery/orders/{id}/invoice
     * Retrieve Tax Invoice Details
     */
    @GetMapping({"/delivery/orders/{id}/invoice", "/api/v1/delivery/orders/{id}/invoice"})
    @PreAuthorize("hasAnyRole('CLIENT', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> getInvoiceDetails(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetailsImpl principal) {
        OrderInvoice inv = orderInvoiceRepository.findByOrderId(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "No invoice found for order #" + id));

        InvoiceDetailsResponse resp = new InvoiceDetailsResponse();
        resp.setId(inv.getId());
        resp.setOrderId(inv.getOrderId());
        resp.setInvoiceNumber(inv.getInvoiceNumber());
        resp.setFinancialYear(inv.getFinancialYear());
        resp.setInvoiceDate(inv.getInvoiceDate());
        resp.setDueDate(inv.getDueDate());
        resp.setClientName(inv.getClientName());
        resp.setClientAddress(inv.getClientAddress());
        resp.setClientGstin(inv.getClientGstin());
        resp.setClientPan(inv.getClientPan());
        resp.setPlaceOfSupply(inv.getPlaceOfSupply());
        resp.setStateCode(inv.getStateCode());
        resp.setFirmName(inv.getFirmName());
        resp.setFirmAddress(inv.getFirmAddress());
        resp.setFirmGstin(inv.getFirmGstin());
        resp.setFirmPan(inv.getFirmPan());
        resp.setSacCode(inv.getSacCode());
        resp.setBaseAmount(inv.getBaseAmount());
        resp.setInterState(inv.isInterState());
        resp.setCgstRate(inv.getCgstRate());
        resp.setCgstAmount(inv.getCgstAmount());
        resp.setSgstRate(inv.getSgstRate());
        resp.setSgstAmount(inv.getSgstAmount());
        resp.setIgstRate(inv.getIgstRate());
        resp.setIgstAmount(inv.getIgstAmount());
        resp.setTotalTax(inv.getTotalTax());
        resp.setGrandTotal(inv.getGrandTotal());
        resp.setAmountPaid(inv.getAmountPaid());
        resp.setBalanceDue(inv.getBalanceDue());
        resp.setStatus(inv.getStatus());
        resp.setInvoiceHash(inv.getInvoiceHash());
        resp.setCreatedAt(inv.getCreatedAt());
        resp.setCreatedBy(inv.getCreatedBy());

        return ResponseEntity.ok(resp);
    }

    private String extractClientIp(HttpServletRequest request) {
        String xf = request.getHeader("X-Forwarded-For");
        if (xf != null && !xf.isBlank()) {
            return xf.split(",")[0].trim();
        }
        return request.getRemoteAddr() != null ? request.getRemoteAddr() : "127.0.0.1";
    }
}
