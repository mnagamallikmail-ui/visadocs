package com.provaluer.util;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.springframework.stereotype.Component;

import java.io.ByteArrayInputStream;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class DocxStructureParser {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private static final Pattern PLACEHOLDER_PATTERN = Pattern.compile("<<([^>]+)>>");

    /**
     * Helper to unwrap JAXBElement instances (matches DocxTemplateEngine).
     */
    private Object unwrap(Object obj) {
        if (obj instanceof jakarta.xml.bind.JAXBElement) {
            return ((jakarta.xml.bind.JAXBElement<?>) obj).getValue();
        }
        return obj;
    }

    /**
     * Primary entry point: parses raw .docx byte stream into structured JsonNode DOM.
     */
    public JsonNode parseDocumentStructure(byte[] docxBytes) throws Exception {
        if (docxBytes == null || docxBytes.length == 0) {
            throw new IllegalArgumentException("DOCX byte content must not be null or empty");
        }
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.load(new ByteArrayInputStream(docxBytes));
        return parseDocumentStructure(wordMLPackage);
    }

    /**
     * Parses an in-memory WordprocessingMLPackage package in a single pass.
     */
    public JsonNode parseDocumentStructure(WordprocessingMLPackage wordMLPackage) {
        ObjectNode root = objectMapper.createObjectNode();
        ArrayNode sections = root.putArray("sections");
        ArrayNode placeholdersSummary = root.putArray("placeholdersSummary");

        Map<String, PlaceholderTracker> trackerMap = new LinkedHashMap<>();

        List<Object> bodyElements = wordMLPackage.getMainDocumentPart().getContent();

        int sectionIndex = 0;
        int elementIndex = 0;

        ObjectNode currentSection = createSection(sections, sectionIndex++, "1. General Document");
        ArrayNode currentElements = currentSection.withArrayProperty("elements");

        for (Object rawElem : bodyElements) {
            Object unwrapped = unwrap(rawElem);

            if (unwrapped instanceof P p) {
                String pText = getParagraphText(p).trim();

                // Check if this paragraph demarcates a new section
                if (isSectionHeading(p, pText) && !currentElements.isEmpty()) {
                    currentSection = createSection(sections, sectionIndex++, pText.isEmpty() ? "Section " + sectionIndex : pText);
                    currentElements = currentSection.withArrayProperty("elements");
                }

                ObjectNode pNode = parseParagraph(p, "p_" + (elementIndex++), trackerMap);
                currentElements.add(pNode);

            } else if (unwrapped instanceof Tbl tbl) {
                ObjectNode tblNode = parseTable(tbl, "tbl_" + (elementIndex++), trackerMap);
                currentElements.add(tblNode);
            }
        }

        // Build placeholdersSummary with 4-tier priority hierarchy
        for (Map.Entry<String, PlaceholderTracker> entry : trackerMap.entrySet()) {
            PlaceholderTracker tracker = entry.getValue();
            ObjectNode pSum = placeholdersSummary.addObject();
            String key = entry.getKey();
            String humanizedLabel = toHumanizedLabel(key);
            pSum.put("key", key);
            pSum.put("label", humanizedLabel);

            String resolvedQuestion = resolveQuestionText(tracker, key);
            pSum.put("questionText", resolvedQuestion);

            if (tracker.serialNo != null && !tracker.serialNo.trim().isEmpty()) {
                pSum.put("serialNo", tracker.serialNo.trim());
            }
            pSum.put("occurrences", tracker.occurrences);
            pSum.put("type", tracker.type);
            pSum.put("source", tracker.source != null ? tracker.source : "PARAGRAPH");
            if (tracker.tableContext != null) {
                pSum.set("tableContext", tracker.tableContext);
            }
        }

        return root;
    }

    /**
     * Parses a Paragraph (P) into JsonNode.
     */
    public ObjectNode parseParagraph(P p, String id, Map<String, PlaceholderTracker> trackerMap) {
        // 1. Normalize fragmented runs before parsing
        normalizeParagraph(p);

        ObjectNode pNode = objectMapper.createObjectNode();
        pNode.put("type", "PARAGRAPH");
        pNode.put("id", id);
        pNode.put("alignment", getAlignment(p));

        ArrayNode runsArray = pNode.putArray("runs");

        // Scan for all docPr DrawingML elements within paragraph (including AlternateContent / Choice / Inline / Anchor)
        List<org.docx4j.dml.CTNonVisualDrawingProps> docPrList = findDocPrElements(p);
        for (org.docx4j.dml.CTNonVisualDrawingProps docPr : docPrList) {
            parseDocPr(docPr, runsArray, trackerMap);
        }

        for (Object rObj : p.getContent()) {
            Object unwrappedR = unwrap(rObj);

            if (unwrappedR instanceof R r) {
                parseRun(r, runsArray, trackerMap);
            }
        }

        return pNode;
    }

    private List<org.docx4j.dml.CTNonVisualDrawingProps> findDocPrElements(Object root) {
        List<org.docx4j.dml.CTNonVisualDrawingProps> result = new ArrayList<>();
        new org.docx4j.TraversalUtil(root, new org.docx4j.TraversalUtil.Callback() {
            @Override
            public List<Object> apply(Object o) {
                Object unwrapped = unwrap(o);
                if (unwrapped instanceof org.docx4j.dml.CTNonVisualDrawingProps docPr) {
                    result.add(docPr);
                } else if (unwrapped instanceof org.docx4j.dml.wordprocessingDrawing.Inline inline) {
                    if (inline.getDocPr() != null) result.add(inline.getDocPr());
                } else if (unwrapped instanceof org.docx4j.dml.wordprocessingDrawing.Anchor anchor) {
                    if (anchor.getDocPr() != null) result.add(anchor.getDocPr());
                }
                return null;
            }

            @Override
            public boolean shouldTraverse(Object o) {
                return true;
            }

            @Override
            public List<Object> getChildren(Object o) {
                return org.docx4j.TraversalUtil.getChildrenImpl(unwrap(o));
            }

            @Override
            public void walkJAXBElements(Object parent) {
                List<Object> children = getChildren(parent);
                if (children != null) {
                    for (Object o : children) {
                        apply(o);
                        if (shouldTraverse(o)) {
                            walkJAXBElements(o);
                        }
                    }
                }
            }
        });
        return result;
    }

    private void parseDocPr(org.docx4j.dml.CTNonVisualDrawingProps docPr, ArrayNode runsArray, Map<String, PlaceholderTracker> trackerMap) {
        if (docPr == null) return;
        String descr = docPr.getDescr();
        String name = docPr.getName();

        String key = extractImageKeyFromDocPr(descr, name);
        if (key != null) {
            boolean exists = false;
            for (JsonNode rn : runsArray) {
                if (rn.has("placeholderKey") && key.equalsIgnoreCase(rn.get("placeholderKey").asText())) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                ObjectNode runNode = runsArray.addObject();
                runNode.put("text", "<<" + key + ">>");
                runNode.put("isPlaceholder", true);
                runNode.put("placeholderKey", key);
                runNode.put("fieldType", "IMAGE");
                runNode.put("isBold", false);
                runNode.put("isItalic", false);
                runNode.put("fontSizePt", 11.0);
            }

            PlaceholderTracker tracker = trackerMap.computeIfAbsent(key, k -> new PlaceholderTracker(k, "IMAGE"));
            tracker.occurrences++;
            tracker.type = "IMAGE";
            if (descr != null && !descr.trim().isEmpty() && !descr.equalsIgnoreCase(key)) {
                tracker.paragraphContextText = descr.trim();
            } else if (name != null && !name.trim().isEmpty() && !name.equalsIgnoreCase(key)) {
                tracker.paragraphContextText = name.trim();
            }
        }
    }

    /**
     * Reusable run normalization from DocxTemplateEngine.
     * Stitches fragmented runs (e.g., << + CLIENT_NAME + >>) into a single unified run.
     */
    private void normalizeParagraph(P p) {
        StringBuilder fullText = new StringBuilder();
        List<Object> content = p.getContent();
        List<Object> preservedElements = new ArrayList<>();
        RPr firstRunRPr = null;

        for (Object obj : content) {
            Object unwrapped = unwrap(obj);
            if (unwrapped instanceof R run) {
                boolean hasText = false;
                boolean hasDrawing = false;
                StringBuilder runText = new StringBuilder();

                for (Object runElem : run.getContent()) {
                    Object unwrappedElem = unwrap(runElem);
                    if (unwrappedElem instanceof Text textElem) {
                        hasText = true;
                        runText.append(textElem.getValue());
                    } else {
                        hasDrawing = true;
                    }
                }

                if (hasDrawing) {
                    preservedElements.add(obj);
                }
                if (hasText) {
                    fullText.append(runText);
                    if (firstRunRPr == null && run.getRPr() != null) {
                        firstRunRPr = run.getRPr();
                    }
                }
            } else {
                preservedElements.add(obj);
            }
        }

        String textStr = fullText.toString();
        if (textStr.contains("{{") && textStr.contains("}}")) {
            textStr = textStr.replaceAll("\\{\\{([A-Za-z0-9_]+)\\}\\}", "<<$1>>");
        }
        if (textStr.contains("<<") && textStr.contains(">>")) {
            p.getContent().clear();

            ObjectFactory factory = new ObjectFactory();
            R newRun = factory.createR();
            if (firstRunRPr != null) {
                newRun.setRPr(firstRunRPr);
            }
            Text newText = factory.createText();
            newText.setValue(textStr);
            newRun.getContent().add(newText);
            p.getContent().add(newRun);

            for (Object elem : preservedElements) {
                p.getContent().add(elem);
            }
        }
    }

    /**
     * Parses a Run (R) decomposing text and tokenizing <<PLACEHOLDERS>>.
     */
    private void parseRun(R r, ArrayNode runsArray, Map<String, PlaceholderTracker> trackerMap) {
        RPr rPr = r.getRPr();
        boolean isBold = rPr != null && rPr.getB() != null && rPr.getB().isVal();
        boolean isItalic = rPr != null && rPr.getI() != null && rPr.getI().isVal();
        double fontSizePt = (rPr != null && rPr.getSz() != null && rPr.getSz().getVal() != null)
                ? rPr.getSz().getVal().doubleValue() / 2.0
                : 11.0;
        String fontColor = (rPr != null && rPr.getColor() != null && rPr.getColor().getVal() != null)
                ? "#" + rPr.getColor().getVal()
                : null;

        for (Object contentObj : r.getContent()) {
            Object unwrappedContent = unwrap(contentObj);

            if (unwrappedContent instanceof Text textObj) {
                String rawText = textObj.getValue();
                if (rawText != null && !rawText.isEmpty()) {
                    tokenizeTextRuns(rawText, isBold, isItalic, fontSizePt, fontColor, runsArray, trackerMap);
                }
            } else if (unwrappedContent instanceof Drawing || isDrawingElement(unwrappedContent)) {
                parseDrawingElement(unwrappedContent, runsArray, trackerMap);
            }
        }
    }

    private void parseDrawingElement(Object unwrappedDrawing, ArrayNode runsArray, Map<String, PlaceholderTracker> trackerMap) {
        String key = null;
        String descr = null;
        String title = null;
        String name = null;

        List<Object> inlinesAndAnchors = new ArrayList<>();
        if (unwrappedDrawing instanceof Drawing drawing) {
            for (Object child : drawing.getAnchorOrInline()) {
                inlinesAndAnchors.add(unwrap(child));
            }
        } else {
            inlinesAndAnchors.add(unwrappedDrawing);
        }

        for (Object item : inlinesAndAnchors) {
            org.docx4j.dml.CTNonVisualDrawingProps docPr = null;
            if (item instanceof org.docx4j.dml.wordprocessingDrawing.Inline inline) {
                docPr = inline.getDocPr();
            } else if (item instanceof org.docx4j.dml.wordprocessingDrawing.Anchor anchor) {
                docPr = anchor.getDocPr();
            }

            if (docPr != null) {
                descr = docPr.getDescr();
                name = docPr.getName();

                key = extractImageKeyFromDocPr(descr, name);
                if (key != null) {
                    break;
                }
            }
        }

        if (key != null) {
            boolean exists = false;
            for (JsonNode rn : runsArray) {
                if (rn.has("placeholderKey") && key.equalsIgnoreCase(rn.get("placeholderKey").asText())) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                ObjectNode runNode = runsArray.addObject();
                runNode.put("text", "<<" + key + ">>");
                runNode.put("isPlaceholder", true);
                runNode.put("placeholderKey", key);
                runNode.put("fieldType", "IMAGE");
                runNode.put("isBold", false);
                runNode.put("isItalic", false);
                runNode.put("fontSizePt", 11.0);
            }

            PlaceholderTracker tracker = trackerMap.computeIfAbsent(key, k -> new PlaceholderTracker(k, "IMAGE"));
            tracker.occurrences++;
            tracker.type = "IMAGE";
            if (descr != null && !descr.trim().isEmpty() && !descr.equalsIgnoreCase(key)) {
                tracker.paragraphContextText = descr.trim();
            } else if (name != null && !name.trim().isEmpty() && !name.equalsIgnoreCase(key)) {
                tracker.paragraphContextText = name.trim();
            }
        } else {
            ObjectNode imgNode = runsArray.addObject();
            imgNode.put("type", "IMAGE");
            imgNode.put("present", true);
        }
    }

    private String extractImageKeyFromDocPr(String descr, String name) {
        String[] candidates = new String[]{descr, name};
        for (String c : candidates) {
            if (c == null) continue;
            String trimmed = c.trim();
            if (trimmed.isEmpty()) continue;

            Matcher m = PLACEHOLDER_PATTERN.matcher(trimmed);
            if (m.find()) {
                return m.group(1).trim();
            }

            String upper = trimmed.toUpperCase();
            if (upper.startsWith("IMG_") || upper.startsWith("PHOTO_") || upper.startsWith("IMAGE_") || upper.startsWith("LOGO_")
                    || upper.endsWith("_IMAGE") || upper.endsWith("_IMG") || upper.endsWith("_PHOTO")
                    || upper.contains("IMAGE_") || upper.contains("PHOTO_") || upper.contains("SITE_PHOTO")) {
                return trimmed.replaceAll("[<>]", "").trim();
            }
        }
        return null;
    }

    /**
     * Tokenizes raw text string splitting regular text from <<PLACEHOLDERS>>.
     */
    private void tokenizeTextRuns(String text, boolean isBold, boolean isItalic,
                                  double fontSizePt, String fontColor,
                                  ArrayNode runsArray, Map<String, PlaceholderTracker> trackerMap) {
        Matcher matcher = PLACEHOLDER_PATTERN.matcher(text);
        int lastIndex = 0;

        while (matcher.find()) {
            // Text before placeholder
            if (matcher.start() > lastIndex) {
                String plainText = text.substring(lastIndex, matcher.start());
                appendRunNode(runsArray, plainText, false, null, isBold, isItalic, fontSizePt, fontColor);
            }

            // Placeholder token
            String fullToken = matcher.group(0);
            String key = matcher.group(1).trim();

            appendRunNode(runsArray, fullToken, true, key, isBold, isItalic, fontSizePt, fontColor);

            // Record in tracker
            PlaceholderTracker tracker = trackerMap.computeIfAbsent(key, k -> new PlaceholderTracker(k, inferFieldType(k)));
            tracker.occurrences++;

            // Priority 2 paragraph context: capture meaningful label before the placeholder in paragraph
            if (matcher.start() > lastIndex) {
                String plainBefore = text.substring(lastIndex, matcher.start()).trim();
                String cleanedContext = cleanContextText(plainBefore);
                if (cleanedContext != null && !cleanedContext.isEmpty() && tracker.paragraphContextText == null) {
                    tracker.paragraphContextText = cleanedContext;
                }
            }

            lastIndex = matcher.end();
        }

        // Remaining trailing text
        if (lastIndex < text.length()) {
            String trailingText = text.substring(lastIndex);
            appendRunNode(runsArray, trailingText, false, null, isBold, isItalic, fontSizePt, fontColor);
        }
    }

    private void appendRunNode(ArrayNode runsArray, String text, boolean isPlaceholder,
                               String placeholderKey, boolean isBold, boolean isItalic,
                               double fontSizePt, String fontColor) {
        if (!isPlaceholder) {
            if (text == null || text.isEmpty()) {
                return;
            }
            String trimmed = text.trim();
            // Orphan text cleanup: remove stray parser noise like standalone 'n', 'r', '_', or empty whitespace runs
            if (trimmed.length() == 1 && (trimmed.equals("n") || trimmed.equals("r") || trimmed.equals("_") || trimmed.equals("`"))) {
                return;
            }
        }
        ObjectNode runNode = runsArray.addObject();
        runNode.put("text", text != null ? text : "");
        runNode.put("isPlaceholder", isPlaceholder);
        if (isPlaceholder && placeholderKey != null) {
            runNode.put("placeholderKey", placeholderKey);
            runNode.put("fieldType", inferFieldType(placeholderKey));
        }
        runNode.put("isBold", isBold);
        runNode.put("isItalic", isItalic);
        runNode.put("fontSizePt", fontSizePt);
        if (fontColor != null) {
            runNode.put("fontColor", fontColor);
        }
    }

    /**
     * Parses a Table (Tbl) into JsonNode.
     */
    public ObjectNode parseTable(Tbl tbl, String id, Map<String, PlaceholderTracker> trackerMap) {
        ObjectNode tblNode = objectMapper.createObjectNode();
        tblNode.put("type", "TABLE");
        tblNode.put("id", id);

        ArrayNode rowsArray = tblNode.putArray("rows");

        int rowIndex = 0;
        int maxColumns = 0;

        for (Object rowObj : tbl.getContent()) {
            Object unwrappedRow = unwrap(rowObj);
            if (unwrappedRow instanceof Tr tr) {
                ObjectNode rowNode = rowsArray.addObject();
                rowNode.put("rowIndex", rowIndex);
                ArrayNode cellsArray = rowNode.putArray("cells");

                int cellIndex = 0;
                for (Object cellObj : tr.getContent()) {
                    Object unwrappedCell = unwrap(cellObj);
                    if (unwrappedCell instanceof Tc tc) {
                        ObjectNode cellNode = parseCell(tc, id + "_r" + rowIndex + "_c" + cellIndex, trackerMap);
                        cellsArray.add(cellNode);
                        cellIndex++;
                    }
                }
                maxColumns = Math.max(maxColumns, cellIndex);
                rowIndex++;
            }
        }

        tblNode.put("rowCount", rowIndex);
        tblNode.put("columnCount", maxColumns);

        // Analyze and enrich semantic roles for tables (2-col, 3-col, headers, subheaders, static text)
        analyzeSemanticTable(tblNode, rowsArray, maxColumns, trackerMap);

        return tblNode;
    }

    /**
     * Semantic Analyzer: Enriches table rows and cells with semantic roles and Q&A bindings.
     */
    private void analyzeSemanticTable(ObjectNode tblNode, ArrayNode rowsArray, int maxColumns, Map<String, PlaceholderTracker> trackerMap) {
        String tableId = tblNode.path("id").asText("tbl");

        for (int r = 0; r < rowsArray.size(); r++) {
            ObjectNode rowNode = (ObjectNode) rowsArray.get(r);
            int rowIndex = rowNode.path("rowIndex").asInt(r);
            ArrayNode cellsArray = (ArrayNode) rowNode.path("cells");
            int numCells = cellsArray.size();

            if (numCells == 0) continue;

            // Extract plain text and placeholders for each cell in this row
            List<String> cellTexts = new ArrayList<>(numCells);
            List<List<String>> cellPlaceholdersList = new ArrayList<>(numCells);
            boolean rowHasPlaceholders = false;

            for (int c = 0; c < numCells; c++) {
                ObjectNode cellNode = (ObjectNode) cellsArray.get(c);
                String plainText = extractCellPlainText(cellNode).trim();
                cellNode.put("plainText", plainText);
                cellTexts.add(plainText);

                List<String> cellPlaceholders = extractCellPlaceholderKeys(cellNode);
                cellPlaceholdersList.add(cellPlaceholders);
                if (!cellPlaceholders.isEmpty()) {
                    rowHasPlaceholders = true;
                }
            }

            // Case 1: Merged Section Sub-header (single cell spanning entire table or colSpan > 1, no placeholders)
            if (numCells == 1 && !rowHasPlaceholders) {
                ObjectNode cellNode = (ObjectNode) cellsArray.get(0);
                int colSpan = cellNode.path("colSpan").asInt(1);
                if (colSpan >= maxColumns || maxColumns <= 1 || colSpan > 1) {
                    rowNode.put("rowType", "SECTION_SUBHEADER");
                    cellNode.put("cellRole", "HEADER");
                    cellNode.put("isSubHeader", true);
                    continue;
                }
            }

            // Case 2: Multi-Column Table Header Row (rowIndex == 0, numCells > 1, and no placeholders)
            if (rowIndex == 0 && !rowHasPlaceholders) {
                rowNode.put("rowType", "TABLE_HEADER");
                for (int c = 0; c < numCells; c++) {
                    ObjectNode cellNode = (ObjectNode) cellsArray.get(c);
                    cellNode.put("cellRole", "HEADER");
                    cellNode.put("isHeader", true);
                }
                continue;
            }

            // Case 3: 3-Column Table Pattern (Rule A: Col 0 = INDEX, Col 1 = QUESTION, Col 2 = ANSWER)
            if (numCells == 3 && !cellPlaceholdersList.get(2).isEmpty()
                    && cellPlaceholdersList.get(0).isEmpty() && cellPlaceholdersList.get(1).isEmpty()) {
                rowNode.put("rowType", "QUESTION_ANSWER");

                ObjectNode c0 = (ObjectNode) cellsArray.get(0);
                ObjectNode c1 = (ObjectNode) cellsArray.get(1);
                ObjectNode c2 = (ObjectNode) cellsArray.get(2);

                c0.put("cellRole", "INDEX");
                c1.put("cellRole", "QUESTION");
                c1.put("targetAnswerCellId", c2.path("cellId").asText());

                c2.put("cellRole", "ANSWER");
                c2.put("sourceQuestionCellId", c1.path("cellId").asText());

                String serialNo = cellTexts.get(0);
                String questionText = cellTexts.get(1);
                List<String> keys = cellPlaceholdersList.get(2);

                ArrayNode bindings = c2.putArray("placeholderBindings");
                for (String key : keys) {
                    ObjectNode binding = bindings.addObject();
                    binding.put("key", key);
                    if (!serialNo.isEmpty()) binding.put("serialNo", serialNo);
                    binding.put("questionText", questionText);
                    binding.put("fieldType", inferFieldType(key));

                    // Enrich trackerMap with authentic table question & context
                    PlaceholderTracker tracker = trackerMap.get(key);
                    if (tracker != null) {
                        tracker.questionText = questionText;
                        if (!serialNo.isEmpty()) tracker.serialNo = serialNo;
                        tracker.source = "TABLE_ROW";
                        ObjectNode ctx = objectMapper.createObjectNode();
                        ctx.put("tableId", tableId);
                        ctx.put("rowIndex", rowIndex);
                        ctx.put("questionCellId", c1.path("cellId").asText());
                        ctx.put("answerCellId", c2.path("cellId").asText());
                        tracker.tableContext = ctx;
                    }
                }
                continue;
            }

            // Case 4: 2-Column Table Pattern (Rule B: Col 0 = QUESTION, Col 1 = ANSWER)
            if (numCells == 2 && !cellPlaceholdersList.get(1).isEmpty() && cellPlaceholdersList.get(0).isEmpty()) {
                rowNode.put("rowType", "QUESTION_ANSWER");

                ObjectNode c0 = (ObjectNode) cellsArray.get(0);
                ObjectNode c1 = (ObjectNode) cellsArray.get(1);

                c0.put("cellRole", "QUESTION");
                c0.put("targetAnswerCellId", c1.path("cellId").asText());

                c1.put("cellRole", "ANSWER");
                c1.put("sourceQuestionCellId", c0.path("cellId").asText());

                String questionText = cellTexts.get(0);
                List<String> keys = cellPlaceholdersList.get(1);

                ArrayNode bindings = c1.putArray("placeholderBindings");
                for (String key : keys) {
                    ObjectNode binding = bindings.addObject();
                    binding.put("key", key);
                    binding.put("questionText", questionText);
                    binding.put("fieldType", inferFieldType(key));

                    PlaceholderTracker tracker = trackerMap.get(key);
                    if (tracker != null) {
                        tracker.questionText = questionText;
                        tracker.serialNo = null;
                        tracker.source = "TABLE_ROW";
                        ObjectNode ctx = objectMapper.createObjectNode();
                        ctx.put("tableId", tableId);
                        ctx.put("rowIndex", rowIndex);
                        ctx.put("questionCellId", c0.path("cellId").asText());
                        ctx.put("answerCellId", c1.path("cellId").asText());
                        tracker.tableContext = ctx;
                    }
                }
                continue;
            }

            // Case 5: Generic Multi-Column or irregular table with placeholders
            if (rowHasPlaceholders) {
                rowNode.put("rowType", "QUESTION_ANSWER");
                for (int c = 0; c < numCells; c++) {
                    ObjectNode cellNode = (ObjectNode) cellsArray.get(c);
                    List<String> keys = cellPlaceholdersList.get(c);

                    if (!keys.isEmpty()) {
                        cellNode.put("cellRole", "ANSWER");
                        ArrayNode bindings = cellNode.putArray("placeholderBindings");

                        String questionText = "";
                        String questionCellId = null;
                        if (c > 0 && cellPlaceholdersList.get(c - 1).isEmpty()) {
                            ObjectNode prevCell = (ObjectNode) cellsArray.get(c - 1);
                            prevCell.put("cellRole", "QUESTION");
                            prevCell.put("targetAnswerCellId", cellNode.path("cellId").asText());
                            questionText = cellTexts.get(c - 1);
                            questionCellId = prevCell.path("cellId").asText();
                            cellNode.put("sourceQuestionCellId", questionCellId);
                        }

                        for (String key : keys) {
                            ObjectNode binding = bindings.addObject();
                            binding.put("key", key);
                            if (!questionText.isEmpty()) binding.put("questionText", questionText);
                            binding.put("fieldType", inferFieldType(key));

                            PlaceholderTracker tracker = trackerMap.get(key);
                            if (tracker != null && !questionText.isEmpty() && (tracker.questionText == null || tracker.questionText.isEmpty())) {
                                tracker.questionText = questionText;
                                tracker.source = "TABLE_ROW";
                                ObjectNode ctx = objectMapper.createObjectNode();
                                ctx.put("tableId", tableId);
                                ctx.put("rowIndex", rowIndex);
                                if (questionCellId != null) ctx.put("questionCellId", questionCellId);
                                ctx.put("answerCellId", cellNode.path("cellId").asText());
                                tracker.tableContext = ctx;
                            }
                        }
                    } else if (!cellNode.has("cellRole")) {
                        cellNode.put("cellRole", "STATIC_TEXT");
                    }
                }
                continue;
            }

            // Case 6: Default Static Content Row
            rowNode.put("rowType", "STATIC_ROW");
            for (int c = 0; c < numCells; c++) {
                ObjectNode cellNode = (ObjectNode) cellsArray.get(c);
                if (!cellNode.has("cellRole")) {
                    cellNode.put("cellRole", "STATIC_TEXT");
                }
            }
        }
    }

    /**
     * Extracts concatenated plain text from all paragraphs within a cell.
     */
    private String extractCellPlainText(ObjectNode cellNode) {
        StringBuilder sb = new StringBuilder();
        JsonNode paragraphs = cellNode.path("paragraphs");
        if (paragraphs.isArray()) {
            for (JsonNode p : paragraphs) {
                JsonNode runs = p.path("runs");
                if (runs.isArray()) {
                    for (JsonNode r : runs) {
                        if (!r.path("isPlaceholder").asBoolean(false) && r.has("text")) {
                            sb.append(r.path("text").asText()).append(" ");
                        }
                    }
                }
            }
        }
        return sb.toString().trim();
    }

    /**
     * Collects all placeholder keys present in a cell.
     */
    private List<String> extractCellPlaceholderKeys(ObjectNode cellNode) {
        List<String> keys = new ArrayList<>();
        JsonNode paragraphs = cellNode.path("paragraphs");
        if (paragraphs.isArray()) {
            for (JsonNode p : paragraphs) {
                JsonNode runs = p.path("runs");
                if (runs.isArray()) {
                    for (JsonNode r : runs) {
                        if (r.path("isPlaceholder").asBoolean(false) && r.has("placeholderKey")) {
                            keys.add(r.path("placeholderKey").asText());
                        }
                    }
                }
            }
        }
        return keys;
    }

    /**
     * Parses a Table Cell (Tc) into JsonNode.
     */
    private ObjectNode parseCell(Tc tc, String cellId, Map<String, PlaceholderTracker> trackerMap) {
        ObjectNode cellNode = objectMapper.createObjectNode();
        cellNode.put("cellId", cellId);

        TcPr tcPr = tc.getTcPr();

        // 1. Column Span (gridSpan)
        int colSpan = 1;
        if (tcPr != null && tcPr.getGridSpan() != null && tcPr.getGridSpan().getVal() != null) {
            colSpan = tcPr.getGridSpan().getVal().intValue();
        }
        cellNode.put("colSpan", colSpan);

        // 2. Vertical Merge (vMerge)
        String vMerge = "none";
        if (tcPr != null && tcPr.getVMerge() != null) {
            String val = tcPr.getVMerge().getVal();
            if (val == null || "continue".equalsIgnoreCase(val)) {
                vMerge = "continue";
            } else if ("restart".equalsIgnoreCase(val)) {
                vMerge = "restart";
            }
        }
        cellNode.put("vMerge", vMerge);

        // 3. Cell Paragraphs
        ArrayNode paragraphsArray = cellNode.putArray("paragraphs");
        int cellPIndex = 0;

        for (Object cellElem : tc.getContent()) {
            Object unwrappedElem = unwrap(cellElem);
            if (unwrappedElem instanceof P p) {
                ObjectNode pNode = parseParagraph(p, cellId + "_p" + (cellPIndex++), trackerMap);
                paragraphsArray.add(pNode);
            } else if (unwrappedElem instanceof Tbl nestedTbl) {
                ObjectNode nestedTblNode = parseTable(nestedTbl, cellId + "_tbl" + (cellPIndex++), trackerMap);
                paragraphsArray.add(nestedTblNode);
            }
        }

        return cellNode;
    }

    private ObjectNode createSection(ArrayNode sections, int index, String title) {
        ObjectNode section = sections.addObject();
        section.put("sectionIndex", index);
        section.put("title", title);
        section.putArray("elements");
        return section;
    }

    private boolean isSectionHeading(P p, String text) {
        if (text == null || text.trim().isEmpty()) {
            return false;
        }
        String clean = text.trim();
        if (clean.matches("^[0-9]+(\\.[0-9]+)*\\s+.*") || clean.startsWith("Heading") || clean.startsWith("Section")) {
            return true;
        }
        if (p.getPPr() != null && p.getPPr().getPStyle() != null && p.getPPr().getPStyle().getVal() != null) {
            return p.getPPr().getPStyle().getVal().startsWith("Heading");
        }
        return false;
    }

    private String getAlignment(P p) {
        if (p.getPPr() != null && p.getPPr().getJc() != null && p.getPPr().getJc().getVal() != null) {
            return p.getPPr().getJc().getVal().value().toUpperCase();
        }
        return "LEFT";
    }

    private String getParagraphText(P p) {
        StringBuilder sb = new StringBuilder();
        for (Object obj : p.getContent()) {
            Object unwrapped = unwrap(obj);
            if (unwrapped instanceof R r) {
                for (Object rChild : r.getContent()) {
                    Object unwrappedChild = unwrap(rChild);
                    if (unwrappedChild instanceof Text t) {
                        sb.append(t.getValue());
                    }
                }
            }
        }
        return sb.toString();
    }

    private boolean isDrawingElement(Object obj) {
        if (obj == null) return false;
        String name = obj.getClass().getSimpleName();
        return name.contains("Drawing") || name.contains("Inline") || name.contains("Anchor") || name.contains("Pict");
    }

    private String inferFieldType(String key) {
        String upper = key.toUpperCase();
        if (upper.equals("LAND_TABLE") || upper.equals("DYNAMIC_LAND_TABLE")) {
            return "DYNAMIC_LAND_TABLE";
        }
        if (upper.equals("BUILDING_TABLE") || upper.equals("DYNAMIC_BUILDING_TABLE")) {
            return "DYNAMIC_BUILDING_TABLE";
        }
        if (upper.equals("VALUATION_SUMMARY_TABLE") || upper.equals("DYNAMIC_VALUATION_SUMMARY_TABLE")) {
            return "DYNAMIC_VALUATION_SUMMARY_TABLE";
        }
        if (upper.equals("PROPERTY_VALUE_TABLE") || upper.equals("VALUE_OF_THE_PROPERTY_TABLE") || upper.equals("VALUE_OF_THE_PROPERTY")) {
            return "DYNAMIC_PROPERTY_VALUE_TABLE";
        }
        if (upper.equals("COMPARABLES_TABLE") || upper.equals("DYNAMIC_COMPARABLES_TABLE")) {
            return "DYNAMIC_COMPARABLES_TABLE";
        }
        if (isCalculatedValuationKey(upper)) {
            return "CALCULATED";
        }
        if (upper.startsWith("IMG_") || upper.endsWith("_IMAGE") || upper.contains("PHOTO") || upper.contains("SIGNATURE")) {
            return "IMAGE";
        }
        if (upper.contains("DATE")) {
            return "DATE";
        }
        if (upper.contains("AREA") || upper.contains("RATE") || upper.contains("VALUE") ||
                upper.contains("AMOUNT") || upper.contains("FEE") || upper.contains("TOTAL") ||
                upper.contains("PRICE") || upper.contains("PERCENT") || upper.contains("RATIO")) {
            return "NUMBER";
        }
        return "TEXT";
    }

    public static boolean isCalculatedValuationKey(String key) {
        if (key == null) return false;
        String upper = key.toUpperCase().trim();
        return upper.equals("TOTAL_LAND_VALUE") || upper.equals("TOTAL_LAND_VALUE_WORDS")
                || upper.equals("TOTAL_BUILDING_VALUE") || upper.equals("TOTAL_BUILDING_VALUE_WORDS")
                || upper.equals("TOTAL_REPLACEMENT_COST") || upper.equals("TOTAL_REPLACEMENT_COST_WORDS")
                || upper.equals("TOTAL_DEPRECIATION_AMOUNT") || upper.equals("TOTAL_DEPRECIATION_AMOUNT_WORDS")
                || upper.equals("TOTAL_SALVAGE_VALUE") || upper.equals("TOTAL_SALVAGE_VALUE_WORDS")
                || upper.equals("FAIR_VALUE") || upper.equals("FAIR_VALUE_WORDS")
                || upper.equals("SAY_VALUE") || upper.equals("SAY_VALUE_WORDS")
                || upper.equals("REALIZABLE_VALUE") || upper.equals("REALIZABLE_VALUE_WORDS")
                || upper.equals("DISTRESS_SALE_VALUE") || upper.equals("DISTRESS_SALE_VALUE_WORDS")
                || upper.equals("INSURABLE_VALUE") || upper.equals("INSURABLE_VALUE_WORDS")
                || upper.equals("GOVERNMENT_VALUE") || upper.equals("GOVERNMENT_VALUE_WORDS")
                || upper.equals("REALIZABLE_PERCENTAGE") || upper.equals("DISTRESS_SALE_PERCENTAGE");
    }

    private static final Map<String, String> KNOWN_HUMANIZED_LABELS = new HashMap<>();
    static {
        KNOWN_HUMANIZED_LABELS.put("LAND_TABLE", "Dynamic Multi-Parcel Land Breakdown");
        KNOWN_HUMANIZED_LABELS.put("BUILDING_TABLE", "Dynamic Multi-Structure Building Breakdown");
        KNOWN_HUMANIZED_LABELS.put("VALUATION_SUMMARY_TABLE", "Consolidated Valuation Summary Certificate");
        KNOWN_HUMANIZED_LABELS.put("PROPERTY_VALUE_TABLE", "Value of the Property Assessment");
        KNOWN_HUMANIZED_LABELS.put("COMPARABLES_TABLE", "Market Comparable Sales Analysis");
        KNOWN_HUMANIZED_LABELS.put("VRIN", "Valuer Registration Identification Number");
        KNOWN_HUMANIZED_LABELS.put("REPORT_REF_NO", "Report Reference Number");
        KNOWN_HUMANIZED_LABELS.put("REF_NO", "Reference Number");
        KNOWN_HUMANIZED_LABELS.put("PROP_LOCATION", "Postal Address of the Property");
        KNOWN_HUMANIZED_LABELS.put("PROP_ELE_BILLS_PAID", "Property Tax and Electricity Bills Paid Status");
        KNOWN_HUMANIZED_LABELS.put("MUNI_CORP_VP", "Municipality / Corporation / Village Panchayat Limit");
        KNOWN_HUMANIZED_LABELS.put("ENACTMENTS_COVER", "Covered Under State / Central Government Enactments");
        KNOWN_HUMANIZED_LABELS.put("BELONG_HOSP_SCH", "Belongs to Social Infrastructure (Hospital / School / etc.)");
        KNOWN_HUMANIZED_LABELS.put("CONSTRUCTED_APPROVED_PLAN", "Constructed as per Approved Municipal Plan");
        KNOWN_HUMANIZED_LABELS.put("MASTERPLAN_PROVI", "Master Plan Provisions and Land Use");
        KNOWN_HUMANIZED_LABELS.put("FREEHOLD_LEASEHOLD", "Freehold or Leasehold Status");
        KNOWN_HUMANIZED_LABELS.put("EXIST_MORTGAGE", "Existing Mortgages / Charges / Encumbrances");
        KNOWN_HUMANIZED_LABELS.put("PERSONAL_GUARANTEE", "Personal or Corporate Guarantee Issued");
        KNOWN_HUMANIZED_LABELS.put("WATER_AVAI", "Water Supply Availability");
        KNOWN_HUMANIZED_LABELS.put("SANITARY_AVAI", "Sewerage / Sanitation System Underground or Open");
        KNOWN_HUMANIZED_LABELS.put("ELECTRICITY_AVAI", "Electricity Availability");
        KNOWN_HUMANIZED_LABELS.put("BUS_DIST", "Distance to Nearest Bus Station");
        KNOWN_HUMANIZED_LABELS.put("RAIL_DIST", "Distance to Nearest Railway Station");
        KNOWN_HUMANIZED_LABELS.put("AIRPORT_DIST", "Distance to Nearest Airport");
        KNOWN_HUMANIZED_LABELS.put("OBSERVATION_1", "Observation 1");
        KNOWN_HUMANIZED_LABELS.put("OBSERVATION_2", "Observation 2");
        KNOWN_HUMANIZED_LABELS.put("OBSERVATON_3", "Observation 3");
        KNOWN_HUMANIZED_LABELS.put("TO_ADDRESSEE", "Report Addressee");
        KNOWN_HUMANIZED_LABELS.put("DATE_OF_REPORT", "Date of Report");
        KNOWN_HUMANIZED_LABELS.put("DATE_OF_INSPECTION", "Date of Inspection");
        KNOWN_HUMANIZED_LABELS.put("NAME_OF_THE_OWNER", "Name of the Owner");
        KNOWN_HUMANIZED_LABELS.put("NAME OF THE CLIENT", "Name of the Client");
        KNOWN_HUMANIZED_LABELS.put("PROPERTY_DESCRIPTION", "Property Description");
        KNOWN_HUMANIZED_LABELS.put("PROPERTY_ADDRESS", "Property Address");
        KNOWN_HUMANIZED_LABELS.put("SCOPE_OF_WORK", "Scope of Work");
        KNOWN_HUMANIZED_LABELS.put("PURPOSE", "Purpose of Valuation");
        KNOWN_HUMANIZED_LABELS.put("APPROACH", "Valuation Approach Adopted");
        KNOWN_HUMANIZED_LABELS.put("IMG_FRONT_PAGE", "Front Page Photograph");
        KNOWN_HUMANIZED_LABELS.put("IMG_SECOND_PAGE", "Second Page Photograph");
        KNOWN_HUMANIZED_LABELS.put("IMG_PIC1", "Property Photograph 1");
        KNOWN_HUMANIZED_LABELS.put("IMG_PIC2", "Property Photograph 2");
        KNOWN_HUMANIZED_LABELS.put("IMG_PIC3", "Property Photograph 3");
        KNOWN_HUMANIZED_LABELS.put("IMG_PIC4", "Property Photograph 4");
        KNOWN_HUMANIZED_LABELS.put("IMG_PIC5", "Property Photograph 5");
        KNOWN_HUMANIZED_LABELS.put("IMG_PIC6", "Property Photograph 6");
        KNOWN_HUMANIZED_LABELS.put("IMG_PIC7", "Property Photograph 7");
        KNOWN_HUMANIZED_LABELS.put("IMG_PIC8", "Property Photograph 8");
        KNOWN_HUMANIZED_LABELS.put("PERSON_COORDINATED_FOR_INSPECTION", "Person Coordinated for Inspection");
    }

    private static final Map<String, String> ABBREVIATION_MAP = Map.ofEntries(
        Map.entry("REF", "Reference"),
        Map.entry("NO", "Number"),
        Map.entry("NUM", "Number"),
        Map.entry("DESC", "Description"),
        Map.entry("ADDR", "Address"),
        Map.entry("VAL", "Value"),
        Map.entry("PROP", "Property"),
        Map.entry("ELE", "Electricity"),
        Map.entry("COMM", "Commercial"),
        Map.entry("RES", "Residential"),
        Map.entry("DOC", "Document"),
        Map.entry("DOCS", "Documents"),
        Map.entry("AUTH", "Authority"),
        Map.entry("MGR", "Manager"),
        Map.entry("QTY", "Quantity"),
        Map.entry("AMT", "Amount"),
        Map.entry("OBSERVATON", "Observation"),
        Map.entry("DIST", "Distance"),
        Map.entry("AVAI", "Availability"),
        Map.entry("PROVI", "Provisions")
    );

    /**
     * Cleans prefix text from a paragraph to use as contextual question text (Priority 2).
     */
    private String cleanContextText(String raw) {
        if (raw == null) return null;
        String clean = raw.replaceAll("(?i)^[\\s\\-\\:\\;\\.\\,\\(\\)\\[\\]]+", "")
                          .replaceAll("[\\s\\-\\:\\;\\.\\,\\(\\)\\[\\]]+$", "")
                          .replaceAll("(?i)\\b(Dt\\.?|at|of)\\b$", "")
                          .replaceAll("[\\s\\-\\:\\;]+$", "")
                          .trim();
        if (clean.length() >= 2 && clean.length() <= 80 && !clean.contains("\n")) {
            return clean;
        }
        return null;
    }

    /**
     * Resolves question text adhering to the 4-tier hierarchy:
     * Priority 1: Table question text
     * Priority 2: Paragraph contextual text / Domain Dictionary Expansion
     * Priority 3: Humanized placeholder label
     * Priority 4: Raw placeholder key
     */
    public String resolveQuestionText(PlaceholderTracker tracker, String key) {
        String upperKey = key.trim().toUpperCase();

        // Check if drawing shape name is parser noise (e.g. "Rectangle 1", "n", "r", "_")
        if (tracker.paragraphContextText != null) {
            String pClean = tracker.paragraphContextText.trim();
            if (pClean.matches("(?i)^(Rectangle|TextBox|Picture|Image|Shape)\\s*\\d*$") || pClean.length() <= 1 || pClean.matches("^[_\\-\\.]+$")) {
                tracker.paragraphContextText = null;
            }
        }
        if (tracker.questionText != null) {
            String qClean = tracker.questionText.trim();
            if (qClean.matches("(?i)^(Rectangle|TextBox|Picture|Image|Shape)\\s*\\d*$") || qClean.length() <= 1 || qClean.matches("^[_\\-\\.]+$")) {
                tracker.questionText = null;
            }
        }

        // Priority 1: Table question text
        if (tracker.tableQuestionText != null && !tracker.tableQuestionText.trim().isEmpty()) {
            return tracker.tableQuestionText.trim();
        }
        if (tracker.questionText != null && !tracker.questionText.trim().isEmpty() && !tracker.questionText.equalsIgnoreCase(key)) {
            return tracker.questionText.trim();
        }

        // Domain dictionary expansions (e.g. VRIN, IMG_PIC1 -> Property Photograph 1)
        if (KNOWN_HUMANIZED_LABELS.containsKey(upperKey)) {
            return KNOWN_HUMANIZED_LABELS.get(upperKey);
        }

        // Priority 2: Paragraph contextual text
        if (tracker.paragraphContextText != null && !tracker.paragraphContextText.trim().isEmpty()
                && !tracker.paragraphContextText.equalsIgnoreCase(key)
                && !tracker.paragraphContextText.equalsIgnoreCase(toHumanizedLabel(key))) {
            return tracker.paragraphContextText.trim();
        }

        // Priority 3: Humanized placeholder label
        String humanized = toHumanizedLabel(key);
        if (humanized != null && !humanized.trim().isEmpty() && !humanized.equalsIgnoreCase(key)) {
            return humanized.trim();
        }

        // Priority 4: Raw placeholder key
        return key;
    }

    /**
     * Converts raw placeholder keys into human-readable prompts.
     */
    public String toHumanizedLabel(String rawKey) {
        if (rawKey == null || rawKey.trim().isEmpty()) {
            return "";
        }
        String cleanKey = rawKey.trim();
        String upperKey = cleanKey.toUpperCase();
        if (KNOWN_HUMANIZED_LABELS.containsKey(upperKey)) {
            return KNOWN_HUMANIZED_LABELS.get(upperKey);
        }

        // Clean common prefixes and suffixes
        String cleaned = cleanKey.replaceAll("(?i)^(IMG_|PHOTO_|IMAGE_)", "")
                                 .replaceAll("(?i)(_IMG|_PHOTO|_IMAGE)$", "");

        // Split by underscores, hyphens, spaces, or camelCase transitions
        String[] rawTokens = cleaned.split("[_\\-\\s]+");
        List<String> words = new ArrayList<>();

        for (String token : rawTokens) {
            if (token.isEmpty()) continue;
            // Split camelCase if present
            String[] camelParts = token.split("(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])");
            for (String part : camelParts) {
                if (part.isEmpty()) continue;
                String partUpper = part.toUpperCase();
                if (ABBREVIATION_MAP.containsKey(partUpper)) {
                    words.add(ABBREVIATION_MAP.get(partUpper));
                } else if (part.length() == 1) {
                    words.add(part.toUpperCase());
                } else {
                    words.add(Character.toUpperCase(part.charAt(0)) + part.substring(1).toLowerCase());
                }
            }
        }

        return words.isEmpty() ? cleanKey : String.join(" ", words);
    }

    public String generatePlaceholderRegistry(JsonNode domRoot) {
        ObjectNode registry = objectMapper.createObjectNode();
        if (domRoot != null && domRoot.has("placeholdersSummary")) {
            for (JsonNode summary : domRoot.get("placeholdersSummary")) {
                String key = summary.get("key").asText().toUpperCase();
                String type = summary.has("type") ? summary.get("type").asText().toUpperCase() : "TEXT";
                String source = summary.has("source") ? summary.get("source").asText() : "EXPLICIT";
                ObjectNode item = registry.putObject(key);
                item.put("type", type);
                item.put("source", source);
                item.put("isCalculated", isCalculatedValuationKey(key));
                if (summary.has("questionText")) {
                    item.put("questionText", summary.get("questionText").asText());
                }
                if (summary.has("serialNo")) {
                    item.put("serialNo", summary.get("serialNo").asText());
                }
                if (summary.has("tableContext")) {
                    item.set("tableContext", summary.get("tableContext"));
                }
            }
        }
        return registry.toString();
    }

    private static class PlaceholderTracker {
        final String key;
        String type;
        int occurrences = 0;
        String tableQuestionText;
        String paragraphContextText;
        String questionText;
        String serialNo;
        String source = "PARAGRAPH";
        JsonNode tableContext;

        PlaceholderTracker(String key, String type) {
            this.key = key;
            this.type = type;
        }
    }
}
