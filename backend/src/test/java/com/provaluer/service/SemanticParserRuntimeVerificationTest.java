package com.provaluer.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.DocumentWorkspaceResponse;
import com.provaluer.model.Order;
import com.provaluer.model.Template;
import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.TemplateRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.util.DocxStructureParser;
import com.provaluer.util.DocxTemplateEngine;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.math.BigInteger;
import java.util.Collections;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class SemanticParserRuntimeVerificationTest {

    @Autowired
    private DocxStructureParser docxStructureParser;

    @Autowired
    private DocxTemplateEngine templateEngine;

    @Autowired
    private TemplateRepository templateRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DocumentWorkspaceService documentWorkspaceService;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final ObjectFactory factory = new ObjectFactory();

    private byte[] createValuationDocxPackage() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();

        // 1. Cover Letter Section Paragraph with PROPERTY_ADDRESS
        P p1 = factory.createP();
        R r1 = factory.createR();
        Text t1 = factory.createText();
        t1.setValue("Valuation Report for <<CLIENT_NAME>> regarding property located at <<PROPERTY_ADDRESS>>.");
        r1.getContent().add(t1);
        p1.getContent().add(r1);
        wordMLPackage.getMainDocumentPart().getContent().add(p1);

        // 2. Executive Summary Paragraph with repeated PROPERTY_ADDRESS
        P p2 = factory.createP();
        R r2 = factory.createR();
        Text t2 = factory.createText();
        t2.setValue("Executive Summary: Inspected site at <<PROPERTY_ADDRESS>> on <<INSPECTION_DATE>>.");
        r2.getContent().add(t2);
        p2.getContent().add(r2);
        wordMLPackage.getMainDocumentPart().getContent().add(p2);

        // 3. Section Table: Details of Property
        Tbl table = factory.createTbl();

        // Table Header (Row 0)
        Tr row0 = factory.createTr();
        row0.getContent().add(createCell("S.No"));
        row0.getContent().add(createCell("Particulars"));
        row0.getContent().add(createCell("Observed Details"));
        table.getContent().add(row0);

        // Row 1: 3-column Q&A for Name of owner(s) and address -> <<CLIENT_NAME>>
        Tr row1 = factory.createTr();
        row1.getContent().add(createCell("1"));
        row1.getContent().add(createCell("Name of owner(s) and address"));
        row1.getContent().add(createCell("<<CLIENT_NAME>>"));
        table.getContent().add(row1);

        // Row 2: 3-column Q&A for Postal address of property -> <<PROPERTY_ADDRESS>>
        Tr row2 = factory.createTr();
        row2.getContent().add(createCell("2"));
        row2.getContent().add(createCell("Postal address of property"));
        row2.getContent().add(createCell("<<PROPERTY_ADDRESS>>"));
        table.getContent().add(row2);

        // Row 3: 2-column Q&A for Purpose of Valuation -> <<VALUATION_PURPOSE>>
        Tr row3 = factory.createTr();
        row3.getContent().add(createCell("Purpose of Valuation"));
        row3.getContent().add(createCell("<<VALUATION_PURPOSE>>"));
        table.getContent().add(row3);

        wordMLPackage.getMainDocumentPart().getContent().add(table);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wordMLPackage.save(out);
        return out.toByteArray();
    }

    private Tc createCell(String text) {
        Tc cell = factory.createTc();
        P p = factory.createP();
        R r = factory.createR();
        Text t = factory.createText();
        t.setValue(text);
        r.getContent().add(t);
        p.getContent().add(r);
        cell.getContent().add(p);
        return cell;
    }

    @Test
    @DisplayName("End-to-End Runtime Semantic Verification")
    @Transactional
    public void testRuntimeSemanticVerification() throws Exception {
        byte[] docxBytes = createValuationDocxPackage();
        byte[] normalized = templateEngine.normalizeTemplate(docxBytes);

        // Task 1 & 6: Parse Document DOM and Placeholder Registry
        JsonNode domNode = docxStructureParser.parseDocumentStructure(normalized);
        String domJson = domNode.toString();
        String registryJson = docxStructureParser.generatePlaceholderRegistry(domNode);

        Template template = new Template();
        template.setName("Official Commercial Valuation Template");
        template.setTemplateContent(normalized);
        template.setDocumentDom(domJson);
        template.setPlaceholderRegistry(registryJson);
        template.setFieldMapping("{}");
        template.setIsActive("Y");
        template.setStatus("CONFIRMED");

        Template savedTemplate = templateRepository.save(template);

        System.out.println("=== TASK 1: DATABASE EVIDENCE ===");
        System.out.println("Template ID: " + savedTemplate.getId());
        System.out.println("Template Version: " + savedTemplate.getVersion());
        System.out.println("document_dom length: " + savedTemplate.getDocumentDom().length() + " chars");
        System.out.println("placeholder_registry length: " + savedTemplate.getPlaceholderRegistry().length() + " chars");

        assertNotNull(savedTemplate.getId());
        assertTrue(savedTemplate.getDocumentDom().length() > 0);

        // Task 2: Verify "Name of owner(s) and address" table row
        System.out.println("\n=== TASK 2: DOCUMENT_DOM TABLE ROW EXCERPT ===");
        JsonNode tableNode = domNode.get("sections").get(0).get("elements").get(2);
        JsonNode row1 = tableNode.get("rows").get(1);
        System.out.println(objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(row1));

        assertEquals("QUESTION_ANSWER", row1.get("rowType").asText());
        assertEquals("INDEX", row1.get("cells").get(0).get("cellRole").asText());
        assertEquals("QUESTION", row1.get("cells").get(1).get("cellRole").asText());
        assertEquals("Name of owner(s) and address", row1.get("cells").get(1).get("plainText").asText());
        assertEquals("ANSWER", row1.get("cells").get(2).get("cellRole").asText());

        // Task 3: Verify placeholdersSummary entry for CLIENT_NAME
        System.out.println("\n=== TASK 3: PLACEHOLDERS_SUMMARY FOR CLIENT_NAME ===");
        JsonNode summaryList = domNode.get("placeholdersSummary");
        JsonNode clientNameSummary = null;
        JsonNode propertyAddressSummary = null;

        for (JsonNode item : summaryList) {
            if ("CLIENT_NAME".equals(item.get("key").asText())) {
                clientNameSummary = item;
            } else if ("PROPERTY_ADDRESS".equals(item.get("key").asText())) {
                propertyAddressSummary = item;
            }
        }

        assertNotNull(clientNameSummary);
        System.out.println(objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(clientNameSummary));

        assertEquals("Name of owner(s) and address", clientNameSummary.get("questionText").asText());
        assertEquals("1", clientNameSummary.get("serialNo").asText());
        assertEquals(2, clientNameSummary.get("occurrences").asInt());
        assertTrue(clientNameSummary.has("tableContext"));

        // Task 4: GET /api/v1/orders/{id}/document-workspace integration
        User user = new User("valuer_admin@test.com", "secret", UserRole.SUPER_ADMIN, "9999999999", "v1");
        user.setFullName("Valuer Admin");
        User savedUser = userRepository.save(user);

        Order order = new Order();
        order.setReportNumber("PV-TEST-001");
        order.setClientName("Acme Corp");
        order.setClientId(savedUser.getId());
        order.setTemplateId(savedTemplate.getId());
        order.setPurpose("Valuation");
        order.setPropertyCategory("Commercial");
        order.setStatus("IN_PROGRESS");
        order.setDocumentDomSnapshot(domJson);
        Order savedOrder = orderRepository.save(order);

        com.provaluer.security.UserDetailsImpl principal = com.provaluer.security.UserDetailsImpl.build(savedUser);

        DocumentWorkspaceResponse workspaceResponse = documentWorkspaceService.getDocumentWorkspace(savedOrder.getId(), principal);
        assertNotNull(workspaceResponse);
        assertNotNull(workspaceResponse.getDocumentDom());

        System.out.println("\n=== TASK 4: WORKSPACE API RESPONSE EXCERPT ===");
        System.out.println("Order ID: " + workspaceResponse.getOrderId());
        System.out.println("Report Number: " + workspaceResponse.getReportNumber());
        System.out.println("documentDom Present: " + (workspaceResponse.getDocumentDom() != null));
        System.out.println("Sections in Workspace DOM: " + workspaceResponse.getDocumentDom().get("sections").size());

        // Task 5: Verify PROPERTY_ADDRESS repeated occurrences (Cover letter + Summary + Table row 2 = 3 occurrences)
        System.out.println("\n=== TASK 5: REPEATED PLACEHOLDER (PROPERTY_ADDRESS) ===");
        assertNotNull(propertyAddressSummary);
        System.out.println(objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(propertyAddressSummary));
        assertEquals(3, propertyAddressSummary.get("occurrences").asInt());
        assertEquals("Postal address of property", propertyAddressSummary.get("questionText").asText());
        assertEquals("2", propertyAddressSummary.get("serialNo").asText());
    }

    @Test
    @DisplayName("Runtime Table & Row Classification Statistics")
    public void testTableRowClassificationStatistics() throws Exception {
        byte[] docxBytes = createValuationDocxPackage();
        byte[] normalized = templateEngine.normalizeTemplate(docxBytes);
        JsonNode dom = docxStructureParser.parseDocumentStructure(normalized);

        int totalTables = 0;
        int totalRows = 0;
        int questionAnswerRows = 0;
        int headerRows = 0;
        int staticRows = 0;

        JsonNode sections = dom.get("sections");
        if (sections != null && sections.isArray()) {
            for (JsonNode section : sections) {
                JsonNode elements = section.get("elements");
                if (elements != null && elements.isArray()) {
                    for (JsonNode el : elements) {
                        if ("TABLE".equalsIgnoreCase(el.path("type").asText())) {
                            totalTables++;
                            JsonNode rows = el.get("rows");
                            if (rows != null && rows.isArray()) {
                                for (JsonNode row : rows) {
                                    totalRows++;
                                    String rowType = row.path("rowType").asText();
                                    if ("QUESTION_ANSWER".equalsIgnoreCase(rowType)) {
                                        questionAnswerRows++;
                                    } else if ("TABLE_HEADER".equalsIgnoreCase(rowType) || "SECTION_SUBHEADER".equalsIgnoreCase(rowType)) {
                                        headerRows++;
                                    } else {
                                        staticRows++;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        System.out.println("\n=== RUNTIME TABLE ROW STATISTICS (VALUATION TEMPLATE) ===");
        System.out.println("TOTAL_TABLES: " + totalTables);
        System.out.println("TOTAL_ROWS: " + totalRows);
        System.out.println("QUESTION_ANSWER_ROWS: " + questionAnswerRows);
        System.out.println("HEADER_ROWS: " + headerRows);
        System.out.println("STATIC_ROWS: " + staticRows);
    }
}
