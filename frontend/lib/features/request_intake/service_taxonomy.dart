import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PROVALUER MASTER SERVICE TAXONOMY (FROZEN VERSION 1.0)
/// ════════════════════════════════════════════════════════════════════════════
/// Immutable taxonomy definitions and service-specific intake path configurations.
/// Governs wizard branching across:
/// 1. Asset Valuation (Asset Category -> Purpose -> Details -> Documents -> Review)
/// 2. Net Worth Certification (Applicant Type -> Purpose -> Financial Details -> Documents -> Review)
/// 3. Technical Assessment (Assessment Type -> Property Type -> Inspection Details -> Documents -> Review)

enum ServiceType {
  assetValuation,
  netWorthCertification,
  technicalAssessment,
}

extension ServiceTypeExtension on ServiceType {
  String get code {
    switch (this) {
      case ServiceType.assetValuation:
        return 'VALUATION';
      case ServiceType.netWorthCertification:
        return 'NET_WORTH';
      case ServiceType.technicalAssessment:
        return 'CHARTERED_ENGINEER';
    }
  }

  String get displayName {
    switch (this) {
      case ServiceType.assetValuation:
        return 'Asset Valuation';
      case ServiceType.netWorthCertification:
        return 'Net Worth Certification';
      case ServiceType.technicalAssessment:
        return 'Technical Assessment';
    }
  }

  String get shortDescription {
    switch (this) {
      case ServiceType.assetValuation:
        return 'Professional valuation reports for banking, taxation, compliance and regulatory requirements.';
      case ServiceType.netWorthCertification:
        return 'Certified net worth statements for immigration, banking, solvency, and statutory purposes.';
      case ServiceType.technicalAssessment:
        return 'Independent technical inspection, engineering stability review, and chartered engineer certification.';
    }
  }

  String get iconText {
    switch (this) {
      case ServiceType.assetValuation:
        return '🏛️';
      case ServiceType.netWorthCertification:
        return '📜';
      case ServiceType.technicalAssessment:
        return '⚙️';
    }
  }

  IconData get iconData {
    switch (this) {
      case ServiceType.assetValuation:
        return Icons.apartment_rounded;
      case ServiceType.netWorthCertification:
        return Icons.account_balance_wallet_outlined;
      case ServiceType.technicalAssessment:
        return Icons.engineering_outlined;
    }
  }

  /// Step 2 title for progress bar
  String get step2Label {
    switch (this) {
      case ServiceType.assetValuation:
        return 'Asset Category';
      case ServiceType.netWorthCertification:
        return 'Applicant Type';
      case ServiceType.technicalAssessment:
        return 'Assessment Type';
    }
  }

  /// Step 3 title for progress bar
  String get step3Label {
    switch (this) {
      case ServiceType.assetValuation:
        return 'Purpose';
      case ServiceType.netWorthCertification:
        return 'Purpose';
      case ServiceType.technicalAssessment:
        return 'Property Type';
    }
  }

  /// Step 4 title for progress bar
  String get step4Label {
    switch (this) {
      case ServiceType.assetValuation:
        return 'Details';
      case ServiceType.netWorthCertification:
        return 'Financial Details';
      case ServiceType.technicalAssessment:
        return 'Inspection Details';
    }
  }

  List<String> get wizardStepLabels {
    return [
      'Service',
      step2Label,
      step3Label,
      step4Label,
      'Documents',
      'Review',
    ];
  }

  String get step2Headline {
    switch (this) {
      case ServiceType.assetValuation:
        return 'Select Statutory Asset Category';
      case ServiceType.netWorthCertification:
        return 'Select Applicant Classification';
      case ServiceType.technicalAssessment:
        return 'Select Technical Assessment Scope';
    }
  }

  String get step2Subhead {
    switch (this) {
      case ServiceType.assetValuation:
        return 'Specify the statutory asset class for your valuation mandate to determine the valuation standard (IVS/IBBI/Companies Act).';
      case ServiceType.netWorthCertification:
        return 'Select applicant category for tailored financial schedules, wealth ratios, and embassy/banking compliance.';
      case ServiceType.technicalAssessment:
        return 'Choose the engineering inspection framework and chartered engineer mandate required.';
    }
  }
}

/// Represents a primary Submenu in the Master Service Taxonomy
class ServiceSubmenu {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<String> items;

  const ServiceSubmenu({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'items': items,
      };
}

/// Master Service Taxonomy Registry (Version 1.0 Frozen)
class ServiceTaxonomy {
  static const String version = "1.0-FROZEN";

  // ══════════════════════════════════════════════════════════════════════════
  // SERVICE 1: ASSET VALUATION
  // ══════════════════════════════════════════════════════════════════════════
  static const List<ServiceSubmenu> assetValuationSubmenus = [
    ServiceSubmenu(
      id: 'REAL_ESTATE_VALUATION',
      title: 'Real Estate Valuation',
      description: 'Land, residential, commercial, industrial and hospitality real estate appraisal under IVS and IBBI standards.',
      icon: Icons.business_outlined,
      items: [
        'Residential Property',
        'Commercial Property',
        'Industrial Property',
        'Land Parcel',
        'Agricultural Land',
        'Mixed Use Property',
        'Warehouse / Logistics',
        'Retail Mall',
        'Office Building',
        'Hospitality Property',
      ],
    ),
    ServiceSubmenu(
      id: 'PLANT_AND_MACHINERY',
      title: 'Plant & Machinery',
      description: 'Depreciation, replacement cost, and residual life assessment for industrial and manufacturing assets.',
      icon: Icons.precision_manufacturing_outlined,
      items: [
        'Manufacturing Equipment',
        'Industrial Machinery',
        'Construction Equipment',
        'Mining Equipment',
        'Power Plant Equipment',
        'Process Plant Assets',
        'Medical Equipment',
        'Laboratory Equipment',
        'Printing Equipment',
        'Textile Machinery',
      ],
    ),
    ServiceSubmenu(
      id: 'SECURITIES_FINANCIAL_ASSETS',
      title: 'Securities & Financial Assets',
      description: 'Fair value assessment of equity, debt instruments, derivatives, and portfolio allocations.',
      icon: Icons.trending_up_rounded,
      items: [
        'Listed Shares',
        'Unlisted Shares',
        'Preference Shares',
        'Bonds',
        'Debentures',
        'Mutual Funds',
        'ESOP Valuation',
        'Partnership Interest',
        'Investment Portfolio',
        'Financial Instruments',
      ],
    ),
    ServiceSubmenu(
      id: 'BUSINESS_VALUATION',
      title: 'Business Valuation',
      description: 'Enterprise valuation, DCF models, goodwill, brand equity, and intangible asset appraisal.',
      icon: Icons.domain_verification_rounded,
      items: [
        'Startup Valuation',
        'SME Valuation',
        'Enterprise Valuation',
        'M&A Valuation',
        'Share Swap Valuation',
        'Fair Value Assessment',
        'Fund Raising Valuation',
        'Goodwill Valuation',
        'Intangible Asset Valuation',
      ],
    ),
    ServiceSubmenu(
      id: 'INVENTORY_CURRENT_ASSETS',
      title: 'Inventory & Current Assets',
      description: 'Audited physical count, net realizable value, and verification of stock and consumables.',
      icon: Icons.inventory_2_outlined,
      items: [
        'Raw Material',
        'Work In Progress',
        'Finished Goods',
        'Trading Stock',
        'Consumables',
        'Warehouse Inventory',
      ],
    ),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // SERVICE 2: NET WORTH CERTIFICATION
  // ══════════════════════════════════════════════════════════════════════════
  static const List<ServiceSubmenu> netWorthSubmenus = [
    ServiceSubmenu(
      id: 'INDIVIDUAL',
      title: 'Individual',
      description: 'Personal asset-liability computation for student visas, investor immigration, and bank solvency certificates.',
      icon: Icons.person_outline_rounded,
      items: [
        'Individual Net Worth',
        'HNI Net Worth',
        'NRI Net Worth',
        'Personal Financial Statement',
        'Visa Net Worth',
      ],
    ),
    ServiceSubmenu(
      id: 'DIRECTOR_PROMOTER',
      title: 'Director & Promoter',
      description: 'Personal guarantees, statutory director statements, and key management financial disclosures.',
      icon: Icons.badge_outlined,
      items: [
        'Director Net Worth',
        'Promoter Net Worth',
        'Shareholder Net Worth',
        'Key Person Certification',
      ],
    ),
    ServiceSubmenu(
      id: 'BUSINESS_ENTITY',
      title: 'Business Entity',
      description: 'Corporate net worth certificate for public procurement, bank consortium limits, and statutory compliance.',
      icon: Icons.corporate_fare_rounded,
      items: [
        'Company Net Worth',
        'LLP Net Worth',
        'Partnership Net Worth',
        'Trust Net Worth',
        'Society Net Worth',
        'Institution Net Worth',
      ],
    ),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // SERVICE 3: TECHNICAL ASSESSMENT
  // ══════════════════════════════════════════════════════════════════════════
  static const List<ServiceSubmenu> technicalAssessmentSubmenus = [
    ServiceSubmenu(
      id: 'PROPERTY_INSPECTION',
      title: 'Property Inspection',
      description: 'On-site physical inspection, technical due diligence, and comprehensive property condition reports.',
      icon: Icons.home_work_outlined,
      items: [
        'Technical Due Diligence',
        'Property Condition Report',
        'Site Feasibility',
        'Physical Inspection',
        'Pre Purchase Inspection',
      ],
    ),
    ServiceSubmenu(
      id: 'CONSTRUCTION_MONITORING',
      title: 'Construction Monitoring',
      description: 'Lender independent engineering, drawdown verification, and construction milestone monitoring.',
      icon: Icons.construction_rounded,
      items: [
        'Construction Progress Review',
        'Project Monitoring',
        'Lender Engineer Inspection',
        'Drawdown Inspection',
        'Stage Completion Assessment',
      ],
    ),
    ServiceSubmenu(
      id: 'ENGINEERING_ASSESSMENT',
      title: 'Engineering Assessment',
      description: 'Chartered engineer structural audits, building stability certification, and MEP quality checks.',
      icon: Icons.architecture_rounded,
      items: [
        'Structural Assessment',
        'Building Stability Review',
        'MEP Inspection',
        'Defect Audit',
        'Engineering Quality Assessment',
      ],
    ),
    ServiceSubmenu(
      id: 'INSURANCE_RISK',
      title: 'Insurance & Risk',
      description: 'Underwriting damage assessment, reinstatement valuation, and post-loss insurance claim investigation.',
      icon: Icons.health_and_safety_outlined,
      items: [
        'Insurance Inspection',
        'Damage Assessment',
        'Loss Assessment',
        'Risk Assessment',
        'Reinstatement Valuation',
      ],
    ),
  ];

  /// Get submenus for a given ServiceType
  static List<ServiceSubmenu> getSubmenusForService(ServiceType service) {
    switch (service) {
      case ServiceType.assetValuation:
        return assetValuationSubmenus;
      case ServiceType.netWorthCertification:
        return netWorthSubmenus;
      case ServiceType.technicalAssessment:
        return technicalAssessmentSubmenus;
    }
  }

  /// Resolve service from string code
  static ServiceType parseService(String code) {
    final upper = code.toUpperCase().trim();
    if (upper == 'VALUATION' || upper == 'ASSET_VALUATION') {
      return ServiceType.assetValuation;
    }
    if (upper == 'NET_WORTH' ||
        upper == 'NET_WORTH_CERTIFICATION' ||
        upper == 'NET_WORTH_CERTIFICATE' ||
        upper == 'NETWORTH') {
      return ServiceType.netWorthCertification;
    }
    if (upper == 'CHARTERED_ENGINEER' || upper == 'TECHNICAL_ASSESSMENT' || upper == 'CHARTERED') {
      return ServiceType.technicalAssessment;
    }
    return ServiceType.assetValuation;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SERVICE 1 PURPOSES
  // ══════════════════════════════════════════════════════════════════════════
  static const List<Map<String, String>> assetValuationPurposes = [
    {'key': 'BANK_COLLATERAL', 'title': 'Bank Collateral / Loan', 'sub': 'Mortgage underwriting, commercial loans, consortium financing.'},
    {'key': 'VISA_IMMIGRATION', 'title': 'Visa / Immigration', 'sub': 'Embassy verified wealth documentation & international visa solvency.'},
    {'key': 'TAX_STATUTORY', 'title': 'Taxation & Compliance', 'sub': 'Capital gains Section 50C/55A, Rule 11UA unquoted share tax defense.'},
    {'key': 'CORPORATE_INSOLVENCY', 'title': 'Corporate & Insolvency', 'sub': 'NCLT CIRP liquidation value, Ind AS balance sheet fair valuation.'},
    {'key': 'CUSTOMS_IMPORT_EXPORT', 'title': 'Customs & Import Export', 'sub': 'Second-hand machinery appraisal, EPC / EPCG import valuation.'},
    {'key': 'DISPUTE_RESOLUTION', 'title': 'Dispute & Legal', 'sub': 'High court arbitration, family partition, court receiver appraisals.'},
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // SERVICE 2 PURPOSES
  // ══════════════════════════════════════════════════════════════════════════
  static const List<Map<String, String>> netWorthPurposes = [
    {'key': 'VISA_IMMIGRATION', 'title': 'Visa & Immigration', 'sub': 'Embassy financial net worth certificate & student/investor visa solvency.'},
    {'key': 'BANK_SOLVENCY', 'title': 'Bank Solvency & Credit Limit', 'sub': 'Bank guarantee limits, credit facilities & borrower credit assessment.'},
    {'key': 'STATUTORY_COMPLIANCE', 'title': 'Statutory & Tax Compliance', 'sub': 'IT department filings, disclosures, and statutory net worth certification.'},
    {'key': 'DIRECTORSHIP_DISCLOSURE', 'title': 'Corporate Directorship', 'sub': 'Director appointment disclosures, ROC filings, and bank mandates.'},
    {'key': 'GOVT_TENDER_BIDDING', 'title': 'Govt Tender & EPC Bidding', 'sub': 'Financial qualification, eligibility thresholds & contractor empanelment.'},
    {'key': 'PERSONAL_FINANCIAL_AUDIT', 'title': 'Personal Estate & Wealth Audit', 'sub': 'Family office records, estate planning & wealth verification.'},
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // SERVICE 3 PROPERTY / ASSET TYPES (FOR STEP 3 BRANCHING)
  // ══════════════════════════════════════════════════════════════════════════
  static const List<Map<String, String>> technicalPropertyTypes = [
    {'key': 'RESIDENTIAL_COMPLEX', 'title': 'Residential Building / Complex', 'sub': 'Apartment towers, gated communities, villas, independent structures.'},
    {'key': 'COMMERCIAL_OFFICE', 'title': 'Commercial Office / IT Park', 'sub': 'Corporate office buildings, retail centers, business parks, tech hubs.'},
    {'key': 'INDUSTRIAL_PLANT', 'title': 'Industrial Plant / Warehouse', 'sub': 'Manufacturing facilities, factory sheds, process units, logistics centers.'},
    {'key': 'INFRASTRUCTURE_CIVIL', 'title': 'Civil Infrastructure / Utilities', 'sub': 'Roads, bridges, drainage networks, institutional campuses, solar parks.'},
    {'key': 'HOSPITALITY_HEALTHCARE', 'title': 'Hospitality / Healthcare Facility', 'sub': 'Hotels, resorts, multi-specialty hospitals, educational campuses.'},
    {'key': 'SPECIALIZED_ASSET', 'title': 'Specialized Plant & Machinery Site', 'sub': 'Equipment installations, captive power plants, heavy machinery bays.'},
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // DOCUMENT SLOTS PER SERVICE
  // ══════════════════════════════════════════════════════════════════════════
  static List<Map<String, dynamic>> getDocumentSlots(ServiceType service) {
    switch (service) {
      case ServiceType.assetValuation:
        return const [
          {'key': 'TITLE_DEED', 'label': 'Title Deed / Ownership Proof', 'mandatory': true, 'hint': 'Registered sale deed, lease deed, or conveyance deed.'},
          {'key': 'SANCTION_PLAN', 'label': 'Approved Plan / Layout', 'mandatory': true, 'hint': 'Competent authority sanctioned building or site layout.'},
          {'key': 'TAX_RECEIPT', 'label': 'Latest Tax Receipt', 'mandatory': true, 'hint': 'Municipal property tax paid receipt / electricity bill.'},
          {'key': 'SUPPORTING_ESTIMATE', 'label': 'Asset Invoices / Schedules (Optional)', 'mandatory': false, 'hint': 'Purchase invoices, P&M schedules, or audited asset registers.'},
        ];
      case ServiceType.netWorthCertification:
        return const [
          {'key': 'IT_RETURNS', 'label': 'Income Tax Returns (Past 3 Yrs)', 'mandatory': true, 'hint': 'ITR Acknowledgement & computation forms for the last 3 financial years.'},
          {'key': 'BANK_STATEMENT', 'label': 'Bank Statements / Wealth Portfolio', 'mandatory': true, 'hint': 'Latest 6 months bank statements, mutual funds, shares & deposit proofs.'},
          {'key': 'ASSET_OWNERSHIP_PROOF', 'label': 'Property & Asset Ownership Proof', 'mandatory': true, 'hint': 'Title deeds, purchase documents, vehicle RC, or business equity certificates.'},
          {'key': 'LIABILITY_STATEMENT', 'label': 'Loan / Liability Statement (Optional)', 'mandatory': false, 'hint': 'Bank loan outstanding letters, mortgage schedules, or liabilities.'},
        ];
      case ServiceType.technicalAssessment:
        return const [
          {'key': 'SITE_SANCTION_DRAWING', 'label': 'Site Layout & Sanctioned Drawings', 'mandatory': true, 'hint': 'Approved architectural plans, site boundaries, and municipal permits.'},
          {'key': 'STRUCTURAL_DRAWING', 'label': 'Structural & Engineering Drawings', 'mandatory': true, 'hint': 'Structural layout, foundation drawings, or engineering specifications.'},
          {'key': 'PREVIOUS_INSPECTION_LOG', 'label': 'Previous Inspection / Defect Logs', 'mandatory': true, 'hint': 'Prior engineer audit reports, QA/QC checklists, or stage progress records.'},
          {'key': 'WORK_ORDER_CONTRACT', 'label': 'Work Order / NOC / Insurance Policy', 'mandatory': false, 'hint': 'Contractor work orders, fire NOC, or insurance coverage policies.'},
        ];
    }
  }

  /// Full Taxonomy JSON representation for export & API sync
  static Map<String, dynamic> exportTaxonomyJson() {
    return {
      'taxonomy_version': version,
      'effective_date': '2026-10-05',
      'services': [
        {
          'id': 'VALUATION',
          'name': 'Asset Valuation',
          'submenus': assetValuationSubmenus.map((s) => s.toJson()).toList(),
          'purposes': assetValuationPurposes,
          'intake_path': ['Service', 'Asset Category', 'Purpose', 'Details', 'Documents', 'Review'],
        },
        {
          'id': 'NET_WORTH',
          'name': 'Net Worth Certification',
          'submenus': netWorthSubmenus.map((s) => s.toJson()).toList(),
          'purposes': netWorthPurposes,
          'intake_path': ['Service', 'Applicant Type', 'Purpose', 'Financial Details', 'Documents', 'Review'],
        },
        {
          'id': 'CHARTERED_ENGINEER',
          'name': 'Technical Assessment',
          'submenus': technicalAssessmentSubmenus.map((s) => s.toJson()).toList(),
          'property_types': technicalPropertyTypes,
          'intake_path': ['Service', 'Assessment Type', 'Property Type', 'Inspection Details', 'Documents', 'Review'],
        },
      ],
    };
  }
}
