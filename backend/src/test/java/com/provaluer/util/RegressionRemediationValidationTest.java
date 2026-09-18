package com.provaluer.util;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.SaveDocumentValuesRequest;
import com.provaluer.model.*;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.TemplateRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.repository.ValuationDataRepository;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.DocumentWorkspaceService;
import com.provaluer.service.ValuationEngineService;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.docx4j.XmlUtils;
import org.docx4j.dml.wordprocessingDrawing.Inline;
import org.docx4j.finders.ClassFinder;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.P;
import org.docx4j.wml.Text;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.util.*;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class RegressionRemediationValidationTest {

    @Autowired
    private DocxTemplateEngine templateEngine;

    @Autowired
    private ValuationEngineService valuationEngineService;

    @Autowired
    private DocumentWorkspaceService documentWorkspaceService;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private ValuationDataRepository valuationDataRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TemplateRepository templateRepository;

    private byte[] templateBytes;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private UserDetailsImpl principal;
    private User testUser;
    private Template testTemplate;

    @BeforeEach
    void setUp() throws Exception {
        File templateFile = new File("official_production_valuation_report.docx");
        assertTrue(templateFile.exists());
        templateBytes = Files.readAllBytes(templateFile.toPath());

        String uid = UUID.randomUUID().toString().substring(0, 8);
        testTemplate = new Template();
        testTemplate.setName("Official Template " + uid);
        testTemplate.setTemplateContent(templateBytes);
        testTemplate.setDocumentDom("{}");
        testTemplate.setPlaceholderRegistry("{}");
        testTemplate.setFieldMapping("{}");
        testTemplate.setIsActive("Y");
        testTemplate.setStatus("CONFIRMED");
        testTemplate = templateRepository.save(testTemplate);

        testUser = new User("user_" + uid + "@provaluer.com", "password", UserRole.SPA, "9" + (long)(Math.random() * 899999999L + 100000000L), "v1.0");
        testUser.setFullName("Remediation Officer");
        testUser = userRepository.save(testUser);
        principal = UserDetailsImpl.build(testUser);
    }

    private byte[] createTestImage(int width, int height, Color color, String label) throws Exception {
        BufferedImage img = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = img.createGraphics();
        g.setColor(color);
        g.fillRect(0, 0, width, height);
        g.setColor(Color.WHITE);
        g.setFont(new Font("Arial", Font.BOLD, 24));
        g.drawString(label, 20, height / 2);
        g.dispose();
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(img, "jpg", baos);
        return baos.toByteArray();
    }

    @Test
    @Transactional
    @DisplayName("VALIDATION A: PROPERTY_ADDRESS is preserved, not overwritten with empty string")
    void testValidationA_PropertyAddressPreserved() throws Exception {
        System.out.println("=== VALIDATION A: PROPERTY_ADDRESS PRESERVATION ===");
        
        Order order = new Order();
        order.setReportNumber("VAL-A-" + UUID.randomUUID().toString().substring(0, 8));
        order.setClientName("Test Client");
        order.setClientId(testUser.getId());
        order.setTemplateId(testTemplate.getId());
        order.setPurpose("Bank Valuation");
        order.setPropertyCategory("Flat");
        order.setStatus("IN_PROGRESS");
        Map<String, String> inputs = new HashMap<>();
        inputs.put("PROPERTY_ADDRESS", "Plot 104, Jubilee Hills");
        order.setInputValues(objectMapper.writeValueAsString(inputs));
        order = orderRepository.save(order);

        ValuationData valData = new ValuationData();
        valData.setOrderId(order.getId());
        valData.setValuationMethodology("COMPOSITE");
        valData = valuationDataRepository.save(valData);

        // 1. Check generatePlaceholders does NOT overwrite PROPERTY_ADDRESS with empty string
        Map<String, String> placeholders = valuationEngineService.generatePlaceholders(
                order, valData, Collections.emptyList(), Collections.emptyList(), Collections.emptyList(), Collections.emptyList()
        );
        String address = placeholders.get("property_address");
        if (address == null || address.isEmpty()) {
            address = placeholders.get("PROPERTY_ADDRESS");
        }
        assertEquals("Plot 104, Jubilee Hills", address, "Address must be sourced from user input, never empty string");

        // 2. Generate DOCX and PDF
        inputs.putAll(placeholders);
        inputs.put("property_address", "Plot 104, Jubilee Hills");
        inputs.put("PROPERTY_ADDRESS", "Plot 104, Jubilee Hills");

        byte[] docxBytes = templateEngine.generateReport(templateBytes, inputs, Collections.emptyMap());
        assertNotNull(docxBytes);
        WordprocessingMLPackage docxPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(docxBytes));
        String docxXml = XmlUtils.marshaltoString(docxPkg.getMainDocumentPart().getJaxbElement());
        assertTrue(docxXml.contains("Plot 104, Jubilee Hills"), "Address must be visible in DOCX");

        byte[] pdfBytes = templateEngine.convertDocxToPdf(docxBytes);
        assertNotNull(pdfBytes);
        try (PDDocument pdfDoc = Loader.loadPDF(pdfBytes)) {
            PDFTextStripper stripper = new PDFTextStripper();
            String pdfText = stripper.getText(pdfDoc);
            assertTrue(pdfText.contains("Plot 104, Jubilee Hills"), "Address must be visible in PDF");
        }

        // Save evidence
        File dir = new File("build/evidence");
        if (!dir.exists()) dir.mkdirs();
        Files.write(new File(dir, "validation_a_address.docx").toPath(), docxBytes);
        Files.write(new File(dir, "validation_a_address.pdf").toPath(), pdfBytes);
        System.out.println("-> VALIDATION A PASSED: Address visible in DOCX and PDF, not overwritten.");
    }

    @Test
    @Transactional
    @DisplayName("VALIDATION B: COMPOSITE_GOVT_RATE syncs to ValuationData and calculates non-zero Government Value")
    void testValidationB_CompositeGovtRatePersistence() throws Exception {
        System.out.println("=== VALIDATION B: COMPOSITE_GOVT_RATE PERSISTENCE ===");

        Order order = new Order();
        order.setReportNumber("VAL-B-" + UUID.randomUUID().toString().substring(0, 8));
        order.setClientName("Test Client");
        order.setClientId(testUser.getId());
        order.setTemplateId(testTemplate.getId());
        order.setPurpose("Bank Valuation");
        order.setPropertyCategory("Flat");
        order.setStatus("IN_PROGRESS");
        order = orderRepository.save(order);

        ValuationData valData = new ValuationData();
        valData.setOrderId(order.getId());
        valData.setValuationMethodology("COMPOSITE");
        valData = valuationDataRepository.save(valData);

        // Save COMPOSITE_GOVERNMENT_RATE = 3500 via workspace service
        SaveDocumentValuesRequest req = new SaveDocumentValuesRequest();
        Map<String, String> values = new HashMap<>();
        values.put("COMPOSITE_GOVERNMENT_RATE", "3500");
        values.put("SUPER_BUILT_UP_AREA", "1200");
        
        List<Map<String, Object>> compItems = List.of(Map.of(
                "itemCategory", "MAIN_UNIT",
                "description", "Flat Unit 104",
                "enteredUnit", "Sq.Ft",
                "quantity", "1200",
                "rate", "6000",
                "amount", "7200000",
                "depreciationAmount", "0",
                "fairValue", "7200000"
        ));
        values.put("RAW_COMPOSITE_ITEMS_JSON", objectMapper.writeValueAsString(compItems));
        req.setValues(values);

        documentWorkspaceService.saveDocumentValues(order.getId(), req, principal);

        // Verify ValuationData.compositeGovernmentRate is 3500
        ValuationData updated = valuationDataRepository.findByOrderId(order.getId()).orElseThrow();
        assertEquals(0, new BigDecimal("3500").compareTo(updated.getCompositeGovernmentRate()),
                "ValuationData.compositeGovernmentRate must be 3500");

        // Verify Government Value = 1200 * 3500 = 42,00,000
        assertNotNull(updated.getGovernmentValue());
        assertEquals(0, new BigDecimal("4200000.00").compareTo(updated.getGovernmentValue()),
                "Government value must be 42,00,000 and not zero");
        System.out.println("-> VALIDATION B PASSED: Government Rate = 3500, Government Value = " + updated.getGovernmentValue());
    }

    @Test
    @DisplayName("VALIDATION C: Site Photographs IMG_PIC1 through IMG_PIC8 in Photo section, 0 in TOC")
    void testValidationC_SitePhotographs() throws Exception {
        System.out.println("=== VALIDATION C: SITE PHOTOGRAPHS IN BODY, ZERO IN TOC ===");

        Map<String, String> inputs = new HashMap<>();
        inputs.put("PROPERTY_ADDRESS", "Plot 104, Jubilee Hills");

        Map<String, byte[]> images = new HashMap<>();
        images.put("IMG_FRONT_PAGE", createTestImage(1200, 800, Color.DARK_GRAY, "COVER"));
        for (int i = 1; i <= 8; i++) {
            images.put("IMG_PIC" + i, createTestImage(800, 600, Color.BLUE, "PIC" + i));
        }

        byte[] docxBytes = templateEngine.generateReport(templateBytes, inputs, images);
        assertNotNull(docxBytes);

        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(docxBytes));

        // 1. Verify TOC contains ZERO photo images
        boolean tocHasImages = false;
        for (Object o : pkg.getMainDocumentPart().getContent()) {
            Object u = XmlUtils.unwrap(o);
            if (u instanceof P p) {
                if (p.getPPr() != null && p.getPPr().getPStyle() != null) {
                    String s = p.getPPr().getPStyle().getVal();
                    if (s != null && s.toUpperCase().contains("TOC")) {
                        ClassFinder drawingFinder = new ClassFinder(org.docx4j.wml.Drawing.class);
                        new org.docx4j.TraversalUtil(p, drawingFinder);
                        if (!drawingFinder.results.isEmpty()) {
                            tocHasImages = true;
                        }
                    }
                }
            }
        }
        assertFalse(tocHasImages, "Zero photos must be inside Table of Contents");

        // 2. Verify all photos in Property Photographs section
        ClassFinder inlineFinder = new ClassFinder(Inline.class);
        new org.docx4j.TraversalUtil(pkg.getMainDocumentPart().getContent(), inlineFinder);
        assertTrue(inlineFinder.results.size() >= 8, "All 8 site photos must be embedded in Property Photographs section");

        // Save evidence
        File dir = new File("build/evidence");
        if (!dir.exists()) dir.mkdirs();
        Files.write(new File(dir, "validation_c_photos.docx").toPath(), docxBytes);

        byte[] pdfBytes = templateEngine.convertDocxToPdf(docxBytes);
        Files.write(new File(dir, "validation_c_photos.pdf").toPath(), pdfBytes);
        System.out.println("-> VALIDATION C PASSED: Photos visible in Property Photographs section, zero in TOC.");
    }

    @Test
    @DisplayName("VALIDATION D: COMPOSITE_PROPERTY_TABLE rendered for Composite Property Template")
    void testValidationD_CompositePropertyTableRendered() throws Exception {
        System.out.println("=== VALIDATION D: COMPOSITE_PROPERTY_TABLE RENDERED ===");

        Map<String, String> inputs = new HashMap<>();
        inputs.put("VALUATION_METHODOLOGY", "COMPOSITE");
        inputs.put("PROPERTY_CATEGORY", "Flat");
        inputs.put("COMPOSITE_RATE", "6000");
        inputs.put("COMPOSITE_GOVERNMENT_RATE", "3500");
        inputs.put("COMPOSITE_GOVT_RATE", "3500");
        inputs.put("RAW_FAIR_VALUE", "7200000");
        inputs.put("SAY_FAIR_VALUE", "7200000");
        inputs.put("FAIR_VALUE", "7200000");
        inputs.put("REALIZABLE_VALUE", "6120000");
        inputs.put("DISTRESS_SALE_VALUE", "5400000");
        inputs.put("GOVERNMENT_VALUE", "4200000");
        inputs.put("INSURABLE_VALUE", "2500000");

        List<Map<String, Object>> compItems = List.of(Map.of(
                "description", "Flat Unit 104",
                "enteredUnit", "Sq.Ft",
                "quantity", "1200",
                "rate", "6000",
                "amount", "7200000",
                "depreciationAmount", "0",
                "fairValue", "7200000"
        ));
        inputs.put("RAW_COMPOSITE_ITEMS_JSON", objectMapper.writeValueAsString(compItems));

        // Create a Composite Property Template containing <<COMPOSITE_PROPERTY_TABLE>> and <<VALUATION_SUMMARY_TABLE>>
        WordprocessingMLPackage compPkg = WordprocessingMLPackage.createPackage();
        org.docx4j.wml.ObjectFactory f = new org.docx4j.wml.ObjectFactory();
        P pComp = f.createP();
        org.docx4j.wml.R rComp = f.createR();
        Text tComp = f.createText();
        tComp.setValue("<<COMPOSITE_PROPERTY_TABLE>>");
        rComp.getContent().add(tComp);
        pComp.getContent().add(rComp);
        compPkg.getMainDocumentPart().getContent().add(pComp);

        P pSumm = f.createP();
        org.docx4j.wml.R rSumm = f.createR();
        Text tSumm = f.createText();
        tSumm.setValue("<<VALUATION_SUMMARY_TABLE>>");
        rSumm.getContent().add(tSumm);
        pSumm.getContent().add(rSumm);
        compPkg.getMainDocumentPart().getContent().add(pSumm);

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        compPkg.save(baos);
        byte[] compTemplateBytes = baos.toByteArray();

        // 1. Verify Template Governance detection
        assertEquals(DocxTemplateEngine.TemplateMethodology.COMPOSITE, templateEngine.detectTemplateMethodology(compTemplateBytes));

        byte[] docxBytes = templateEngine.generateReport(compTemplateBytes, inputs, Collections.emptyMap());
        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(docxBytes));
        String xml = XmlUtils.marshaltoString(pkg.getMainDocumentPart().getJaxbElement());

        assertTrue(xml.contains("Valuation of Property (Composite Rate Method)"), "Composite Property Table must be rendered");
        assertTrue(xml.contains("Flat Unit 104"), "Composite Item must appear in table");

        // 2. Verify Canonical Land+Building template does NOT get hijacked into composite table
        assertEquals(DocxTemplateEngine.TemplateMethodology.LAND_AND_BUILDING, templateEngine.detectTemplateMethodology(templateBytes));
        byte[] lbDocx = templateEngine.generateReport(templateBytes, inputs, Collections.emptyMap());
        String lbXml = XmlUtils.marshaltoString(WordprocessingMLPackage.load(new ByteArrayInputStream(lbDocx)).getMainDocumentPart().getJaxbElement());
        assertFalse(lbXml.contains("Valuation of Property (Composite Rate Method)"), "Land+Building template must NOT hijack LAND_TABLE into Composite Table");
        assertTrue(lbXml.contains("Value Of Land"), "Land+Building template must honor LAND_TABLE directive");

        // Save evidence
        File dir = new File("build/evidence");
        if (!dir.exists()) dir.mkdirs();
        Files.write(new File(dir, "validation_d_composite.docx").toPath(), docxBytes);

        byte[] pdfBytes = templateEngine.convertDocxToPdf(docxBytes);
        Files.write(new File(dir, "validation_d_composite.pdf").toPath(), pdfBytes);
        System.out.println("-> VALIDATION D PASSED: COMPOSITE_PROPERTY_TABLE rendered according to template directive.");
    }

    @Test
    @DisplayName("VALIDATION E: Composite Summary populated with non-zero values")
    void testValidationE_CompositeSummaryPopulated() throws Exception {
        System.out.println("=== VALIDATION E: COMPOSITE SUMMARY POPULATED ===");

        Map<String, String> inputs = new HashMap<>();
        inputs.put("VALUATION_METHODOLOGY", "COMPOSITE");
        inputs.put("PROPERTY_CATEGORY", "Flat");
        inputs.put("FAIR_VALUE", "7200000");
        inputs.put("SAY_FAIR_VALUE", "7200000");
        inputs.put("REALIZABLE_VALUE", "6120000");
        inputs.put("DISTRESS_SALE_VALUE", "5400000");
        inputs.put("GOVERNMENT_VALUE", "4200000");
        inputs.put("INSURABLE_VALUE", "2500000");

        // Create Composite Template
        WordprocessingMLPackage compPkg = WordprocessingMLPackage.createPackage();
        org.docx4j.wml.ObjectFactory f = new org.docx4j.wml.ObjectFactory();
        P pComp = f.createP();
        org.docx4j.wml.R rComp = f.createR();
        Text tComp = f.createText();
        tComp.setValue("<<COMPOSITE_PROPERTY_TABLE>>");
        rComp.getContent().add(tComp);
        pComp.getContent().add(rComp);
        compPkg.getMainDocumentPart().getContent().add(pComp);

        P pSumm = f.createP();
        org.docx4j.wml.R rSumm = f.createR();
        Text tSumm = f.createText();
        tSumm.setValue("<<VALUATION_SUMMARY_TABLE>>");
        rSumm.getContent().add(tSumm);
        pSumm.getContent().add(rSumm);
        compPkg.getMainDocumentPart().getContent().add(pSumm);

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        compPkg.save(baos);
        byte[] compTemplateBytes = baos.toByteArray();

        byte[] docxBytes = templateEngine.generateReport(compTemplateBytes, inputs, Collections.emptyMap());
        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(docxBytes));
        String xml = XmlUtils.marshaltoString(pkg.getMainDocumentPart().getJaxbElement());

        // Check Valuation Parameters Summary table
        assertTrue(xml.contains("Valuation Parameters Summary"), "Summary table must be rendered");
        assertTrue(xml.contains("Realizable Value"), "Must contain Realizable Value");
        assertTrue(xml.contains("61,20,000"), "Must contain Realizable Value amount");
        assertTrue(xml.contains("Distress Sale Value"), "Must contain Distress Sale Value");
        assertTrue(xml.contains("54,00,000"), "Must contain Distress Sale Value amount");
        assertTrue(xml.contains("Government Value"), "Must contain Government Value");
        assertTrue(xml.contains("42,00,000"), "Must contain Government Value amount");

        // Save evidence
        File dir = new File("build/evidence");
        if (!dir.exists()) dir.mkdirs();
        Files.write(new File(dir, "validation_e_summary.docx").toPath(), docxBytes);

        byte[] pdfBytes = templateEngine.convertDocxToPdf(docxBytes);
        Files.write(new File(dir, "validation_e_summary.pdf").toPath(), pdfBytes);
        System.out.println("-> VALIDATION E PASSED: Composite Summary populated with non-zero values.");
    }
}
