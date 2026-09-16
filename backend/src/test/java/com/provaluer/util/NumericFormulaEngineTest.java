package com.provaluer.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.P;
import org.docx4j.wml.R;
import org.docx4j.wml.Text;
import org.docx4j.wml.ObjectFactory;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

public class NumericFormulaEngineTest {

    @Test
    @DisplayName("Scenario 1: N1=4700, N2=2026 => CALC:N1*N2 displays 9522200")
    public void testScenario1BasicMultiplication() {
        Map<String, String> inputs = new HashMap<>();
        inputs.put("N1", "4700");
        inputs.put("N2", "2026");

        String expression = "N1*N2";
        NumericFormulaEngine.EvaluationResult result = NumericFormulaEngine.evaluate(expression, inputs);

        assertTrue(result.isValid(), "Result should be valid: " + result.getErrorMessage());
        assertEquals("9522200", result.getFormattedValue());
        assertEquals(9522200.0, result.getValue(), 0.0001);
    }

    @Test
    @DisplayName("Scenario 2: N1=10, N2=20, N3=5 => CALC:(N1+N2)*N3 displays 150")
    public void testScenario2ParenthesesAndPrecedence() {
        Map<String, String> inputs = new HashMap<>();
        inputs.put("N1", "10");
        inputs.put("N2", "20");
        inputs.put("N3", "5");

        String expression = "(N1+N2)*N3";
        NumericFormulaEngine.EvaluationResult result = NumericFormulaEngine.evaluate(expression, inputs);

        assertTrue(result.isValid(), "Result should be valid: " + result.getErrorMessage());
        assertEquals("150", result.getFormattedValue());
        assertEquals(150.0, result.getValue(), 0.0001);
    }

    @Test
    @DisplayName("Scenario 3: Live update N1 changes from 4700 to 5000 => CALC:N1*N2 immediately becomes 10130000")
    public void testScenario3ValueUpdateImmediate() {
        Map<String, String> inputs = new HashMap<>();
        inputs.put("N1", "4700");
        inputs.put("N2", "2026");

        NumericFormulaEngine.EvaluationResult res1 = NumericFormulaEngine.evaluate("N1*N2", inputs);
        assertEquals("9522200", res1.getFormattedValue());

        // Update N1 to 5000
        inputs.put("N1", "5000");
        NumericFormulaEngine.EvaluationResult res2 = NumericFormulaEngine.evaluate("N1*N2", inputs);
        assertEquals("10130000", res2.getFormattedValue());
        assertEquals(10130000.0, res2.getValue(), 0.0001);
    }

    @Test
    @DisplayName("Whitespace invariance: <<CALC:N1*N2>>, <<CALC:N1 * N2>>, <<CALC:( N1 + N2 ) * N3>> work identically")
    public void testWhitespaceInvariance() {
        Map<String, String> inputs = new HashMap<>();
        inputs.put("N1", "10");
        inputs.put("N2", "20");
        inputs.put("N3", "5");

        NumericFormulaEngine.EvaluationResult res1 = NumericFormulaEngine.evaluate("(N1+N2)*N3", inputs);
        NumericFormulaEngine.EvaluationResult res2 = NumericFormulaEngine.evaluate("( N1 + N2 ) * N3", inputs);
        NumericFormulaEngine.EvaluationResult res3 = NumericFormulaEngine.evaluate(" (  N1   +   N2  )  *   N3  ", inputs);

        assertTrue(res1.isValid());
        assertTrue(res2.isValid());
        assertTrue(res3.isValid());
        assertEquals("150", res1.getFormattedValue());
        assertEquals("150", res2.getFormattedValue());
        assertEquals("150", res3.getFormattedValue());
    }

    @Test
    @DisplayName("Complex arithmetic: <<CALC:(N1+N2)*N3/(N4-N5)>>")
    public void testComplexArithmetic() {
        Map<String, String> inputs = new HashMap<>();
        inputs.put("N1", "15");
        inputs.put("N2", "25");
        inputs.put("N3", "10");
        inputs.put("N4", "12");
        inputs.put("N5", "4");

        // (15+25)*10 / (12-4) = 40 * 10 / 8 = 400 / 8 = 50
        NumericFormulaEngine.EvaluationResult result = NumericFormulaEngine.evaluate("(N1+N2)*N3/(N4-N5)", inputs);
        assertTrue(result.isValid());
        assertEquals("50", result.getFormattedValue());
        assertEquals(50.0, result.getValue(), 0.0001);
    }

    @Test
    @DisplayName("Unary minus support: -N1 + (-N2 * -N3)")
    public void testUnaryMinus() {
        Map<String, String> inputs = new HashMap<>();
        inputs.put("N1", "5");
        inputs.put("N2", "4");
        inputs.put("N3", "3");

        // -5 + (-4 * -3) = -5 + 12 = 7
        NumericFormulaEngine.EvaluationResult result = NumericFormulaEngine.evaluate("-N1 + (-N2 * -N3)", inputs);
        assertTrue(result.isValid());
        assertEquals("7", result.getFormattedValue());
    }

    @Test
    @DisplayName("Validation 1: Unknown variable detection e.g. CALC:N1+N99")
    public void testValidationUnknownVariable() {
        Map<String, String> inputs = new HashMap<>();
        inputs.put("N1", "10");

        NumericFormulaEngine.EvaluationResult result = NumericFormulaEngine.evaluate("N1+N99", inputs);
        assertFalse(result.isValid());
        assertTrue(result.getErrorMessage().contains("Unknown variable: N99") || result.getErrorMessage().contains("N99"), "Expected unknown variable error: " + result.getErrorMessage());
    }

    @Test
    @DisplayName("Validation 2: Division by zero detection e.g. CALC:N1/N2 when N2=0")
    public void testValidationDivisionByZero() {
        Map<String, String> inputs = new HashMap<>();
        inputs.put("N1", "100");
        inputs.put("N2", "0");

        NumericFormulaEngine.EvaluationResult result = NumericFormulaEngine.evaluate("N1/N2", inputs);
        assertFalse(result.isValid());
        assertTrue(result.getErrorMessage().contains("Division by zero"), "Expected division by zero error: " + result.getErrorMessage());
    }

    @Test
    @DisplayName("Validation 3: Invalid expression detection e.g. CALC:N1+*N2")
    public void testValidationInvalidExpression() {
        Map<String, String> inputs = new HashMap<>();
        inputs.put("N1", "10");
        inputs.put("N2", "20");

        NumericFormulaEngine.EvaluationResult result = NumericFormulaEngine.evaluate("N1+*N2", inputs);
        assertFalse(result.isValid());
        assertTrue(result.getErrorMessage().toLowerCase().contains("syntax") || result.getErrorMessage().toLowerCase().contains("unexpected"),
                "Expected invalid expression error: " + result.getErrorMessage());
    }

    @Test
    @DisplayName("Validation 4: Mismatched parentheses detection e.g. (N1+N2")
    public void testValidationMismatchedParentheses() {
        Map<String, String> inputs = new HashMap<>();
        inputs.put("N1", "10");
        inputs.put("N2", "20");

        NumericFormulaEngine.EvaluationResult result = NumericFormulaEngine.evaluate("(N1+N2", inputs);
        assertFalse(result.isValid());
        assertTrue(result.getErrorMessage().contains("Mismatched parentheses") || result.getErrorMessage().contains("Expected ')'"),
                "Expected mismatched parentheses error: " + result.getErrorMessage());
    }

    @Test
    @DisplayName("Validation 5: Circular dependency detection e.g. CALC_A -> CALC_B -> CALC_A")
    public void testValidationCircularDependency() {
        Map<String, String> formulas = new HashMap<>();
        formulas.put("CALC:CALC_B+10", "CALC_B+10");
        formulas.put("CALC:CALC_A*2", "CALC_A*2");

        // Set up mapping where A depends on B and B depends on A
        Map<String, String> calcDefs = new HashMap<>();
        calcDefs.put("CALC_A", "CALC_B + 10");
        calcDefs.put("CALC_B", "CALC_A * 2");

        String cycleError = NumericFormulaEngine.detectCircularDependencies(calcDefs);
        assertNotNull(cycleError, "Should detect circular dependency cycle");
        assertTrue(cycleError.contains("Circular dependency detected"));
    }

    @Test
    @DisplayName("Key identification: isNumericInputKey & isFormulaCalcKey")
    public void testKeyIdentification() {
        assertTrue(NumericFormulaEngine.isNumericInputKey("N1"));
        assertTrue(NumericFormulaEngine.isNumericInputKey("<<N1>>"));
        assertTrue(NumericFormulaEngine.isNumericInputKey("N25"));
        assertFalse(NumericFormulaEngine.isNumericInputKey("NAME"));
        assertFalse(NumericFormulaEngine.isNumericInputKey("IMG_PHOTO"));

        assertTrue(NumericFormulaEngine.isFormulaCalcKey("<<CALC:N1*N2>>"));
        assertTrue(NumericFormulaEngine.isFormulaCalcKey("CALC:N1*N2"));
        assertTrue(NumericFormulaEngine.isFormulaCalcKey("CALC:(N1+N2)*N3"));
        assertFalse(NumericFormulaEngine.isFormulaCalcKey("CALCULATOR"));
        assertFalse(NumericFormulaEngine.isFormulaCalcKey("<<N1>>"));

        assertEquals("N1*N2", NumericFormulaEngine.extractFormulaExpression("<<CALC:N1*N2>>"));
        assertEquals("(N1+N2)*N3", NumericFormulaEngine.extractFormulaExpression("CALC:(N1+N2)*N3"));
    }

    @Test
    @DisplayName("Clean number formatting without scientific notation or trailing zeros")
    public void testCleanFormatting() {
        assertEquals("9522200", NumericFormulaEngine.formatResult(9522200.0));
        assertEquals("150", NumericFormulaEngine.formatResult(150.0));
        assertEquals("12.5", NumericFormulaEngine.formatResult(12.5));
        assertEquals("0.333333", NumericFormulaEngine.formatResult(1.0 / 3.0));
    }

    @Test
    @DisplayName("DOCX Generation: Replace <<CALC:N1*N2>> with evaluated value 9522200; formula expression never appears")
    public void testDocxGenerationFormulaReplacement() throws Exception {
        DocxTemplateEngine engine = new DocxTemplateEngine();
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        P p = createParagraphWithText("Total Valuation: <<CALC:N1*N2>>");
        pkg.getMainDocumentPart().getContent().add(p);

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        pkg.save(baos);
        byte[] templateBytes = baos.toByteArray();

        Map<String, String> inputs = new HashMap<>();
        inputs.put("N1", "4700");
        inputs.put("N2", "2026");

        byte[] generatedDocx = engine.generateReport(templateBytes, inputs, Collections.emptyMap());
        assertNotNull(generatedDocx);

        WordprocessingMLPackage resultDoc = WordprocessingMLPackage.load(new ByteArrayInputStream(generatedDocx));
        StringBuilder fullText = new StringBuilder();
        for (Object o : resultDoc.getMainDocumentPart().getContent()) {
            Object unwrapped = (o instanceof jakarta.xml.bind.JAXBElement) ? ((jakarta.xml.bind.JAXBElement<?>) o).getValue() : o;
            if (unwrapped instanceof P) {
                fullText.append(getParagraphContentText((P) unwrapped)).append("\n");
            }
        }

        String docText = fullText.toString();
        assertTrue(docText.contains("Total Valuation: 9522200"), "Output must contain evaluated formula value 9522200, was: " + docText);
        assertFalse(docText.contains("CALC:"), "Output must NEVER contain raw formula expression");
        assertFalse(docText.contains("<<"), "Output must contain no unreplaced placeholders");
    }

    private static final ObjectFactory factory = new ObjectFactory();

    private P createParagraphWithText(String text) {
        P p = factory.createP();
        R r = factory.createR();
        Text t = factory.createText();
        t.setValue(text);
        r.getContent().add(t);
        p.getContent().add(r);
        return p;
    }

    private String getParagraphContentText(P p) {
        StringBuilder sb = new StringBuilder();
        for (Object rObj : p.getContent()) {
            Object unwrappedR = (rObj instanceof jakarta.xml.bind.JAXBElement) ? ((jakarta.xml.bind.JAXBElement<?>) rObj).getValue() : rObj;
            if (unwrappedR instanceof R) {
                R r = (R) unwrappedR;
                for (Object tObj : r.getContent()) {
                    Object unwrappedT = (tObj instanceof jakarta.xml.bind.JAXBElement) ? ((jakarta.xml.bind.JAXBElement<?>) tObj).getValue() : tObj;
                    if (unwrappedT instanceof Text) {
                        sb.append(((Text) unwrappedT).getValue());
                    }
                }
            }
        }
        return sb.toString();
    }
}
