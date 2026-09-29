package com.provaluer.controller;

import com.provaluer.dto.*;
import com.provaluer.model.LeadQuotation;
import com.provaluer.service.LeadService;
import com.provaluer.service.QuotationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping({"/api/leads", "/api/v1/leads"})
@CrossOrigin(origins = "*", maxAge = 3600)
public class LeadController {

    @Autowired
    private LeadService leadService;

    @Autowired
    private QuotationService quotationService;

    /**
     * Public commercial lead intake submission
     */
    @PostMapping
    public ResponseEntity<LeadResponseDto> createLead(@RequestBody LeadRequestDto requestDto) {
        LeadResponseDto response = leadService.createLead(requestDto);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    /**
     * Public / client upload of valuation documents for lead
     */
    @PostMapping("/{id}/upload")
    public ResponseEntity<LeadResponseDto> uploadDocuments(
            @PathVariable Long id,
            @RequestParam("files") MultipartFile[] files) throws IOException {
        LeadResponseDto response = leadService.uploadDocumentsForLead(id, files);
        return ResponseEntity.ok(response);
    }

    /**
     * Get lead details by ID (ADMIN only)
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<LeadResponseDto> getLeadById(@PathVariable Long id, Principal principal) {
        String actor = principal != null ? principal.getName() : "ADMIN";
        return ResponseEntity.ok(leadService.getLeadById(id, actor));
    }

    /**
     * List all leads with optional filtering (status, service, intent) (ADMIN only)
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<List<LeadResponseDto>> getLeads(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String service,
            @RequestParam(required = false) String intent) {
        return ResponseEntity.ok(leadService.getLeads(status, service, intent));
    }

    /**
     * Generate formal valuation quotation for lead (ADMIN only)
     */
    @PostMapping("/{id}/quote")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<LeadQuotation> generateQuote(
            @PathVariable Long id,
            @RequestBody LeadQuoteRequestDto quoteDto,
            Principal principal) {
        String actor = principal != null ? principal.getName() : "ADMIN";
        LeadQuotation quote = quotationService.generateQuote(id, quoteDto, actor);
        return ResponseEntity.ok(quote);
    }

    /**
     * Assign lead to a designated Valuer (ADMIN only)
     */
    @PostMapping("/{id}/assign")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<LeadResponseDto> assignValuer(
            @PathVariable Long id,
            @RequestBody LeadAssignDto assignDto) {
        return ResponseEntity.ok(leadService.assignValuer(id, assignDto));
    }

    /**
     * Transition lead status (NEW, QUALIFIED, QUOTED, WON, LOST) (ADMIN only)
     */
    @PostMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<LeadResponseDto> updateStatus(
            @PathVariable Long id,
            @RequestBody LeadStatusUpdateDto statusDto,
            Principal principal) {
        String actor = principal != null ? principal.getName() : "ADMIN";
        return ResponseEntity.ok(leadService.updateStatus(id, statusDto, actor));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<java.util.Map<String, String>> handleIllegalArgumentException(IllegalArgumentException ex) {
        java.util.Map<String, String> error = new java.util.HashMap<>();
        error.put("error", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
    }
}
