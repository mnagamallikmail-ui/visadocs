import os
import re
import json

ARTICLES = [
    {
        "file": "digital-marketing/articles/government-approved-valuers-complete-guide.md",
        "slug": "government-approved-valuers-complete-guide",
        "default_title": "Government Approved Valuers in India: Section 34AB Complete Guide | ProValuer",
        "default_desc": "Definitive guide to Government Approved Valuers under Section 34AB of Wealth Tax Act. Form O-1 reports, FMV 2001, Section 50C capital gains disputes, and probate appraisals.",
        "category": "Statutory Law & Section 34AB Wealth Tax Act",
        "read_time": "35 min read"
    },
    {
        "file": "digital-marketing/articles/rule-11ua-complete-guide.md",
        "slug": "rule-11ua-complete-guide",
        "default_title": "Rule 11UA Valuation Complete Guide: DCF, NAV & Tax Defense | ProValuer",
        "default_desc": "Statutory guide to Rule 11UA valuation under Income Tax Rules: DCF modeling, Adjusted NAV formulas, Section 56(2)(viib) Angel Tax, 50CA, and safe harbor bands.",
        "category": "Corporate Finance & Rule 11UA Valuation",
        "read_time": "38 min read"
    },
    {
        "file": "digital-marketing/articles/property-valuation-methods-complete-guide.md",
        "slug": "property-valuation-methods-complete-guide",
        "default_title": "Property Valuation Methods Complete Guide: Models, IVS & Indian Practice | ProValuer",
        "default_desc": "Master Indian property valuation methods: Sales Comparison, Land & Building DRC, Income Capitalization, DCF, and Residual Land under IVS and Section 34AB rules.",
        "category": "Real Estate & Land Appraisals",
        "read_time": "36 min read"
    },
    {
        "file": "digital-marketing/articles/plant-and-machinery-valuation-complete-guide.md",
        "slug": "plant-and-machinery-valuation-complete-guide",
        "default_title": "Plant & Machinery Valuation Complete Guide: DRC, Methods & IBC Compliance | ProValuer",
        "default_desc": "Complete guide to Plant & Machinery valuation in India: Depreciated Replacement Cost (DRC), MEA modeling, obsolescence, bank haircuts, IBC CIRP, and IVS 300 rules.",
        "category": "Industrial Engineering & Machinery Appraisals",
        "read_time": "32 min read"
    },
    {
        "file": "digital-marketing/articles/angel-tax-complete-guide.md",
        "slug": "angel-tax-complete-guide",
        "default_title": "Angel Tax Complete Guide: Section 56(2)(viib), Rule 11UA DCF & Scrutiny Defense | ProValuer",
        "default_desc": "Master Angel Tax under Section 56(2)(viib): Rule 11UA DCF methods, SEBI Merchant Banker reports, 10% safe harbor band, abolition, and legacy audit defense.",
        "category": "Direct Taxation & Startup Valuation",
        "read_time": "40 min read"
    },
    {
        "file": "digital-marketing/articles/visa-and-immigration-valuation-complete-guide.md",
        "slug": "visa-and-immigration-valuation-complete-guide",
        "default_title": "Visa & Immigration Valuation Guide India: Property Valuation & CA Net Worth | ProValuer",
        "default_desc": "Complete guide to visa property valuation reports & CA net worth certificates in India for US INA 214(b), Canada, UK, Australia, and UAE Golden Visa compliance.",
        "category": "Cross-Border Wealth & Immigration Valuation",
        "read_time": "42 min read"
    }
]

CSS = """
:root {
  --primary: #0F172A;
  --primary-light: #1E293B;
  --secondary: #1E40AF;
  --accent: #2563EB;
  --accent-light: #3B82F6;
  --gold: #D97706;
  --gold-light: #F59E0B;
  --gold-bg: #FEF3C7;
  --text-primary: #0F172A;
  --text-secondary: #475569;
  --text-muted: #64748B;
  --bg-primary: #FFFFFF;
  --bg-secondary: #F8FAFC;
  --bg-tertiary: #F1F5F9;
  --border-color: #E2E8F0;
  --border-light: #CBD5E1;
  --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.08), 0 2px 4px -2px rgba(0, 0, 0, 0.05);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.08), 0 4px 6px -4px rgba(0, 0, 0, 0.04);
}

* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  color: var(--text-primary);
  background-color: var(--bg-primary);
  line-height: 1.7;
  font-size: 16px;
}

h1, h2, h3, h4, h5, h6 {
  font-family: 'Montserrat', sans-serif;
  font-weight: 700;
  color: var(--primary);
  line-height: 1.3;
}

a { color: var(--accent); text-decoration: none; transition: all 0.2s; }
a:hover { color: var(--secondary); text-decoration: underline; }

/* Navbar */
.navbar {
  position: sticky;
  top: 0;
  z-index: 1000;
  background: rgba(15, 23, 42, 0.95);
  backdrop-filter: blur(8px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  padding: 0.75rem 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.brand-logo { display: flex; align-items: center; gap: 0.75rem; text-decoration: none; }
.brand-icon {
  width: 38px; height: 38px; background: linear-gradient(135deg, #2563EB, #1D4ED8);
  border-radius: 8px; display: flex; align-items: center; justify-content: center;
  color: #fff; font-weight: 900; font-size: 1.25rem;
}
.brand-text { display: flex; flex-direction: column; }
.brand-name { font-size: 1.25rem; font-weight: 800; color: #fff; letter-spacing: -0.5px; }
.brand-sub { font-size: 0.65rem; color: #94A3B8; text-transform: uppercase; letter-spacing: 1px; }

.nav-links { display: flex; align-items: center; gap: 1.5rem; list-style: none; }
.nav-links a { color: #E2E8F0; font-size: 0.9rem; font-weight: 500; }
.nav-links a:hover { color: #60A5FA; text-decoration: none; }
.btn-cta {
  background: linear-gradient(135deg, #2563EB, #1D4ED8);
  color: #fff !important;
  padding: 0.5rem 1.25rem;
  border-radius: 6px;
  font-weight: 600 !important;
  box-shadow: 0 2px 4px rgba(37, 99, 235, 0.3);
}
.btn-cta:hover { background: #1D4ED8 !important; transform: translateY(-1px); }

/* Breadcrumbs */
.breadcrumbs-bar {
  background: var(--bg-secondary);
  border-bottom: 1px solid var(--border-color);
  padding: 0.75rem 2rem;
  font-size: 0.85rem;
}
.breadcrumbs {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  list-style: none;
  color: var(--text-muted);
}
.breadcrumbs li+li:before { content: "/"; padding-right: 0.5rem; color: var(--border-light); }
.breadcrumbs a { color: var(--text-secondary); }
.breadcrumbs span { color: var(--text-primary); font-weight: 500; }

/* Article Hero Header */
.article-header {
  background: linear-gradient(180deg, #0F172A 0%, #1E293B 100%);
  color: #fff;
  padding: 4rem 2rem;
  border-bottom: 3px solid var(--gold);
}
.header-container { max-width: 1000px; margin: 0 auto; }
.topic-badge {
  display: inline-block;
  background: rgba(217, 119, 6, 0.2);
  border: 1px solid var(--gold);
  color: #FCD34D;
  padding: 0.3rem 0.8rem;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.75px;
  margin-bottom: 1.5rem;
}
.article-header h1 {
  color: #fff;
  font-size: 2.35rem;
  line-height: 1.25;
  margin-bottom: 1.5rem;
  letter-spacing: -0.5px;
}
.article-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 1.5rem;
  font-size: 0.85rem;
  color: #94A3B8;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  padding-top: 1.25rem;
}
.meta-item { display: flex; align-items: center; gap: 0.4rem; }
.meta-item strong { color: #E2E8F0; }

/* Main Article Container */
.article-wrapper {
  max-width: 1200px;
  margin: 3rem auto;
  padding: 0 1.5rem;
  display: grid;
  grid-template-columns: 300px 1fr;
  gap: 3rem;
  align-items: start;
}

/* Sidebar & TOC */
.sidebar-sticky {
  position: sticky;
  top: 5rem;
  background: var(--bg-secondary);
  border: 1px solid var(--border-color);
  border-radius: 10px;
  padding: 1.5rem;
  box-shadow: var(--shadow-sm);
  max-height: calc(100vh - 6rem);
  overflow-y: auto;
}
.toc-title {
  font-size: 0.95rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--primary);
  margin-bottom: 1rem;
  padding-bottom: 0.5rem;
  border-bottom: 2px solid var(--accent);
}
.toc-list { list-style: none; }
.toc-list li { margin-bottom: 0.6rem; font-size: 0.85rem; }
.toc-list a { color: var(--text-secondary); display: block; line-height: 1.4; }
.toc-list a:hover { color: var(--accent); }

/* Content Body */
.article-content {
  background: #fff;
  color: var(--text-primary);
  min-width: 0;
}
.article-content h2 {
  font-size: 1.7rem;
  margin: 2.5rem 0 1rem;
  padding-bottom: 0.5rem;
  border-bottom: 2px solid var(--bg-tertiary);
  color: var(--primary);
}
.article-content h3 { font-size: 1.3rem; margin: 1.8rem 0 0.8rem; color: var(--primary-light); }
.article-content h4 { font-size: 1.1rem; margin: 1.2rem 0 0.5rem; color: var(--secondary); }
.article-content p { margin-bottom: 1.25rem; font-size: 1.05rem; line-height: 1.75; color: #334155; }
.article-content ul, .article-content ol { margin: 1rem 0 1.5rem 2rem; }
.article-content li { margin-bottom: 0.5rem; font-size: 1.02rem; color: #334155; }
.article-content blockquote {
  border-left: 4px solid var(--accent);
  background: var(--bg-secondary);
  padding: 1.25rem 1.5rem;
  margin: 1.5rem 0;
  border-radius: 0 8px 8px 0;
  font-style: italic;
  color: var(--text-secondary);
}
.article-content table {
  width: 100%;
  border-collapse: collapse;
  margin: 1.5rem 0;
  font-size: 0.9rem;
}
.article-content th, .article-content td {
  padding: 0.75rem 1rem;
  border: 1px solid var(--border-color);
  text-align: left;
}
.article-content th { background: var(--bg-tertiary); font-weight: 700; color: var(--primary); }
.article-content tr:nth-child(even) { background: var(--bg-secondary); }

/* Callout Box */
.callout-box {
  background: #EFF6FF;
  border: 1px solid #BFDBFE;
  border-left: 5px solid #2563EB;
  border-radius: 6px;
  padding: 1.25rem 1.5rem;
  margin: 1.75rem 0;
}
.callout-title { font-weight: 700; color: #1E40AF; margin-bottom: 0.4rem; font-size: 1rem; }

/* FAQ Accordion */
.faq-section {
  margin: 3rem 0;
  background: var(--bg-secondary);
  padding: 2.5rem;
  border-radius: 12px;
  border: 1px solid var(--border-color);
}
.faq-section h2 { border-bottom: none; margin-top: 0; }
.faq-item {
  background: #fff;
  border: 1px solid var(--border-color);
  border-radius: 8px;
  margin-bottom: 1rem;
  overflow: hidden;
  box-shadow: var(--shadow-sm);
}
.faq-question {
  padding: 1.25rem 1.5rem;
  font-weight: 600;
  cursor: pointer;
  background: #fff;
  display: flex;
  justify-content: space-between;
  align-items: center;
  list-style: none;
  font-size: 1.05rem;
  color: var(--primary);
}
.faq-question::-webkit-details-marker { display: none; }
.faq-question:hover { background: var(--bg-secondary); }
.faq-answer {
  padding: 0 1.5rem 1.25rem;
  font-size: 0.98rem;
  line-height: 1.7;
  color: var(--text-secondary);
}

/* Internal Links Cluster Card */
.cluster-nav-card {
  background: #F8FAFC;
  border: 1px solid var(--border-color);
  border-radius: 10px;
  padding: 2rem;
  margin: 3rem 0;
}
.cluster-nav-card h3 { margin-top: 0; margin-bottom: 1rem; }
.cluster-links-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 1rem;
}
.cluster-link-item {
  background: #fff;
  padding: 1rem;
  border-radius: 6px;
  border: 1px solid var(--border-color);
  transition: all 0.2s;
  display: flex;
  flex-direction: column;
}
.cluster-link-item:hover {
  transform: translateY(-2px);
  border-color: var(--accent);
  box-shadow: var(--shadow-sm);
  text-decoration: none;
}
.cluster-link-title { font-weight: 600; color: var(--primary); font-size: 0.95rem; margin-bottom: 0.3rem; }
.cluster-link-desc { font-size: 0.8rem; color: var(--text-muted); }

/* Conversion CTA */
.cta-banner {
  background: linear-gradient(135deg, #0F172A 0%, #1E3A8A 100%);
  color: #fff;
  border-radius: 12px;
  padding: 3rem 2rem;
  text-align: center;
  margin: 3.5rem 0;
  box-shadow: var(--shadow-lg);
  border: 1px solid rgba(255, 255, 255, 0.1);
}
.cta-banner h2 { color: #fff; border-bottom: none; margin-top: 0; font-size: 2rem; }
.cta-banner p { color: #CBD5E1; max-width: 700px; margin: 0.75rem auto 2rem; font-size: 1.1rem; }
.cta-buttons { display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap; }
.btn-primary-gold {
  background: linear-gradient(135deg, #D97706, #B45309);
  color: #fff !important;
  font-weight: 700;
  padding: 0.85rem 2rem;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(217, 119, 6, 0.3);
}
.btn-primary-gold:hover { background: #B45309 !important; transform: translateY(-2px); }
.btn-secondary-outline {
  border: 1px solid rgba(255, 255, 255, 0.3);
  color: #fff !important;
  font-weight: 600;
  padding: 0.85rem 2rem;
  border-radius: 8px;
}
.btn-secondary-outline:hover { background: rgba(255, 255, 255, 0.1); }

/* Footer */
footer {
  background: #0B1120;
  color: #94A3B8;
  padding: 3.5rem 2rem 2rem;
  font-size: 0.9rem;
  border-top: 1px solid #1E293B;
}
.footer-container {
  max-width: 1200px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 2.5rem;
  margin-bottom: 2.5rem;
}
.footer-col h4 { color: #F8FAFC; margin-bottom: 1rem; font-size: 1rem; }
.footer-col ul { list-style: none; margin: 0; }
.footer-col li { margin-bottom: 0.6rem; }
.footer-col a { color: #94A3B8; }
.footer-col a:hover { color: #60A5FA; text-decoration: none; }
.footer-bottom {
  max-width: 1200px;
  margin: 0 auto;
  padding-top: 2rem;
  border-top: 1px solid #1E293B;
  display: flex;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 1rem;
  font-size: 0.8rem;
}

@media (max-width: 900px) {
  .article-wrapper { grid-template-columns: 1fr; }
  .sidebar-sticky { display: none; }
  .navbar { padding: 0.75rem 1rem; }
  .article-header h1 { font-size: 1.8rem; }
}
"""

def slugify(text):
    text = re.sub(r'[^a-zA-Z0-9\s-]', '', text).strip().lower()
    return re.sub(r'[\s]+', '-', text)

def md_to_html(md_text):
    # Process tables
    def replace_table(match):
        table_raw = match.group(0).strip().split('\n')
        html = ['<table>']
        in_tbody = False
        for i, row in enumerate(table_raw):
            row = row.strip()
            if not row or re.match(r'^\s*\|?\s*:?-+:?\s*(\|?\s*:?-+:?\s*)+\|?\s*$', row):
                continue
            cols = [c.strip() for c in row.split('|')]
            if cols and not cols[0]:
                cols.pop(0)
            if cols and not cols[-1]:
                cols.pop()
            
            if i == 0:
                html.append('<thead><tr>')
                for c in cols:
                    html.append(f'<th>{c}</th>')
                html.append('</tr></thead><tbody>')
                in_tbody = True
            else:
                html.append('<tr>')
                for c in cols:
                    html.append(f'<td>{c}</td>')
                html.append('</tr>')
        if in_tbody:
            html.append('</tbody>')
        html.append('</table>')
        return '\n'.join(html)

    # Convert markdown links [text](url)
    md_text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', md_text)
    
    # Bold & italic
    md_text = re.sub(r'\*\*\*([^*]+)\*\*\*', r'<strong><em>\1</em></strong>', md_text)
    md_text = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', md_text)
    md_text = re.sub(r'\*([^*]+)\*', r'<em>\1</em>', md_text)
    
    # Inline code
    md_text = re.sub(r'`([^`]+)`', r'<code>\1</code>', md_text)

    # Tables regex
    table_pattern = re.compile(r'(\|[^\n]+\|\r?\n\|[-:\s|]+\|\r?\n(?:\|[^\n]+\|\r?\n?)+)', re.MULTILINE)
    md_text = table_pattern.sub(replace_table, md_text)

    # Parse line by line
    lines = md_text.split('\n')
    out = []
    in_ul = False
    in_ol = False
    in_faq = False
    in_details = False

    for line in lines:
        sline = line.strip()
        
        # Headers
        if sline.startswith('#### '):
            if in_ul: out.append('</ul>'); in_ul = False
            if in_ol: out.append('</ol>'); in_ol = False
            title = sline[5:].strip()
            out.append(f'<h4 id="{slugify(title)}">{title}</h4>')
            continue
        elif sline.startswith('### '):
            if in_ul: out.append('</ul>'); in_ul = False
            if in_ol: out.append('</ol>'); in_ol = False
            title = sline[4:].strip()
            # Check if FAQ question
            if '?' in title or title.lower().startswith('faq') or in_faq:
                if in_details:
                    out.append('</div></details>')
                    in_details = False
                out.append(f'<details class="faq-item"><summary class="faq-question"><span>{title}</span><span style="font-size:1.25rem;">+</span></summary><div class="faq-answer">')
                in_details = True
            else:
                out.append(f'<h3 id="{slugify(title)}">{title}</h3>')
            continue
        elif sline.startswith('## '):
            if in_details:
                out.append('</div></details>')
                in_details = False
            if in_faq:
                out.append('</div>')
                in_faq = False
            if in_ul: out.append('</ul>'); in_ul = False
            if in_ol: out.append('</ol>'); in_ol = False
            title = sline[3:].strip()
            if 'faq' in title.lower() or 'frequently asked questions' in title.lower():
                in_faq = True
                out.append(f'<div class="faq-section"><h2 id="{slugify(title)}">{title}</h2>')
            else:
                out.append(f'<h2 id="{slugify(title)}">{title}</h2>')
            continue

        # Lists
        if sline.startswith('- ') or sline.startswith('* '):
            if in_ol: out.append('</ol>'); in_ol = False
            if not in_ul: out.append('<ul>'); in_ul = True
            out.append(f'<li>{sline[2:].strip()}</li>')
            continue
        elif re.match(r'^\d+\.\s', sline):
            if in_ul: out.append('</ul>'); in_ul = False
            if not in_ol: out.append('<ol>'); in_ol = True
            item_text = re.sub(r'^\d+\.\s', '', sline)
            out.append(f'<li>{item_text}</li>')
            continue
        else:
            if in_ul: out.append('</ul>'); in_ul = False
            if in_ol: out.append('</ol>'); in_ol = False

        # Blockquote
        if sline.startswith('> '):
            out.append(f'<blockquote>{sline[2:].strip()}</blockquote>')
            continue

        # Dividers
        if sline in ('---', '***', '___'):
            continue

        # Blank or Paragraph
        if not sline:
            continue
        elif sline.startswith('<table') or sline.startswith('</table') or sline.startswith('<tr') or sline.startswith('<th') or sline.startswith('<td') or sline.startswith('<thead') or sline.startswith('<tbody'):
            out.append(line)
        else:
            out.append(f'<p>{sline}</p>')

    if in_details:
        out.append('</div></details>')
    if in_faq:
        out.append('</div>')
    if in_ul:
        out.append('</ul>')
    if in_ol:
        out.append('</ol>')

    return '\n'.join(out)

def build_page(article_meta):
    file_path = article_meta["file"]
    slug = article_meta["slug"]
    
    with open(file_path, "r", encoding="utf-8") as f:
        raw_md = f.read()

    # Extract Meta Title
    m_title = re.search(r'\*\*Meta Title:\*\*\s*(.+)', raw_md)
    page_title = m_title.group(1).strip() if m_title else article_meta["default_title"]

    # Extract Meta Description
    m_desc = re.search(r'\*\*Meta Description:\*\*\s*(.+)', raw_md)
    page_desc = m_desc.group(1).strip() if m_desc else article_meta["default_desc"]

    # Extract Canonical
    m_canon = re.search(r'\*\*Target Canonical URL:\*\*\s*`?([^`\n]+)`?', raw_md)
    canonical_url = m_canon.group(1).strip() if m_canon else f"https://www.provaluer.in/knowledge/{slug}"

    # Extract Keywords
    m_kw = re.search(r'\*\*Primary Keywords:\*\*\s*(.+)', raw_md)
    keywords = m_kw.group(1).strip() if m_kw else "valuation, government approved valuer, IBBI registered valuer"

    # Extract JSON-LD block from Technical Appendix or script tags
    json_ld_str = ""
    json_match = re.search(r'```json\s*(\{[\s\S]+?\})\s*```', raw_md)
    if not json_match:
        json_match = re.search(r'<script type="application/ld\+json">\s*(\{[\s\S]+?\})\s*</script>', raw_md)
    if json_match:
        try:
            # Validate JSON
            parsed_json = json.loads(json_match.group(1))
            if '@graph' in parsed_json:
                types = [x.get('@type') for x in parsed_json['@graph']]
                if 'BreadcrumbList' not in types:
                    parsed_json['@graph'].append({
                        "@type": "BreadcrumbList",
                        "@id": f"{canonical_url}#breadcrumb",
                        "itemListElement": [
                            { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://www.provaluer.in/" },
                            { "@type": "ListItem", "position": 2, "name": "Knowledge Center", "item": "https://www.provaluer.in/knowledge-sitemap.xml" },
                            { "@type": "ListItem", "position": 3, "name": page_title, "item": canonical_url }
                        ]
                    })
            json_ld_str = json.dumps(parsed_json, indent=2)
        except Exception as e:
            print(f"Warning: JSON parse error in {slug}: {e}")

    # Fallback JSON-LD if not found
    if not json_ld_str:
        json_ld_str = json.dumps({
            "@context": "https://schema.org",
            "@graph": [
                {
                    "@type": "Article",
                    "@id": f"{canonical_url}#article",
                    "isPartOf": {
                        "@type": "WebPage",
                        "@id": canonical_url
                    },
                    "headline": page_title,
                    "description": page_desc,
                    "url": canonical_url,
                    "inLanguage": "en-IN",
                    "publisher": {
                        "@type": "Organization",
                        "@id": "https://www.provaluer.in/#organization",
                        "name": "ProValuer Commercial",
                        "url": "https://www.provaluer.in/",
                        "logo": "https://www.provaluer.in/icons/Icon-512.png"
                    }
                },
                {
                    "@type": "BreadcrumbList",
                    "@id": f"{canonical_url}#breadcrumb",
                    "itemListElement": [
                        { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://www.provaluer.in/" },
                        { "@type": "ListItem", "position": 2, "name": "Knowledge Center", "item": "https://www.provaluer.in/knowledge-sitemap.xml" },
                        { "@type": "ListItem", "position": 3, "name": page_title, "item": canonical_url }
                    ]
                }
            ]
        }, indent=2)

    # Extract H1
    h1_match = re.search(r'^#\s+(.+)$', raw_md, re.MULTILINE)
    h1_title = h1_match.group(1).strip() if h1_match else page_title

    # Extract H2s for TOC
    h2_matches = re.findall(r'^##\s+(.+)$', raw_md, re.MULTILINE)
    toc_items = []
    for h2 in h2_matches:
        h2_clean = h2.strip()
        if 'technical appendix' in h2_clean.lower():
            continue
        toc_items.append((h2_clean, slugify(h2_clean)))

    # Clean body: strip Technical Appendix & initial meta blocks
    body_md = raw_md
    idx_app = body_md.find('## Technical Appendix')
    if idx_app != -1:
        body_md = body_md[:idx_app]

    # Remove meta lines from body
    body_md = re.sub(r'\*\*Meta Title:\*\*.*?\n', '', body_md)
    body_md = re.sub(r'\*\*Meta Description:\*\*.*?\n', '', body_md)
    body_md = re.sub(r'\*\*Target Canonical URL:\*\*.*?\n', '', body_md)
    body_md = re.sub(r'\*\*Primary Keywords:\*\*.*?\n', '', body_md)
    body_md = re.sub(r'\*\*Target Audience:\*\*.*?\n', '', body_md)
    # Remove H1 since it's in the header
    body_md = re.sub(r'^#\s+.+?\n', '', body_md)

    content_html = md_to_html(body_md)

    # Other cluster articles
    cluster_links_html = []
    for other in ARTICLES:
        if other["slug"] != slug:
            cluster_links_html.append(f"""
            <a href="https://www.provaluer.in/knowledge/{other['slug']}" class="cluster-link-item">
              <span class="cluster-link-title">{other['default_title'].split('|')[0].strip()}</span>
              <span class="cluster-link-desc">{other['category']} • {other['read_time']}</span>
            </a>
            """)

    toc_html = '\n'.join([f'<li><a href="#{tid}">{title}</a></li>' for title, tid in toc_items])

    full_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <base href="/">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <!-- Primary SEO Meta Tags -->
  <title>{page_title}</title>
  <meta name="title" content="{page_title}">
  <meta name="description" content="{page_desc}">
  <meta name="keywords" content="{keywords}">
  <meta name="author" content="ProValuer Commercial - IBBI Registered Valuers">
  <meta name="robots" content="index, follow">

  <!-- Canonical URL -->
  <link rel="canonical" href="{canonical_url}">

  <!-- Open Graph / Facebook / LinkedIn -->
  <meta property="og:type" content="article">
  <meta property="og:url" content="{canonical_url}">
  <meta property="og:title" content="{page_title}">
  <meta property="og:description" content="{page_desc}">
  <meta property="og:image" content="https://www.provaluer.in/icons/Icon-512.png">
  <meta property="og:site_name" content="ProValuer Commercial">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:url" content="{canonical_url}">
  <meta name="twitter:title" content="{page_title}">
  <meta name="twitter:description" content="{page_desc}">
  <meta name="twitter:image" content="https://www.provaluer.in/icons/Icon-512.png">

  <!-- Favicon & PWA -->
  <link rel="icon" type="image/png" href="favicon.png"/>
  <link rel="manifest" href="manifest.json">

  <!-- Fonts -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@500;600;700;800;900&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

  <!-- Schema.org JSON-LD Structured Data -->
  <script type="application/ld+json">
{json_ld_str}
  </script>

  <style>
{CSS}
  </style>
</head>
<body>

  <!-- Navigation Bar -->
  <nav class="navbar">
    <a href="https://www.provaluer.in/" class="brand-logo">
      <div class="brand-icon">PV</div>
      <div class="brand-text">
        <span class="brand-name">ProValuer</span>
        <span class="brand-sub">Commercial & Advisory</span>
      </div>
    </a>
    <ul class="nav-links">
      <li><a href="https://www.provaluer.in/services/property-valuation">Services</a></li>
      <li><a href="https://www.provaluer.in/government-approved-valuers">Approved Valuers</a></li>
      <li><a href="https://www.provaluer.in/knowledge-sitemap.xml">Knowledge Base</a></li>
      <li><a href="https://www.provaluer.in/login">Valuation Portal</a></li>
      <li><a href="https://www.provaluer.in/login" class="btn-cta">Request Valuation</a></li>
    </ul>
  </nav>

  <!-- Breadcrumbs Bar -->
  <div class="breadcrumbs-bar">
    <ul class="breadcrumbs">
      <li><a href="https://www.provaluer.in/">Home</a></li>
      <li><a href="https://www.provaluer.in/knowledge-sitemap.xml">Knowledge Center</a></li>
      <li><span>{article_meta['category']}</span></li>
    </ul>
  </div>

  <!-- Article Header -->
  <header class="article-header">
    <div class="header-container">
      <span class="topic-badge">{article_meta['category']}</span>
      <h1>{h1_title}</h1>
      <div class="article-meta">
        <div class="meta-item">📅 Published: <strong>September 2026</strong></div>
        <div class="meta-item">⏱️ Reading Time: <strong>{article_meta['read_time']}</strong></div>
        <div class="meta-item">🏛️ Authority: <strong>IBBI Registered Valuers & Section 34AB Panel</strong></div>
        <div class="meta-item">⚖️ Jurisdiction: <strong>Republic of India (CBDT, MCA, RBI)</strong></div>
      </div>
    </div>
  </header>

  <!-- Article Content & Sidebar Wrapper -->
  <main class="article-wrapper">
    <!-- Sticky Table of Contents -->
    <aside class="sidebar-sticky">
      <div class="toc-title">Table of Contents</div>
      <ul class="toc-list">
        {toc_html}
      </ul>
      <div style="margin-top: 2rem; padding: 1rem; background: #EFF6FF; border-radius: 8px; border: 1px solid #BFDBFE;">
        <div style="font-weight: 700; font-size: 0.85rem; color: #1E40AF; margin-bottom: 0.4rem;">Institutional Advisory</div>
        <p style="font-size: 0.8rem; color: #3B82F6; margin: 0;">Need immediate advisory from certified IBBI registered valuers or merchant bankers?</p>
        <a href="https://www.provaluer.in/login" style="display: inline-block; margin-top: 0.75rem; font-size: 0.8rem; font-weight: 700; color: #1D4ED8;">Connect with Valuer →</a>
      </div>
    </aside>

    <!-- Main Content -->
    <article class="article-content">
      {content_html}

      <!-- Authority Knowledge Cluster -->
      <section class="cluster-nav-card">
        <h3>Explore Other Authority Valuation Guides in this Series</h3>
        <p style="font-size: 0.9rem; color: #64748B; margin-bottom: 1.5rem;">Cross-referenced statutory treatises and technical guidelines authored by the ProValuer Research Directorate.</p>
        <div class="cluster-links-grid">
          {''.join(cluster_links_html)}
        </div>
      </section>

      <!-- Conversion CTA Banner -->
      <section class="cta-banner">
        <h2>Need a Certified Valuation Report from an IBBI Registered Valuer?</h2>
        <p>Our multidisciplinary panel of IBBI Registered Valuers, Wealth Tax Approved Valuers, and SEBI Merchant Bankers issues court-admissible, bank-compliant valuation reports across India.</p>
        <div class="cta-buttons">
          <a href="https://www.provaluer.in/login" class="btn-primary-gold">Submit Valuation Request</a>
          <a href="tel:+919876543210" class="btn-secondary-outline">Call +91 98765 43210</a>
        </div>
      </section>
    </article>
  </main>

  <!-- Institutional Footer -->
  <footer>
    <div class="footer-container">
      <div class="footer-col">
        <h4>ProValuer Commercial</h4>
        <p style="font-size: 0.85rem; line-height: 1.6; margin-bottom: 1rem;">Premier asset intelligence, institutional property appraisal, and statutory valuation compliance for real estate, business enterprises, and industrial plant & machinery.</p>
        <p style="font-size: 0.8rem; color: #64748B;">Registered Office: Hyderabad, Telangana, India</p>
      </div>
      <div class="footer-col">
        <h4>Statutory Practice Areas</h4>
        <ul>
          <li><a href="https://www.provaluer.in/services/property-valuation">Commercial Property Valuation</a></li>
          <li><a href="https://www.provaluer.in/services/bank-collateral-valuation">Bank Collateral Appraisal</a></li>
          <li><a href="https://www.provaluer.in/services/nclt-ibc-valuation">NCLT & IBC Liquidation</a></li>
          <li><a href="https://www.provaluer.in/services/share-valuation">Share & Equity Valuation (Rule 11UA)</a></li>
          <li><a href="https://www.provaluer.in/services/visa-and-immigration-valuations">Visa & Immigration Net Worth</a></li>
        </ul>
      </div>
      <div class="footer-col">
        <h4>Authority Guides</h4>
        <ul>
          <li><a href="https://www.provaluer.in/knowledge/government-approved-valuers-complete-guide">Government Approved Valuers</a></li>
          <li><a href="https://www.provaluer.in/knowledge/rule-11ua-complete-guide">Rule 11UA DCF & NAV Math</a></li>
          <li><a href="https://www.provaluer.in/knowledge/property-valuation-methods-complete-guide">Property Valuation Methods</a></li>
          <li><a href="https://www.provaluer.in/knowledge/plant-and-machinery-valuation-complete-guide">Plant & Machinery Appraisals</a></li>
          <li><a href="https://www.provaluer.in/knowledge/angel-tax-complete-guide">Angel Tax & Section 56(2)(viib)</a></li>
          <li><a href="https://www.provaluer.in/knowledge/visa-and-immigration-valuation-complete-guide">Visa & Immigration Appraisals</a></li>
        </ul>
      </div>
      <div class="footer-col">
        <h4>Compliance & Portal</h4>
        <ul>
          <li><a href="https://www.provaluer.in/login">Client Valuation Portal</a></li>
          <li><a href="https://www.provaluer.in/robots.txt">Robots Directive</a></li>
          <li><a href="https://www.provaluer.in/sitemap.xml">Primary Sitemap</a></li>
          <li><a href="https://www.provaluer.in/knowledge-sitemap.xml">Knowledge Sitemap</a></li>
          <li><a href="https://www.provaluer.in/llms.txt">LLMs Context File</a></li>
        </ul>
      </div>
    </div>
    <div class="footer-bottom">
      <div>© 2026 ProValuer Commercial. All Rights Reserved. Compliant with IBBI Regulations & Wealth Tax Rules.</div>
      <div>Strict Confidentiality Guaranteed • ISO 9001:2015 Compliant Processes</div>
    </div>
  </footer>

</body>
</html>
"""
    return full_html

def main():
    base_dir = "frontend/web/knowledge"
    os.makedirs(base_dir, exist_ok=True)

    for item in ARTICLES:
        slug = item["slug"]
        out_dir = os.path.join(base_dir, slug)
        os.makedirs(out_dir, exist_ok=True)
        out_file = os.path.join(out_dir, "index.html")

        html_content = build_page(item)
        with open(out_file, "w", encoding="utf-8") as f:
            f.write(html_content)

        size_kb = len(html_content.encode("utf-8")) / 1024
        print(f"Generated: {out_file} ({size_kb:.1f} KB)")

if __name__ == "__main__":
    main()
