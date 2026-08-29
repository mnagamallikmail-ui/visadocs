package com.provaluer.dto;

import java.io.Serializable;
import java.util.List;

/**
 * Data Transfer Object representing the pixel-perfect visual preview layout,
 * page dimensions, and normalized bounding box coordinates for Document Studio.
 */
public class VisualPreviewResponse implements Serializable {
    private static final long serialVersionUID = 1L;

    private Long templateId;
    private String previewSessionId;
    private int totalPages;
    private PageDimensions pageDimensions;
    private List<VisualPage> pages;

    public VisualPreviewResponse() {}

    public VisualPreviewResponse(Long templateId, int totalPages, PageDimensions pageDimensions, List<VisualPage> pages) {
        this.templateId = templateId;
        this.totalPages = totalPages;
        this.pageDimensions = pageDimensions;
        this.pages = pages;
    }

    public VisualPreviewResponse(Long templateId, String previewSessionId, int totalPages, PageDimensions pageDimensions, List<VisualPage> pages) {
        this.templateId = templateId;
        this.previewSessionId = previewSessionId;
        this.totalPages = totalPages;
        this.pageDimensions = pageDimensions;
        this.pages = pages;
    }

    public Long getTemplateId() { return templateId; }
    public void setTemplateId(Long templateId) { this.templateId = templateId; }

    public String getPreviewSessionId() { return previewSessionId; }
    public void setPreviewSessionId(String previewSessionId) { this.previewSessionId = previewSessionId; }

    public int getTotalPages() { return totalPages; }
    public void setTotalPages(int totalPages) { this.totalPages = totalPages; }

    public PageDimensions getPageDimensions() { return pageDimensions; }
    public void setPageDimensions(PageDimensions pageDimensions) { this.pageDimensions = pageDimensions; }

    public List<VisualPage> getPages() { return pages; }
    public void setPages(List<VisualPage> pages) { this.pages = pages; }

    // ─── Sub-models ──────────────────────────────────────────────

    public static class PageDimensions implements Serializable {
        private static final long serialVersionUID = 1L;

        private double widthPt;
        private double heightPt;
        private double aspectRatio;

        public PageDimensions() {}

        public PageDimensions(double widthPt, double heightPt, double aspectRatio) {
            this.widthPt = widthPt;
            this.heightPt = heightPt;
            this.aspectRatio = aspectRatio;
        }

        public double getWidthPt() { return widthPt; }
        public void setWidthPt(double widthPt) { this.widthPt = widthPt; }

        public double getHeightPt() { return heightPt; }
        public void setHeightPt(double heightPt) { this.heightPt = heightPt; }

        public double getAspectRatio() { return aspectRatio; }
        public void setAspectRatio(double aspectRatio) { this.aspectRatio = aspectRatio; }
    }

    public static class VisualPage implements Serializable {
        private static final long serialVersionUID = 1L;

        private int pageIndex;
        private String pageImageUrl;
        private List<VisualPlaceholder> placeholders;

        public VisualPage() {}

        public VisualPage(int pageIndex, String pageImageUrl, List<VisualPlaceholder> placeholders) {
            this.pageIndex = pageIndex;
            this.pageImageUrl = pageImageUrl;
            this.placeholders = placeholders;
        }

        public int getPageIndex() { return pageIndex; }
        public void setPageIndex(int pageIndex) { this.pageIndex = pageIndex; }

        public String getPageImageUrl() { return pageImageUrl; }
        public void setPageImageUrl(String pageImageUrl) { this.pageImageUrl = pageImageUrl; }

        public List<VisualPlaceholder> getPlaceholders() { return placeholders; }
        public void setPlaceholders(List<VisualPlaceholder> placeholders) { this.placeholders = placeholders; }
    }

    public static class VisualPlaceholder implements Serializable {
        private static final long serialVersionUID = 1L;

        private String key;
        private String rawText;
        private int occurrenceIndex;
        private List<NormalizedRect> rectangles;

        public VisualPlaceholder() {}

        public VisualPlaceholder(String key, String rawText, int occurrenceIndex, List<NormalizedRect> rectangles) {
            this.key = key;
            this.rawText = rawText;
            this.occurrenceIndex = occurrenceIndex;
            this.rectangles = rectangles;
        }

        public String getKey() { return key; }
        public void setKey(String key) { this.key = key; }

        public String getRawText() { return rawText; }
        public void setRawText(String rawText) { this.rawText = rawText; }

        public int getOccurrenceIndex() { return occurrenceIndex; }
        public void setOccurrenceIndex(int occurrenceIndex) { this.occurrenceIndex = occurrenceIndex; }

        public List<NormalizedRect> getRectangles() { return rectangles; }
        public void setRectangles(List<NormalizedRect> rectangles) { this.rectangles = rectangles; }
    }

    public static class NormalizedRect implements Serializable {
        private static final long serialVersionUID = 1L;

        private double x;
        private double y;
        private double w;
        private double h;

        public NormalizedRect() {}

        public NormalizedRect(double x, double y, double w, double h) {
            this.x = x;
            this.y = y;
            this.w = w;
            this.h = h;
        }

        public double getX() { return x; }
        public void setX(double x) { this.x = x; }

        public double getY() { return y; }
        public void setY(double y) { this.y = y; }

        public double getW() { return w; }
        public void setW(double w) { this.w = w; }

        public double getH() { return h; }
        public void setH(double h) { this.h = h; }
    }
}
