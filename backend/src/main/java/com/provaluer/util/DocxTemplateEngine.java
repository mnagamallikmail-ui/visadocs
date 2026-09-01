package com.provaluer.util;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.docx4j.Docx4J;
import org.docx4j.TraversalUtil;
import org.docx4j.dml.wordprocessingDrawing.Inline;
import org.docx4j.dml.wordprocessingDrawing.Anchor;
import org.docx4j.finders.ClassFinder;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.docx4j.openpackaging.parts.WordprocessingML.BinaryPartAbstractImage;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Autowired;
import com.provaluer.repository.TemplateQuestionRepository;
import com.provaluer.model.TemplateQuestion;


import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.math.BigInteger;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.awt.BasicStroke;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;

@Component
public class DocxTemplateEngine {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private static final Pattern PLACEHOLDER_PATTERN = Pattern.compile("<<([^>]+)>>");

    @Autowired(required = false)
    private TemplateQuestionRepository templateQuestionRepository;


    // Dictionary lookup for common keys
    private static final Map<String, String> QUESTION_DICTIONARY = new HashMap<>();
    static {
        System.setProperty("java.awt.headless", "true");
        QUESTION_DICTIONARY.put("GST_NUMBER", "What is the GST registration number?");
        QUESTION_DICTIONARY.put("CLIENT_NAME", "What is the client's full name?");
        QUESTION_DICTIONARY.put("PROPERTY_ADDRESS", "What is the complete address of the property?");
        QUESTION_DICTIONARY.put("REGISTRATION_NUMBER", "What is the property registration number?");
        QUESTION_DICTIONARY.put("INSPECTION_DATE", "When did the property inspection take place?");
        QUESTION_DICTIONARY.put("PROPERTY_AREA_SFT", "What is the property area in square feet?");
    }

    private Object unwrap(Object obj) {
        if (obj instanceof jakarta.xml.bind.JAXBElement) {
            return ((jakarta.xml.bind.JAXBElement<?>) obj).getValue();
        }
        return obj;
    }

    /**
     * Normalizes fragmented run strings (e.g., << VENDOR_NAME >>) inside a docx template.
     */
    public byte[] normalizeTemplate(byte[] content) throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.load(new ByteArrayInputStream(content));
        
        // 1. Normalize Main Document Part
        normalizeElements(wordMLPackage.getMainDocumentPart().getContent());

        // 2. Normalize Headers and Footers
        for (org.docx4j.openpackaging.parts.Part part : wordMLPackage.getParts().getParts().values()) {
            if (part instanceof org.docx4j.openpackaging.parts.WordprocessingML.HeaderPart) {
                org.docx4j.openpackaging.parts.WordprocessingML.HeaderPart header = (org.docx4j.openpackaging.parts.WordprocessingML.HeaderPart) part;
                normalizeElements(header.getContent());
            } else if (part instanceof org.docx4j.openpackaging.parts.WordprocessingML.FooterPart) {
                org.docx4j.openpackaging.parts.WordprocessingML.FooterPart footer = (org.docx4j.openpackaging.parts.WordprocessingML.FooterPart) part;
                normalizeElements(footer.getContent());
            }
        }

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wordMLPackage.save(out);
        return out.toByteArray();
    }

    private void normalizeElements(List<Object> elements) {
        for (Object elem : elements) {
            Object unwrapped = unwrap(elem);
            if (unwrapped instanceof P) {
                normalizeParagraph((P) unwrapped);
            } else if (unwrapped instanceof Tbl) {
                Tbl tbl = (Tbl) unwrapped;
                for (Object rowObj : tbl.getContent()) {
                    Object unwrappedRow = unwrap(rowObj);
                    if (unwrappedRow instanceof Tr) {
                        Tr row = (Tr) unwrappedRow;
                        for (Object cellObj : row.getContent()) {
                            Object unwrappedCell = unwrap(cellObj);
                            if (unwrappedCell instanceof Tc) {
                                Tc cell = (Tc) unwrappedCell;
                                normalizeElements(cell.getContent());
                            }
                        }
                    }
                }
            }
        }
    }

    private void normalizeParagraph(P p) {
        StringBuilder fullText = new StringBuilder();
        List<Object> content = p.getContent();
        List<Object> preservedElements = new ArrayList<>();
        org.docx4j.wml.RPr firstRunRPr = null;
        
        // Extract paragraph text and preserve formatting / non-text elements
        for (Object obj : content) {
            Object unwrapped = unwrap(obj);
            if (unwrapped instanceof R) {
                R run = (R) unwrapped;
                boolean hasText = false;
                boolean hasDrawing = false;
                StringBuilder runText = new StringBuilder();
                
                for (Object runElem : run.getContent()) {
                    Object unwrappedElem = unwrap(runElem);
                    if (unwrappedElem instanceof Text) {
                        hasText = true;
                        runText.append(((Text) unwrappedElem).getValue());
                    } else if (unwrappedElem instanceof Drawing) {
                        hasDrawing = true;
                    }
                }
                
                if (hasDrawing) {
                    preservedElements.add(obj); // Preserve the run wrapping the drawing
                }
                if (hasText) {
                    fullText.append(runText);
                    if (firstRunRPr == null && run.getRPr() != null) {
                        firstRunRPr = run.getRPr();
                    }
                }
            } else {
                preservedElements.add(obj); // Preserve other structural elements
            }
        }

        String textStr = fullText.toString();
        // 0.12: Standardize placeholders — migrate legacy {{PLACEHOLDER}} syntax to canonical <<PLACEHOLDER>>
        if (textStr.contains("{{") && textStr.contains("}}")) {
            textStr = textStr.replaceAll("\\{\\{([A-Za-z0-9_]+)\\}\\}", "<<$1>>");
        }

        // If it contains placeholders, merge text runs into a single clean stitched run
        if (textStr.contains("<<") && textStr.contains(">>")) {
            p.getContent().clear();
            
            // Re-add PPr first if it was preserved
            if (p.getPPr() != null) {
                p.getContent().add(p.getPPr());
            }
            
            // Add normalized run
            ObjectFactory factory = new ObjectFactory();
            R newRun = factory.createR();
            if (firstRunRPr != null) {
                newRun.setRPr(firstRunRPr);
            }
            Text newText = factory.createText();
            newText.setValue(textStr);
            newRun.getContent().add(newText);
            p.getContent().add(newRun);
            
            // Add all other preserved elements (like drawings) back to paragraph content list
            for (Object elem : preservedElements) {
                Object unwrappedElem = unwrap(elem);
                if (!(unwrappedElem instanceof PPr)) {
                    p.getContent().add(elem);
                }
            }
        }
    }

    private static class ParseContext {
        int lineGroupCounter = 0;
        int getNextLineGroup() {
            return ++lineGroupCounter;
        }
    }

    /**
     * Parses the .docx template elements sequentially to build a dynamic form metadata scheme.
     */
    public String parseTemplate(byte[] content) throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.load(new ByteArrayInputStream(content));
        
        ArrayNode fieldsArray = objectMapper.createArrayNode();
        Set<String> uniqueKeys = new HashSet<>();

        String currentSection = "General Information";
        ParseContext ctx = new ParseContext();

        // 1. Process Main Document Part
        currentSection = parseElements(wordMLPackage.getMainDocumentPart().getContent(), currentSection, fieldsArray, uniqueKeys, ctx);

        // 2. Process Headers and Footers
        for (org.docx4j.openpackaging.parts.Part part : wordMLPackage.getParts().getParts().values()) {
            if (part instanceof org.docx4j.openpackaging.parts.WordprocessingML.HeaderPart) {
                org.docx4j.openpackaging.parts.WordprocessingML.HeaderPart header = (org.docx4j.openpackaging.parts.WordprocessingML.HeaderPart) part;
                parseElements(header.getContent(), "Header Content", fieldsArray, uniqueKeys, ctx);
            } else if (part instanceof org.docx4j.openpackaging.parts.WordprocessingML.FooterPart) {
                org.docx4j.openpackaging.parts.WordprocessingML.FooterPart footer = (org.docx4j.openpackaging.parts.WordprocessingML.FooterPart) part;
                parseElements(footer.getContent(), "Footer Content", fieldsArray, uniqueKeys, ctx);
            }
        }

        ObjectNode schema = objectMapper.createObjectNode();
        
        // Post-processing to enforce same-line text positioning and push images to the end
        List<com.fasterxml.jackson.databind.JsonNode> nonImages = new ArrayList<>();
        List<com.fasterxml.jackson.databind.JsonNode> images = new ArrayList<>();
        for (int i = 0; i < fieldsArray.size(); i++) {
            com.fasterxml.jackson.databind.JsonNode node = fieldsArray.get(i);
            String type = node.get("type").asText();
            if ("IMAGE".equalsIgnoreCase(type)) {
                images.add(node);
            } else {
                nonImages.add(node);
            }
        }
        
        ArrayNode finalFieldsArray = objectMapper.createArrayNode();
        for (com.fasterxml.jackson.databind.JsonNode node : nonImages) {
            finalFieldsArray.add(node);
        }
        for (com.fasterxml.jackson.databind.JsonNode node : images) {
            finalFieldsArray.add(node);
        }

        schema.set("fields", finalFieldsArray);
        return objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(schema);
    }

    private String parseElements(List<Object> elements, String initialSection, ArrayNode fieldsArray, Set<String> uniqueKeys, ParseContext ctx) {
        String currentSection = initialSection;
        int tableIndex = 0;
        for (Object element : elements) {
            Object unwrapped = unwrap(element);
            if (unwrapped instanceof P) {
                P p = (P) unwrapped;
                String pText = getParagraphText(p);

                boolean hasPlaceholders = pText.contains("<<") && pText.contains(">>");
                ClassFinder inlineFinder = new ClassFinder(Inline.class);
                new TraversalUtil(p, inlineFinder);
                ClassFinder anchorFinder = new ClassFinder(Anchor.class);
                new TraversalUtil(p, anchorFinder);
                boolean hasDrawings = !inlineFinder.results.isEmpty() || !anchorFinder.results.isEmpty();

                int currentLineGroup = (hasPlaceholders || hasDrawings) ? ctx.getNextLineGroup() : 0;

                // Section Tracking: Check for Headings
                if (pText.trim().matches("^[0-9]+.*") || pText.trim().startsWith("Heading") || pText.trim().startsWith("Section")) {
                    currentSection = pText.trim();
                } else if (p.getPPr() != null && p.getPPr().getPStyle() != null) {
                    String styleVal = p.getPPr().getPStyle().getVal();
                    if (styleVal != null && styleVal.startsWith("Heading")) {
                        currentSection = pText.trim();
                    }
                }

                // Parse standard placeholders
                parsePlaceholdersInText(pText, currentSection, null, null, null, fieldsArray, uniqueKeys, currentLineGroup);
                
                // Parse image dimensions
                parseImageDrawing(p, currentSection, fieldsArray, uniqueKeys, currentLineGroup);

            } else if (unwrapped instanceof Tbl) {
                Tbl tbl = (Tbl) unwrapped;
                int rowIndex = 0;
                for (Object rowObj : tbl.getContent()) {
                    Object unwrappedRow = unwrap(rowObj);
                    if (unwrappedRow instanceof Tr) {
                        Tr row = (Tr) unwrappedRow;
                        int colIndex = 0;
                        
                        int currentLineGroup = ctx.getNextLineGroup();

                        for (Object cellObj : row.getContent()) {
                            Object unwrappedCell = unwrap(cellObj);
                            if (unwrappedCell instanceof Tc) {
                                Tc cell = (Tc) unwrappedCell;
                                String cellContext = "T" + tableIndex + "_R" + rowIndex + "_C" + colIndex;
                                String colHeader = rowIndex > 0 ? getCellText(tbl, 0, colIndex) : "";
                                String rowHeader = colIndex > 0 ? getCellText(tbl, rowIndex, 0) : "";

                                parseCellElements(cell.getContent(), currentSection, cellContext, colHeader, rowHeader, fieldsArray, uniqueKeys, currentLineGroup, ctx);
                                colIndex++;
                            }
                        }
                        rowIndex++;
                    }
                }
                tableIndex++;
            }
        }
        return currentSection;
    }

    private void parseCellElements(List<Object> elements, String section, String cellContext, String colHeader, String rowHeader, ArrayNode fieldsArray, Set<String> uniqueKeys, int lineGroupId, ParseContext ctx) {
        for (Object elem : elements) {
            Object unwrapped = unwrap(elem);
            if (unwrapped instanceof P) {
                P p = (P) unwrapped;
                String text = getParagraphText(p);
                parsePlaceholdersInText(text, section, cellContext, colHeader, rowHeader, fieldsArray, uniqueKeys, lineGroupId);
                parseImageDrawing(p, section, fieldsArray, uniqueKeys, lineGroupId);
            } else if (unwrapped instanceof Tbl) {
                Tbl tbl = (unwrapped instanceof Tbl) ? (Tbl) unwrapped : null;
                if (tbl == null) continue;
                int rowIndex = 0;
                for (Object rowObj : tbl.getContent()) {
                    Object unwrappedRow = unwrap(rowObj);
                    if (unwrappedRow instanceof Tr) {
                        Tr row = (Tr) unwrappedRow;
                        int colIndex = 0;
                        int currentLineGroup = ctx.getNextLineGroup();
                        for (Object cellObj : row.getContent()) {
                            Object unwrappedCell = unwrap(cellObj);
                            if (unwrappedCell instanceof Tc) {
                                Tc cell = (Tc) unwrappedCell;
                                parseCellElements(cell.getContent(), section, cellContext, colHeader, rowHeader, fieldsArray, uniqueKeys, currentLineGroup, ctx);
                                colIndex++;
                            }
                        }
                        rowIndex++;
                    }
                }
            }
        }
    }

    private String getCellText(Tbl tbl, int rIdx, int cIdx) {
        if (rIdx < 0 || rIdx >= tbl.getContent().size()) return "";
        Object rObj = unwrap(tbl.getContent().get(rIdx));
        if (rObj instanceof Tr) {
            Tr row = (Tr) rObj;
            if (cIdx >= 0 && cIdx < row.getContent().size()) {
                Object cObj = unwrap(row.getContent().get(cIdx));
                if (cObj instanceof Tc) {
                    Tc cell = (Tc) cObj;
                    StringBuilder text = new StringBuilder();
                    for (Object elem : cell.getContent()) {
                        Object unwrappedElem = unwrap(elem);
                        if (unwrappedElem instanceof P) {
                            text.append(getParagraphText((P) unwrappedElem)).append(" ");
                        }
                    }
                    return text.toString().trim();
                }
            }
        }
        return "";
    }

    private void parsePlaceholdersInText(String text, String section, String tableContext, String colHeader, String rowHeader, ArrayNode fieldsArray, Set<String> uniqueKeys, int lineGroupId) {
        Matcher matcher = PLACEHOLDER_PATTERN.matcher(text);
        while (matcher.find()) {
            String rawKey = matcher.group(1).trim();
            String key = rawKey.toUpperCase();
            
            if (uniqueKeys.contains(key)) {
                continue;
            }
            uniqueKeys.add(key);

            // Determine Field Type: text placeholders between << >>, image as image placeholders, date as date placeholders
            String fieldType = "TEXT";
            if (key.toLowerCase().contains("image") || key.toLowerCase().contains("img_") || key.toLowerCase().contains("_image")) {
                fieldType = "IMAGE";
            } else if (key.toLowerCase().contains("date_") || key.toLowerCase().contains("_date") || key.toLowerCase().equals("date")) {
                fieldType = "DATE";
            }

            // Auto Label Generation
            String label = makeDisplayLabel(key);
            
            // Question Generation
            String question = null;
            if (templateQuestionRepository != null) {
                question = templateQuestionRepository.findByPlaceholderKeyIgnoreCase(key)
                        .map(TemplateQuestion::getQuestionText)
                        .orElse(null);
            }
            if (question == null) {
                question = QUESTION_DICTIONARY.getOrDefault(key, null);
            }

            if (question == null) {
                if (fieldType.equals("IMAGE")) {
                    question = "Upload the " + label + " image";
                } else {
                    question = "What is the " + label + "?";
                }
            }

            ObjectNode fieldNode = objectMapper.createObjectNode();
            fieldNode.put("key", key);
            fieldNode.put("label", label);
            fieldNode.put("question", question);
            fieldNode.put("type", fieldType);
            fieldNode.put("section", section);
            fieldNode.put("isRequired", true);
            fieldNode.put("lineGroupId", lineGroupId);
            if (tableContext != null) {
                fieldNode.put("tableContext", tableContext);
                if (colHeader != null && !colHeader.isEmpty()) {
                    fieldNode.put("colHeader", colHeader);
                }
                if (rowHeader != null && !rowHeader.isEmpty()) {
                    fieldNode.put("rowHeader", rowHeader);
                }
            }
            
            fieldsArray.add(fieldNode);
        }
    }

    private void parseImageDrawing(P p, String section, ArrayNode fieldsArray, Set<String> uniqueKeys, int lineGroupId) {
        // 1. Inline drawings
        ClassFinder inlineFinder = new ClassFinder(Inline.class);
        new TraversalUtil(p, inlineFinder);
        for (Object o : inlineFinder.results) {
            Inline inline = (Inline) o;
            if (inline.getDocPr() == null) continue;
            String desc = inline.getDocPr().getDescr();
            String name = inline.getDocPr().getName();
            String matchedName = (desc != null && desc.startsWith("IMG_")) ? desc : name;

            if (matchedName != null && (matchedName.toUpperCase().contains("IMG_") || matchedName.toUpperCase().contains("_IMAGE"))) {
                String key = matchedName.toUpperCase();
                if (uniqueKeys.contains(key)) continue;
                uniqueKeys.add(key);

                long emuCx = 0;
                long emuCy = 0;
                if (inline.getExtent() != null) {
                    emuCx = inline.getExtent().getCx();
                    emuCy = inline.getExtent().getCy();
                }
                
                addImageSlot(key, section, emuCx, emuCy, fieldsArray, lineGroupId);
            }
        }

        // 2. Anchor drawings
        ClassFinder anchorFinder = new ClassFinder(Anchor.class);
        new TraversalUtil(p, anchorFinder);
        for (Object o : anchorFinder.results) {
            Anchor anchor = (Anchor) o;
            if (anchor.getDocPr() == null) continue;
            String desc = anchor.getDocPr().getDescr();
            String name = anchor.getDocPr().getName();
            String matchedName = (desc != null && desc.startsWith("IMG_")) ? desc : name;

            if (matchedName != null && (matchedName.toUpperCase().contains("IMG_") || matchedName.toUpperCase().contains("_IMAGE"))) {
                String key = matchedName.toUpperCase();
                if (uniqueKeys.contains(key)) continue;
                uniqueKeys.add(key);

                long emuCx = 0;
                long emuCy = 0;
                if (anchor.getExtent() != null) {
                    emuCx = anchor.getExtent().getCx();
                    emuCy = anchor.getExtent().getCy();
                }
                
                addImageSlot(key, section, emuCx, emuCy, fieldsArray, lineGroupId);
            }
        }
    }

    private void addImageSlot(String key, String section, long emuCx, long emuCy, ArrayNode fieldsArray, int lineGroupId) {
        double inchesW = (double) emuCx / 914400.0;
        double inchesH = (double) emuCy / 914400.0;
        double pixelsW = (double) emuCx / 9144.0;
        double pixelsH = (double) emuCy / 9144.0;

        ObjectNode fieldNode = objectMapper.createObjectNode();
        fieldNode.put("key", key);
        fieldNode.put("label", makeDisplayLabel(key));
        fieldNode.put("question", "Upload the " + makeDisplayLabel(key) + " image");
        fieldNode.put("type", "IMAGE");
        fieldNode.put("section", section);
        fieldNode.put("isRequired", true);
        fieldNode.put("lineGroupId", lineGroupId);
        
        ObjectNode dimensions = objectMapper.createObjectNode();
        dimensions.put("emuCx", emuCx);
        dimensions.put("emuCy", emuCy);
        dimensions.put("inchesW", inchesW);
        dimensions.put("inchesH", inchesH);
        dimensions.put("pixelsW", pixelsW);
        dimensions.put("pixelsH", pixelsH);
        
        fieldNode.set("dimensions", dimensions);
        fieldsArray.add(fieldNode);
    }

    private String makeDisplayLabel(String key) {
        String cleanKey = key.toUpperCase();
        
        // Remove standard markers anywhere
        cleanKey = cleanKey.replaceAll("(?i)IMG_", "");
        cleanKey = cleanKey.replaceAll("(?i)_IMAGE", "");
        cleanKey = cleanKey.replaceAll("(?i)DATE_", "");
        cleanKey = cleanKey.replaceAll("(?i)_DATE", "");
        cleanKey = cleanKey.replaceAll("(?i)NUM_", "");
        cleanKey = cleanKey.replaceAll("(?i)NUMBER_", "");
        cleanKey = cleanKey.replaceAll("(?i)_NUM", "");
        cleanKey = cleanKey.replaceAll("(?i)_NUMBER", "");
        cleanKey = cleanKey.replaceAll("(?i)SELECT_", "");
        
        cleanKey = cleanKey.replace("_", " ").trim().toLowerCase();
        
        // Title Case Conversion
        StringBuilder titleCase = new StringBuilder();
        boolean nextTitleCase = true;
        for (char c : cleanKey.toCharArray()) {
            if (Character.isSpaceChar(c)) {
                nextTitleCase = true;
                titleCase.append(c);
            } else if (nextTitleCase) {
                titleCase.append(Character.toUpperCase(c));
                nextTitleCase = false;
            } else {
                titleCase.append(c);
            }
        }
        return titleCase.toString();
    }

    private String getParagraphText(P p) {
        StringBuilder sb = new StringBuilder();
        for (Object obj : p.getContent()) {
            Object unwrapped = unwrap(obj);
            if (unwrapped instanceof R) {
                R run = (R) unwrapped;
                for (Object runElem : run.getContent()) {
                    Object unwrappedElem = unwrap(runElem);
                    if (unwrappedElem instanceof Text) {
                        sb.append(((Text) unwrappedElem).getValue());
                    }
                }
            }
        }
        return sb.toString();
    }

    /**
     * Hydrates the normalized template document with client input answers and returns the final compiled report.
     */
    public byte[] generateReport(byte[] content, Map<String, String> inputs, Map<String, byte[]> images) throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.load(new ByteArrayInputStream(content));
        
        // 1. Process Main Document Part
        generateElements(wordMLPackage, wordMLPackage.getMainDocumentPart().getContent(), inputs, images);

        // 2. Process Headers and Footers
        for (org.docx4j.openpackaging.parts.Part part : wordMLPackage.getParts().getParts().values()) {
            if (part instanceof org.docx4j.openpackaging.parts.WordprocessingML.HeaderPart) {
                org.docx4j.openpackaging.parts.WordprocessingML.HeaderPart header = (org.docx4j.openpackaging.parts.WordprocessingML.HeaderPart) part;
                generateElements(wordMLPackage, header.getContent(), inputs, images);
            } else if (part instanceof org.docx4j.openpackaging.parts.WordprocessingML.FooterPart) {
                org.docx4j.openpackaging.parts.WordprocessingML.FooterPart footer = (org.docx4j.openpackaging.parts.WordprocessingML.FooterPart) part;
                generateElements(wordMLPackage, footer.getContent(), inputs, images);
            }
        }

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wordMLPackage.save(out);
        return out.toByteArray();
    }

    private void generateElements(WordprocessingMLPackage wordMLPackage, List<Object> elements, Map<String, String> inputs, Map<String, byte[]> images) throws Exception {
        for (int i = 0; i < elements.size(); i++) {
            Object elem = elements.get(i);
            Object unwrapped = unwrap(elem);
            if (unwrapped instanceof P) {
                P p = (P) unwrapped;
                String pText = getParagraphText(p).trim();
                
                // 30, 31, 32, 33: Dynamic Table Generation
                if (pText.equalsIgnoreCase("<<LAND_TABLE>>") || pText.contains("<<LAND_TABLE>>")) {
                    Tbl landTable = buildDynamicLandTable(inputs);
                    if (landTable != null) {
                        elements.set(i, landTable);
                        continue;
                    }
                } else if (pText.equalsIgnoreCase("<<BUILDING_TABLE>>") || pText.contains("<<BUILDING_TABLE>>")) {
                    Tbl buildingTable = buildDynamicBuildingTable(inputs);
                    if (buildingTable != null) {
                        elements.set(i, buildingTable);
                        continue;
                    }
                } else if (pText.equalsIgnoreCase("<<VALUATION_SUMMARY_TABLE>>") || pText.contains("<<VALUATION_SUMMARY_TABLE>>")) {
                    Tbl summaryTable = buildDynamicValuationSummaryTable(inputs);
                    if (summaryTable != null) {
                        elements.set(i, summaryTable);
                        continue;
                    }
                } else if (pText.equalsIgnoreCase("<<COMPARABLES_TABLE>>") || pText.contains("<<COMPARABLES_TABLE>>")) {
                    Tbl compTable = buildDynamicComparablesTable(inputs);
                    if (compTable != null) {
                        elements.set(i, compTable);
                        continue;
                    }
                } else if (pText.equalsIgnoreCase("<<PROPERTY_VALUE_TABLE>>") || pText.contains("<<PROPERTY_VALUE_TABLE>>")
                        || pText.equalsIgnoreCase("<<VALUE_OF_THE_PROPERTY_TABLE>>") || pText.contains("<<VALUE_OF_THE_PROPERTY_TABLE>>")) {
                    Tbl propTable = buildDynamicPropertyValueTable(inputs);
                    if (propTable != null) {
                        elements.set(i, propTable);
                        continue;
                    }
                }
                
                substituteInParagraph(wordMLPackage, p, inputs, images);
            } else if (unwrapped instanceof Tbl) {
                Tbl tbl = (Tbl) unwrapped;
                
                // Enforce FIXED layout to prevent horizontal expansion of columns
                TblPr tblPr = tbl.getTblPr();
                if (tblPr == null) {
                    ObjectFactory factory = new ObjectFactory();
                    tblPr = factory.createTblPr();
                    tbl.setTblPr(tblPr);
                }
                if (tblPr.getTblLayout() == null) {
                    ObjectFactory factory = new ObjectFactory();
                    CTTblLayoutType layout = factory.createCTTblLayoutType();
                    layout.setType(STTblLayoutType.FIXED);
                    tblPr.setTblLayout(layout);
                } else {
                    tblPr.getTblLayout().setType(STTblLayoutType.FIXED);
                }

                for (Object rowObj : tbl.getContent()) {
                    Object unwrappedRow = unwrap(rowObj);
                    if (unwrappedRow instanceof Tr) {
                        Tr row = (Tr) unwrappedRow;
                        for (Object cellObj : row.getContent()) {
                            Object unwrappedCell = unwrap(cellObj);
                            if (unwrappedCell instanceof Tc) {
                                Tc cell = (Tc) unwrappedCell;
                                generateElements(wordMLPackage, cell.getContent(), inputs, images);
                            }
                        }
                    }
                }
            }
        }
    }

    private Tbl buildDynamicLandTable(Map<String, String> inputs) {
        List<String> headers = List.of("Survey No", "Description", "Area", "Unit", "Area (Sq.Ft)", "Rate (INR)", "Value (INR)");
        List<List<String>> rows = new ArrayList<>();
        
        // Parse land items from JSON if available in inputs
        String landJson = inputs != null ? inputs.get("RAW_LAND_ITEMS_JSON") : null;
        if (landJson != null && !landJson.trim().isEmpty()) {
            try {
                com.fasterxml.jackson.databind.JsonNode root = objectMapper.readTree(landJson);
                if (root.isArray()) {
                    for (com.fasterxml.jackson.databind.JsonNode n : root) {
                        rows.add(List.of(
                                n.path("surveyNo").asText("-"),
                                n.path("description").asText("Land Parcel"),
                                n.path("enteredArea").asText("0"),
                                n.path("enteredUnit").asText("Sq.Ft"),
                                n.path("standardAreaSqft").asText("0"),
                                n.path("rate").asText("0"),
                                n.path("value").asText("0")
                        ));
                    }
                }
            } catch (Exception ignored) {}
        }
        
        if (rows.isEmpty()) {
            // Default single row from inputs
            rows.add(List.of(
                    inputs != null ? inputs.getOrDefault("SURVEY_NO", "-") : "-",
                    "Primary Land Parcel",
                    inputs != null ? inputs.getOrDefault("LAND_AREA", "0") : "0",
                    "Sq.Ft",
                    inputs != null ? inputs.getOrDefault("LAND_AREA", "0") : "0",
                    inputs != null ? inputs.getOrDefault("LAND_RATE", "0") : "0",
                    inputs != null ? inputs.getOrDefault("TOTAL_LAND_VALUE", inputs.getOrDefault("LAND_VALUE", "0")) : "0"
            ));
        }

        List<String> footer = List.of("Total Land Value", "", "", "", "", "", inputs != null ? inputs.getOrDefault("TOTAL_LAND_VALUE", "0") : "0");
        return createDocxTable(headers, rows, footer);
    }

    private Tbl buildDynamicBuildingTable(Map<String, String> inputs) {
        List<String> headers = List.of("Structure", "Type", "Area", "Rate", "Cost (INR)", "Age", "Life", "Depr %", "Depr (INR)", "Value (INR)");
        List<List<String>> rows = new ArrayList<>();

        String bldgJson = inputs != null ? inputs.get("RAW_BUILDING_ITEMS_JSON") : null;
        if (bldgJson != null && !bldgJson.trim().isEmpty()) {
            try {
                com.fasterxml.jackson.databind.JsonNode root = objectMapper.readTree(bldgJson);
                if (root.isArray()) {
                    for (com.fasterxml.jackson.databind.JsonNode n : root) {
                        rows.add(List.of(
                                n.path("structureType").asText("Structure"),
                                n.path("buildingType").asText("RCC"),
                                n.path("enteredArea").asText("0") + " " + n.path("enteredUnit").asText("Sq.Ft"),
                                n.path("replacementRate").asText("0"),
                                n.path("replacementCost").asText("0"),
                                n.path("buildingAge").asText("0") + " Yrs",
                                n.path("buildingUsefulLife").asText("60") + " Yrs",
                                n.path("depreciationPercentage").asText("0") + "%",
                                n.path("depreciationAmount").asText("0"),
                                n.path("buildingValue").asText("0")
                        ));
                    }
                }
            } catch (Exception ignored) {}
        }

        if (rows.isEmpty()) {
            rows.add(List.of(
                    "Main Structure",
                    inputs != null ? inputs.getOrDefault("BUILDING_TYPE", "RCC Residential") : "RCC Residential",
                    inputs != null ? inputs.getOrDefault("BUILDING_AREA", "0") : "0",
                    inputs != null ? inputs.getOrDefault("REPLACEMENT_RATE", "0") : "0",
                    inputs != null ? inputs.getOrDefault("TOTAL_REPLACEMENT_COST", inputs.getOrDefault("REPLACEMENT_COST", "0")) : "0",
                    inputs != null ? inputs.getOrDefault("BUILDING_AGE", "0") : "0",
                    inputs != null ? inputs.getOrDefault("BUILDING_USEFUL_LIFE", "60") : "60",
                    inputs != null ? inputs.getOrDefault("DEPRECIATION_PERCENT", "0%") : "0%",
                    inputs != null ? inputs.getOrDefault("TOTAL_DEPRECIATION_AMOUNT", inputs.getOrDefault("DEPRECIATION_AMOUNT", "0")) : "0",
                    inputs != null ? inputs.getOrDefault("TOTAL_BUILDING_VALUE", inputs.getOrDefault("BUILDING_VALUE", "0")) : "0"
            ));
        }

        List<String> footer = List.of("Total Building Value", "", "", "", "", "", "", "", "", inputs != null ? inputs.getOrDefault("TOTAL_BUILDING_VALUE", "0") : "0");
        return createDocxTable(headers, rows, footer);
    }

    private Tbl buildDynamicValuationSummaryTable(Map<String, String> inputs) {
        List<String> headers = List.of("Valuation Parameter", "Assessed Value / Percentage");
        List<List<String>> rows = new ArrayList<>();
        if (inputs != null) {
            rows.add(List.of("Total Land Value", "INR " + inputs.getOrDefault("TOTAL_LAND_VALUE", "0")));
            rows.add(List.of("Total Replacement Cost", "INR " + inputs.getOrDefault("TOTAL_REPLACEMENT_COST", "0")));
            rows.add(List.of("Total Depreciation Amount", "INR " + inputs.getOrDefault("TOTAL_DEPRECIATION_AMOUNT", "0")));
            rows.add(List.of("Total Salvage Value Floor", "INR " + inputs.getOrDefault("TOTAL_SALVAGE_VALUE", "0")));
            rows.add(List.of("Total Building Value", "INR " + inputs.getOrDefault("TOTAL_BUILDING_VALUE", "0")));
            rows.add(List.of("Fair Market Value", "INR " + inputs.getOrDefault("FAIR_VALUE", "0")));
            rows.add(List.of("Realizable Percentage", inputs.getOrDefault("REALIZABLE_PERCENTAGE", "85%")));
            rows.add(List.of("Realizable Sale Value", "INR " + inputs.getOrDefault("REALIZABLE_VALUE", "0")));
            rows.add(List.of("Distress Sale Percentage", inputs.getOrDefault("DISTRESS_SALE_PERCENTAGE", "75%")));
            rows.add(List.of("Distress Sale Value", "INR " + inputs.getOrDefault("DISTRESS_SALE_VALUE", "0")));
            rows.add(List.of("Insurable Value (Building Replacement Cost)", "INR " + inputs.getOrDefault("INSURABLE_VALUE", inputs.getOrDefault("TOTAL_REPLACEMENT_COST", "0"))));
            rows.add(List.of("Government / Guideline Value", "INR " + inputs.getOrDefault("GOVERNMENT_VALUE", "0")));
        }
        return createDocxTable(headers, rows, null);
    }

    private Tbl buildDynamicComparablesTable(Map<String, String> inputs) {
        List<String> headers = List.of("Location", "Survey No", "Area", "Rate (INR)", "Sale Value (INR)", "Date", "Source");
        List<List<String>> rows = new ArrayList<>();

        String compJson = inputs != null ? inputs.get("RAW_COMPARABLES_JSON") : null;
        if (compJson != null && !compJson.trim().isEmpty()) {
            try {
                com.fasterxml.jackson.databind.JsonNode root = objectMapper.readTree(compJson);
                if (root.isArray()) {
                    for (com.fasterxml.jackson.databind.JsonNode n : root) {
                        rows.add(List.of(
                                n.path("location").asText("-"),
                                n.path("surveyNo").asText("-"),
                                n.path("enteredArea").asText("0") + " " + n.path("enteredUnit").asText("Sq.Ft"),
                                n.path("rate").asText("0"),
                                n.path("saleValue").asText("0"),
                                n.path("transactionDate").asText("-"),
                                n.path("source").asText("-")
                        ));
                    }
                }
            } catch (Exception ignored) {}
        }

        if (rows.isEmpty()) {
            rows.add(List.of("Market Vicinity", "Primary Cluster", "Standard Unit", "Prevailing Rate", "Comparable Value", "Recent", "Registrar Office"));
        }

        return createDocxTable(headers, rows, null);
    }

    private Tbl buildDynamicPropertyValueTable(Map<String, String> inputs) {
        List<String> headers = List.of("Description", "Assessed Value");
        List<List<String>> rows = new ArrayList<>();

        String landVal = inputs != null ? inputs.getOrDefault("total_land_value", inputs.getOrDefault("TOTAL_LAND_VALUE", "0")) : "0";
        String bldgVal = inputs != null ? inputs.getOrDefault("total_building_value", inputs.getOrDefault("TOTAL_BUILDING_VALUE", "0")) : "0";
        String fairVal = inputs != null ? inputs.getOrDefault("fair_value", inputs.getOrDefault("FAIR_VALUE", "0")) : "0";
        String sayVal = inputs != null ? inputs.getOrDefault("say_value", inputs.getOrDefault("SAY_VALUE", fairVal)) : fairVal;

        rows.add(List.of("Value of Land", "INR " + landVal));
        rows.add(List.of("Value of Buildings", "INR " + bldgVal));
        rows.add(List.of("Total", "INR " + fairVal));
        rows.add(List.of("Say", "INR " + sayVal));

        return createDocxTable(headers, rows, null);
    }

    private Tbl createDocxTable(List<String> headers, List<List<String>> dataRows, List<String> footerRow) {
        ObjectFactory factory = new ObjectFactory();
        Tbl tbl = factory.createTbl();

        // 1. Table Properties (Center, Full Width, Fixed Layout, Borders)
        TblPr tblPr = factory.createTblPr();
        CTTblLayoutType layout = factory.createCTTblLayoutType();
        layout.setType(STTblLayoutType.FIXED);
        tblPr.setTblLayout(layout);

        TblBorders borders = factory.createTblBorders();
        CTBorder border = factory.createCTBorder();
        border.setVal(STBorder.SINGLE);
        border.setSz(BigInteger.valueOf(4));
        border.setColor("CCCCCC");
        borders.setTop(border);
        borders.setBottom(border);
        borders.setLeft(border);
        borders.setRight(border);
        borders.setInsideH(border);
        borders.setInsideV(border);
        tblPr.setTblBorders(borders);
        tbl.setTblPr(tblPr);

        // 2. Header Row
        if (headers != null && !headers.isEmpty()) {
            Tr headerTr = factory.createTr();
            for (String h : headers) {
                Tc tc = factory.createTc();
                P p = factory.createP();
                R r = factory.createR();
                RPr rpr = factory.createRPr();
                BooleanDefaultTrue b = factory.createBooleanDefaultTrue();
                rpr.setB(b);
                Color color = factory.createColor();
                color.setVal("000000");
                rpr.setColor(color);
                r.setRPr(rpr);

                Text text = factory.createText();
                text.setValue(h);
                r.getContent().add(text);
                p.getContent().add(r);
                tc.getContent().add(p);

                // Header cell background
                TcPr tcPr = factory.createTcPr();
                CTShd shd = factory.createCTShd();
                shd.setVal(STShd.CLEAR);
                shd.setColor("auto");
                shd.setFill("EAEAEA");
                tcPr.setShd(shd);
                tc.setTcPr(tcPr);

                headerTr.getContent().add(tc);
            }
            tbl.getContent().add(headerTr);
        }

        // 3. Data Rows
        if (dataRows != null) {
            for (List<String> rowData : dataRows) {
                Tr tr = factory.createTr();
                for (String val : rowData) {
                    Tc tc = factory.createTc();
                    P p = factory.createP();
                    R r = factory.createR();
                    Text text = factory.createText();
                    text.setValue(val != null ? val : "");
                    r.getContent().add(text);
                    p.getContent().add(r);
                    tc.getContent().add(p);
                    tr.getContent().add(tc);
                }
                tbl.getContent().add(tr);
            }
        }

        // 4. Footer Row (Bold)
        if (footerRow != null && !footerRow.isEmpty()) {
            Tr footerTr = factory.createTr();
            for (String val : footerRow) {
                Tc tc = factory.createTc();
                P p = factory.createP();
                R r = factory.createR();
                RPr rpr = factory.createRPr();
                rpr.setB(factory.createBooleanDefaultTrue());
                r.setRPr(rpr);
                Text text = factory.createText();
                text.setValue(val != null ? val : "");
                r.getContent().add(text);
                p.getContent().add(r);
                tc.getContent().add(p);

                TcPr tcPr = factory.createTcPr();
                CTShd shd = factory.createCTShd();
                shd.setVal(STShd.CLEAR);
                shd.setColor("auto");
                shd.setFill("F5F5F5");
                tcPr.setShd(shd);
                tc.setTcPr(tcPr);

                footerTr.getContent().add(tc);
            }
            tbl.getContent().add(footerTr);
        }

        return tbl;
    }

    private String extractImageKey(org.docx4j.dml.CTNonVisualDrawingProps docPr) {
        if (docPr == null) return null;
        String[] candidates = new String[]{docPr.getDescr(), docPr.getName()};
        for (String c : candidates) {
            if (c == null) continue;
            String trimmed = c.trim();
            if (trimmed.isEmpty()) continue;
            Matcher m = Pattern.compile("<<([^>]+)>>").matcher(trimmed);
            if (m.find()) return m.group(1).trim().toUpperCase();
            String upper = trimmed.toUpperCase();
            if (upper.startsWith("IMG_") || upper.startsWith("PHOTO_") || upper.startsWith("IMAGE_") || upper.startsWith("LOGO_")
                    || upper.endsWith("_IMAGE") || upper.endsWith("_IMG") || upper.endsWith("_PHOTO")
                    || upper.contains("IMAGE_") || upper.contains("PHOTO_") || upper.contains("SITE_PHOTO")) {
                return trimmed.replaceAll("[<>]", "").trim().toUpperCase();
            }
        }
        return null;
    }

    private void substituteInParagraph(WordprocessingMLPackage wordMLPackage, P p, Map<String, String> inputs, Map<String, byte[]> images) throws Exception {
        normalizeParagraph(p);
        // First, check if there are drawing elements inside the paragraph
        ClassFinder inlineFinder = new ClassFinder(Inline.class);
        new TraversalUtil(p, inlineFinder);
        for (Object o : inlineFinder.results) {
            Inline inline = (Inline) o;
            if (inline.getDocPr() == null) continue;
            String key = extractImageKey(inline.getDocPr());
            if (key != null) {
                byte[] imgBytes = getUploadedOrPlaceholderImage(key, images, inputs);
                if (imgBytes != null) {
                    long originalCx = inline.getExtent() != null ? inline.getExtent().getCx() : 2743200L;
                    long originalCy = inline.getExtent() != null ? inline.getExtent().getCy() : 1828800L;
                    
                    imgBytes = padImageToFitEmu(imgBytes, originalCx, originalCy);

                    BinaryPartAbstractImage imagePart = BinaryPartAbstractImage.createImagePart(wordMLPackage, imgBytes);
                    Inline inlineImage = imagePart.createImageInline("Uploaded Image", "Image", 10002, 10003, false);
                    
                    if (inline.getExtent() != null) {
                        inlineImage.getExtent().setCx(originalCx);
                        inlineImage.getExtent().setCy(originalCy);
                    }
                    
                    org.docx4j.dml.picture.Pic pic = inlineImage.getGraphic().getGraphicData().getPic();
                    if (pic != null && pic.getSpPr() != null && pic.getSpPr().getXfrm() != null && pic.getSpPr().getXfrm().getExt() != null) {
                        pic.getSpPr().getXfrm().getExt().setCx(originalCx);
                        pic.getSpPr().getXfrm().getExt().setCy(originalCy);
                    }
                    
                    replaceDrawingInParagraph(p, inline, inlineImage);
                }
            }
        }

        ClassFinder anchorFinder = new ClassFinder(Anchor.class);
        new TraversalUtil(p, anchorFinder);
        for (Object o : anchorFinder.results) {
            Anchor anchor = (Anchor) o;
            if (anchor.getDocPr() == null) continue;
            String key = extractImageKey(anchor.getDocPr());
            if (key != null) {
                byte[] imgBytes = getUploadedOrPlaceholderImage(key, images, inputs);
                if (imgBytes != null) {
                    long originalCx = anchor.getExtent() != null ? anchor.getExtent().getCx() : 2743200L;
                    long originalCy = anchor.getExtent() != null ? anchor.getExtent().getCy() : 1828800L;
                    
                    imgBytes = padImageToFitEmu(imgBytes, originalCx, originalCy);

                    BinaryPartAbstractImage imagePart = BinaryPartAbstractImage.createImagePart(wordMLPackage, imgBytes);
                    Inline inlineImage = imagePart.createImageInline("Uploaded Image", "Image", 10002, 10003, false);
                    
                    if (anchor.getExtent() != null) {
                        inlineImage.getExtent().setCx(originalCx);
                        inlineImage.getExtent().setCy(originalCy);
                    }
                    
                    org.docx4j.dml.picture.Pic pic = inlineImage.getGraphic().getGraphicData().getPic();
                    if (pic != null && pic.getSpPr() != null && pic.getSpPr().getXfrm() != null && pic.getSpPr().getXfrm().getExt() != null) {
                        pic.getSpPr().getXfrm().getExt().setCx(originalCx);
                        pic.getSpPr().getXfrm().getExt().setCy(originalCy);
                    }

                    replaceDrawingInParagraph(p, anchor, inlineImage);
                }
            }
        }

        // Second, perform standard text replacement on Runs
        for (Object obj : p.getContent()) {
            Object unwrapped = unwrap(obj);
            if (unwrapped instanceof R) {
                R run = (R) unwrapped;
                List<Object> runContent = run.getContent();
                for (int i = 0; i < runContent.size(); i++) {
                    Object runElem = runContent.get(i);
                    Object unwrappedElem = unwrap(runElem);
                    if (unwrappedElem instanceof Text) {
                        Text text = (Text) unwrappedElem;
                        String val = text.getValue();
                        
                        Matcher matcher = PLACEHOLDER_PATTERN.matcher(val);
                        StringBuffer sb = new StringBuffer();
                        boolean substituted = false;
                        
                        // Check if the entire run is just an image placeholder like <<IMG_XYZ>>
                        if (val.startsWith("<<") && val.endsWith(">>")) {
                            String possibleKey = val.substring(2, val.length() - 2).trim().toUpperCase();
                            if (possibleKey.contains("IMG_") || possibleKey.contains("_IMAGE")) {
                                byte[] imgBytes = getUploadedOrPlaceholderImage(possibleKey, images, inputs);
                                if (imgBytes != null) {
                                    BinaryPartAbstractImage imagePart = BinaryPartAbstractImage.createImagePart(wordMLPackage, imgBytes);
                                    Inline inlineImage = imagePart.createImageInline("Uploaded Image", "Image", 10004, 10005, false);
                                    
                                    // Set a default size for text placeholders if they don't have guidelines
                                    inlineImage.getExtent().setCx(2743200L); // 3 inches
                                    inlineImage.getExtent().setCy(1828800L); // 2 inches
                                    
                                    ObjectFactory factory = new ObjectFactory();
                                    Drawing drawing = factory.createDrawing();
                                    org.docx4j.dml.wordprocessingDrawing.ObjectFactory dmlFactory = new org.docx4j.dml.wordprocessingDrawing.ObjectFactory();
                                    drawing.getAnchorOrInline().add(inlineImage);
                                    
                                    runContent.set(i, drawing);
                                    continue;
                                }
                            }
                        }
                        
                        while (matcher.find()) {
                            String key = matcher.group(1).trim().toUpperCase();
                            String rawVal = inputs.getOrDefault(key, "<<" + key + ">>");
                            String replacement = formatIfDate(key, rawVal);
                            matcher.appendReplacement(sb, Matcher.quoteReplacement(replacement));
                            substituted = true;
                        }
                        if (substituted) {
                            matcher.appendTail(sb);
                            String resultText = sb.toString();
                            if (resultText.contains("\n")) {
                                String[] lines = resultText.split("\r?\n", -1);
                                ObjectFactory factory = new ObjectFactory();
                                runContent.remove(i);
                                int insertPos = i;
                                for (int lineIdx = 0; lineIdx < lines.length; lineIdx++) {
                                    if (lineIdx > 0) {
                                        runContent.add(insertPos++, factory.createBr());
                                    }
                                    Text lineText = factory.createText();
                                    lineText.setValue(lines[lineIdx]);
                                    lineText.setSpace("preserve");
                                    runContent.add(insertPos++, lineText);
                                }
                                i = insertPos - 1;
                            } else {
                                text.setValue(resultText);
                            }
                        }
                    }
                }
            }
        }
    }

    private static final Pattern ISO_DATE_PATTERN = Pattern.compile("^(\\d{4})-(\\d{1,2})-(\\d{1,2})$");
    private static final String[] MONTH_NAMES = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};

    private String formatIfDate(String key, String value) {
        if (value == null || value.trim().isEmpty()) return value;
        String trimmed = value.trim();
        if (key.contains("DATE") || key.contains("DT") || trimmed.matches("^\\d{4}-\\d{1,2}-\\d{1,2}$")) {
            Matcher m = ISO_DATE_PATTERN.matcher(trimmed);
            if (m.matches()) {
                int year = Integer.parseInt(m.group(1));
                int month = Integer.parseInt(m.group(2));
                int day = Integer.parseInt(m.group(3));
                if (month >= 1 && month <= 12) {
                    return String.format("%02d-%s-%04d", day, MONTH_NAMES[month - 1], year);
                }
            }
        }
        return value;
    }

    private void replaceDrawingInParagraph(P p, Object originalDrawingPart, Inline newInline) {
        ClassFinder drawingFinder = new ClassFinder(Drawing.class);
        new TraversalUtil(p, drawingFinder);
        for (Object dObj : drawingFinder.results) {
            Drawing drawing = (Drawing) dObj;
            for (int j = 0; j < drawing.getAnchorOrInline().size(); j++) {
                Object anchorOrInline = unwrap(drawing.getAnchorOrInline().get(j));
                if (anchorOrInline == originalDrawingPart) {
                    drawing.getAnchorOrInline().set(j, newInline);
                    return;
                }
            }
        }
    }

    private byte[] getUploadedOrPlaceholderImage(String key, Map<String, byte[]> images, Map<String, String> inputs) {
        // 1. Try bytes map
        if (images != null && images.containsKey(key) && images.get(key) != null) {
            return images.get(key);
        }
        
        // 2. Try inputs map (e.g. if it contains base64 string or mock filename)
        if (inputs != null && inputs.containsKey(key)) {
            String val = inputs.get(key);
            if (val != null && !val.trim().isEmpty()) {
                if (val.startsWith("data:image") && val.contains(";base64,")) {
                    try {
                        String base64Data = val.substring(val.indexOf(";base64,") + 8);
                        return Base64.getDecoder().decode(base64Data);
                    } catch (Exception ignored) {}
                }
                try {
                    return Base64.getDecoder().decode(val);
                } catch (Exception ignored) {}
            }
        }
        
        // 3. Fallback: Generate a nice styled placeholder image
        try {
            int width = 600;
            int height = 400;
            BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
            Graphics2D g = image.createGraphics();
            
            // Background
            g.setColor(new java.awt.Color(30, 87, 164)); // Brand blue
            g.fillRect(0, 0, width, height);
            
            // Subtle border
            g.setColor(new java.awt.Color(255, 255, 255, 100));
            g.setStroke(new BasicStroke(4));
            g.drawRect(20, 20, width - 40, height - 40);
            
            // Blueprint-style grid
            g.setColor(new java.awt.Color(255, 255, 255, 30));
            g.setStroke(new BasicStroke(1));
            for (int x = 40; x < width; x += 40) {
                g.drawLine(x, 20, x, height - 20);
            }
            for (int y = 40; y < height; y += 40) {
                g.drawLine(20, y, width - 20, y);
            }
            
            // Text rendering
            g.setColor(java.awt.Color.WHITE);
            g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
            
            g.setFont(new Font("Arial", Font.BOLD, 24));
            String title = "VALUATION REPORT IMAGE SLOT";
            FontMetrics fm = g.getFontMetrics();
            int titleX = (width - fm.stringWidth(title)) / 2;
            g.drawString(title, titleX, 150);
            
            g.setFont(new Font("Monospaced", Font.PLAIN, 18));
            String keyLabel = "<< " + key + " >>";
            FontMetrics fm2 = g.getFontMetrics();
            int labelX = (width - fm2.stringWidth(keyLabel)) / 2;
            g.drawString(keyLabel, labelX, 220);
            
            g.setFont(new Font("Arial", Font.ITALIC, 14));
            String note = "Status: Placeholder Asset Bound";
            FontMetrics fm3 = g.getFontMetrics();
            int noteX = (width - fm3.stringWidth(note)) / 2;
            g.drawString(note, noteX, 280);
            
            g.dispose();
            
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ImageIO.write(image, "png", baos);
            return baos.toByteArray();
        } catch (Exception e) {
            return null;
        }
    }

    private byte[] padImageToFitEmu(byte[] originalImageBytes, long emuCx, long emuCy) {
        try {
            // Approx EMU to pixel conversion (96 DPI)
            int targetW = (int) (emuCx / 9525);
            int targetH = (int) (emuCy / 9525);
            if (targetW <= 0 || targetH <= 0) return originalImageBytes;

            BufferedImage srcImg = ImageIO.read(new ByteArrayInputStream(originalImageBytes));
            if (srcImg == null) return originalImageBytes;

            double scaleX = (double) targetW / srcImg.getWidth();
            double scaleY = (double) targetH / srcImg.getHeight();
            double scale = Math.min(scaleX, scaleY);

            int scaledW = (int) (srcImg.getWidth() * scale);
            int scaledH = (int) (srcImg.getHeight() * scale);

            BufferedImage canvas = new BufferedImage(targetW, targetH, BufferedImage.TYPE_INT_ARGB);
            Graphics2D g = canvas.createGraphics();
            // Transparent background by default for ARGB
            g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

            int x = (targetW - scaledW) / 2;
            int y = (targetH - scaledH) / 2;
            g.drawImage(srcImg, x, y, scaledW, scaledH, null);
            g.dispose();

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ImageIO.write(canvas, "png", baos);
            return baos.toByteArray();
        } catch (Exception e) {
            return originalImageBytes;
        }
    }

    public byte[] convertDocxToPdf(byte[] docxBytes) throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.load(new ByteArrayInputStream(docxBytes));
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        Docx4J.toPDF(wordMLPackage, out);
        return out.toByteArray();
    }

    public byte[] stampDigitalSignature(byte[] docxBytes, String signerName, String timestamp) throws Exception {
        // Signature block removed per workflow configuration.
        // Return the document unmodified.
        return docxBytes;
    }
}
