package com.provaluer.service;

import com.provaluer.model.Order;
import com.provaluer.model.User;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.format.DateTimeFormatter;

@Service
public class QuotePdfGeneratorService {

    private static final Logger log = LoggerFactory.getLogger(QuotePdfGeneratorService.class);
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd-MMM-yyyy");

    public byte[] generateQuotePdf(Order order, User client, User admin) throws IOException {
        log.info("Generating Quotation PDF for quoteNumber={} orderId={}", order.getQuoteNumber(), order.getId());
        try (PDDocument doc = new PDDocument()) {
            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);

            PDType1Font fontBold = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
            PDType1Font fontRegular = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
            PDType1Font fontOblique = new PDType1Font(Standard14Fonts.FontName.HELVETICA_OBLIQUE);

            float width = page.getMediaBox().getWidth();
            float height = page.getMediaBox().getHeight();

            try (PDPageContentStream cs = new PDPageContentStream(doc, page)) {
                // Header Banner: Brand Navy (#0F172A)
                cs.setNonStrokingColor(15 / 255f, 23 / 255f, 42 / 255f);
                cs.addRect(0, height - 90, width, 90);
                cs.fill();

                // Gold Accent Line (#D97706)
                cs.setNonStrokingColor(217 / 255f, 119 / 255f, 6 / 255f);
                cs.addRect(0, height - 94, width, 4);
                cs.fill();

                // Company Header Title
                cs.setNonStrokingColor(1.0f, 1.0f, 1.0f);
                cs.beginText();
                cs.setFont(fontBold, 18);
                cs.newLineAtOffset(40, height - 42);
                cs.showText("PROVALUER COMMERCIAL ADVISORY LLP");
                cs.endText();

                cs.beginText();
                cs.setFont(fontRegular, 9);
                cs.newLineAtOffset(40, height - 58);
                cs.showText("Government Registered & IBBI Licensed Commercial Valuation Advisory");
                cs.newLineAtOffset(0, -12);
                cs.showText("Email: desk@provaluer.in  |  Website: www.provaluer.in  |  GSTIN: 24AAAFP1234M1Z2");
                cs.endText();

                // Document Title
                float y = height - 125;
                cs.setNonStrokingColor(15 / 255f, 23 / 255f, 42 / 255f);
                cs.beginText();
                cs.setFont(fontBold, 15);
                cs.newLineAtOffset(40, y);
                cs.showText("COMMERCIAL VALUATION QUOTATION");
                cs.endText();

                // Metadata Box
                y -= 15;
                cs.setNonStrokingColor(248 / 255f, 250 / 255f, 252 / 255f);
                cs.setStrokingColor(226 / 255f, 232 / 255f, 240 / 255f);
                cs.addRect(40, y - 55, width - 80, 55);
                cs.fillAndStroke();

                cs.setNonStrokingColor(15 / 255f, 23 / 255f, 42 / 255f);
                cs.beginText();
                cs.setFont(fontBold, 10);
                cs.newLineAtOffset(55, y - 20);
                cs.showText("Quote Number: ");
                cs.setFont(fontRegular, 10);
                cs.showText(order.getQuoteNumber() != null ? order.getQuoteNumber() : "N/A");

                cs.setFont(fontBold, 10);
                cs.newLineAtOffset(260, 0);
                cs.showText("Date of Issue: ");
                cs.setFont(fontRegular, 10);
                cs.showText(order.getQuotedAt() != null ? order.getQuotedAt().format(DATE_FMT) : "N/A");

                cs.setFont(fontBold, 10);
                cs.newLineAtOffset(-260, -20);
                cs.showText("Mandate Reference: ");
                cs.setFont(fontRegular, 10);
                cs.showText(order.getReferenceCode() != null ? order.getReferenceCode() : "N/A");

                cs.setFont(fontBold, 10);
                cs.newLineAtOffset(260, 0);
                cs.showText("Valid Until: ");
                cs.setFont(fontRegular, 10);
                cs.showText(order.getQuoteValidUntil() != null ? order.getQuoteValidUntil().format(DATE_FMT) : "15 Days");
                cs.endText();

                // Client & Mandate Particulars
                y -= 85;
                cs.setNonStrokingColor(15 / 255f, 23 / 255f, 42 / 255f);
                cs.beginText();
                cs.setFont(fontBold, 11);
                cs.newLineAtOffset(40, y);
                cs.showText("CLIENT & MANDATE DETAILS");
                cs.endText();

                y -= 18;
                String clientName = (client != null && client.getFullName() != null && !client.getFullName().isBlank())
                        ? client.getFullName() : (client != null ? client.getUsername() : "Client");
                String clientEmail = client != null && client.getEmail() != null ? client.getEmail() : "N/A";
                String clientMobile = client != null && client.getMobileNumber() != null ? client.getMobileNumber() : "N/A";
                String service = order.getServiceCategory() != null ? order.getServiceCategory() : "Valuation Report";
                String asset = order.getPropertyCategory() != null ? order.getPropertyCategory() : "Land & Building";
                String purpose = order.getPurpose() != null ? order.getPurpose() : "Bank Collateral / Loan";

                cs.beginText();
                cs.setFont(fontRegular, 9.5f);
                cs.newLineAtOffset(40, y);
                cs.showText("Client Name: " + clientName + "  |  Mobile: " + clientMobile + "  |  Email: " + clientEmail);
                cs.newLineAtOffset(0, -15);
                cs.showText("Service Vertical: " + service + "  |  Asset Category: " + asset);
                cs.newLineAtOffset(0, -15);
                cs.showText("Purpose of Valuation: " + purpose);
                cs.endText();

                // Fee Schedule Table
                y -= 50;
                cs.beginText();
                cs.setFont(fontBold, 11);
                cs.newLineAtOffset(40, y);
                cs.showText("COMMERCIAL FEE SCHEDULE");
                cs.endText();

                y -= 15;
                // Header row
                cs.setNonStrokingColor(241 / 255f, 245 / 255f, 249 / 255f);
                cs.addRect(40, y - 20, width - 80, 20);
                cs.fill();

                cs.setNonStrokingColor(15 / 255f, 23 / 255f, 42 / 255f);
                cs.beginText();
                cs.setFont(fontBold, 9);
                cs.newLineAtOffset(50, y - 14);
                cs.showText("DESCRIPTION");
                cs.newLineAtOffset(340, 0);
                cs.showText("AMOUNT (INR)");
                cs.endText();

                // Base fee row
                y -= 22;
                cs.beginText();
                cs.setFont(fontRegular, 9);
                cs.newLineAtOffset(50, y - 14);
                cs.showText("Professional Valuation Fee (Base)");
                cs.newLineAtOffset(340, 0);
                cs.showText("INR " + (order.getQuoteAmount() != null ? order.getQuoteAmount().toPlainString() : "0.00"));
                cs.endText();

                // GST row
                y -= 20;
                cs.beginText();
                cs.setFont(fontRegular, 9);
                cs.newLineAtOffset(50, y - 14);
                cs.showText("Goods & Services Tax (GST @ 18%)");
                cs.newLineAtOffset(340, 0);
                cs.showText("INR " + (order.getQuoteTax() != null ? order.getQuoteTax().toPlainString() : "0.00"));
                cs.endText();

                // Total row
                y -= 24;
                cs.setNonStrokingColor(254 / 255f, 243 / 255f, 199 / 255f);
                cs.addRect(40, y - 22, width - 80, 22);
                cs.fill();

                cs.setNonStrokingColor(180 / 255f, 83 / 255f, 9 / 255f);
                cs.beginText();
                cs.setFont(fontBold, 10);
                cs.newLineAtOffset(50, y - 15);
                cs.showText("TOTAL PAYABLE FEE (INCL. TAXES):");
                cs.newLineAtOffset(340, 0);
                cs.showText("INR " + (order.getQuoteTotal() != null ? order.getQuoteTotal().toPlainString() : "0.00"));
                cs.endText();

                // SLA & Turnaround
                y -= 45;
                cs.setNonStrokingColor(15 / 255f, 23 / 255f, 42 / 255f);
                cs.beginText();
                cs.setFont(fontBold, 10);
                cs.newLineAtOffset(40, y);
                cs.showText("Committed Turnaround: ");
                cs.setFont(fontRegular, 10);
                cs.showText(order.getQuoteTurnaround() != null ? order.getQuoteTurnaround() : "3-5 Working Days from site inspection");
                cs.endText();

                // Scope Notes
                y -= 25;
                cs.beginText();
                cs.setFont(fontBold, 10);
                cs.newLineAtOffset(40, y);
                cs.showText("Scope of Valuation:");
                cs.endText();

                y -= 14;
                cs.beginText();
                cs.setFont(fontRegular, 8.5f);
                cs.newLineAtOffset(40, y);
                String notes = order.getQuoteNotes() != null ? order.getQuoteNotes() : "Comprehensive physical inspection and market valuation.";
                if (notes.length() > 180) notes = notes.substring(0, 177) + "...";
                cs.showText(notes);
                cs.endText();

                // Terms & Conditions
                y -= 25;
                cs.beginText();
                cs.setFont(fontBold, 10);
                cs.newLineAtOffset(40, y);
                cs.showText("Terms & Conditions:");
                cs.endText();

                y -= 14;
                cs.beginText();
                cs.setFont(fontRegular, 8.5f);
                cs.newLineAtOffset(40, y);
                String terms = order.getQuoteTerms() != null ? order.getQuoteTerms() : "Standard engagement terms apply. Report issued digitally upon finalization.";
                if (terms.length() > 180) terms = terms.substring(0, 177) + "...";
                cs.showText(terms);
                cs.endText();

                // Signatory
                y -= 55;
                cs.beginText();
                cs.setFont(fontBold, 9.5f);
                cs.newLineAtOffset(width - 240, y);
                cs.showText("For ProValuer Valuation Advisory LLP");
                cs.setFont(fontOblique, 8.5f);
                cs.newLineAtOffset(0, -22);
                cs.showText("[Digital Verification & Stamped Copy]");
                cs.setFont(fontRegular, 8.5f);
                cs.newLineAtOffset(0, -12);
                cs.showText("Authorized Signatory");
                cs.endText();

                // Footer
                cs.setNonStrokingColor(100 / 255f, 116 / 255f, 139 / 255f);
                cs.beginText();
                cs.setFont(fontRegular, 7.5f);
                cs.newLineAtOffset(40, 24);
                cs.showText("This document is a formal quotation issued by ProValuer. Generated on " +
                        (order.getQuotedAt() != null ? order.getQuotedAt().format(DATE_FMT) : "N/A") + " for Reference " +
                        (order.getReferenceCode() != null ? order.getReferenceCode() : "N/A"));
                cs.endText();
            }

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            doc.save(baos);
            return baos.toByteArray();
        }
    }
}
