package com.provaluer.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.SaveDocumentValuesRequest;
import com.provaluer.dto.ValuationBundleResponse;
import com.provaluer.model.Order;
import com.provaluer.model.Template;
import com.provaluer.model.User;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.TemplateRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.util.DocxTemplateEngine;
import org.docx4j.XmlUtils;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class CriticalRuntimeGovernanceTest {

    @Autowired
    private DocxTemplateEngine templateEngine;

    @Autowired
    private DocumentWorkspaceService workspaceService;

    @Autowired
    private ValuationEngineService valuationEngineService;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private TemplateRepository templateRepository;

    @Autowired
    private UserRepository userRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private UserDetailsImpl testUser;

    @BeforeEach
    public void setup() {
        testUser = new UserDetailsImpl(1L, "admin", "admin@provaluer.com", "pass",
                List.of(new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_SUPER_ADMIN")),
                true, true);
    }

    @Test
    @DisplayName("TEST D & E: Zero unresolved placeholders in generated output")
    public void testZeroPlaceholdersInGeneratedReport() throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        ObjectFactory factory = new ObjectFactory();

        P p1 = factory.createP();
        R r1 = factory.createR();
        Text t1 = factory.createText();
        t1.setValue("Report for <<OWNER_NAME>>, located at <<PROPERTY_ADDRESS>>. Extra: <<UNRESOLVED_CUSTOM_FIELD>>.");
        r1.getContent().add(t1);
        p1.getContent().add(r1);
        pkg.getMainDocumentPart().getContent().add(p1);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        pkg.save(out);
        byte[] templateBytes = out.toByteArray();

        Map<String, String> inputs = new HashMap<>();
        inputs.put("NAME_OF_THE_OWNER", "M/s Sri Venkateswara Enterprises");

        byte[] generated = templateEngine.generateReport(templateBytes, inputs, Collections.emptyMap());
        WordprocessingMLPackage genPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(generated));
        String xml = XmlUtils.marshaltoString(genPkg.getMainDocumentPart().getJaxbElement());

        // Value resolved via alias lookup
        assertTrue(xml.contains("M/s Sri Venkateswara Enterprises"), "Must resolve OWNER_NAME via alias");
        // Must NEVER contain << or >> placeholders in the final report
        assertFalse(xml.contains("<<"), "Must NOT contain any opening placeholder tag '<<'");
        assertFalse(xml.contains(">>"), "Must NOT contain any closing placeholder tag '>>'");
        assertFalse(xml.contains("UNRESOLVED_CUSTOM_FIELD"), "Unresolved placeholder must be replaced with empty string");
    }

    @Test
    @DisplayName("TEST F: Certificate Page renders ONLY template content without auto-injecting tables")
    public void testCertificatePageFidelityNoInjectedTables() throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        ObjectFactory factory = new ObjectFactory();

        // Paragraph mentioning 'Value of the property' in a normal sentence
        P p = factory.createP();
        R r = factory.createR();
        Text t = factory.createText();
        t.setValue("I hereby certify that the fair value of the property is <<VALUE_OF_THE_PROPERTY>> as on valuation date.");
        r.getContent().add(t);
        p.getContent().add(r);
        pkg.getMainDocumentPart().getContent().add(p);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        pkg.save(out);
        byte[] templateBytes = out.toByteArray();

        Map<String, String> inputs = new HashMap<>();
        inputs.put("VALUATION_METHODOLOGY", "COMPOSITE");
        inputs.put("VALUE_OF_THE_PROPERTY", "₹ 1,12,00,000");

        byte[] generated = templateEngine.generateReport(templateBytes, inputs, Collections.emptyMap());
        WordprocessingMLPackage genPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(generated));

        // Ensure NO table was auto-injected onto this certificate page
        List<Object> elements = genPkg.getMainDocumentPart().getContent();
        int tableCount = 0;
        for (Object elem : elements) {
            Object unwrapped = XmlUtils.unwrap(elem);
            if (unwrapped instanceof Tbl) {
                tableCount++;
            }
        }
        assertEquals(0, tableCount, "Certificate page with sentence text must NOT have tables auto-injected");

        String xml = XmlUtils.marshaltoString(genPkg.getMainDocumentPart().getJaxbElement());
        assertTrue(xml.contains("₹ 1,12,00,000"), "Certificate sentence must display the evaluated property value inline");
    }

    @Test
    @DisplayName("TEST G & H: Image placement has allowOverlap=false and empty placeholder produces blank image")
    public void testImageGovernanceAndBlankPlaceholder() throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        ObjectFactory factory = new ObjectFactory();

        P p = factory.createP();
        R r = factory.createR();
        Text t = factory.createText();
        t.setValue("<<PROPERTY_IMAGE>>");
        r.getContent().add(t);
        p.getContent().add(r);
        pkg.getMainDocumentPart().getContent().add(p);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        pkg.save(out);
        byte[] templateBytes = out.toByteArray();

        // No image uploaded in inputs -> must produce empty blank reserved frame without error text or blueprint
        Map<String, String> inputs = new HashMap<>();
        byte[] generated = templateEngine.generateReport(templateBytes, inputs, Collections.emptyMap());
        WordprocessingMLPackage genPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(generated));
        String xml = XmlUtils.marshaltoString(genPkg.getMainDocumentPart().getJaxbElement());

        // Zero placeholder markers remaining
        assertFalse(xml.contains("<<PROPERTY_IMAGE>>"));
        // No blueprint or missing image warning text
        assertFalse(xml.contains("MISSING IMAGE"), "Must not display 'MISSING IMAGE' warning text");
        assertFalse(xml.contains("Image Not Uploaded"), "Must not display error text");

        // Overlap governance
        assertFalse(xml.contains("allowOverlap=\"1\""), "Images must never allow overlap");
    }

    @Test
    @Transactional
    @DisplayName("TEST C: Persistence - 1425 sft persists and rehydrates on reopen")
    public void testCompositePropertyPersistenceAndRehydration() {
        Order order = new Order();
        order.setClientId(1L);
        order.setPurpose("Valuation");
        order.setStatus("DRAFT");
        order.setPropertyCategory("Commercial Unit");
        order = orderRepository.save(order);
        Long orderId = order.getId();

        // PA enters 1425 sft and saves
        Map<String, String> values = new HashMap<>();
        values.put("SALEABLE_AREA", "1425 sft");
        values.put("SALEABLE_AREA_NUMERIC", "1425");
        values.put("SALEABLE_AREA_UNIT", "Sq.Ft");
        values.put("SALEABLE_AREA_STANDARD_SQFT", "1425");

        SaveDocumentValuesRequest req = new SaveDocumentValuesRequest();
        req.setValues(values);
        workspaceService.saveDocumentValues(orderId, req, testUser);

        // Simulate close and reopen: fetch consolidated values and valuation bundle
        Map<String, String> rehydrated = workspaceService.getConsolidatedValues(orderId);
        assertEquals("1425", rehydrated.get("SALEABLE_AREA_NUMERIC"), "Numeric value must be persisted as 1425");

        ValuationBundleResponse bundle = valuationEngineService.getValuationBundle(orderId);
        assertNotNull(bundle.getCompositeItems(), "Composite items must exist");
        assertFalse(bundle.getCompositeItems().isEmpty(), "Composite items must not be empty");

        com.provaluer.model.ValuationCompositeItem mainUnit = bundle.getCompositeItems().stream()
                .filter(i -> "MAIN_UNIT".equalsIgnoreCase(i.getItemCategory()))
                .findFirst().orElse(null);

        assertNotNull(mainUnit, "Main unit composite item must exist");
        assertEquals(0, new BigDecimal("1425").compareTo(mainUnit.getQuantity()),
                "Main unit quantity must be rehydrated to 1425 and NOT fallback to 0");
    }
}
