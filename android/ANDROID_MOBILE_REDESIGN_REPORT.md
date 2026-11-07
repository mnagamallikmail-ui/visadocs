# ProValuer Android Mobile UX Redesign Report (Native Field Appraiser Engine)
**Document Target:** `android/ANDROID_MOBILE_REDESIGN_REPORT.md`  
**Version:** 2.0.0 (Executive Approved)  
**Date:** November 7, 2026  
**Status:** Architecture Approved  

---

## 1. UX Transformation Philosophy: Native Field-Appraiser Experience

ProValuer Android is not an adaptive web layout crammed into mobile viewports. It is an **ergonomic, field-grade mobile application** tailored specifically for appraisers on the move in remote locations, industrial plots, and bank branches.

### Core Experience Standards
1. **Vertical Hierarchy (Question-over-Answer)**: Questions are displayed distinctly above input fields. Inputs span $100\%$ available width, with auto-growing text boxes for detailed observation notes.
2. **Section-Based Workflows**: Multi-step valuation templates are broken into discrete, bite-sized sections with progress indicators, direct-jump selectors, and back/forward navigation.
3. **Data Integrity (Autosave & Offline)**: 30-second local autosave prevents data loss; offline support enables complete site inspection without cellular coverage.
4. **Camera-First Workflow**: Site inspections prioritize instant camera capture over gallery uploads.
5. **No Cramped Grids**: Wide multi-column tables are replaced by structured information cards and accordion panels.

---

## 2. Screen-by-Screen Redesign Specifications

### 2.1 Navigation & Frame (`AppDrawer` & `AppBar`)
* **Hamburger Menu Icon**: Placed on top left of `AppBar` across all authenticated screens.
* **Drawer Hierarchy (`width: 290dp`)**:
  - **Header**: Gradient navy banner with circular avatar, user's full name, email, and high-visibility role badge (`SUPER ADMIN`, `ADMIN`, `SPA`, `PA`, `CLIENT`).
  - **Menu List**: Clean list tiles with $48\text{ dp}$ touch targets and leading icons.
  - **Footer**: Application build version (`v1.0.0+101`), Settings, and prominent red **Sign Out** button.

### 2.2 Section-Based Valuation Form Workflow
* **Section Stepper Header**:
  ```
  [✓ 1. General Info]  [✓ 2. Land Details]  [► 3. Structural Specs]  [□ 4. Valuation]
  ```
* **Step Navigation**:
  - Sticky bottom action bar with `[ < Previous Section ]` and `[ Next Section > ]`.
  - Floating Section Jump modal allowing one-tap transition between any of the 6+ sections.
* **Question Layout**:
  - Question text rendered in 15sp semi-bold dark slate (`#1E293B`).
  - Helper guidance text rendered in 12sp muted grey (`#64748B`).
  - Input field styled with 1.5dp outline border, 12dp rounded corners, full screen width.

### 2.3 Field Appraiser Dashboards (PA & SPA)
* **Current Web Structure**: 7-column data table forcing 20px column widths on phones.
* **Android Card Structure**:
  - **Top Row**: Reference Number (`PV-2610-0328`) in bold 16sp font + Status Badge (`Site Visit Allocated`).
  - **Middle Row**: Borrower / Client Name (`Sunrise Industries Ltd`) + Property Asset Type (`Commercial Warehouse`).
  - **Bottom Row**: Allocation Date + Issuing Bank Name (`State Bank of India`).
  - **Thumb Toolbar**: Full-width buttons: `[ (Camera) Take Photos ]` and `[ Open Inspection Form ]`.

### 2.4 Client & Admin Dashboards
* **KPI Metrics**: Desktop 4-column horizontal strip converted into a 2x2 grid or swipeable metric cards.
* **Order Tracking**: Expandable accordions displaying timeline stages: `Order Placed` $\longrightarrow$ `PA Inspection` $\longrightarrow$ `SPA Review` $\longrightarrow$ `Delivered`.
* **Lead CRM & User Roster**: Vertical cards with quick call, email, and role-toggle triggers.

---

## 3. Responsive Multi-Density Validation

| Viewport Resolution | Typical Devices | Navigation Drawer | Form Layout | Table Cards | Text Wrapping Status |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **360 × 800 dp** | Galaxy A-series, Redmi | Slides smoothly (290dp) | Full-width inputs, auto-grow | 100% width card, 0 horizontal scroll | **Zero character breaking** |
| **393 × 852 dp** | Pixel 7/8, iPhone 14/15 | Slides smoothly (290dp) | Full-width inputs, auto-grow | 100% width card, 0 horizontal scroll | **Zero character breaking** |
| **412 × 915 dp** | Galaxy S23/S24 Ultra | Slides smoothly (290dp) | Full-width inputs, auto-grow | 100% width card, 0 horizontal scroll | **Zero character breaking** |

---

## 4. Preservation of Web Presentation

Every single modification in this report is enclosed within runtime platform checks:
```dart
if (kIsWeb) {
  // Untouched desktop layout: sidebars, multi-column tables, 2-column forms
  return _buildOriginalDesktopWebLayout();
}
// Native Android presentation: sliding drawer, section stepper, vertical cards
return _buildAndroidFieldLayout();
```
Under this architecture, Web production on `master` is 100% immune to mobile layout changes.
