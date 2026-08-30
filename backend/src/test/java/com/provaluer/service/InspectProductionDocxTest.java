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
        JsonNode dom = parser.parseDocumentStructure(docxBytes);
        String registry = parser.generatePlaceholderRegistry(dom);

        System.out.println("=== INSPECT PRODUCTION DOCX PLACEHOLDERS ===");
        JsonNode sections = dom.get("sections");
        System.out.println("Total sections: " + sections.size());

        for (int i = 0; i < sections.size(); i++) {
            JsonNode sec = sections.get(i);
            String title = sec.get("title").asText();
            JsonNode elements = sec.get("elements");
            for (JsonNode el : elements) {
                String type = el.get("type").asText();
                if ("PARAGRAPH".equals(type)) {
                    JsonNode runs = el.get("runs");
                    for (JsonNode r : runs) {
                        if (r.has("isPlaceholder") && r.get("isPlaceholder").asBoolean()) {
                            System.out.printf("[SEC %d: %s] Paragraph Run Placeholder: key=%s, fieldType=%s, text=%s%n",
                                    i, title,
                                    r.get("placeholderKey").asText(),
                                    r.has("fieldType") ? r.get("fieldType").asText() : "N/A",
                                    r.get("text").asText());
                        }
                    }
                } else if ("TABLE".equals(type)) {
                    if (el.has("questionAnswerBindings")) {
                        for (JsonNode b : el.get("questionAnswerBindings")) {
                            System.out.printf("[SEC %d: %s] Table Binding Placeholder: key=%s, fieldType=%s, question=%s%n",
                                    i, title,
                                    b.get("placeholderKey").asText(),
                                    b.has("fieldType") ? b.get("fieldType").asText() : "N/A",
                                    b.get("questionText").asText());
                        }
                    }
                }
            }
        }

        System.out.println("\n=== PLACEHOLDER REGISTRY ===");
        System.out.println(new ObjectMapper().writerWithDefaultPrettyPrinter().writeValueAsString(dom.get("placeholdersSummary")));
    }
}
