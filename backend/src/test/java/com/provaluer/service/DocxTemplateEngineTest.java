package com.provaluer.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.util.DocxTemplateEngine;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.io.ByteArrayOutputStream;
import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class DocxTemplateEngineTest {

    @Autowired
    private DocxTemplateEngine templateEngine;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    public void testParseTemplatePlaceholderTypes() throws Exception {
        // Construct a mock document
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        ObjectFactory factory = new ObjectFactory();

        // Add a paragraph with different placeholder categories
        P p = factory.createP();
        R r = factory.createR();
        Text t = factory.createText();
        t.setValue("Verify text <<CLIENT_NAME>>, date <<date_inspection>>, suffix date <<inspection_date>>, and image <<IMG_SITE_MAP>>.");
        r.getContent().add(t);
        p.getContent().add(r);
        wordMLPackage.getMainDocumentPart().getContent().add(p);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wordMLPackage.save(out);
        byte[] docxBytes = out.toByteArray();

        // Normalize and parse
        byte[] normalized = templateEngine.normalizeTemplate(docxBytes);
        String schemaJson = templateEngine.parseTemplate(normalized);

        // Assert schema details
        JsonNode root = objectMapper.readTree(schemaJson);
        assertTrue(root.has("fields"));
        JsonNode fields = root.get("fields");
        assertTrue(fields.isArray());
        
        Map<String, JsonNode> fieldMap = new HashMap<>();
        for (JsonNode field : fields) {
            fieldMap.put(field.get("key").asText(), field);
        }

        // 1. Text Field: CLIENT_NAME
        assertTrue(fieldMap.containsKey("CLIENT_NAME"));
        assertEquals("TEXT", fieldMap.get("CLIENT_NAME").get("type").asText());
        assertEquals("Client Name", fieldMap.get("CLIENT_NAME").get("label").asText());

        // 2. Date Fields
        assertTrue(fieldMap.containsKey("DATE_INSPECTION"));
        assertEquals("DATE", fieldMap.get("DATE_INSPECTION").get("type").asText());
        assertEquals("Inspection", fieldMap.get("DATE_INSPECTION").get("label").asText());

        assertTrue(fieldMap.containsKey("INSPECTION_DATE"));
        assertEquals("DATE", fieldMap.get("INSPECTION_DATE").get("type").asText());
        assertEquals("Inspection", fieldMap.get("INSPECTION_DATE").get("label").asText());

        // 3. Image Field
        assertTrue(fieldMap.containsKey("IMG_SITE_MAP"));
        assertEquals("IMAGE", fieldMap.get("IMG_SITE_MAP").get("type").asText());
        assertEquals("Site Map", fieldMap.get("IMG_SITE_MAP").get("label").asText());
    }

    @Test
    public void testSubstituteImageAndEmptyDate() throws Exception {
        java.io.File file = new java.io.File("sample_template.docx");
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.load(file);
        ObjectFactory factory = new ObjectFactory();

        // 1. Add text run with empty date placeholder
        P pText = factory.createP();
        R rText = factory.createR();
        Text textElem = factory.createText();
        textElem.setValue("Report Date: <<DATE_TEST>>");
        rText.getContent().add(textElem);
        pText.getContent().add(rText);
        wordMLPackage.getMainDocumentPart().getContent().add(pText);

        // 2. Add drawing image placeholder
        P pImg = factory.createP();
        R rImg = factory.createR();
        
        // Standard tiny 1x1 pixel PNG bytes
        byte[] dummyImgBytes = new byte[]{
            (byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
            0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, (byte) 0xC4, (byte) 0x89, 0x00, 0x00, 0x00,
            0x0B, 0x49, 0x44, 0x41, 0x54, 0x08, (byte) 0xD7, 0x63, 0x60, 0x00, 0x02, 0x00,
            0x00, 0x05, 0x00, 0x01, (byte) 0xE2, 0x26, (byte) 0xB5, (byte) 0x9B, 0x00, 0x00, 0x00,
            0x00, 0x49, 0x45, 0x4E, 0x44, (byte) 0xAE, 0x42, 0x60, (byte) 0x82
        };
        
        org.docx4j.openpackaging.parts.WordprocessingML.BinaryPartAbstractImage imagePart = 
            org.docx4j.openpackaging.parts.WordprocessingML.BinaryPartAbstractImage.createImagePart(wordMLPackage, dummyImgBytes);
        org.docx4j.dml.wordprocessingDrawing.Inline inlineObj = imagePart.createImageInline("Uploaded Image", "Image", 101, 102, false);
        inlineObj.getDocPr().setName("IMG_FRONT_PAGE");
        inlineObj.getDocPr().setDescr("IMG_FRONT_PAGE");
        
        Drawing drawing = factory.createDrawing();
        drawing.getAnchorOrInline().add(inlineObj);
        rImg.getContent().add(drawing);
        pImg.getContent().add(rImg);
        wordMLPackage.getMainDocumentPart().getContent().add(pImg);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wordMLPackage.save(out);
        byte[] docxBytes = out.toByteArray();

        // Prepare substitution inputs
        Map<String, String> inputs = new HashMap<>();
        inputs.put("DATE_TEST", ""); // empty date
        
        // Simulating the controller fallback for empty date
        for (Map.Entry<String, String> entry : new HashMap<>(inputs).entrySet()) {
            String key = entry.getKey();
            String val = entry.getValue();
            if (key.contains("DATE") && (val == null || val.trim().isEmpty())) {
                inputs.put(key, "2026-05-30");
            }
        }

        Map<String, byte[]> images = new HashMap<>();
        images.put("IMG_FRONT_PAGE", dummyImgBytes);

        // Run hydration/substitution
        byte[] hydratedDocx = templateEngine.generateReport(docxBytes, inputs, images);

        // Verify result can be loaded and processed without throwing XML/marshalling exceptions
        WordprocessingMLPackage resultPackage = WordprocessingMLPackage.load(new java.io.ByteArrayInputStream(hydratedDocx));
        assertNotNull(resultPackage);
        
        // Verify date substitution
        String textResult = resultPackage.getMainDocumentPart().getXML();
        assertTrue(textResult.contains("2026-05-30"));
    }
}
