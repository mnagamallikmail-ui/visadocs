package com.provaluer.service;

import com.provaluer.dto.VisualPreviewResponse;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.pdfbox.text.TextPosition;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.*;

/**
 * Service that extracts character-level spatial coordinates for <<KEY>> placeholders
 * from PDF documents and normalizes them to fractional ratios (0.0 - 1.0).
 */
@Service
public class DocxCoordinateExtractor {

    private static final Logger log = LoggerFactory.getLogger(DocxCoordinateExtractor.class);

    private final com.fasterxml.jackson.databind.ObjectMapper objectMapper = new com.fasterxml.jackson.databind.ObjectMapper();

    /**
     * Retrieves coordinates from storage/preview-cache/{templateId}_v{version}/coordinates.json if present;
     * otherwise extracts from PDF bytes, caches to disk, and returns.
     */
    public Map<Integer, List<VisualPreviewResponse.VisualPlaceholder>> getOrExtractCoordinates(
            Long templateId, Integer version, byte[] pdfBytes) {
        int v = (version != null && version > 0) ? version : 1;
        java.nio.file.Path cacheDir = java.nio.file.Paths.get("storage/preview-cache", templateId + "_v" + v);
        if (!java.nio.file.Files.exists(cacheDir)) {
            // Fallback check for unversioned legacy directory
            java.nio.file.Path legacyDir = java.nio.file.Paths.get("storage/preview-cache", String.valueOf(templateId));
            if (java.nio.file.Files.exists(legacyDir)) {
                cacheDir = legacyDir;
            } else {
                try {
                    java.nio.file.Files.createDirectories(cacheDir);
                } catch (Exception ignored) {}
            }
        }

        java.nio.file.Path coordsFile = cacheDir.resolve("coordinates.json");
        if (java.nio.file.Files.exists(coordsFile)) {
            try {
                Map<Integer, List<VisualPreviewResponse.VisualPlaceholder>> cached =
                        objectMapper.readValue(coordsFile.toFile(),
                                new com.fasterxml.jackson.core.type.TypeReference<Map<Integer, List<VisualPreviewResponse.VisualPlaceholder>>>() {});
                log.info("Loaded coordinates from disk cache for template #{} (version {})", templateId, v);
                return cached;
            } catch (Exception e) {
                log.warn("Failed to read cached coordinates.json for template #{}: {}. Re-extracting.", templateId, e.getMessage());
            }
        }

        Map<Integer, List<VisualPreviewResponse.VisualPlaceholder>> extracted = extractCoordinates(pdfBytes);
        try {
            if (java.nio.file.Files.exists(cacheDir)) {
                objectMapper.writeValue(coordsFile.toFile(), extracted);
                log.info("Saved coordinates.json to disk cache for template #{} (version {})", templateId, v);
            }
        } catch (Exception e) {
            log.warn("Failed to persist coordinates.json for template #{}: {}", templateId, e.getMessage());
        }

        return extracted;
    }

    /**
     * Extracts normalized placeholder coordinates for all pages of a PDF document.
     *
     * @param pdfBytes Raw binary byte array of the PDF.
     * @return Map of pageIndex -> List of VisualPlaceholder objects with normalized bounding boxes.
     */
    public Map<Integer, List<VisualPreviewResponse.VisualPlaceholder>> extractCoordinates(byte[] pdfBytes) {
        if (pdfBytes == null || pdfBytes.length == 0) {
            return Collections.emptyMap();
        }

        Map<Integer, List<VisualPreviewResponse.VisualPlaceholder>> result = new HashMap<>();

        try (PDDocument document = Loader.loadPDF(pdfBytes)) {
            int totalPages = document.getNumberOfPages();

            for (int pageIdx = 0; pageIdx < totalPages; pageIdx++) {
                PDPage page = document.getPage(pageIdx);
                PDRectangle mediaBox = page.getMediaBox();
                float pageWidth = mediaBox.getWidth();
                float pageHeight = mediaBox.getHeight();

                CoordinateStripper stripper = new CoordinateStripper(pageIdx, pageWidth, pageHeight);
                stripper.setStartPage(pageIdx + 1);
                stripper.setEndPage(pageIdx + 1);

                // Run stripper on page
                try (Writer dummy = new OutputStreamWriter(new ByteArrayOutputStream())) {
                    stripper.writeText(document, dummy);
                }

                result.put(pageIdx, stripper.getExtractedPlaceholders());
            }
        } catch (Exception e) {
            log.error("Failed to extract placeholder coordinates from PDF: {}", e.getMessage(), e);
        }

        return result;
    }

    /**
     * Custom PDFTextStripper tracking character positions and bounding boxes for <<...>> tokens.
     */
    private static class CoordinateStripper extends PDFTextStripper {

        private final int pageIndex;
        private final float pageWidth;
        private final float pageHeight;

        private final List<VisualPreviewResponse.VisualPlaceholder> extractedPlaceholders = new ArrayList<>();
        private final List<TextPosition> tokenBuffer = new ArrayList<>();
        private final StringBuilder textBuffer = new StringBuilder();
        private int occurrenceCounter = 0;

        CoordinateStripper(int pageIndex, float pageWidth, float pageHeight) throws IOException {
            super();
            this.pageIndex = pageIndex;
            this.pageWidth = pageWidth;
            this.pageHeight = pageHeight;
        }

        List<VisualPreviewResponse.VisualPlaceholder> getExtractedPlaceholders() {
            return extractedPlaceholders;
        }

        @Override
        protected void processTextPosition(TextPosition text) {
            String unicode = text.getUnicode();
            if (unicode == null || unicode.isEmpty()) {
                return;
            }

            textBuffer.append(unicode);
            tokenBuffer.add(text);

            String current = textBuffer.toString();

            // Detect closed placeholder tag
            int openIdx = current.lastIndexOf("<<");
            int closeIdx = current.lastIndexOf(">>");

            if (openIdx != -1 && closeIdx != -1 && closeIdx > openIdx) {
                // We have a full <<KEY>> token
                String fullToken = current.substring(openIdx, closeIdx + 2);
                String rawKey = current.substring(openIdx + 2, closeIdx).trim();

                if (!rawKey.isEmpty()) {
                    List<TextPosition> matchedPositions = new ArrayList<>(
                            tokenBuffer.subList(openIdx, closeIdx + 2)
                    );

                    List<VisualPreviewResponse.NormalizedRect> rects = computeNormalizedRectangles(matchedPositions);

                    if (!rects.isEmpty()) {
                        VisualPreviewResponse.VisualPlaceholder placeholder = new VisualPreviewResponse.VisualPlaceholder(
                                rawKey.toUpperCase(),
                                fullToken,
                                occurrenceCounter++,
                                rects
                        );
                        extractedPlaceholders.add(placeholder);
                    }
                }

                // Reset buffers
                textBuffer.setLength(0);
                tokenBuffer.clear();
            } else if (textBuffer.length() > 200) {
                // Safeguard buffer size if no token opened
                if (!current.contains("<<")) {
                    textBuffer.setLength(0);
                    tokenBuffer.clear();
                }
            }
        }

        /**
         * Computes normalized bounding rectangles for a set of text glyph positions,
         * grouping characters on distinct vertical lines into separate rectangles for multi-line support.
         */
        private List<VisualPreviewResponse.NormalizedRect> computeNormalizedRectangles(List<TextPosition> positions) {
            if (positions.isEmpty()) {
                return Collections.emptyList();
            }

            // Group characters by baseline Y coordinate (threshold ~ 4 points)
            Map<Integer, List<TextPosition>> lines = new LinkedHashMap<>();

            for (TextPosition pos : positions) {
                int lineKey = Math.round(pos.getYDirAdj() / 4.0f);
                lines.computeIfAbsent(lineKey, k -> new ArrayList<>()).add(pos);
            }

            List<VisualPreviewResponse.NormalizedRect> rects = new ArrayList<>();

            for (List<TextPosition> linePositions : lines.values()) {
                float minX = Float.MAX_VALUE;
                float maxX = Float.MIN_VALUE;
                float minY = Float.MAX_VALUE;
                float maxY = Float.MIN_VALUE;

                for (TextPosition tp : linePositions) {
                    float x = tp.getXDirAdj();
                    float y = tp.getYDirAdj() - tp.getHeightDir(); // Top-left Y
                    float w = tp.getWidthDirAdj();
                    float h = tp.getHeightDir();

                    minX = Math.min(minX, x);
                    maxX = Math.max(maxX, x + w);
                    minY = Math.min(minY, y);
                    maxY = Math.max(maxY, y + h);
                }

                float boxWidth = Math.max(maxX - minX, 1.0f);
                float boxHeight = Math.max(maxY - minY, 1.0f);

                // Convert to fractional 0.0 - 1.0 normalized coordinates
                double normX = Math.max(0.0, Math.min(1.0, minX / (double) pageWidth));
                double normY = Math.max(0.0, Math.min(1.0, minY / (double) pageHeight));
                double normW = Math.max(0.0, Math.min(1.0, boxWidth / (double) pageWidth));
                double normH = Math.max(0.0, Math.min(1.0, boxHeight / (double) pageHeight));

                rects.add(new VisualPreviewResponse.NormalizedRect(normX, normY, normW, normH));
            }

            return rects;
        }
    }
}
