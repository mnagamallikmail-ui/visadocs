# Indexing Queue Report: Authority Cluster V1

**Date:** 2026-09-24  
**Cluster:** Authority Cluster V1 — Statutory Valuation & Legal Appraisals  
**Canonical Domain:** `https://www.provaluer.in`  

---

## 1. Indexing Queue URLs

The following six canonical URLs have been prepared and formatted for automated and manual indexing submissions:

1. `https://www.provaluer.in/knowledge/government-approved-valuers-complete-guide`
2. `https://www.provaluer.in/knowledge/rule-11ua-complete-guide`
3. `https://www.provaluer.in/knowledge/property-valuation-methods-complete-guide`
4. `https://www.provaluer.in/knowledge/plant-and-machinery-valuation-complete-guide`
5. `https://www.provaluer.in/knowledge/angel-tax-complete-guide`
6. `https://www.provaluer.in/knowledge/visa-and-immigration-valuation-complete-guide`

---

## 2. Search Engine & Discovery Submission Matrix

| Channel / Engine | Submission Mechanism | Priority | Target Timeline | Status |
|:---|:---|:---:|:---:|:---:|
| **Google Search Console** | URL Inspection API & Priority Crawl Request | P0 | Immediate (<24 hrs) | Queued |
| **Bing Webmaster Tools** | IndexNow Protocol & Batch URL Submission | P0 | Immediate (<24 hrs) | Queued |
| **Google AI Overviews / Gemini** | XML Sitemap Ingestion (`sitemap.xml` & `knowledge-sitemap.xml`) | P1 | 48–72 hrs | Enabled |
| **OpenAI / ChatGPT (OAI-SearchBot)** | Direct `robots.txt` allowance + `llms.txt` parse | P1 | 48–72 hrs | Enabled |
| **Perplexity AI (PerplexityBot)** | Direct `robots.txt` allowance + Structured Data Extraction | P1 | 48–72 hrs | Enabled |
| **Microsoft Copilot** | Bing IndexNow ingestion + OpenGraph rich card discovery | P1 | 48–72 hrs | Enabled |

---

## 3. Crawler Infrastructure Verification

- [x] **Primary Sitemap:** `https://www.provaluer.in/sitemap.xml` regenerated with `<lastmod>2026-09-24</lastmod>`, `<priority>0.9</priority>`.
- [x] **Knowledge Sitemap:** `https://www.provaluer.in/knowledge-sitemap.xml` created with exact 6 cluster URLs, zero duplicates.
- [x] **Robots Directive:** `https://www.provaluer.in/robots.txt` configured with explicit allowances for:
  - `Google-Extended`
  - `GPTBot`
  - `OAI-SearchBot`
  - `PerplexityBot`
  - `ClaudeBot`
  - `Applebot-Extended`
- [x] **LLM Context Discovery:** `https://www.provaluer.in/llms.txt` augmented with Section 10 containing full authority summaries and canonical links.
- [x] **Schema Validation:** JSON-LD schemas validated across `TechArticle`/`Article`, `FAQPage`, `HowTo`, `ProfessionalService`, `BreadcrumbList`, and Wikidata `sameAs` entity mappings.
