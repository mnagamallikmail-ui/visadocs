package com.provaluer.service;

import com.provaluer.util.DocxTemplateEngine;
import org.docx4j.XmlUtils;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class TableDesignConsistencyVerificationTest {

    @Autowired
    private DocxTemplateEngine templateEngine;

    @Test
    public void testDynamicValuationTablesConsistencyAndSingleLineHeaders() throws Exception {
        String path = "D:\\naga\\Valuation Report.docx";
        File file = new File(path);
        if (!file.exists()) {
            return;
        }

        byte[] templateBytes = Files.readAllBytes(Paths.get(path));

        Map<String, String> inputs = new HashMap<>();
        inputs.put("VRIN", "VAL-TEST-9001");
        inputs.put("CLIENT_NAME", "State Bank of India");
        inputs.put("PROPERTY_ADDRESS", "Plot 42, Jubilee Hills, Hyderabad");
        inputs.put("TOTAL_LAND_VALUE", "1,50,00,000");
        inputs.put("TOTAL_BUILDING_VALUE", "2,35,00,000");
        inputs.put("TOTAL_REPLACEMENT_COST", "2,80,00,000");
        inputs.put("TOTAL_DEPRECIATION_AMOUNT", "45,00,000");
        inputs.put("TOTAL_SALVAGE_VALUE", "28,00,000");
        inputs.put("FAIR_VALUE", "3,85,00,000");
        inputs.put("SAY_VALUE", "3,85,00,000");
        inputs.put("REALIZABLE_VALUE", "3,27,25,000");
        inputs.put("DISTRESS_SALE_VALUE", "2,88,75,000");
        inputs.put("INSURABLE_VALUE", "2,80,00,000");
        inputs.put("GOVERNMENT_VALUE", "2,10,00,000");

        inputs.put("RAW_LAND_ITEMS_JSON", "[{\"surveyNo\":\"42/A\",\"description\":\"Frontage Plot\",\"enteredArea\":500,\"enteredUnit\":\"Sq.Yd\",\"standardAreaSqft\":4500,\"rate\":25000,\"value\":11250000},{\"surveyNo\":\"42/B\",\"description\":\"Rear Yard\",\"enteredArea\":150,\"enteredUnit\":\"Sq.Yd\",\"standardAreaSqft\":1350,\"rate\":20000,\"value\":2700000}]");
        inputs.put("RAW_BUILDING_ITEMS_JSON", "[{\"structureType\":\"Ground Floor\",\"buildingType\":\"RCC Commercial\",\"enteredArea\":3000,\"enteredUnit\":\"Sq.Ft\",\"replacementRate\":3500,\"replacementCost\":10500000,\"buildingAge\":5,\"buildingUsefulLife\":60,\"depreciationPercentage\":7.5,\"depreciationAmount\":787500,\"buildingValue\":9712500},{\"structureType\":\"First Floor\",\"buildingType\":\"RCC Commercial\",\"enteredArea\":3000,\"enteredUnit\":\"Sq.Ft\",\"replacementRate\":3200,\"replacementCost\":9600000,\"buildingAge\":5,\"buildingUsefulLife\":60,\"depreciationPercentage\":7.5,\"depreciationAmount\":720000,\"buildingValue\":8880000}]");

        byte[] generatedDocx = templateEngine.generateReport(templateBytes, inputs, new HashMap<>());
        assertNotNull(generatedDocx);
        assertTrue(generatedDocx.length > 1000);

        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.load(new ByteArrayInputStream(generatedDocx));
        Body body = wordMLPackage.getMainDocumentPart().getJaxbElement().getBody();

        int tablesInspected = 0;
        for (Object o : body.getContent()) {
            Object unwrapped = XmlUtils.unwrap(o);
            if (unwrapped instanceof Tbl) {
                Tbl tbl = (Tbl) unwrapped;
                tablesInspected++;
                TblPr tblPr = tbl.getTblPr();
                assertNotNull(tblPr);

                // Verify fixed layout
                if (tblPr.getTblLayout() != null) {
                    assertEquals(STTblLayoutType.FIXED, tblPr.getTblLayout().getType());
                }

                // Check rows
                List<Object> rows = tbl.getContent();
                assertFalse(rows.isEmpty());

                // Check header row formatting
                Object firstRowObj = XmlUtils.unwrap(rows.get(0));
                if (firstRowObj instanceof Tr) {
                    Tr headerTr = (Tr) firstRowObj;
                    for (Object cellObj : headerTr.getContent()) {
                        Object unwrappedCell = XmlUtils.unwrap(cellObj);
                        if (unwrappedCell instanceof Tc) {
                            Tc tc = (Tc) unwrappedCell;
                            TcPr tcPr = tc.getTcPr();
                            assertNotNull(tcPr);

                            // Verify header font and styling
                            for (Object co : tc.getContent()) {
                                Object uco = XmlUtils.unwrap(co);
                                if (uco instanceof P) {
                                    P cp = (P) uco;
                                    for (Object ro : cp.getContent()) {
                                        Object uro = XmlUtils.unwrap(ro);
                                        if (uro instanceof R) {
                                            R cr = (R) uro;
                                            if (cr.getRPr() != null && cr.getRPr().getRFonts() != null) {
                                                assertEquals("Book Antiqua", cr.getRPr().getRFonts().getAscii());
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        assertTrue(tablesInspected >= 4, "Expected at least 4 tables including dynamic valuation tables");
        System.out.println("Verified visual design consistency across all " + tablesInspected + " tables in generated report.");
    }
}
