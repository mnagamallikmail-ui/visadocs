package com.provaluer.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.ImageOutputStream;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.Iterator;

/**
 * Utility for compressing, resizing, and normalizing uploaded and embedded images
 * to prevent OutOfMemoryErrors during PDF/DOCX compilation while preserving crisp
 * 300 DPI print quality.
 */
public class ImageOptimizationUtil {

    private static final Logger log = LoggerFactory.getLogger(ImageOptimizationUtil.class);

    public static final int DEFAULT_MAX_DIMENSION = 1600;
    public static final float DEFAULT_JPEG_QUALITY = 0.85f;

    public static byte[] compressAndResizeImage(byte[] imageBytes) {
        return compressAndResizeImage(imageBytes, DEFAULT_MAX_DIMENSION, DEFAULT_JPEG_QUALITY);
    }

    public static byte[] compressAndResizeImage(byte[] imageBytes, int maxDimension, float quality) {
        if (imageBytes == null || imageBytes.length == 0) {
            return imageBytes;
        }

        try {
            BufferedImage srcImg = ImageIO.read(new ByteArrayInputStream(imageBytes));
            if (srcImg == null) {
                return imageBytes;
            }

            int srcW = srcImg.getWidth();
            int srcH = srcImg.getHeight();
            if (srcW <= 0 || srcH <= 0) {
                return imageBytes;
            }

            // If image is already smaller than maxDimension and under 400 KB, keep it
            if (srcW <= maxDimension && srcH <= maxDimension && imageBytes.length < 400 * 1024) {
                return imageBytes;
            }

            int targetW = srcW;
            int targetH = srcH;
            if (srcW > maxDimension || srcH > maxDimension) {
                double scale = Math.min((double) maxDimension / srcW, (double) maxDimension / srcH);
                targetW = Math.max(1, (int) Math.round(srcW * scale));
                targetH = Math.max(1, (int) Math.round(srcH * scale));
            }

            BufferedImage rgbImg = new BufferedImage(targetW, targetH, BufferedImage.TYPE_INT_RGB);
            Graphics2D g = rgbImg.createGraphics();
            g.setColor(Color.WHITE);
            g.fillRect(0, 0, targetW, targetH);
            g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g.drawImage(srcImg, 0, 0, targetW, targetH, null);
            g.dispose();

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            Iterator<ImageWriter> writers = ImageIO.getImageWritersByFormatName("jpg");
            if (writers.hasNext()) {
                ImageWriter writer = writers.next();
                try (ImageOutputStream ios = ImageIO.createImageOutputStream(baos)) {
                    writer.setOutput(ios);
                    ImageWriteParam param = writer.getDefaultWriteParam();
                    if (param.canWriteCompressed()) {
                        param.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
                        param.setCompressionQuality(quality);
                    }
                    writer.write(null, new IIOImage(rgbImg, null, null), param);
                } finally {
                    writer.dispose();
                }
                byte[] compressed = baos.toByteArray();
                log.info("Optimized image: [{}x{}] {} KB -> [{}x{}] {} KB",
                        srcW, srcH, imageBytes.length / 1024,
                        targetW, targetH, compressed.length / 1024);
                return compressed;
            } else {
                ImageIO.write(rgbImg, "jpg", baos);
                return baos.toByteArray();
            }
        } catch (Exception e) {
            log.warn("Failed to optimize image, returning original bytes: {}", e.getMessage());
            return imageBytes;
        }
    }
}
