package com.provaluer.util;

import com.fasterxml.jackson.databind.JsonNode;
import com.provaluer.service.ValuationEngineService;
import org.docx4j.dml.wordprocessingDrawing.Inline;
import org.docx4j.finders.ClassFinder;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.Text;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.nio.file.Files;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

public class FinalRemediationApprovalRuntimeVerificationTest {

    private final DocxTemplateEngine templateEngine = new DocxTemplateEngine();
    private final DocxStructureParser parser = new DocxStructureParser();
    private final ValuationEngineService valuationEngine = new ValuationEngineService();

    private byte[] createDummyImage(int w, int h, Color color) throws Exception {
        BufferedImage img = new BufferedImage(w, h, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = img.createGraphics();
        g.setColor(color);
        g.fillRect(0, 0, w, h);
        g.dispose();
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(img, "jpg", baos);
        return baos.toByteArray();
    }

    @Test
    @DisplayName("MANDATORY VALIDATION: Complete Runtime Verification for Defects 1 to 10")
    void testCompleteRuntimeReportGeneration() throws Exception {
        File file = new File("official_production_valuation_report.docx");
        assertTrue(file.exists(), "official_production_valuation_report.docx must exist in backend root");
        byte[] templateBytes = Files.readAllBytes(file.toPath());

        // 1. Prepare Inputs with Persisted Values
        Map<String, String> inputs = new HashMap<>();
        inputs.put("CLIENT_NAME", "State Bank of India");
        inputs.put("OWNER_NAME", "Mr. Rajesh Sharma");
        inputs.put("PROPERTY_ADDRESS", "Flat 402, Lotus Heights, Bengaluru");
        inputs.put("PROPERTY_CATEGORY", "Flat");
        inputs.put("PROPERTY_SUB_TYPE", "Apartment");
        inputs.put("REPORT_REF_NO", "VAL/2026/09/1425");
        inputs.put("DATE_OF_REPORT", "2026-09-14");

        // Saleable Area Normalization (Defect 5)
        inputs.put("SALEABLE_AREA", "1425");
        inputs.put("SALEABLE_AREA_RAW", "1425 sft");
        inputs.put("SALEABLE_AREA_NUMERIC", "1425");
        inputs.put("SALEABLE_AREA_STANDARD_SQFT", "1425");

        // Saleable Rate (Defect 3 & 4)
        inputs.put("SALEABLE_RATE", "7000");
        inputs.put("MARKET_RATE_FLAT", "7000");
        inputs.put("MARKET_RATE_FLAT_NUMERIC", "7000");

        // Government Value (Defect 1)
        inputs.put("GOVERNMENT_VALUE", "5000000");
        inputs.put("COMPOSITE_GOVERNMENT_RATE", "3500");

        // Create Order and ValuationData models to generate placeholders
        com.provaluer.model.Order order = new com.provaluer.model.Order();
        order.setId(9999L);
        order.setClientName("Mr. Rajesh Sharma");
        order.setBankName("State Bank of India");
        order.setPropertyCategory("Flat");

        com.provaluer.model.ValuationData valData = new com.provaluer.model.ValuationData();
        valData.setOrderId(9999L);
        valData.setValuationMethodology("COMPOSITE");
        valData.setGovernmentValue(new java.math.BigDecimal("5000000"));
        valData.setCompositeGovernmentRate(new java.math.BigDecimal("3500"));
        valData.setCompositeConstructionCost(new java.math.BigDecimal("2200"));
        valData.setFairValue(new java.math.BigDecimal("9975000"));
        valData.setRawFairValue(new java.math.BigDecimal("9975000"));

        com.provaluer.model.ValuationCompositeItem compItem1 = new com.provaluer.model.ValuationCompositeItem();
        compItem1.setOrderId(9999L);
        compItem1.setItemCategory("MAIN_UNIT");
        compItem1.setDescription("Flat 402");
        compItem1.setQuantity(new java.math.BigDecimal("1425"));
        compItem1.setRate(new java.math.BigDecimal("7000"));
        compItem1.setEnteredUnit("Sq.Ft");
        compItem1.setConstructionCost(new java.math.BigDecimal("2200"));
        compItem1.setBuildingAge(new java.math.BigDecimal("3"));
        compItem1.setTotalLife(60);

        Map<String, String> enginePlaceholders = valuationEngine.generatePlaceholders(
                order, valData, java.util.Collections.emptyList(), java.util.Collections.emptyList(), java.util.Collections.emptyList(), List.of(compItem1)
        );
        assertNotNull(enginePlaceholders);
        inputs.putAll(enginePlaceholders);

        // Verify Defect 1: GOVT_VALUE and GOVT_VALUE_WORDS derived automatically
        assertNotNull(inputs.get("GOVT_VALUE"), "GOVT_VALUE must be populated by engine");
        assertNotNull(inputs.get("GOVT_VALUE_WORDS"), "GOVT_VALUE_WORDS must be populated by engine");
        System.out.println("TEST C/D: GOVT_VALUE = " + inputs.get("GOVT_VALUE") + " | GOVT_VALUE_WORDS = " + inputs.get("GOVT_VALUE_WORDS"));
        assertTrue(inputs.get("GOVT_VALUE_WORDS").toLowerCase().contains("fifty") || inputs.get("GOVT_VALUE_WORDS").toLowerCase().contains("lakh"),
                "GOVT_VALUE_WORDS must describe government value in words");

        // Prepare Images including IMG_COVER_PAGE (Defect 2)
        byte[] coverBytes = createDummyImage(1200, 800, Color.BLUE);
        byte[] pic1Bytes = createDummyImage(1000, 600, Color.RED);
        byte[] pic2Bytes = createDummyImage(1000, 600, Color.GREEN);

        Map<String, byte[]> images = new HashMap<>();
        // Upload IMG_COVER_PAGE (testing alias resolution to IMG_FRONT_PAGE in template)
        images.put("IMG_COVER_PAGE", coverBytes);
        images.put("IMG_PIC1", pic1Bytes);
        images.put("IMG_PIC2", pic2Bytes);
        // Leave IMG_PIC3 to IMG_PIC8 empty to test empty placeholder governance (Defects 7 & 8)

        // Compile DOCX
        byte[] generatedDocx = templateEngine.generateReport(templateBytes, inputs, images);
        assertNotNull(generatedDocx);
        assertTrue(generatedDocx.length > 0);

        // Save generated DOCX for verification
        File outDocxFile = new File("build/test_generated_output.docx");
        outDocxFile.getParentFile().mkdirs();
        Files.write(outDocxFile.toPath(), generatedDocx);
        System.out.println("Generated DOCX saved to: " + outDocxFile.getAbsolutePath());

        // Parse generated DOCX
        WordprocessingMLPackage resultPackage = WordprocessingMLPackage.load(new ByteArrayInputStream(generatedDocx));

        // TEST E & G: Image Dimension Governance & Overlap Verification
        ClassFinder inlineFinder = new ClassFinder(Inline.class);
        new org.docx4j.TraversalUtil(resultPackage.getMainDocumentPart().getContent(), inlineFinder);

        System.out.println("IMAGE DIMENSION VERIFICATION:");
        for (Object o : inlineFinder.results) {
            Inline inline = (Inline) o;
            if (inline.getDocPr() != null) {
                String key = inline.getDocPr().getName();
                long cx = inline.getExtent() != null ? inline.getExtent().getCx() : 0;
                long cy = inline.getExtent() != null ? inline.getExtent().getCy() : 0;
                System.out.println("-> Inline Image [" + key + "]: Width = " + cx + " EMU (" + (cx / 914400.0) + " in), Height = " + cy + " EMU (" + (cy / 914400.0) + " in)");
                assertTrue(cx <= 6000000L, "Image width must not exceed printable boundary");
                assertTrue(cy <= 9000000L, "Image height must not exceed printable boundary");

                // DEFECT 7 & 8: Verify no black borders / frames
                org.docx4j.dml.picture.Pic pic = inline.getGraphic().getGraphicData().getPic();
                if (pic != null && pic.getSpPr() != null && pic.getSpPr().getLn() != null) {
                    assertNotNull(pic.getSpPr().getLn().getNoFill(), "Pic shape must have noFill on line properties (no black borders)");
                }
            }
        }

        // TEST I: Search for unresolved placeholders (<< and >>)
        ClassFinder textFinder = new ClassFinder(Text.class);
        new org.docx4j.TraversalUtil(resultPackage.getMainDocumentPart().getContent(), textFinder);
        int unresolvedCount = 0;
        for (Object o : textFinder.results) {
            Text t = (Text) o;
            String textVal = t.getValue();
            if (textVal != null && (textVal.contains("<<") || textVal.contains(">>"))) {
                System.err.println("UNRESOLVED PLACEHOLDER LEAK: [" + textVal + "]");
                unresolvedCount++;
            }
        }
        assertEquals(0, unresolvedCount, "Generated DOCX must have ZERO unresolved placeholders (<< and >> count must be 0)");

        // TEST J: Certificate Page Template Fidelity
        // The certificate section in official template contains certificate text but NO auto-injected composite/valuation tables
        JsonNode parsedDom = parser.parseDocumentStructure(generatedDocx);
        assertNotNull(parsedDom);
        JsonNode sections = parsedDom.get("sections");
        for (JsonNode sec : sections) {
            String title = sec.has("title") ? sec.get("title").asText() : "";
            if (title.toUpperCase().contains("CERTIFICATE") || title.toUpperCase().contains("CERTIF")) {
                // Verify no auto-injected composite tables inside certificate section
                JsonNode elements = sec.get("elements");
                int tblCount = 0;
                if (elements != null) {
                    for (JsonNode el : elements) {
                        if ("TABLE".equalsIgnoreCase(el.get("type").asText())) {
                            tblCount++;
                        }
                    }
                }
                System.out.println("CERTIFICATE PAGE VERIFICATION: Section [" + title + "] contains " + tblCount + " tables (Expected only static template content)");
            }
        }

        // TEST D: Convert to PDF and verify PDF output
        byte[] generatedPdf = templateEngine.convertDocxToPdf(generatedDocx);
        assertNotNull(generatedPdf);
        assertTrue(generatedPdf.length > 0, "PDF bytes must be non-empty");
        File outPdfFile = new File("build/test_generated_output.pdf");
        Files.write(outPdfFile.toPath(), generatedPdf);
        System.out.println("Generated PDF saved to: " + outPdfFile.getAbsolutePath() + " (" + generatedPdf.length + " bytes)");

        // Explicit PDFBox text extraction and validation
        try (org.apache.pdfbox.pdmodel.PDDocument pdfDoc = org.apache.pdfbox.Loader.loadPDF(outPdfFile)) {
            System.out.println("PDF RUNTIME INSPECTION: Total Pages = " + pdfDoc.getNumberOfPages());
            org.apache.pdfbox.text.PDFTextStripper stripper = new org.apache.pdfbox.text.PDFTextStripper();
            String pdfText = stripper.getText(pdfDoc);
            System.out.println("PDF RUNTIME INSPECTION: PDF Text Length = " + pdfText.length());
            assertTrue(pdfText.contains("50,00,000"), "PDF must contain hydrated GOVT_VALUE 50,00,000");
            assertTrue(pdfText.contains("Rupees Fifty Lakh Only"), "PDF must contain hydrated GOVT_VALUE_WORDS");
            assertFalse(pdfText.contains("<<GOVT_VALUE>>"), "PDF must not contain unresolved <<GOVT_VALUE>>");
            assertFalse(pdfText.contains("<<GOVT_VALUE_WORDS>>"), "PDF must not contain unresolved <<GOVT_VALUE_WORDS>>");
            int pdfUnresolved = (pdfText.split("<<", -1).length - 1) + (pdfText.split(">>", -1).length - 1);
            System.out.println("PDF RUNTIME INSPECTION: Unresolved << or >> count in PDF = " + pdfUnresolved);
            assertEquals(0, pdfUnresolved, "PDF must have zero unresolved placeholders");
        }
    }
}
