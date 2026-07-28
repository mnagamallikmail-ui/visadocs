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
        for (Object elem : elements) {
            Object unwrapped = unwrap(elem);
            if (unwrapped instanceof P) {
                P p = (P) unwrapped;
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

    private void substituteInParagraph(WordprocessingMLPackage wordMLPackage, P p, Map<String, String> inputs, Map<String, byte[]> images) throws Exception {
        normalizeParagraph(p);
        // First, check if there are drawing elements inside the paragraph
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
            String desc = anchor.getDocPr().getDescr();
            String name = anchor.getDocPr().getName();
            String matchedName = (desc != null && desc.startsWith("IMG_")) ? desc : name;
            if (matchedName != null && (matchedName.toUpperCase().contains("IMG_") || matchedName.toUpperCase().contains("_IMAGE"))) {
                String key = matchedName.toUpperCase();
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
                            String replacement = inputs.getOrDefault(key, "<<" + key + ">>");
                            matcher.appendReplacement(sb, Matcher.quoteReplacement(replacement));
                            substituted = true;
                        }
                        if (substituted) {
                            matcher.appendTail(sb);
                            text.setValue(sb.toString());
                        }
                    }
                }
            }
        }
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
