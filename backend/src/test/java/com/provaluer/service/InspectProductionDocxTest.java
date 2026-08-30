package com.provaluer.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.util.DocxStructureParser;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;

@SpringBootTest
@ActiveProfiles("test")
public class InspectProductionDocxTest {

    @Autowired
    private DocxStructureParser parser;

    @Test
    public void inspectImagesAndPlaceholders() throws Exception {
        String path = "D:\\naga\\Valuation Report.docx";
        byte[] docxBytes = Files.readAllBytes(Paths.get(path));
        
        System.out.println("=====================================================================");
        System.out.println("STEP 1 – DOCX PARSER TRACE (VALUATION REPORT.DOCX)");
        System.out.println("=====================================================================");
        
        org.docx4j.openpackaging.packages.WordprocessingMLPackage wordMLPackage =
                org.docx4j.openpackaging.packages.WordprocessingMLPackage.load(new java.io.ByteArrayInputStream(docxBytes));
        org.docx4j.wml.Document wmlDocumentEl = wordMLPackage.getMainDocumentPart().getJaxbElement();
        org.docx4j.wml.Body body = wmlDocumentEl.getBody();
        
        java.util.List<Object> allElements = new java.util.ArrayList<>();
        new org.docx4j.TraversalUtil(body, new org.docx4j.TraversalUtil.CallbackImpl() {
            @Override
            public java.util.List<Object> apply(Object o) {
                Object unwrapped = org.docx4j.XmlUtils.unwrap(o);
                if (unwrapped instanceof org.docx4j.dml.CTNonVisualDrawingProps docPr) {
                    allElements.add(docPr);
                }
                return null;
            }
        });
        
        System.out.println("Total docPr elements discovered in DOCX: " + allElements.size());
        for (Object obj : allElements) {
            org.docx4j.dml.CTNonVisualDrawingProps docPr = (org.docx4j.dml.CTNonVisualDrawingProps) obj;
            System.out.printf("docPr [ID=%d] name=\"%s\" descr=\"%s\"%n",
                    docPr.getId(), docPr.getName(), docPr.getDescr());
        }

        JsonNode dom = parser.parseDocumentStructure(docxBytes);
        ObjectMapper mapper = new ObjectMapper().enable(com.fasterxml.jackson.databind.SerializationFeature.INDENT_OUTPUT);

        System.out.println("\n=====================================================================");
        System.out.println("STEP 2 – DOCUMENT DOM TRACE (SEARCH FOR IMG_FRONT_PAGE & IMG_PIC3)");
        System.out.println("=====================================================================");
        JsonNode sections = dom.get("sections");
        boolean foundFront = false;
        boolean foundPic3 = false;

        for (int i = 0; i < sections.size(); i++) {
            JsonNode sec = sections.get(i);
            String title = sec.get("title").asText();
            JsonNode elements = sec.get("elements");
            for (JsonNode el : elements) {
                if (el.has("runs")) {
                    for (JsonNode r : el.get("runs")) {
                        String key = r.has("placeholderKey") ? r.get("placeholderKey").asText() : "";
                        if ("IMG_FRONT_PAGE".equalsIgnoreCase(key) || "IMG_PIC3".equalsIgnoreCase(key)) {
                            System.out.printf("[Section %d: %s] Run Node: %s%n", i, title, mapper.writeValueAsString(r));
                            if ("IMG_FRONT_PAGE".equalsIgnoreCase(key)) foundFront = true;
                            if ("IMG_PIC3".equalsIgnoreCase(key)) foundPic3 = true;
                        }
                    }
                }
                if (el.has("rows")) {
                    for (JsonNode row : el.get("rows")) {
                        if (row.has("cells")) {
                            for (JsonNode cell : row.get("cells")) {
                                if (cell.has("placeholderBindings")) {
                                    for (JsonNode b : cell.get("placeholderBindings")) {
                                        String key = b.has("key") ? b.get("key").asText() : "";
                                        if ("IMG_FRONT_PAGE".equalsIgnoreCase(key) || "IMG_PIC3".equalsIgnoreCase(key)) {
                                            System.out.printf("[Section %d: %s] Cell Binding Node: %s%n", i, title, mapper.writeValueAsString(b));
                                            if ("IMG_FRONT_PAGE".equalsIgnoreCase(key)) foundFront = true;
                                            if ("IMG_PIC3".equalsIgnoreCase(key)) foundPic3 = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        System.out.println("DOM Search Result: IMG_FRONT_PAGE found = " + foundFront + ", IMG_PIC3 found = " + foundPic3);
        System.out.println("\nPlaceholders Summary Array Items for Images:");
        JsonNode summary = dom.get("placeholdersSummary");
        if (summary != null && summary.isArray()) {
            for (JsonNode item : summary) {
                String key = item.has("key") ? item.get("key").asText() : "";
                if ("IMG_FRONT_PAGE".equalsIgnoreCase(key) || "IMG_PIC3".equalsIgnoreCase(key)) {
                    System.out.println(mapper.writeValueAsString(item));
                }
            }
        }
    }
}
