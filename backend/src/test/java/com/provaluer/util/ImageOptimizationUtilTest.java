package com.provaluer.util;

import org.junit.jupiter.api.Test;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;

import static org.junit.jupiter.api.Assertions.*;

class ImageOptimizationUtilTest {

    @Test
    void testCompressAndResizeOversizedImage() throws Exception {
        // Create an oversized image (3000 x 2000)
        BufferedImage largeImage = new BufferedImage(3000, 2000, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = largeImage.createGraphics();
        for (int y = 0; y < 2000; y += 10) {
            for (int x = 0; x < 3000; x += 10) {
                g.setColor(new Color((x * y) % 255, (x + y) % 255, (x ^ y) % 255));
                g.fillRect(x, y, 10, 10);
            }
        }
        g.dispose();

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(largeImage, "png", baos);
        byte[] largeBytes = baos.toByteArray();

        // Optimize
        byte[] optimized = ImageOptimizationUtil.compressAndResizeImage(largeBytes);
        assertNotNull(optimized);
        assertTrue(optimized.length < largeBytes.length, "Optimized image must be significantly smaller than uncompressed PNG");

        // Verify dimensions are capped to max 1600
        BufferedImage resultImg = ImageIO.read(new ByteArrayInputStream(optimized));
        assertNotNull(resultImg);
        assertTrue(resultImg.getWidth() <= 1600, "Width must be <= 1600");
        assertTrue(resultImg.getHeight() <= 1600, "Height must be <= 1600");
        assertEquals(1600, resultImg.getWidth(), "Width should be exactly 1600 due to aspect ratio");
        assertEquals((int) Math.round(2000 * (1600.0 / 3000.0)), resultImg.getHeight(), "Height should maintain aspect ratio");
    }

    @Test
    void testNullAndEmptyHandling() {
        assertNull(ImageOptimizationUtil.compressAndResizeImage(null));
        assertArrayEquals(new byte[0], ImageOptimizationUtil.compressAndResizeImage(new byte[0]));
    }
}
