package com.provaluer.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * DPDP Act 2023 - Multilingual Statutory Policy & Notice Controller
 * Serves English (en), Hindi (hi), and Telugu (te) translations of:
 * 1. Privacy Notice (Section 5)
 * 2. Consent Notice (Section 6)
 * 3. Cookie & Telemetry Policy (Section 6 & 8)
 * 4. Retention & Erasure Policy (Section 8(7))
 */
@RestController
@RequestMapping("/api/v1/privacy/policies")
@CrossOrigin(origins = "*", maxAge = 3600)
public class DpdpPolicyController {

    private final Map<String, Map<String, Map<String, String>>> policyStore = new HashMap<>();

    public DpdpPolicyController() {
        initEnglishPolicies();
        initHindiPolicies();
        initTeluguPolicies();
    }

    @GetMapping("/{policyType}")
    public ResponseEntity<?> getPolicy(
            @PathVariable String policyType,
            @RequestParam(defaultValue = "en") String lang) {
        String normalizedLang = lang.toLowerCase();
        if (!policyStore.containsKey(normalizedLang)) {
            normalizedLang = "en";
        }

        Map<String, Map<String, String>> langPolicies = policyStore.get(normalizedLang);
        if (!langPolicies.containsKey(policyType.toLowerCase())) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(langPolicies.get(policyType.toLowerCase()));
    }

    private void initEnglishPolicies() {
        Map<String, Map<String, String>> en = new HashMap<>();

        en.put("privacy-notice", Map.of(
                "title", "DPDP Statutory Privacy Notice (Section 5)",
                "version", "DPDP-NOTICE-V2.0",
                "effectiveDate", "2026-01-01",
                "language", "en",
                "dataFiduciary", "Pro Valuer OPC Pvt Ltd, Cyber Towers, HITEC City, Hyderabad, India",
                "dpoContact", "CS / Adv. R. Parthasarathy, Data Protection Officer (dpo@provaluer.in / grievance@provaluer.in)",
                "purposes", "Processing valuation requests, verifying title deeds, issuing legally binding bank and visa immigration valuation certificates, and complying with statutory audit mandates under IBBI and Companies Act 2013.",
                "dataCollected", "Applicant Name, Mobile Number, Email Address, Property Address, Title Deeds, Municipal Tax Receipts, Age/Guardian information for minors, and Bank Loan Particulars.",
                "rightsSummary", "Under DPDP Act 2023 Sections 11-14, you hold the Right to Access, Right to Correction & Erasure, Right to Grievance Redressal, and Right to Nominate."
        ));

        en.put("consent-notice", Map.of(
                "title", "Statutory Consent Notice (Section 6)",
                "version", "CONSENT-V2.0",
                "effectiveDate", "2026-01-01",
                "language", "en",
                "notice", "Consent must be free, specific, informed, unconditional, and unambiguous with a clear affirmative action. Pre-ticked checkboxes and bundled consents are prohibited. You may withdraw consent at any time without penalty for past lawful processing.",
                "withdrawalMechanism", "Consent can be withdrawn through the Client Self-Service Privacy Dashboard or by emailing grievance@provaluer.in."
        ));

        en.put("cookie-policy", Map.of(
                "title", "Cookie & Web Telemetry Policy",
                "version", "COOKIE-V2.0",
                "effectiveDate", "2026-01-01",
                "language", "en",
                "description", "We deploy essential operational session cookies and optional web telemetry (Google Analytics 4 & Microsoft Clarity). Telemetry is never activated without prior explicit affirmative consent. Under Section 9, telemetry is permanently disabled for minors.",
                "optOutNotice", "You may opt out or modify cookie preferences anytime via the banner or the Privacy Hub."
        ));

        en.put("retention-policy", Map.of(
                "title", "Data Retention & Erasure Policy (Section 8(7))",
                "version", "RETENTION-V2.0",
                "effectiveDate", "2026-01-01",
                "language", "en",
                "schedule", "Certified valuation dossiers and signed reports: Retained for 8 years under Section 247 Companies Act and IBBI Valuation Rules. Marketing and transient inquiries: Retained for 90 days. User account profile: Retained for active duration + 180 days post-closure.",
                "erasureProcess", "Automated daily purge sweeps through DataRetentionScheduler. Expired records are cryptographically shredded and logged to audit trails."
        ));

        policyStore.put("en", en);
    }

    private void initHindiPolicies() {
        Map<String, Map<String, String>> hi = new HashMap<>();

        hi.put("privacy-notice", Map.of(
                "title", "डिजिटल व्यक्तिगत डेटा संरक्षण वैधानिक गोपनीयता सूचना (धारा 5)",
                "version", "DPDP-NOTICE-V2.0-HI",
                "effectiveDate", "2026-01-01",
                "language", "hi",
                "dataFiduciary", "प्रो वैल्यूअर ओपीसी प्राइवेट लिमिटेड, साइबर टावर्स, हाईटेक सिटी, हैदराबाद, भारत",
                "dpoContact", "सीएस / एडव. आर. पार्थसारथी, डेटा संरक्षण अधिकारी (dpo@provaluer.in / grievance@provaluer.in)",
                "purposes", "संपत्ति मूल्यांकन अनुरोधों को संसाधित करना, कानूनी दस्तावेजों का सत्यापन, बैंकों और वीजा दूतावासों के लिए प्रमाणित मूल्यांकन रिपोर्ट जारी करना और आईबीबीआई एवं कंपनी अधिनियम के तहत वैधानिक अनुपालन।",
                "dataCollected", "आवेदक का नाम, मोबाइल नंबर, ईमेल, संपत्ति का पता, सेल डीड/दस्तावेज, नगरपालिका कर रसीदें, अवयस्कों के लिए अभिभावक सहमति, एवं बैंक ऋण विवरण।",
                "rightsSummary", "डीपीडीपी अधिनियम 2023 की धारा 11-14 के अंतर्गत आपके पास जानकारी प्राप्त करने का अधिकार, सुधार एवं मिटाने का अधिकार, शिकायत निवारण का अधिकार और नामांकित व्यक्ति (नॉमिनी) नियुक्त करने का अधिकार है।"
        ));

        hi.put("consent-notice", Map.of(
                "title", "वैधानिक सहमति सूचना (धारा 6)",
                "version", "CONSENT-V2.0-HI",
                "effectiveDate", "2026-01-01",
                "language", "hi",
                "notice", "सहमति स्वतंत्र, विशिष्ट, सूचित, बिना शर्त और स्पष्ट सकारात्मक कार्रवाई द्वारा दी जानी चाहिए। पहले से टिक किए गए चेकबॉक्स और बंडल सहमति प्रतिबंधित हैं। आप किसी भी समय अपनी सहमति वापस ले सकते हैं।",
                "withdrawalMechanism", "सहमति क्लाइंट प्राइवेसी डैशबोर्ड से या grievance@provaluer.in पर ईमेल करके किसी भी समय वापस ली जा सकती है।"
        ));

        hi.put("cookie-policy", Map.of(
                "title", "कुकी और वेब टेलीमेट्री नीति",
                "version", "COOKIE-V2.0-HI",
                "effectiveDate", "2026-01-01",
                "language", "hi",
                "description", "हम आवश्यक सत्र कुकीज और वैकल्पिक विश्लेषण (Google Analytics 4 और Microsoft Clarity) का उपयोग करते हैं। स्पष्ट सकारात्मक सहमति के बिना टेलीमेट्री सक्रिय नहीं की जाती है। धारा 9 के तहत अवयस्कों (नाबालिगों) के लिए टेलीमेट्री स्थायी रूप से अक्षम है।",
                "optOutNotice", "आप प्राइवेसी बैनर या प्राइवेसी डैशबोर्ड के माध्यम से कभी भी ऑप्ट-आउट कर सकते हैं।"
        ));

        hi.put("retention-policy", Map.of(
                "title", "डेटा प्रतिधारण और मिटाने की नीति (धारा 8(7))",
                "version", "RETENTION-V2.0-HI",
                "effectiveDate", "2026-01-01",
                "language", "hi",
                "schedule", "प्रमाणित मूल्यांकन रिपोर्ट और डोजियर: कंपनी अधिनियम धारा 247 एवं आईबीबीआई नियमों के तहत 8 वर्षों तक सुरक्षित रखे जाते हैं। अस्थायी लीड्स: 90 दिन। उपयोगकर्ता खाता: सक्रिय अवधि + खाता बंद होने के 180 दिन बाद तक।",
                "erasureProcess", "स्वचालित दैनिक शेड्यूलर द्वारा अवधि समाप्त होने पर डेटा स्थायी रूप से मिटा दिया जाता है।"
        ));

        policyStore.put("hi", hi);
    }

    private void initTeluguPolicies() {
        Map<String, Map<String, String>> te = new HashMap<>();

        te.put("privacy-notice", Map.of(
                "title", "డిజిటల్ వ్యక్తిగత డేటా రక్షణ చట్టబద్ధమైన గోప్యతా నోటీసు (సెక్షన్ 5)",
                "version", "DPDP-NOTICE-V2.0-TE",
                "effectiveDate", "2026-01-01",
                "language", "te",
                "dataFiduciary", "ప్రో వాల్యూయర్ ఒపిసి ప్రైవేట్ లిమిటెడ్, సైబర్ టవర్స్, హైటెక్ సిటీ, హైదరాబాద్, భారతదేశం",
                "dpoContact", "సిఎస్ / అడ్వ. ఆర్. పార్థసారథి, డేటా ప్రొటెక్షన్ ఆఫీసర్ (dpo@provaluer.in / grievance@provaluer.in)",
                "purposes", "ఆస్తి మూల్యాంకన అభ్యర్థనలను ప్రాసెస్ చేయడం, రిజిస్టర్డ్ దస్తావేజుల పరిశీలన, బ్యాంకులు మరియు వీసా ఎంబసీల కోసం అధికారిక సర్టిఫికేట్లు జారీ చేయడం మరియు ఐబిబిఐ చట్ట నిబంధనల అమలు.",
                "dataCollected", "దరఖాస్తుదారు పేరు, మొబైల్ నంబర్, ఈమెయిల్, ఆస్తి చిరునామా, సేల్ డీడ్ రికార్డులు, పన్ను రసీదులు, మైనర్ల కోసం సంరక్షకుల సమ్మతి, మరియు రుణ వివరాలు.",
                "rightsSummary", "డిపిడిపి చట్టం 2023 సెక్షన్లు 11-14 ప్రకారం మీకు డేటాను తెలుసుకునే హక్కు, సవరణ మరియు తొలగింపు హక్కు, ఫిర్యాదుల పరిష్కార హక్కు మరియు నామినీని నియమించే హక్కు ఉన్నాయి."
        ));

        te.put("consent-notice", Map.of(
                "title", "చట్టబద్ధమైన సమ్మతి నోటీసు (సెక్షన్ 6)",
                "version", "CONSENT-V2.0-TE",
                "effectiveDate", "2026-01-01",
                "language", "te",
                "notice", "సమ్మతి అనేది స్పష్టమైన, నిర్దిష్టమైన, సమాచారంతో కూడిన మరియు నిర్ద్వంద్వమైన చర్య ద్వారా మాత్రమే ఇవ్వబడాలి. ముందే టిక్ చేసిన చెక్‌బాక్స్‌లు నిషేధించబడ్డాయి. మీరు ఎప్పుడైనా సమ్మతిని ఉపసంహరించుకోవచ్చు.",
                "withdrawalMechanism", "క్లయింట్ ప్రైవసీ డాష్‌బోర్డ్ ద్వారా లేదా grievance@provaluer.in కు ఈమెయిల్ చేయడం ద్వారా సమ్మతిని ఉపసంహరించుకోవచ్చు."
        ));

        te.put("cookie-policy", Map.of(
                "title", "కుకీ మరియు వెబ్ టెలిమెట్రీ విధానం",
                "version", "COOKIE-V2.0-TE",
                "effectiveDate", "2026-01-01",
                "language", "te",
                "description", "మేము అవసరమైన సెషన్ కుకీలు మరియు ఐచ్ఛిక విశ్లేషణలను (Google Analytics 4 & Microsoft Clarity) ఉపయోగిస్తాము. స్పష్టమైన సమ్మతి లేకుండా టెలిమెట్రీ యాక్టివేట్ చేయబడదు. సెక్షన్ 9 ప్రకారం మైనర్లకు టెలిమెట్రీ శాశ్వతంగా నిలిపివేయబడుతుంది.",
                "optOutNotice", "మీరు ప్రైవసీ బ్యానర్ లేదా డాష్‌బోర్డ్ ద్వారా ఎప్పుడైనా విరమించుకోవచ్చు (ఆప్ట్-అవుట్)."
        ));

        te.put("retention-policy", Map.of(
                "title", "డేటా నిలుపుదల మరియు తొలగింపు విధానం (సెక్షన్ 8(7))",
                "version", "RETENTION-V2.0-TE",
                "effectiveDate", "2026-01-01",
                "language", "te",
                "schedule", "ధృవీకరించబడిన మూల్యాంకన నివేదికలు: కంపెనీల చట్టం సెక్షన్ 247 మరియు ఐబిబిఐ నిబంధనల ప్రకారం 8 సంవత్సరాల పాటు భద్రపరచబడతాయి. తాత్కాలిక విచారణలు: 90 రోజులు. యూజర్ ఖాతా: క్రియాశీల కాలం + రద్దు చేసిన 180 రోజుల వరకు.",
                "erasureProcess", "గడువు ముగిసిన తర్వాత ఆటోమేటెడ్ షెడ్యూలర్ ద్వారా డేటా శాశ్వతంగా తొలగించబడుతుంది."
        ));

        policyStore.put("te", te);
    }
}
