import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/request_intake/service_taxonomy.dart';

void main() {
  group('Master Service Taxonomy Freeze Version 1.0 Tests', () {
    test('Verify Service Taxonomy Version is 1.0-FROZEN', () {
      expect(ServiceTaxonomy.version, equals('1.0-FROZEN'));
      expect(ServiceType.values.length, equals(3));
    });

    test('SERVICE 1: ASSET VALUATION Taxonomy Completeness', () {
      final submenus = ServiceTaxonomy.getSubmenusForService(ServiceType.assetValuation);
      expect(submenus.length, equals(5));

      // Submenu A: REAL ESTATE VALUATION
      final realEstate = submenus[0];
      expect(realEstate.id, equals('REAL_ESTATE_VALUATION'));
      expect(realEstate.title.toUpperCase(), equals('REAL ESTATE VALUATION'));
      expect(realEstate.items, equals([
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
      ]));

      // Submenu B: PLANT & MACHINERY
      final plantMachinery = submenus[1];
      expect(plantMachinery.id, equals('PLANT_AND_MACHINERY'));
      expect(plantMachinery.title.toUpperCase(), equals('PLANT & MACHINERY'));
      expect(plantMachinery.items, equals([
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
      ]));

      // Submenu C: SECURITIES & FINANCIAL ASSETS
      final securities = submenus[2];
      expect(securities.id, equals('SECURITIES_FINANCIAL_ASSETS'));
      expect(securities.title.toUpperCase(), equals('SECURITIES & FINANCIAL ASSETS'));
      expect(securities.items, equals([
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
      ]));

      // Submenu D: BUSINESS VALUATION
      final business = submenus[3];
      expect(business.id, equals('BUSINESS_VALUATION'));
      expect(business.title.toUpperCase(), equals('BUSINESS VALUATION'));
      expect(business.items, equals([
        'Startup Valuation',
        'SME Valuation',
        'Enterprise Valuation',
        'M&A Valuation',
        'Share Swap Valuation',
        'Fair Value Assessment',
        'Fund Raising Valuation',
        'Goodwill Valuation',
        'Intangible Asset Valuation',
      ]));

      // Submenu E: INVENTORY & CURRENT ASSETS
      final inventory = submenus[4];
      expect(inventory.id, equals('INVENTORY_CURRENT_ASSETS'));
      expect(inventory.title.toUpperCase(), equals('INVENTORY & CURRENT ASSETS'));
      expect(inventory.items, equals([
        'Raw Material',
        'Work In Progress',
        'Finished Goods',
        'Trading Stock',
        'Consumables',
        'Warehouse Inventory',
      ]));

      // Total items in Asset Valuation: 10 + 10 + 10 + 9 + 6 = 45
      final totalItems = submenus.fold<int>(0, (sum, sub) => sum + sub.items.length);
      expect(totalItems, equals(45));
    });

    test('SERVICE 2: NET WORTH CERTIFICATION Taxonomy Completeness', () {
      final submenus = ServiceTaxonomy.getSubmenusForService(ServiceType.netWorthCertification);
      expect(submenus.length, equals(3));

      // Submenu A: INDIVIDUAL
      final individual = submenus[0];
      expect(individual.id, equals('INDIVIDUAL'));
      expect(individual.title.toUpperCase(), equals('INDIVIDUAL'));
      expect(individual.items, equals([
        'Individual Net Worth',
        'HNI Net Worth',
        'NRI Net Worth',
        'Personal Financial Statement',
        'Visa Net Worth',
      ]));

      // Submenu B: DIRECTOR & PROMOTER
      final director = submenus[1];
      expect(director.id, equals('DIRECTOR_PROMOTER'));
      expect(director.title.toUpperCase(), equals('DIRECTOR & PROMOTER'));
      expect(director.items, equals([
        'Director Net Worth',
        'Promoter Net Worth',
        'Shareholder Net Worth',
        'Key Person Certification',
      ]));

      // Submenu C: BUSINESS ENTITY
      final businessEntity = submenus[2];
      expect(businessEntity.id, equals('BUSINESS_ENTITY'));
      expect(businessEntity.title.toUpperCase(), equals('BUSINESS ENTITY'));
      expect(businessEntity.items, equals([
        'Company Net Worth',
        'LLP Net Worth',
        'Partnership Net Worth',
        'Trust Net Worth',
        'Society Net Worth',
        'Institution Net Worth',
      ]));

      // Total items in Net Worth: 5 + 4 + 6 = 15
      final totalItems = submenus.fold<int>(0, (sum, sub) => sum + sub.items.length);
      expect(totalItems, equals(15));
    });

    test('SERVICE 3: TECHNICAL ASSESSMENT Taxonomy Completeness', () {
      final submenus = ServiceTaxonomy.getSubmenusForService(ServiceType.technicalAssessment);
      expect(submenus.length, equals(4));

      // Submenu A: PROPERTY INSPECTION
      final inspection = submenus[0];
      expect(inspection.id, equals('PROPERTY_INSPECTION'));
      expect(inspection.title.toUpperCase(), equals('PROPERTY INSPECTION'));
      expect(inspection.items, equals([
        'Technical Due Diligence',
        'Property Condition Report',
        'Site Feasibility',
        'Physical Inspection',
        'Pre Purchase Inspection',
      ]));

      // Submenu B: CONSTRUCTION MONITORING
      final construction = submenus[1];
      expect(construction.id, equals('CONSTRUCTION_MONITORING'));
      expect(construction.title.toUpperCase(), equals('CONSTRUCTION MONITORING'));
      expect(construction.items, equals([
        'Construction Progress Review',
        'Project Monitoring',
        'Lender Engineer Inspection',
        'Drawdown Inspection',
        'Stage Completion Assessment',
      ]));

      // Submenu C: ENGINEERING ASSESSMENT
      final engineering = submenus[2];
      expect(engineering.id, equals('ENGINEERING_ASSESSMENT'));
      expect(engineering.title.toUpperCase(), equals('ENGINEERING ASSESSMENT'));
      expect(engineering.items, equals([
        'Structural Assessment',
        'Building Stability Review',
        'MEP Inspection',
        'Defect Audit',
        'Engineering Quality Assessment',
      ]));

      // Submenu D: INSURANCE & RISK
      final insurance = submenus[3];
      expect(insurance.id, equals('INSURANCE_RISK'));
      expect(insurance.title.toUpperCase(), equals('INSURANCE & RISK'));
      expect(insurance.items, equals([
        'Insurance Inspection',
        'Damage Assessment',
        'Loss Assessment',
        'Risk Assessment',
        'Reinstatement Valuation',
      ]));

      // Total items in Technical Assessment: 5 + 5 + 5 + 5 = 20
      final totalItems = submenus.fold<int>(0, (sum, sub) => sum + sub.items.length);
      expect(totalItems, equals(20));
    });

    test('Taxonomy JSON serialization contains version and all 3 services', () {
      final json = ServiceTaxonomy.exportTaxonomyJson();
      expect(json['taxonomy_version'], equals('1.0-FROZEN'));
      expect(json['services'], isA<List>());
      final servicesList = json['services'] as List;
      expect(servicesList.length, equals(3));
      final ids = servicesList.map((s) => s['id']).toList();
      expect(ids.contains('VALUATION'), isTrue);
      expect(ids.contains('NET_WORTH'), isTrue);
      expect(ids.contains('CHARTERED_ENGINEER'), isTrue);
    });
  });

  group('Wizard Branching & Strict Isolation Validation Rules', () {
    test('Asset Valuation intake isolation', () {
      final assetSubmenus = ServiceTaxonomy.getSubmenusForService(ServiceType.assetValuation);
      final assetSubmenuIds = assetSubmenus.map((s) => s.id).toSet();
      final assetItems = assetSubmenus.expand((s) => s.items).toSet();

      // Must NOT show Net Worth options
      final netWorthSubmenus = ServiceTaxonomy.getSubmenusForService(ServiceType.netWorthCertification);
      final netWorthIds = netWorthSubmenus.map((s) => s.id).toSet();
      final netWorthItems = netWorthSubmenus.expand((s) => s.items).toSet();
      expect(assetSubmenuIds.intersection(netWorthIds), isEmpty);
      expect(assetItems.intersection(netWorthItems), isEmpty);

      // Must NOT show Technical Assessment options
      final techSubmenus = ServiceTaxonomy.getSubmenusForService(ServiceType.technicalAssessment);
      final techIds = techSubmenus.map((s) => s.id).toSet();
      final techItems = techSubmenus.expand((s) => s.items).toSet();
      expect(assetSubmenuIds.intersection(techIds), isEmpty);
      expect(assetItems.intersection(techItems), isEmpty);
    });

    test('Net Worth Certification intake isolation (Must NOT show Land & Building, Plant & Machinery, Securities)', () {
      final netWorthSubmenus = ServiceTaxonomy.getSubmenusForService(ServiceType.netWorthCertification);
      final netWorthTitles = netWorthSubmenus.map((s) => s.title.toUpperCase()).toList();
      final netWorthItems = netWorthSubmenus.expand((s) => s.items).toList();

      // Must NOT show Land & Building, Plant & Machinery, Securities
      for (final title in netWorthTitles) {
        expect(title.contains('LAND & BUILDING'), isFalse);
        expect(title.contains('PLANT & MACHINERY'), isFalse);
        expect(title.contains('SECURITIES'), isFalse);
      }
      for (final item in netWorthItems) {
        expect(item, isNot(equals('Land & Building')));
        expect(item, isNot(equals('Plant & Machinery')));
        expect(item, isNot(equals('Securities')));
      }

      // Must NOT show Technical Assessment options
      final techSubmenus = ServiceTaxonomy.getSubmenusForService(ServiceType.technicalAssessment);
      final techIds = techSubmenus.map((s) => s.id).toSet();
      final netWorthIds = netWorthSubmenus.map((s) => s.id).toSet();
      expect(netWorthIds.intersection(techIds), isEmpty);
    });

    test('Technical Assessment intake isolation (Must NOT show Net Worth or Asset Valuation options)', () {
      final techSubmenus = ServiceTaxonomy.getSubmenusForService(ServiceType.technicalAssessment);
      final techTitles = techSubmenus.map((s) => s.title.toUpperCase()).toList();
      final techIds = techSubmenus.map((s) => s.id).toSet();

      // Must NOT show Net Worth options
      final netWorthSubmenus = ServiceTaxonomy.getSubmenusForService(ServiceType.netWorthCertification);
      final netWorthIds = netWorthSubmenus.map((s) => s.id).toSet();
      expect(techIds.intersection(netWorthIds), isEmpty);

      // Must NOT show Asset Valuation options
      final assetSubmenus = ServiceTaxonomy.getSubmenusForService(ServiceType.assetValuation);
      final assetIds = assetSubmenus.map((s) => s.id).toSet();
      expect(techIds.intersection(assetIds), isEmpty);

      for (final title in techTitles) {
        expect(title.contains('REAL ESTATE VALUATION'), isFalse);
        expect(title.contains('PLANT & MACHINERY'), isFalse);
        expect(title.contains('SECURITIES & FINANCIAL ASSETS'), isFalse);
        expect(title.contains('BUSINESS VALUATION'), isFalse);
        expect(title.contains('INVENTORY & CURRENT ASSETS'), isFalse);
        expect(title.contains('INDIVIDUAL'), isFalse);
        expect(title.contains('DIRECTOR & PROMOTER'), isFalse);
        expect(title.contains('BUSINESS ENTITY'), isFalse);
      }
    });

    test('Dedicated Step 2 labels per service', () {
      expect(ServiceType.assetValuation.step2Label, equals('Asset Category'));
      expect(ServiceType.netWorthCertification.step2Label, equals('Applicant Type'));
      expect(ServiceType.technicalAssessment.step2Label, equals('Assessment Type'));
    });

    test('Dedicated Step 3 labels per service', () {
      expect(ServiceType.assetValuation.step3Label, equals('Purpose'));
      expect(ServiceType.netWorthCertification.step3Label, equals('Purpose'));
      expect(ServiceType.technicalAssessment.step3Label, equals('Property Type'));
    });

    test('Dedicated Step 4 labels per service', () {
      expect(ServiceType.assetValuation.step4Label, equals('Details'));
      expect(ServiceType.netWorthCertification.step4Label, equals('Financial Details'));
      expect(ServiceType.technicalAssessment.step4Label, equals('Inspection Details'));
    });

    test('Dedicated Document Requirements per service', () {
      final assetDocs = ServiceTaxonomy.getDocumentSlots(ServiceType.assetValuation);
      final netWorthDocs = ServiceTaxonomy.getDocumentSlots(ServiceType.netWorthCertification);
      final techDocs = ServiceTaxonomy.getDocumentSlots(ServiceType.technicalAssessment);

      // Net Worth must contain financial & tax documents
      final netWorthKeys = netWorthDocs.map((d) => d['key']).toSet();
      expect(netWorthKeys.contains('IT_RETURNS'), isTrue);
      expect(netWorthKeys.contains('BANK_STATEMENT'), isTrue);
      expect(netWorthKeys.contains('ASSET_OWNERSHIP_PROOF'), isTrue);

      // Technical Assessment must contain architectural & engineering documents
      final techKeys = techDocs.map((d) => d['key']).toSet();
      expect(techKeys.contains('SITE_SANCTION_DRAWING'), isTrue);
      expect(techKeys.contains('STRUCTURAL_DRAWING'), isTrue);
      expect(techKeys.contains('PREVIOUS_INSPECTION_LOG'), isTrue);

      // Asset Valuation must contain title deed & layout
      final assetKeys = assetDocs.map((d) => d['key']).toSet();
      expect(assetKeys.contains('TITLE_DEED'), isTrue);
      expect(assetKeys.contains('SANCTION_PLAN'), isTrue);
    });
  });
}
