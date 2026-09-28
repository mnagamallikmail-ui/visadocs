package com.provaluer.service;

import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.nio.file.Files;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

public class RunSplitSafeGovernanceValidationTest {

    private TemplateProcessingService templateProcessingService;
    private ObjectFactory factory;

    @BeforeEach
    void setUp() {
        templateProcessingService = new TemplateProcessingService();
        factory = new ObjectFactory();
    }

    private byte[] createDocxWithParagraph(P paragraph) throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        pkg.getMainDocumentPart().getContent().add(paragraph);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        pkg.save(baos);
        return baos.toByteArray();
    }

    @Test
    @DisplayName("Test 1: <<LAND_TABLE>> stored in a single run is detected")
    void testSingleRunLandTable() throws Exception {
        P p = factory.createP();
        R r = factory.createR();
        Text t = factory.createText();
        t.setValue("<<LAND_TABLE>>");
        r.getContent().add(t);
        p.getContent().add(r);

        byte[] docxBytes = createDocxWithParagraph(p);
        Set<String> placeholders = templateProcessingService.extractVisiblePlaceholders(docxBytes);

        assertTrue(placeholders.contains("LANDTABLE"), "Single-run <<LAND_TABLE>> must be detected");
    }

    @Test
    @DisplayName("Test 2: <<LAND_TABLE>> split across 3 separate runs is detected")
    void testSplitAcrossThreeRunsLandTable() throws Exception {
        P p = factory.createP();

        // Run 1: "<<"
        R r1 = factory.createR();
        Text t1 = factory.createText();
        t1.setValue("<<");
        r1.getContent().add(t1);
        p.getContent().add(r1);

        // Run 2: "LAND_TABLE"
        R r2 = factory.createR();
        Text t2 = factory.createText();
        t2.setValue("LAND_TABLE");
        r2.getContent().add(t2);
        p.getContent().add(r2);

        // Run 3: ">>"
        R r3 = factory.createR();
        Text t3 = factory.createText();
        t3.setValue(">>");
        r3.getContent().add(t3);
        p.getContent().add(r3);

        byte[] docxBytes = createDocxWithParagraph(p);
        Set<String> placeholders = templateProcessingService.extractVisiblePlaceholders(docxBytes);

        assertTrue(placeholders.contains("LANDTABLE"), "3-run split <<LAND_TABLE>> must be detected");
    }

    @Test
    @DisplayName("Test 3: <<VALUE_OF_PROPERTY_TABLE>> split across 5 separate runs is detected")
    void testSplitAcrossMultipleRunsValueOfPropertyTable() throws Exception {
        P p = factory.createP();

        String[] parts = {"<<", "VALUE_", "OF_", "PROPERTY_", "TABLE>>"};
        for (String part : parts) {
            R r = factory.createR();
            Text t = factory.createText();
            t.setValue(part);
            r.getContent().add(t);
            p.getContent().add(r);
        }

        byte[] docxBytes = createDocxWithParagraph(p);
        Set<String> placeholders = templateProcessingService.extractVisiblePlaceholders(docxBytes);

        assertTrue(placeholders.contains("VALUEOFPROPERTYTABLE"),
                "5-run split <<VALUE_OF_PROPERTY_TABLE>> must be detected");
    }

    @Test
    @DisplayName("Test 4: Certified templates pass governance validation")
    void testCertifiedTemplatesPassGovernance() throws Exception {
        String[] certifiedTemplatePaths = {
            "C:/Users/Admin/Desktop/TEmplates/Final Templates/SBI Flat Below 5 Cr.docx",
            "C:/Users/Admin/Desktop/TEmplates/SBI LB Below 5 Cr.docx",
            "C:/Users/Admin/Desktop/TEmplates/Final Templates/SBI LB above 5 Cr.docx",
            "C:/Users/Admin/Desktop/TEmplates/Final Templates/Land only SBI Under 5 Cr.docx"
        };

        for (String pathStr : certifiedTemplatePaths) {
            File f = new File(pathStr);
            if (f.exists()) {
                byte[] rawBytes = Files.readAllBytes(f.toPath());
                assertDoesNotThrow(() -> {
                    templateProcessingService.validateTemplateUploadGovernance(rawBytes, f.getName());
                }, "Certified template must pass governance validation: " + f.getName());
            }
        }
    }
}
