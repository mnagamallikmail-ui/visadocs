package com.provaluer.service;

import com.provaluer.dto.SaveDocumentValuesRequest;
import com.provaluer.model.Order;
import com.provaluer.repository.OrderInputRepository;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.ValuationDataRepository;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.util.DocxTemplateEngine;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class PaEditDuringSpaGateAndCleanDocumentTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private OrderInputRepository orderInputRepository;

    @Mock
    private ValuationDataRepository valuationDataRepository;

    @Mock
    private AuditLogService auditLogService;

    @Mock
    private ValuationEngineService valuationEngineService;

    @InjectMocks
    private DocumentWorkspaceService documentWorkspaceService;

    @InjectMocks
    private ValuationEngineService valuationEngineServiceReal;

    private UserDetailsImpl paUser;
    private UserDetailsImpl otherPaUser;
    private Order testOrder;

    @BeforeEach
    public void setup() {
        paUser = new UserDetailsImpl(
                10L, "pa@provaluer.com", "password",
                List.of(new SimpleGrantedAuthority("ROLE_PA")), false, false
        );

        otherPaUser = new UserDetailsImpl(
                99L, "otherpa@provaluer.com", "password",
                List.of(new SimpleGrantedAuthority("ROLE_PA")), false, false
        );

        testOrder = new Order();
        testOrder.setId(101L);
        testOrder.setPaId(10L);
        testOrder.setStatus("ASSIGNED");
        testOrder.setValuationStatus("DRAFT");
    }

    @Test
    @DisplayName("PA can save and submit in ASSIGNED status")
    public void testPaCanSaveAndSubmitInAssigned() {
        when(orderRepository.findById(101L)).thenReturn(Optional.of(testOrder));
        when(orderInputRepository.findAllByOrderId(101L)).thenReturn(Collections.emptyList());

        // 1. PA saves document values
        SaveDocumentValuesRequest req = new SaveDocumentValuesRequest();
        req.setValues(Map.of("CLIENT_NAME", "State Bank of India"));
        Map<String, String> saveRes = documentWorkspaceService.saveDocumentValues(101L, req, paUser);
        assertEquals("SAVED", saveRes.get("status"));

        // 2. PA submits to SPA -> moves to SPA_GATE
        Map<String, String> submitRes = documentWorkspaceService.submitToSpa(101L, paUser);
        assertEquals("SPA_GATE", submitRes.get("status"));
        assertEquals("SPA_GATE", testOrder.getStatus());
        verify(auditLogService, times(1)).log(
                eq(10L), eq("pa@provaluer.com"), eq("ROLE_PA"),
                eq("PA_SUBMITTED"), eq("ORDER"), eq("101"), anyString()
        );
    }

    @Test
    @DisplayName("PRIMARY REQUIREMENT: PA can edit, save, and resubmit while in SPA_GATE")
    public void testPaCanEditSaveAndResubmitInSpaGate() {
        testOrder.setStatus("SPA_GATE");
        when(orderRepository.findById(101L)).thenReturn(Optional.of(testOrder));
        when(orderInputRepository.findAllByOrderId(101L)).thenReturn(Collections.emptyList());

        // 1. PA modifies inputs while in SPA_GATE -> SUCСEEDS
        SaveDocumentValuesRequest req = new SaveDocumentValuesRequest();
        req.setValues(Map.of("PROPERTY_AREA_SFT", "1250"));
        Map<String, String> saveRes = documentWorkspaceService.saveDocumentValues(101L, req, paUser);
        assertEquals("SAVED", saveRes.get("status"));

        // 2. PA calls submitToSpa (resubmit) while in SPA_GATE -> SUCCEEDS & logs PA_RESUBMITTED
        Map<String, String> resubmitRes = documentWorkspaceService.submitToSpa(101L, paUser);
        assertEquals("SPA_GATE", resubmitRes.get("status"));
        assertEquals("SPA_GATE", testOrder.getStatus());
        verify(auditLogService, times(1)).log(
                eq(10L), eq("pa@provaluer.com"), eq("ROLE_PA"),
                eq("PA_RESUBMITTED"), eq("ORDER"), eq("101"), anyString()
        );
    }

    @Test
    @DisplayName("LOCKING RULE: PA edit and resubmit are strictly blocked after SPA confirmation (SPA_CONFIRMED)")
    public void testPaBlockedAfterSpaConfirmed() {
        testOrder.setStatus("SPA_CONFIRMED");
        when(orderRepository.findById(101L)).thenReturn(Optional.of(testOrder));

        SaveDocumentValuesRequest req = new SaveDocumentValuesRequest();
        req.setValues(Map.of("CLIENT_NAME", "HDFC Bank"));

        // PA save blocked
        assertThrows(AccessDeniedException.class, () -> {
            documentWorkspaceService.saveDocumentValues(101L, req, paUser);
        });

        // PA submit blocked
        assertThrows(AccessDeniedException.class, () -> {
            documentWorkspaceService.submitToSpa(101L, paUser);
        });
    }

    @Test
    @DisplayName("LOCKING RULE: PA edit is strictly blocked if valuationStatus is FINALIZED or LOCKED")
    public void testPaBlockedIfValuationFinalizedOrLocked() {
        testOrder.setStatus("ASSIGNED");
        testOrder.setValuationStatus("FINALIZED");
        when(orderRepository.findById(101L)).thenReturn(Optional.of(testOrder));

        SaveDocumentValuesRequest req = new SaveDocumentValuesRequest();
        req.setValues(Map.of("CLIENT_NAME", "ICICI Bank"));

        assertThrows(AccessDeniedException.class, () -> {
            documentWorkspaceService.saveDocumentValues(101L, req, paUser);
        });

        testOrder.setValuationStatus("LOCKED");
        assertThrows(AccessDeniedException.class, () -> {
            documentWorkspaceService.submitToSpa(101L, paUser);
        });
    }

    @Test
    @DisplayName("LOCKING RULE: Unassigned PA cannot access order")
    public void testUnassignedPaCannotAccess() {
        testOrder.setStatus("ASSIGNED");
        when(orderRepository.findById(101L)).thenReturn(Optional.of(testOrder));

        SaveDocumentValuesRequest req = new SaveDocumentValuesRequest();
        req.setValues(Map.of("CLIENT_NAME", "Axis Bank"));

        assertThrows(AccessDeniedException.class, () -> {
            documentWorkspaceService.saveDocumentValues(101L, req, otherPaUser);
        });
    }

    @Test
    @DisplayName("SECONDARY REQUIREMENT: AST cleanup pass eliminates consecutive empty paragraphs & page break traps")
    public void testAstCleanupPassEliminatesBlankParagraphs() throws Exception {
        DocxTemplateEngine engine = new DocxTemplateEngine();
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        ObjectFactory factory = new ObjectFactory();
        List<Object> content = pkg.getMainDocumentPart().getContent();

        // Add regular paragraph
        P p1 = factory.createP();
        R r1 = factory.createR();
        Text t1 = factory.createText();
        t1.setValue("Section 1: Details");
        r1.getContent().add(t1);
        p1.getContent().add(r1);
        content.add(p1);

        // Add 5 consecutive empty paragraphs
        for (int i = 0; i < 5; i++) {
            content.add(factory.createP());
        }

        // Add paragraph with page break
        P pBreak = factory.createP();
        R rBr = factory.createR();
        Br br = factory.createBr();
        br.setType(STBrType.PAGE);
        rBr.getContent().add(br);
        pBreak.getContent().add(rBr);
        content.add(pBreak);

        // Add 4 consecutive empty paragraphs following page break
        for (int i = 0; i < 4; i++) {
            content.add(factory.createP());
        }

        // Add Section 2
        P p2 = factory.createP();
        R r2 = factory.createR();
        Text t2 = factory.createText();
        t2.setValue("Section 2: Valuation");
        r2.getContent().add(t2);
        p2.getContent().add(r2);
        content.add(p2);

        // Before cleanup: 1 + 5 + 1 + 4 + 1 = 12 elements
        assertEquals(12, content.size());

        // Execute AST Cleanup pass
        engine.cleanupEmptyParagraphsAndBreaks(content);

        // After cleanup: empty paragraphs preceding and following page break are removed!
        // Should only have: p1, pBreak, p2
        assertEquals(3, content.size());
        assertTrue(content.contains(p1));
        assertTrue(content.contains(pBreak));
        assertTrue(content.contains(p2));
    }

    @Test
    @DisplayName("THIRD REQUIREMENT: enableUpdateFields injects updateFields into settings.xml")
    public void testEnableUpdateFields() throws Exception {
        DocxTemplateEngine engine = new DocxTemplateEngine();
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();

        engine.enableUpdateFields(pkg);

        org.docx4j.wml.CTSettings settings = pkg.getMainDocumentPart().getDocumentSettingsPart().getJaxbElement();
        assertNotNull(settings);
        assertNotNull(settings.getUpdateFields());
        assertTrue(settings.getUpdateFields().isVal());
    }
}
