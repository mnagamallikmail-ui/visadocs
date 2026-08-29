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

        // Build placeholdersSummary
        for (Map.Entry<String, PlaceholderTracker> entry : trackerMap.entrySet()) {
            ObjectNode pSum = placeholdersSummary.addObject();
            pSum.put("key", entry.getKey());
            pSum.put("label", toReadableLabel(entry.getKey()));
            pSum.put("occurrences", entry.getValue().occurrences);
            pSum.put("type", entry.getValue().type);
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

        for (Object rObj : p.getContent()) {
            Object unwrappedR = unwrap(rObj);

            if (unwrappedR instanceof R r) {
                parseRun(r, runsArray, trackerMap);
            } else if (unwrappedR instanceof Drawing || isDrawingElement(unwrappedR)) {
                ObjectNode imgNode = runsArray.addObject();
                imgNode.put("type", "IMAGE");
                imgNode.put("present", true);
            }
        }

        return pNode;
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
                    } else if (unwrappedElem instanceof Drawing || isDrawingElement(unwrappedElem)) {
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
                ObjectNode imgNode = runsArray.addObject();
                imgNode.put("type", "IMAGE");
                imgNode.put("present", true);
            }
        }
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
        ObjectNode runNode = runsArray.addObject();
        runNode.put("text", text);
        runNode.put("isPlaceholder", isPlaceholder);
        if (isPlaceholder && placeholderKey != null) {
            runNode.put("placeholderKey", placeholderKey);
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

        return tblNode;
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

    private String toReadableLabel(String key) {
        String[] parts = key.replace("IMG_", "").replace("_IMAGE", "").split("_");
        StringBuilder sb = new StringBuilder();
        for (String part : parts) {
            if (!part.isEmpty()) {
                sb.append(Character.toUpperCase(part.charAt(0)))
                  .append(part.substring(1).toLowerCase())
                  .append(" ");
            }
        }
        return sb.toString().trim();
    }

    public String generatePlaceholderRegistry(JsonNode domRoot) {
        ObjectNode registry = objectMapper.createObjectNode();
        if (domRoot != null && domRoot.has("placeholdersSummary")) {
            for (JsonNode summary : domRoot.get("placeholdersSummary")) {
                String key = summary.get("key").asText().toUpperCase();
                String type = summary.has("type") ? summary.get("type").asText().toUpperCase() : "TEXT";
                ObjectNode item = registry.putObject(key);
                item.put("type", type);
                item.put("source", "EXPLICIT");
            }
        }
        return registry.toString();
    }

    private static class PlaceholderTracker {
        final String key;
        final String type;
        int occurrences = 0;

        PlaceholderTracker(String key, String type) {
            this.key = key;
            this.type = type;
        }
    }
}
