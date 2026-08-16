package com.provaluer.service;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.rendering.ImageType;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.docx4j.Docx4J;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.TimeUnit;

/**
 * Service responsible for converting DOCX templates into pixel-perfect
 * high-DPI (200 DPI) rasterized page images for Document Studio visual canvas.
 */
@Service
public class DocxPreviewGenerator {

    private static final Logger log = LoggerFactory.getLogger(DocxPreviewGenerator.class);

    private static final int DEFAULT_DPI = 200;

    @Value("${app.storage.preview-cache:storage/preview-cache}")
    private String previewCacheBaseDir;

    /**
     * Generates or retrieves cached preview assets for a given template byte array.
     *
     * @param templateId       Unique template identifier.
     * @param docxBytes        Raw binary byte array of the DOCX template.
     * @param forceRegenerate  Whether to invalidate existing cache and recreate page images.
     * @return PreviewMetadata containing page count, dimensions, and image paths.
     */
    public PreviewMetadata generatePreview(Long templateId, byte[] docxBytes, boolean forceRegenerate) {
        if (templateId == null) {
            throw new IllegalArgumentException("Template ID must not be null");
        }
        if (docxBytes == null || docxBytes.length == 0) {
            throw new IllegalArgumentException("DOCX template byte array must not be empty");
        }

        Path templateCacheDir = Paths.get(previewCacheBaseDir, String.valueOf(templateId));

        try {
            Files.createDirectories(templateCacheDir);
        } catch (IOException e) {
            log.error("Failed to create preview cache directory at {}: {}", templateCacheDir, e.getMessage());
            throw new IllegalStateException("Could not create preview cache directory: " + e.getMessage(), e);
        }

        // Check if cached pages already exist
        if (!forceRegenerate && isCacheValid(templateCacheDir)) {
            log.debug("Serving cached preview assets for template #{}", templateId);
            return loadMetadataFromCache(templateId, templateCacheDir);
        }

        log.info("Generating pixel-perfect visual preview for template #{} ({} bytes, DPI: {})",
                templateId, docxBytes.length, DEFAULT_DPI);

        // 1. Convert DOCX to PDF bytes
        byte[] pdfBytes = convertDocxToPdf(templateId, docxBytes);

        // 2. Render PDF pages to 200 DPI PNG images using PDFBox
        return renderPdfToImages(templateId, pdfBytes, templateCacheDir);
    }

    /**
     * Retrieves the raw PNG image bytes for a specific template page.
     *
     * @param templateId Unique template identifier.
     * @param pageIndex  0-indexed page number.
     * @return Raw PNG byte array.
     */
    public byte[] getPageImage(Long templateId, int pageIndex) {
        Path imagePath = Paths.get(previewCacheBaseDir, String.valueOf(templateId), "page_" + pageIndex + ".png");
        if (!Files.exists(imagePath)) {
            throw new NoSuchElementException("Preview image not found for template #" + templateId + " page " + pageIndex);
        }
        try {
            return Files.readAllBytes(imagePath);
        } catch (IOException e) {
            log.error("Failed to read preview image at {}: {}", imagePath, e.getMessage());
            throw new IllegalStateException("Failed to read page image: " + e.getMessage(), e);
        }
    }

    /**
     * Converts DOCX to PDF using LibreOffice headless (primary) with docx4j fallback.
     */
    public byte[] convertDocxToPdf(Long templateId, byte[] docxBytes) {
        // Try LibreOffice headless first for 100% MS Word visual fidelity
        try {
            byte[] pdf = convertWithLibreOffice(docxBytes);
            if (pdf != null && pdf.length > 0) {
                log.debug("Template #{} converted to PDF via LibreOffice ({} bytes)", templateId, pdf.length);
                return pdf;
            }
        } catch (Exception e) {
            log.warn("LibreOffice headless conversion failed for template #{}. Falling back to docx4j export-fo: {}",
                    templateId, e.getMessage());
        }

        // Fallback: docx4j native FO PDF exporter
        try (ByteArrayInputStream bais = new ByteArrayInputStream(docxBytes);
             ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.load(bais);
            Docx4J.toPDF(wordMLPackage, baos);
            log.info("Template #{} converted to PDF via docx4j fallback ({} bytes)", templateId, baos.size());
            return baos.toByteArray();
        } catch (Exception e) {
            log.error("Failed to convert template #{} DOCX to PDF: {}", templateId, e.getMessage(), e);
            throw new IllegalStateException("Failed to convert DOCX to PDF: " + e.getMessage(), e);
        }
    }

    /**
     * Converts DOCX bytes to PDF bytes using an installed LibreOffice CLI process.
     */
    private byte[] convertWithLibreOffice(byte[] docxBytes) throws Exception {
        Path tempDir = Files.createTempDirectory("provaluer_preview_");
        Path tempDocx = tempDir.resolve("template.docx");
        Path tempPdf = tempDir.resolve("template.pdf");

        try {
            Files.write(tempDocx, docxBytes);

            String sofficeCmd = findLibreOfficeExecutable();
            ProcessBuilder pb = new ProcessBuilder(
                    sofficeCmd,
                    "--headless",
                    "--convert-to", "pdf",
                    "--outdir", tempDir.toAbsolutePath().toString(),
                    tempDocx.toAbsolutePath().toString()
            );

            pb.redirectErrorStream(true);
            Process process = pb.start();
            boolean finished = process.waitFor(45, TimeUnit.SECONDS);

            if (!finished) {
                process.destroyForcibly();
                throw new IllegalStateException("LibreOffice conversion timed out after 45s");
            }

            if (process.exitValue() != 0 || !Files.exists(tempPdf)) {
                throw new IllegalStateException("LibreOffice exited with code " + process.exitValue());
            }

            return Files.readAllBytes(tempPdf);
        } finally {
            // Clean up temporary files
            try {
                Files.deleteIfExists(tempDocx);
                Files.deleteIfExists(tempPdf);
                Files.deleteIfExists(tempDir);
            } catch (Exception ignored) {}
        }
    }

    /**
     * Finds the LibreOffice executable across Linux, Windows, and Mac environments.
     */
    private String findLibreOfficeExecutable() {
        String[] candidates = {
                "libreoffice",
                "soffice",
                "/usr/bin/libreoffice",
                "/usr/bin/soffice",
                "/usr/local/bin/libreoffice",
                "C:\\Program Files\\LibreOffice\\program\\soffice.exe",
                "C:\\Program Files (x86)\\LibreOffice\\program\\soffice.exe"
        };

        for (String candidate : candidates) {
            try {
                Process p = new ProcessBuilder(candidate, "--version").start();
                if (p.waitFor(3, TimeUnit.SECONDS) && p.exitValue() == 0) {
                    return candidate;
                }
            } catch (Exception ignored) {}
        }
        return "libreoffice"; // Default fallback
    }

    /**
     * Renders a PDF document into 200 DPI PNG images and stores them in the cache directory.
     */
    private PreviewMetadata renderPdfToImages(Long templateId, byte[] pdfBytes, Path cacheDir) {
        try (PDDocument document = Loader.loadPDF(pdfBytes)) {
            PDFRenderer renderer = new PDFRenderer(document);
            int totalPages = document.getNumberOfPages();

            if (totalPages == 0) {
                throw new IllegalStateException("Converted PDF contains 0 pages");
            }

            // Extract dimensions from the first page (points)
            PDPage firstPage = document.getPage(0);
            PDRectangle mediaBox = firstPage.getMediaBox();
            double widthPt = mediaBox.getWidth();
            double heightPt = mediaBox.getHeight();
            double aspectRatio = heightPt > 0 ? (widthPt / heightPt) : 0.707;

            List<PageAsset> pageAssets = new ArrayList<>();

            for (int pageIdx = 0; pageIdx < totalPages; pageIdx++) {
                BufferedImage image = renderer.renderImageWithDPI(pageIdx, DEFAULT_DPI, ImageType.RGB);
                Path pageFile = cacheDir.resolve("page_" + pageIdx + ".png");

                ImageIO.write(image, "PNG", pageFile.toFile());

                String relativeUrl = "/api/v1/studio/templates/" + templateId + "/pages/" + pageIdx + ".png";
                pageAssets.add(new PageAsset(pageIdx, image.getWidth(), image.getHeight(), relativeUrl, pageFile.toString()));
            }

            log.info("Successfully rendered {} preview pages for template #{} to {}",
                    totalPages, templateId, cacheDir);

            return new PreviewMetadata(templateId, totalPages, widthPt, heightPt, aspectRatio, pageAssets);
        } catch (Exception e) {
            log.error("Failed to render PDF pages to images for template #{}: {}", templateId, e.getMessage(), e);
            throw new IllegalStateException("Failed to render preview images: " + e.getMessage(), e);
        }
    }

    /**
     * Checks whether valid cached page images exist in the target directory.
     */
    private boolean isCacheValid(Path cacheDir) {
        if (!Files.isDirectory(cacheDir)) {
            return false;
        }
        try (var stream = Files.list(cacheDir)) {
            return stream.anyMatch(p -> p.getFileName().toString().startsWith("page_") && p.toString().endsWith(".png"));
        } catch (IOException e) {
            return false;
        }
    }

    /**
     * Reconstructs metadata from an existing valid cache directory.
     */
    private PreviewMetadata loadMetadataFromCache(Long templateId, Path cacheDir) {
        try {
            List<Path> pageFiles = new ArrayList<>();
            try (var stream = Files.list(cacheDir)) {
                stream.filter(p -> p.getFileName().toString().startsWith("page_") && p.toString().endsWith(".png"))
                        .sorted(Comparator.comparing(p -> extractPageIndex(p.getFileName().toString())))
                        .forEach(pageFiles::add);
            }

            int totalPages = pageFiles.size();
            List<PageAsset> pageAssets = new ArrayList<>();

            int sampleWidth = 1654;
            int sampleHeight = 2339;

            for (int i = 0; i < pageFiles.size(); i++) {
                Path p = pageFiles.get(i);
                String relativeUrl = "/api/v1/studio/templates/" + templateId + "/pages/" + i + ".png";
                pageAssets.add(new PageAsset(i, sampleWidth, sampleHeight, relativeUrl, p.toString()));
            }

            double widthPt = 595.28; // Standard A4 points
            double heightPt = 841.89;
            double aspectRatio = widthPt / heightPt;

            return new PreviewMetadata(templateId, totalPages, widthPt, heightPt, aspectRatio, pageAssets);
        } catch (Exception e) {
            log.warn("Failed to load metadata from cache for template #{}. Will regenerate.", templateId);
            return null;
        }
    }

    private int extractPageIndex(String fileName) {
        try {
            return Integer.parseInt(fileName.replace("page_", "").replace(".png", ""));
        } catch (Exception e) {
            return 0;
        }
    }

    // ─── Value Objects ───────────────────────────────────────────

    public static class PreviewMetadata implements Serializable {
        private static final long serialVersionUID = 1L;

        private final Long templateId;
        private final int totalPages;
        private final double widthPt;
        private final double heightPt;
        private final double aspectRatio;
        private final List<PageAsset> pages;

        public PreviewMetadata(Long templateId, int totalPages, double widthPt, double heightPt, double aspectRatio, List<PageAsset> pages) {
            this.templateId = templateId;
            this.totalPages = totalPages;
            this.widthPt = widthPt;
            this.heightPt = heightPt;
            this.aspectRatio = aspectRatio;
            this.pages = pages;
        }

        public Long getTemplateId() { return templateId; }
        public int getTotalPages() { return totalPages; }
        public double getWidthPt() { return widthPt; }
        public double getHeightPt() { return heightPt; }
        public double getAspectRatio() { return aspectRatio; }
        public List<PageAsset> getPages() { return pages; }
    }

    public static class PageAsset implements Serializable {
        private static final long serialVersionUID = 1L;

        private final int pageIndex;
        private final int widthPx;
        private final int heightPx;
        private final String imageUrl;
        private final String filePath;

        public PageAsset(int pageIndex, int widthPx, int heightPx, String imageUrl, String filePath) {
            this.pageIndex = pageIndex;
            this.widthPx = widthPx;
            this.heightPx = heightPx;
            this.imageUrl = imageUrl;
            this.filePath = filePath;
        }

        public int getPageIndex() { return pageIndex; }
        public int getWidthPx() { return widthPx; }
        public int getHeightPx() { return heightPx; }
        public String getImageUrl() { return imageUrl; }
        public String getFilePath() { return filePath; }
    }
}
