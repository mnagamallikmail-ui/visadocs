package com.provaluer.util;

import org.docx4j.dml.wordprocessingDrawing.Anchor;
import org.docx4j.dml.wordprocessingDrawing.Inline;
import org.docx4j.finders.ClassFinder;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.Tbl;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class PhotoGridAnchorRemovalTest {

    @Autowired
    private DocxTemplateEngine templateEngine;

    private byte[] createTestImage(int width, int height, Color color, String label) throws Exception {
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = image.createGraphics();
        g.setColor(color);
        g.fillRect(0, 0, width, height);
        g.setColor(Color.WHITE);
        g.setFont(new Font("Arial", Font.BOLD, 24));
        g.drawString(label, 20, height / 2);
        g.dispose();

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", baos);
        return baos.toByteArray();
    }

    @Test
    @DisplayName("Verify legacy IMG_PIC anchors removed and only photo grid table remains")
    void testLegacyPhotoAnchorsRemoved() throws Exception {
        String templatePath = "D:\\naga\\Valuation Report.docx";
        if (!new File(templatePath).exists()) {
            templatePath = "official_production_valuation_report.docx";
        }
        byte[] tplBytes = Files.readAllBytes(Paths.get(templatePath));

        Map<String, String> inputs = new HashMap<>();
        inputs.put("PROPERTY_ADDRESS", "Validation Site Address");
        inputs.put("NAME_OF_THE_OWNER", "Test Owner");

        Map<String, byte[]> images = new HashMap<>();
        images.put("IMG_FRONT_PAGE", createTestImage(800, 600, Color.BLACK, "COVER"));
        for (int i = 1; i <= 8; i++) {
            images.put("IMG_PIC" + i, createTestImage(800, 600, Color.BLUE, "PIC" + i));
        }

        byte[] generatedDocx = templateEngine.generateReport(tplBytes, inputs, images);
        assertNotNull(generatedDocx);

        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(generatedDocx));

        // 1. Verify that ZERO wp:anchor elements in the final DOCX have IMG_PIC in their description or name
        ClassFinder anchorFinder = new ClassFinder(Anchor.class);
        new org.docx4j.TraversalUtil(pkg.getMainDocumentPart().getContent(), anchorFinder);
        
        int legacyAnchorCount = 0;
        for (Object o : anchorFinder.results) {
            Anchor anchor = (Anchor) o;
            if (anchor.getDocPr() != null) {
                String descr = anchor.getDocPr().getDescr();
                String name = anchor.getDocPr().getName();
                if ((descr != null && descr.toUpperCase().contains("IMG_PIC")) ||
                    (name != null && name.toUpperCase().contains("IMG_PIC"))) {
                    legacyAnchorCount++;
                }
            }
        }
        assertEquals(0, legacyAnchorCount, "There must be ZERO legacy IMG_PIC wp:anchor drawings remaining in final DOCX");

        // 2. Verify photo grid table exists and contains the images as Inline
        ClassFinder tableFinder = new ClassFinder(Tbl.class);
        new org.docx4j.TraversalUtil(pkg.getMainDocumentPart().getContent(), tableFinder);
        
        boolean foundPhotoGridTable = false;
        for (Object o : tableFinder.results) {
            Tbl tbl = (Tbl) o;
            ClassFinder inlineFinder = new ClassFinder(Inline.class);
            new org.docx4j.TraversalUtil(tbl, inlineFinder);
            if (inlineFinder.results.size() >= 8) {
                foundPhotoGridTable = true;
                break;
            }
        }
        assertTrue(foundPhotoGridTable, "The generated photo grid table with >= 8 Inline images must be present in the final DOCX");

        System.out.println("-> SUCCESS: Legacy IMG_PIC wp:anchor count = 0, photo grid table successfully generated and isolated.");
    }

    @Test
    @DisplayName("Verify legacy placeholders IMG_1..IMG_5, IM_6, IMG_7..IMG_8 activate photo grid and eliminate wp:anchor overlap")
    void testProductionTemplateWithLegacyPlaceholdersAndIm6() throws Exception {
        File tplFile = new File("official_production_valuation_report.docx");
        if (!tplFile.exists()) {
            tplFile = new File("D:\\naga\\Valuation Report.docx");
        }
        assertTrue(tplFile.exists(), "Production template must exist");
        byte[] tplBytes = Files.readAllBytes(tplFile.toPath());

        // Count anchors before generation
        WordprocessingMLPackage initialPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(tplBytes));
        ClassFinder initialAnchorFinder = new ClassFinder(Anchor.class);
        new org.docx4j.TraversalUtil(initialPkg.getMainDocumentPart().getContent(), initialAnchorFinder);
        int initialPhotoAnchorCount = 0;
        for (Object o : initialAnchorFinder.results) {
            Anchor anchor = (Anchor) o;
            if (anchor.getDocPr() != null) {
                String descr = anchor.getDocPr().getDescr() != null ? anchor.getDocPr().getDescr() : "";
                String name = anchor.getDocPr().getName() != null ? anchor.getDocPr().getName() : "";
                String combined = (descr + " " + name).toUpperCase();
                if (combined.contains("IMG_") || combined.contains("IM_6") || combined.contains("PIC")) {
                    if (!combined.contains("FRONT_PAGE") && !combined.contains("COVER")) {
                        initialPhotoAnchorCount++;
                    }
                }
            }
        }
        System.out.println("-> Before: Initial site photo wp:anchor drawings count = " + initialPhotoAnchorCount);

        Map<String, String> inputs = new HashMap<>();
        inputs.put("PROPERTY_ADDRESS", "123 Commercial Boulevard, Industrial Park");
        inputs.put("NAME_OF_THE_OWNER", "Legacy Test Holdings Ltd");
        inputs.put("BORROWER_NAME", "Legacy Test Holdings Ltd");
        inputs.put("VALUATION_DATE", "2026-09-28");
        inputs.put("REPORT_REF_NO", "VAL/2026/LEGACY/001");

        // Supply photos using BOTH legacy and standard keys
        Map<String, byte[]> images = new HashMap<>();
        images.put("IMG_FRONT_PAGE", createTestImage(800, 600, Color.DARK_GRAY, "COVER_PAGE"));
        images.put("IMG_1", createTestImage(800, 600, Color.RED, "PHOTO 1"));
        images.put("IMG_2", createTestImage(800, 600, Color.GREEN, "PHOTO 2"));
        images.put("IMG_3", createTestImage(800, 600, Color.BLUE, "PHOTO 3"));
        images.put("IMG_4", createTestImage(800, 600, Color.ORANGE, "PHOTO 4"));
        images.put("IMG_5", createTestImage(800, 600, Color.MAGENTA, "PHOTO 5"));
        images.put("IM_6", createTestImage(800, 600, Color.CYAN, "PHOTO 6 (IM_6)"));
        images.put("IMG_7", createTestImage(800, 600, Color.YELLOW, "PHOTO 7"));
        images.put("IMG_8", createTestImage(800, 600, Color.PINK, "PHOTO 8"));

        byte[] generatedDocx = templateEngine.generateReport(tplBytes, inputs, images);
        assertNotNull(generatedDocx);

        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(generatedDocx));

        // 1. Verify ZERO site photograph wp:anchor drawings remain
        ClassFinder finalAnchorFinder = new ClassFinder(Anchor.class);
        new org.docx4j.TraversalUtil(pkg.getMainDocumentPart().getContent(), finalAnchorFinder);
        int finalPhotoAnchorCount = 0;
        for (Object o : finalAnchorFinder.results) {
            Anchor anchor = (Anchor) o;
            if (anchor.getDocPr() != null) {
                String descr = anchor.getDocPr().getDescr() != null ? anchor.getDocPr().getDescr().trim() : "";
                String name = anchor.getDocPr().getName() != null ? anchor.getDocPr().getName().trim() : "";
                String combined = (descr + " " + name).toUpperCase();
                System.out.println("Remaining anchor: name='" + name + "', descr='" + descr + "', id=" + anchor.getDocPr().getId());
                // Identify site photograph placeholders: IMG_1..8, IM_6, IMG_PIC1..8
                if (combined.matches(".*\\b(IMG_PIC[1-8]|IMG_[1-8]|IM_6|PIC[1-8])\\b.*") ||
                    descr.matches(".*(IMG_PIC[1-8]|IMG_[1-8]|IM_6).*") ||
                    name.matches(".*(IMG_PIC[1-8]|IMG_[1-8]|IM_6).*")) {
                    finalPhotoAnchorCount++;
                }
            }
        }
        System.out.println("-> After: Final site photo wp:anchor drawings count = " + finalPhotoAnchorCount);
        assertEquals(0, finalPhotoAnchorCount, "All legacy site photo wp:anchor drawings must be removed");

        // 2. Verify exactly one photo grid table exists and contains wp:inline images
        ClassFinder tableFinder = new ClassFinder(Tbl.class);
        new org.docx4j.TraversalUtil(pkg.getMainDocumentPart().getContent(), tableFinder);
        int photoGridTableCount = 0;
        int inlineImageCountInGrid = 0;
        for (Object o : tableFinder.results) {
            Tbl tbl = (Tbl) o;
            ClassFinder inlineFinder = new ClassFinder(Inline.class);
            new org.docx4j.TraversalUtil(tbl, inlineFinder);
            if (inlineFinder.results.size() >= 8) {
                photoGridTableCount++;
                inlineImageCountInGrid = inlineFinder.results.size();
            }
        }
        assertEquals(1, photoGridTableCount, "Exactly one photo grid table must exist");
        assertEquals(8, inlineImageCountInGrid, "Photo grid table must contain 8 wp:inline images");

        System.out.println("-> SUCCESS: Photo grid table count = " + photoGridTableCount + ", wp:inline count = " + inlineImageCountInGrid);
        System.out.println("-> SUCCESS: Zero wp:anchor drawings for site photos. Overlap eliminated.");
    }
}
