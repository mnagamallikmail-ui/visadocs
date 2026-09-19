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
}
