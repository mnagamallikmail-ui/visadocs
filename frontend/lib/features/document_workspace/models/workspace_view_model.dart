import 'package:flutter/material.dart';
import '../../document_studio/models/studio_document_model.dart';


/// Top-level ViewModel representing the full parsed Document Workspace.
class DocumentWorkspaceVm {
  final List<SectionVm> sections;
  final Map<String, int> placeholderCounts;
  final Map<String, PlaceholderSummaryItem> placeholderSummaries;

  const DocumentWorkspaceVm({
    required this.sections,
    this.placeholderCounts = const {},
    this.placeholderSummaries = const {},
  });

  int get totalFields => placeholderSummaries.length;

  int getCompletedFieldsCount(Map<String, String> values) {
    int count = 0;
    for (final key in placeholderSummaries.keys) {
      final val = values[key.toUpperCase()]?.trim();
      if (val != null && val.isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  double getCompletionProgress(Map<String, String> values) {
    if (totalFields == 0) return 1.0;
    return getCompletedFieldsCount(values) / totalFields;
  }

  /// Parses [StudioDocumentModel] into structured UI ViewModels in a single pass.
  /// Helper to determine if a placeholder key or fieldType explicitly represents the composite valuation table.
  static bool isCompositeTableKey(String? key, [String? fieldType]) {
    if (key != null) {
      final clean = key.replaceAll('<<', '').replaceAll('>>', '').trim().toUpperCase();
      if (clean == 'COMPOSITE_PROPERTY_TABLE' ||
          clean == 'DYNAMIC_COMPOSITE_PROPERTY_TABLE' ||
          clean == 'COMPOSITE_TABLE') {
        return true;
      }
    }
    if (fieldType != null) {
      final cleanType = fieldType.replaceAll('<<', '').replaceAll('>>', '').trim().toUpperCase();
      if (cleanType == 'DYNAMIC_COMPOSITE_PROPERTY_TABLE' ||
          cleanType == 'COMPOSITE_PROPERTY_TABLE') {
        return true;
      }
    }
    return false;
  }

  factory DocumentWorkspaceVm.fromDocumentDom(StudioDocumentModel dom, Map<String, String> values) {
    final Map<String, int> counts = {};
    final Map<String, PlaceholderSummaryItem> summaries = {};

    for (final item in dom.placeholdersSummary) {
      final key = item.key.toUpperCase();
      counts[key] = item.occurrences;
      summaries[key] = item;
    }

    final List<SectionVm> parsedSections = [];

    final meth = values['VALUATION_METHODOLOGY'] ?? '';
    final cat = (values['PROPERTY_CATEGORY'] ?? values['property_category'] ?? values['PROPERTY_TYPE'] ?? '').toLowerCase();
    final isComposite = meth == 'COMPOSITE' ||
        cat.contains('flat') || cat.contains('apartment') || cat.contains('commercial space') ||
        cat.contains('office') || cat.contains('retail') || cat.contains('shop') || cat.contains('commercial unit') ||
        (values['RAW_COMPOSITE_ITEMS_JSON'] != null && values['RAW_COMPOSITE_ITEMS_JSON']!.trim().isNotEmpty && values['RAW_COMPOSITE_ITEMS_JSON'] != '[]');

    bool compositeBlockAdded = false;

    for (final s in dom.sections) {
      final List<TableVm> tables = [];
      final List<StudioParagraph> paragraphs = [];
      final List<ParagraphBlockVm> paragraphBlocks = [];
      final List<SectionBlockVm> orderedBlocks = [];
      final Set<String> sectionKeys = {};

      for (final el in s.elements) {
        if (el is StudioTable) {
          // Check if this table contains the COMPOSITE_PROPERTY_TABLE directive
          bool tableHasComposite = false;
          for (final r in el.rows) {
            for (final c in r.cells) {
              for (final b in c.placeholderBindings) {
                if (isCompositeTableKey(b.key, b.fieldType)) {
                  tableHasComposite = true;
                  break;
                }
              }
              if (tableHasComposite) break;
              if (isCompositeTableKey(c.plainText)) {
                tableHasComposite = true;
                break;
              }
            }
            if (tableHasComposite) break;
          }

          if (tableHasComposite && (el.rows.length == 1 || !compositeBlockAdded)) {
            orderedBlocks.add(ValuationCompositeBlockVm(el.id));
            compositeBlockAdded = true;
            continue;
          }

          final List<TableRowVm> rows = [];

          for (final r in el.rows) {
            final rowVm = TableRowVm.fromStudioTableRow(r, counts, summaries, values);
            rows.add(rowVm);
            for (final f in rowVm.inputFields) {
              sectionKeys.add(f.key.toUpperCase());
            }
          }

          final tableVm = TableVm(
            tableId: el.id,
            rowCount: el.rowCount,
            columnCount: el.columnCount,
            rows: rows,
          );
          tables.add(tableVm);
          orderedBlocks.add(TableBlockVm(tableVm));
        } else if (el is StudioParagraph) {
          paragraphs.add(el);

          // Extract placeholders in this paragraph
          final List<String> pKeys = [];
          for (final run in el.runs) {
            if (run.isPlaceholder && run.placeholderKey != null) {
              pKeys.add(run.placeholderKey!.trim());
            }
          }

          // Regex fallback on plain text
          final text = el.plainText;
          final matches = RegExp(r'<<([^>]+)>>').allMatches(text);
          for (final m in matches) {
            final k = m.group(1)?.trim();
            if (k != null && k.isNotEmpty && !pKeys.contains(k)) {
              pKeys.add(k);
            }
          }

          // Check if this paragraph is an explicit COMPOSITE_PROPERTY_TABLE directive
          final hasComposite = pKeys.any((k) => isCompositeTableKey(k)) ||
              isCompositeTableKey(text);
          if (hasComposite) {
            orderedBlocks.add(ValuationCompositeBlockVm(el.id));
            compositeBlockAdded = true;
            continue;
          }

          final upperPKeys = pKeys.map((k) => k.replaceAll('<<', '').replaceAll('>>', '').toUpperCase().trim()).toList();

          if (isComposite) {
            if (upperPKeys.contains('LAND_TABLE') || upperPKeys.contains('DYNAMIC_LAND_TABLE') ||
                upperPKeys.contains('BUILDING_TABLE') || upperPKeys.contains('DYNAMIC_BUILDING_TABLE') ||
                upperPKeys.contains('VALUATION_SUMMARY_TABLE') || upperPKeys.contains('DYNAMIC_VALUATION_SUMMARY_TABLE') ||
                upperPKeys.contains('PROPERTY_VALUE_TABLE') || upperPKeys.contains('VALUE_OF_THE_PROPERTY') ||
                upperPKeys.contains('VALUE_OF_THE_PROPERTY_TABLE') ||
                (upperPKeys.contains('TOTAL_LAND_VALUE') && upperPKeys.contains('FAIR_VALUE') && upperPKeys.contains('SAY_VALUE'))) {
              if (!compositeBlockAdded) {
                orderedBlocks.add(ValuationCompositeBlockVm(el.id));
                compositeBlockAdded = true;
              }
              continue;
            }
          }

          if (upperPKeys.contains('LAND_TABLE') || upperPKeys.contains('DYNAMIC_LAND_TABLE')) {
            orderedBlocks.add(ValuationLandBlockVm(el.id));
            continue;
          }
          if (upperPKeys.contains('BUILDING_TABLE') || upperPKeys.contains('DYNAMIC_BUILDING_TABLE')) {
            orderedBlocks.add(ValuationBuildingBlockVm(el.id));
            continue;
          }
          if (upperPKeys.contains('VALUATION_SUMMARY_TABLE') || upperPKeys.contains('DYNAMIC_VALUATION_SUMMARY_TABLE')) {
            orderedBlocks.add(ValuationSummaryBlockVm(el.id));
            continue;
          }
          if (upperPKeys.contains('COMPARABLES_TABLE') ||
              upperPKeys.contains('COMPARABLE_SALES_TABLE') ||
              upperPKeys.contains('DYNAMIC_COMPARABLES_TABLE')) {
            orderedBlocks.add(ValuationComparableBlockVm(el.id));
            continue;
          }
          if (upperPKeys.contains('PROPERTY_VALUE_TABLE') ||
              upperPKeys.contains('VALUE_OF_THE_PROPERTY') ||
              upperPKeys.contains('VALUE_OF_THE_PROPERTY_TABLE') ||
              (upperPKeys.contains('TOTAL_LAND_VALUE') && upperPKeys.contains('FAIR_VALUE') && upperPKeys.contains('SAY_VALUE'))) {
            orderedBlocks.add(ValuationPropertyBlockVm(el.id));
            continue;
          }

          final List<DocumentRunNode> docNodes = [];
          final List<InputFieldVm> fields = [];
          final Map<String, InputFieldVm> fieldCache = {};

          InputFieldVm getOrCreateField(String kUpper) {
            if (fieldCache.containsKey(kUpper)) {
              return fieldCache[kUpper]!;
            }
            final occ = counts[kUpper] ?? 1;
            final summaryItem = summaries[kUpper];
            String prompt = summaryItem?.questionText ?? '';
            if (prompt.isEmpty ||
                prompt.trim().length <= 1 ||
                prompt.toLowerCase().startsWith('rectangle') ||
                prompt.toLowerCase().startsWith('picture') ||
                prompt.toLowerCase().startsWith('textbox') ||
                prompt.trim() == '_') {
              prompt = _toHumanizedLabel(kUpper);
            }

            String fieldType = summaryItem?.type ?? 'TEXT';
            if (fieldType.toUpperCase() == 'IMAGE' ||
                kUpper.startsWith('IMG_') ||
                kUpper.endsWith('_IMAGE') ||
                kUpper.contains('PHOTO') ||
                kUpper.contains('SELFIE') ||
                kUpper.contains('SIGNATURE')) {
              fieldType = 'IMAGE';
            } else if (kUpper.contains('DATE') || kUpper.contains('DT')) {
              fieldType = 'DATE';
            } else if (kUpper.contains('OBSERVATION') ||
                kUpper.contains('ADVANTAGE') ||
                kUpper.contains('DISADVANTAGE') ||
                kUpper.contains('DOCUMENT') ||
                kUpper.contains('DESCRIPTION') ||
                kUpper.contains('ADDRESS')) {
              fieldType = 'MULTILINE';
            }

            final fVm = InputFieldVm(
              key: kUpper,
              questionText: prompt,
              fieldType: fieldType,
              occurrences: occ,
              currentValue: values[kUpper] ?? '',
            );
            fieldCache[kUpper] = fVm;
            if (!fields.any((f) => f.key == kUpper)) {
              fields.add(fVm);
            }
            sectionKeys.add(kUpper);
            return fVm;
          }

          if (el.runs.isNotEmpty) {
            for (final run in el.runs) {
              if (run.isImage ||
                  (run.placeholderKey != null &&
                      (run.placeholderKey!.toUpperCase().startsWith('IMG_') ||
                          run.placeholderKey!.toUpperCase().endsWith('_IMAGE') ||
                          run.placeholderKey!.toUpperCase().contains('PHOTO') ||
                          run.placeholderKey!.toUpperCase().contains('SELFIE') ||
                          run.placeholderKey!.toUpperCase().contains('SIGNATURE')))) {
                final keyUpper = (run.placeholderKey ?? 'IMAGE').toUpperCase().trim();
                final fVm = getOrCreateField(keyUpper);
                docNodes.add(ImageRunNode(key: keyUpper, fieldVm: fVm));
              } else if (run.isPlaceholder && run.placeholderKey != null) {
                final keyUpper = run.placeholderKey!.toUpperCase().trim();
                final fVm = getOrCreateField(keyUpper);
                docNodes.add(PlaceholderRunNode(
                  key: keyUpper,
                  fieldVm: fVm,
                  isBold: run.isBold,
                  isItalic: run.isItalic,
                  fontSizePt: run.fontSizePt,
                  fontColor: run.fontColor,
                ));
              } else {
                final rText = run.text;
                final matches = RegExp(r'<<([^>]+)>>').allMatches(rText);
                if (matches.isEmpty) {
                  if (rText.isNotEmpty) {
                    docNodes.add(TextRunNode(
                      text: rText,
                      isBold: run.isBold,
                      isItalic: run.isItalic,
                      fontSizePt: run.fontSizePt,
                      fontColor: run.fontColor,
                    ));
                  }
                } else {
                  int lastIdx = 0;
                  for (final m in matches) {
                    if (m.start > lastIdx) {
                      final prefix = rText.substring(lastIdx, m.start);
                      if (prefix.isNotEmpty) {
                        docNodes.add(TextRunNode(
                          text: prefix,
                          isBold: run.isBold,
                          isItalic: run.isItalic,
                          fontSizePt: run.fontSizePt,
                          fontColor: run.fontColor,
                        ));
                      }
                    }
                    final rawK = m.group(1)?.trim() ?? '';
                    final kUpper = rawK.toUpperCase();
                    if (kUpper.isNotEmpty) {
                      final fVm = getOrCreateField(kUpper);
                      docNodes.add(PlaceholderRunNode(
                        key: kUpper,
                        fieldVm: fVm,
                        isBold: run.isBold,
                        isItalic: run.isItalic,
                        fontSizePt: run.fontSizePt,
                        fontColor: run.fontColor,
                      ));
                    }
                    lastIdx = m.end;
                  }
                  if (lastIdx < rText.length) {
                    final suffix = rText.substring(lastIdx);
                    if (suffix.isNotEmpty) {
                      docNodes.add(TextRunNode(
                        text: suffix,
                        isBold: run.isBold,
                        isItalic: run.isItalic,
                        fontSizePt: run.fontSizePt,
                        fontColor: run.fontColor,
                      ));
                    }
                  }
                }
              }
            }
          } else {
            // Fallback for paragraph with plainText but no runs
            final pText = el.plainText;
            final matches = RegExp(r'<<([^>]+)>>').allMatches(pText);
            if (matches.isEmpty) {
              if (pText.isNotEmpty) {
                docNodes.add(TextRunNode(text: pText));
              }
            } else {
              int lastIdx = 0;
              for (final m in matches) {
                if (m.start > lastIdx) {
                  final prefix = pText.substring(lastIdx, m.start);
                  if (prefix.isNotEmpty) {
                    docNodes.add(TextRunNode(text: prefix));
                  }
                }
                final rawK = m.group(1)?.trim() ?? '';
                final kUpper = rawK.toUpperCase();
                if (kUpper.isNotEmpty) {
                  final fVm = getOrCreateField(kUpper);
                  docNodes.add(PlaceholderRunNode(key: kUpper, fieldVm: fVm));
                }
                lastIdx = m.end;
              }
              if (lastIdx < pText.length) {
                final suffix = pText.substring(lastIdx);
                if (suffix.isNotEmpty) {
                  docNodes.add(TextRunNode(text: suffix));
                }
              }
            }
          }

          final cleanText = text.trim();
          // Filter out parser noise (single character artifacts like 'n', 'r', '_')
          final isNoise = docNodes.length == 1 &&
              docNodes.first is TextRunNode &&
              ((docNodes.first as TextRunNode).text.trim().length <= 1 &&
                  ((docNodes.first as TextRunNode).text.trim() == 'n' ||
                      (docNodes.first as TextRunNode).text.trim() == 'r' ||
                      (docNodes.first as TextRunNode).text.trim() == '_'));

          if (!isNoise && (docNodes.isNotEmpty || cleanText.isNotEmpty)) {
            final block = ParagraphBlockVm(
              id: el.id,
              alignment: el.alignment,
              inputFields: fields,
              nodes: docNodes,
              rawText: text,
              staticText: fields.isEmpty ? cleanText : null,
            );
            paragraphBlocks.add(block);
            orderedBlocks.add(ParagraphBlockWrapperVm(block));
          }
        }

      }

      parsedSections.add(SectionVm(
        sectionIndex: s.sectionIndex,
        title: s.title,
        tables: tables,
        standaloneParagraphs: paragraphs,
        paragraphBlocks: paragraphBlocks,
        orderedBlocks: orderedBlocks,
        boundKeys: sectionKeys,
      ));
    }

    return DocumentWorkspaceVm(
      sections: parsedSections,
      placeholderCounts: counts,
      placeholderSummaries: summaries,
    );
  }

  static String toHumanizedLabel(String key) {
    final clean = key.replaceAll(RegExp(r'[<>\s]+'), '');
    final upper = clean.toUpperCase();
    if (upper == 'VRIN') return 'Valuer Registration Identification Number';
    if (upper == 'REPORT_REF_NO') return 'Report Reference Number';
    if (upper == 'PROPERTY_DESCRIPTION') return 'Property Description';
    if (upper == 'PROPERTY_ADDRESS') return 'Property Address';
    if (upper == 'NAME_OF_THE_OWNER' || upper == 'OWNER_NAME') return 'Name of the Owner';
    if (upper == 'TO_ADDRESSEE') return 'To / Addressee';
    if (upper == 'DATE_OF_REPORT') return 'Date of Report';
    if (upper == 'OBSERVATION_1') return 'Observation 1';
    if (upper == 'OBSERVATION_2') return 'Observation 2';
    if (upper == 'OBSERVATON_3' || upper == 'OBSERVATION_3') return 'Observation 3';
    if (upper == 'ADVANTAGES') return 'Advantages of Property';
    if (upper == 'DISADVANTAGES') return 'Disadvantages of Property';
    if (upper == 'DOCUMENTS_PERUSED') return 'Documents Perused';
    if (upper == 'IMG_FRONT_PAGE') return 'Front Page Photograph';
    if (upper == 'IMG_SECOND_PAGE') return 'Second Page Photograph';
    if (upper == 'IMG_PIC1' || upper == 'PIC1') return 'Property Photograph 1';
    if (upper == 'IMG_PIC2' || upper == 'PIC2') return 'Property Photograph 2';
    if (upper == 'IMG_PIC3' || upper == 'PIC3') return 'Property Photograph 3';
    if (upper == 'IMG_PIC4' || upper == 'PIC4') return 'Property Photograph 4';
    if (upper == 'IMG_PIC5' || upper == 'PIC5') return 'Property Photograph 5';
    if (upper == 'IMG_PIC6' || upper == 'PIC6') return 'Property Photograph 6';
    if (upper == 'IMG_PIC7' || upper == 'PIC7') return 'Property Photograph 7';
    if (upper == 'IMG_PIC8' || upper == 'PIC8') return 'Property Photograph 8';

    final words = clean.split(RegExp(r'[_\s]+'));
    return words.map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  static String _toHumanizedLabel(String key) => toHumanizedLabel(key);
}

/// Base class for all renderable blocks within a section.
abstract class SectionBlockVm {}

class TableBlockVm extends SectionBlockVm {
  final TableVm table;
  TableBlockVm(this.table);
}

class ParagraphBlockWrapperVm extends SectionBlockVm {
  final ParagraphBlockVm block;
  ParagraphBlockWrapperVm(this.block);
}

class ValuationLandBlockVm extends SectionBlockVm {
  final String id;
  ValuationLandBlockVm(this.id);
}

class ValuationBuildingBlockVm extends SectionBlockVm {
  final String id;
  ValuationBuildingBlockVm(this.id);
}

class ValuationSummaryBlockVm extends SectionBlockVm {
  final String id;
  ValuationSummaryBlockVm(this.id);
}

class ValuationPropertyBlockVm extends SectionBlockVm {
  final String id;
  ValuationPropertyBlockVm(this.id);
}

class ValuationComparableBlockVm extends SectionBlockVm {
  final String id;
  ValuationComparableBlockVm(this.id);
}

class ValuationCompositeBlockVm extends SectionBlockVm {
  final String id;
  ValuationCompositeBlockVm(this.id);
}

bool isCalculatedValuationKey(String key) {
  final upper = key.toUpperCase().trim();
  return upper == 'TOTAL_LAND_VALUE' ||
      upper == 'TOTAL_LAND_VALUE_WORDS' ||
      upper == 'TOTAL_BUILDING_VALUE' ||
      upper == 'TOTAL_BUILDING_VALUE_WORDS' ||
      upper == 'TOTAL_REPLACEMENT_COST' ||
      upper == 'TOTAL_REPLACEMENT_COST_WORDS' ||
      upper == 'TOTAL_DEPRECIATION_AMOUNT' ||
      upper == 'TOTAL_DEPRECIATION_AMOUNT_WORDS' ||
      upper == 'TOTAL_SALVAGE_VALUE' ||
      upper == 'TOTAL_SALVAGE_VALUE_WORDS' ||
      upper == 'TOTAL_FAIR_VALUE' ||
      upper == 'TOTAL_FAIR_VALUE_WORDS' ||
      upper == 'TOTAL_FAIR_VALUE_NUMERIC' ||
      upper == 'FAIR_VALUE' ||
      upper == 'FAIR_VALUE_WORDS' ||
      upper == 'FAIR_VALUE_NUMERIC' ||
      upper == 'RAW_FAIR_VALUE' ||
      upper == 'RAW_FAIR_VALUE_WORDS' ||
      upper == 'SAY_FAIR_VALUE' ||
      upper == 'SAY_FAIR_VALUE_WORDS' ||
      upper == 'REPORT_FAIR_VALUE' ||
      upper == 'REPORT_FAIR_VALUE_WORDS' ||
      upper == 'SAY_VALUE' ||
      upper == 'SAY_VALUE_WORDS' ||
      upper == 'MARKET_VALUE' ||
      upper == 'MARKET_VALUE_WORDS' ||
      upper == 'PROPERTY_VALUE' ||
      upper == 'PROPERTY_VALUE_WORDS' ||
      upper == 'FINAL_VALUE' ||
      upper == 'FINAL_VALUE_WORDS' ||
      upper == 'VALUATION_AMOUNT' ||
      upper == 'VALUATION_AMOUNT_WORDS' ||
      upper == 'OPINION_OF_VALUE' ||
      upper == 'OPINION_OF_VALUE_WORDS' ||
      upper == 'RECOMMENDED_VALUE' ||
      upper == 'RECOMMENDED_VALUE_WORDS' ||
      upper == 'REALIZABLE_VALUE' ||
      upper == 'REALIZABLE_VALUE_WORDS' ||
      upper == 'DISTRESS_SALE_VALUE' ||
      upper == 'DISTRESS_SALE_VALUE_WORDS' ||
      upper == 'INSURABLE_VALUE' ||
      upper == 'INSURABLE_VALUE_WORDS' ||
      upper == 'GOVERNMENT_VALUE' ||
      upper == 'GOVERNMENT_VALUE_WORDS' ||
      upper == 'REALIZABLE_PERCENTAGE' ||
      upper == 'DISTRESS_SALE_PERCENTAGE' ||
      upper == 'TOTAL_INTERIOR_AMOUNT' ||
      upper == 'TOTAL_INTERIOR_DEPRECIATION' ||
      upper == 'TOTAL_INTERIOR_FAIR_VALUE' ||
      upper == 'LAND_TABLE' ||
      upper == 'DYNAMIC_LAND_TABLE' ||
      upper == 'BUILDING_TABLE' ||
      upper == 'DYNAMIC_BUILDING_TABLE' ||
      upper == 'VALUATION_SUMMARY_TABLE' ||
      upper == 'DYNAMIC_VALUATION_SUMMARY_TABLE' ||
      upper == 'PROPERTY_VALUE_TABLE' ||
      upper == 'DYNAMIC_PROPERTY_VALUE_TABLE' ||
      upper == 'VALUE_OF_THE_PROPERTY' ||
      upper == 'VALUE_OF_THE_PROPERTY_TABLE' ||
      upper == 'COMPARABLES_TABLE' ||
      upper == 'DYNAMIC_COMPARABLES_TABLE' ||
      upper == 'COMPOSITE_PROPERTY_TABLE' ||
      upper == 'DYNAMIC_COMPOSITE_PROPERTY_TABLE' ||
      upper == 'COMPOSITE_TABLE';
}

/// Base class for inline runs within a document-native paragraph.
abstract class DocumentRunNode {}

/// Text run with styling matching the author's original OpenXML runs.
class TextRunNode extends DocumentRunNode {
  final String text;
  final bool isBold;
  final bool isItalic;
  final double fontSizePt;
  final String? fontColor;

  TextRunNode({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.fontSizePt = 11.0,
    this.fontColor,
  });
}

/// Inline editable placeholder run bound to an InputFieldVm.
class PlaceholderRunNode extends DocumentRunNode {
  final String key;
  final InputFieldVm fieldVm;
  final bool isBold;
  final bool isItalic;
  final double fontSizePt;
  final String? fontColor;

  PlaceholderRunNode({
    required this.key,
    required this.fieldVm,
    this.isBold = false,
    this.isItalic = false,
    this.fontSizePt = 11.0,
    this.fontColor,
  });
}

/// Inline image slot run.
class ImageRunNode extends DocumentRunNode {
  final String key;
  final InputFieldVm fieldVm;

  ImageRunNode({
    required this.key,
    required this.fieldVm,
  });
}

/// ViewModel for a document-native paragraph block containing rich runs and/or interactive input fields.
class ParagraphBlockVm {
  final String id;
  final String? staticText;
  final String? rawText;
  final String alignment; // 'LEFT', 'CENTER', 'RIGHT', 'JUSTIFY', 'BOTH'
  final List<InputFieldVm> inputFields;
  final List<DocumentRunNode> nodes;

  const ParagraphBlockVm({
    required this.id,
    this.staticText,
    this.rawText,
    this.alignment = 'LEFT',
    this.inputFields = const [],
    this.nodes = const [],
  });

  bool get hasInputs => inputFields.isNotEmpty;
  bool get hasNodes => nodes.isNotEmpty;

  TextAlign get textAlign {
    switch (alignment.toUpperCase()) {
      case 'CENTER':
        return TextAlign.center;
      case 'RIGHT':
        return TextAlign.right;
      case 'JUSTIFY':
      case 'BOTH':
        return TextAlign.justify;
      case 'LEFT':
      default:
        return TextAlign.left;
    }
  }
}


/// ViewModel for a logical document section.
class SectionVm {
  final int sectionIndex;
  final String title;
  final List<TableVm> tables;
  final List<StudioParagraph> standaloneParagraphs;
  final List<ParagraphBlockVm> paragraphBlocks;
  final List<SectionBlockVm> orderedBlocks;
  final Set<String> boundKeys;

  const SectionVm({
    required this.sectionIndex,
    required this.title,
    this.tables = const [],
    this.standaloneParagraphs = const [],
    this.paragraphBlocks = const [],
    this.orderedBlocks = const [],
    this.boundKeys = const {},
  });

  int get totalFields => boundKeys.length;

  int getCompletedCount(Map<String, String> values) {
    int count = 0;
    for (final key in boundKeys) {
      final val = values[key.toUpperCase()]?.trim();
      if (val != null && val.isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  bool isCompleted(Map<String, String> values) {
    if (totalFields == 0) return true;
    return getCompletedCount(values) >= totalFields;
  }
}

/// ViewModel for a table structure within a section.
class TableVm {
  final String tableId;
  final int rowCount;
  final int columnCount;
  final List<TableRowVm> rows;

  const TableVm({
    required this.tableId,
    required this.rowCount,
    required this.columnCount,
    required this.rows,
  });
}

/// ViewModel for a table row, classifying 3-column, 2-column, header, or subheader.
class TableRowVm {
  final int rowIndex;
  final String rowType; // QUESTION_ANSWER, TABLE_HEADER, SECTION_SUBHEADER, STATIC_ROW
  final String? serialNo;
  final String? questionText;
  final String? indexCellId;
  final String? questionCellId;
  final String? answerCellId;
  final List<InputFieldVm> inputFields;
  final List<StudioTableCell> rawCells;

  const TableRowVm({
    required this.rowIndex,
    required this.rowType,
    this.serialNo,
    this.questionText,
    this.indexCellId,
    this.questionCellId,
    this.answerCellId,
    this.inputFields = const [],
    this.rawCells = const [],
  });

  bool get isQuestionAnswer => rowType == 'QUESTION_ANSWER';
  bool get isTableHeader => rowType == 'TABLE_HEADER';
  bool get isSubHeader => rowType == 'SECTION_SUBHEADER';
  bool get isStatic => rowType == 'STATIC_ROW';

  /// Type B Section Header: Merged headers, group titles, category headers, chapter names.
  /// (e.g. Application No, Property Details, Stage of Construction, Violations if any observed, Area Details of Property)
  /// ALWAYS LEFT ALIGNED, never centered.
  bool get isSectionHeadingRow =>
      isSubHeader ||
      (inputFields.isEmpty && !isTableHeader) ||
      (rawCells.length == 1 && !isTableHeader);

  bool get is3Column => inputFields.isNotEmpty && serialNo != null && serialNo!.isNotEmpty;
  bool get is2Column => inputFields.isNotEmpty && (serialNo == null || serialNo!.isEmpty);
  bool get hasCompositeTable => inputFields.any((f) => f.isCompositeTable);


  factory TableRowVm.fromStudioTableRow(
    StudioTableRow row,
    Map<String, int> counts,
    Map<String, PlaceholderSummaryItem> summaries,
    Map<String, String> values,
  ) {
    String? sNo;
    String? qText;
    String? idxCellId;
    String? qCellId;
    String? aCellId;
    final List<InputFieldVm> fields = [];

    final cells = row.cells;

    for (final cell in cells) {
      if (cell.cellRole == 'INDEX') {
        sNo = cell.plainText.trim();
        idxCellId = cell.cellId;
      } else if (cell.cellRole == 'QUESTION') {
        qText = cell.plainText.trim();
        qCellId = cell.cellId;
      } else if (cell.cellRole == 'ANSWER') {
        aCellId = cell.cellId;
        for (final b in cell.placeholderBindings) {
          final keyUpper = b.key.toUpperCase();
          final occ = counts[keyUpper] ?? 1;
          String prompt = b.questionText.isNotEmpty
              ? b.questionText
              : (qText != null && qText.isNotEmpty ? qText : summaries[keyUpper]?.questionText ?? DocumentWorkspaceVm._toHumanizedLabel(keyUpper));
          if (prompt.trim().length <= 1 ||
              prompt.toLowerCase().startsWith('rectangle') ||
              prompt.toLowerCase().startsWith('picture') ||
              prompt.trim() == '_') {
            prompt = DocumentWorkspaceVm._toHumanizedLabel(keyUpper);
          }

          fields.add(InputFieldVm(
            key: keyUpper,
            serialNo: b.serialNo ?? sNo,
            questionText: prompt,
            fieldType: b.fieldType,
            occurrences: occ,
            currentValue: values[keyUpper] ?? '',
          ));
        }
      }
    }

    // When no input fields exist in this row (e.g. section title rows, category headers),
    // extract any available serial number and title text from the raw cells.
    if (fields.isEmpty) {
      final nonEmptyCells = cells.where((c) => c.plainText.trim().isNotEmpty).toList();
      if (nonEmptyCells.length == 1) {
        qText ??= nonEmptyCells.first.plainText.trim();
      } else if (nonEmptyCells.length >= 2) {
        final firstText = nonEmptyCells[0].plainText.trim();
        if (RegExp(r'^\d+[\.\)]?$').hasMatch(firstText) || RegExp(r'^[a-zA-Z][\.\)]?$').hasMatch(firstText)) {
          sNo ??= firstText;
          qText ??= nonEmptyCells.sublist(1).map((c) => c.plainText.trim()).join(' ');
        } else {
          qText ??= nonEmptyCells.map((c) => c.plainText.trim()).join(' — ');
        }
      }
    }

    return TableRowVm(
      rowIndex: row.rowIndex,
      rowType: row.rowType,
      serialNo: sNo,
      questionText: qText,
      indexCellId: idxCellId,
      questionCellId: qCellId,
      answerCellId: aCellId,
      inputFields: fields,
      rawCells: cells,
    );
  }
}

/// ViewModel for an interactive input field slot within an answer cell or paragraph form.
class InputFieldVm {
  final String key;
  final String? serialNo;
  final String questionText;
  final String fieldType; // TEXT, MULTILINE, NUMBER, DATE, SELECT, IMAGE
  final int occurrences;
  final String currentValue;

  const InputFieldVm({
    required this.key,
    this.serialNo,
    required this.questionText,
    required this.fieldType,
    this.occurrences = 1,
    this.currentValue = '',
  });

  String get type => fieldType;

  bool get isRepeated => occurrences > 1;

  /// Explicit detection for <<COMPOSITE_PROPERTY_TABLE>>
  bool get isCompositeTable =>
      DocumentWorkspaceVm.isCompositeTableKey(key, fieldType);
  
  bool get isImage {
    if (isCompositeTable) return false;
    final t = fieldType.toUpperCase();
    if (t == 'IMAGE') return true;
    final k = key.toUpperCase();
    final isExplicitImageKey = k.startsWith('IMG_') ||
        k.endsWith('_IMAGE') ||
        k.contains('PHOTO') ||
        k.contains('SELFIE') ||
        k.contains('SIGNATURE');
    if (isExplicitImageKey) return true;
    if (t == 'TEXT' || t == 'MULTILINE' || t == 'NUMBER' || t == 'DATE') return false;
    return false;
  }

  bool get isDate =>
      !isCompositeTable &&
      (fieldType.toUpperCase() == 'DATE' ||
          key.toUpperCase().contains('DATE') ||
          key.toUpperCase().startsWith('DT_') ||
          key.toUpperCase().endsWith('_DT'));

  bool get isNumber {
    if (isCompositeTable || isImage || isDate) return false;
    final t = fieldType.toUpperCase();
    if (t == 'MULTILINE') return false;
    final k = key.toUpperCase();
    if (k.contains('REMARK') ||
        k.contains('COMMENT') ||
        k.contains('OBSERVATION') ||
        k.contains('NOTE') ||
        k.contains('DESC') ||
        k.contains('ADDRESS') ||
        k.contains('NAME') ||
        k.contains('TEXT') ||
        k.contains('TREND') ||
        k.contains('DETAIL') ||
        k.contains('BOUNDARY') ||
        k.contains('BOUNDARIES')) {
      return false;
    }
    return t == 'NUMBER' ||
        k.contains('AMOUNT') ||
        k.contains('VALUE') ||
        k.contains('RATE') ||
        k.contains('AREA') ||
        k.contains('SFT') ||
        k.contains('SQFT') ||
        k.contains('SQYD');
  }

  bool get isMultiline {
    if (isCompositeTable || isImage || isDate || isNumber) return false;
    // DEFECT 1: Every TEXT placeholder without exception behaves as a multiline expandable textbox.
    return true;
  }

  bool get isCurrency =>
      isNumber &&
      (key.toUpperCase().contains('VALUE') ||
          key.toUpperCase().contains('RATE') ||
          key.toUpperCase().contains('AMOUNT') ||
          key.toUpperCase().contains('COST') ||
          key.toUpperCase().contains('PRICE') ||
          key.toUpperCase().contains('FEE') ||
          key.toUpperCase().contains('DEPRECIATION'));

  /// Type A Column 3 conditional alignment:
  /// Left align for addresses, remarks, boundary descriptions, narratives, multiline content.
  /// Center align for short values: numbers, currency, percentages, dates, dropdowns, yes/no, approval values.
  bool get shouldLeftAlign {
    if (isMultiline) return true;
    final k = key.toUpperCase();
    final q = questionText.toUpperCase();
    if (k.contains('ADDRESS') || q.contains('ADDRESS')) return true;
    if (k.contains('REMARK') || q.contains('REMARK')) return true;
    if (k.contains('DESCRIPTION') || q.contains('DESCRIPTION')) return true;
    if (k.contains('BOUNDARY') || q.contains('BOUNDARY')) return true;
    if (k.contains('OBSERVATION') || q.contains('OBSERVATION')) return true;
    if (k.contains('NARRATIVE') || q.contains('NARRATIVE')) return true;
    if (k.contains('LEGAL') || q.contains('LEGAL')) return true;
    if (k.contains('NOTE') || q.contains('NOTE')) return true;
    if (k.contains('VIOLATION') || q.contains('VIOLATION')) return true;
    if (k.contains('DEVIATION') || q.contains('DEVIATION')) return true;
    if (k.contains('SURROUNDING') || q.contains('SURROUNDING')) return true;
    if (k.contains('LOCALITY') || q.contains('LOCALITY')) return true;
    if (k.contains('TENURE') || q.contains('TENURE')) return true;
    return false;
  }

  TextAlign get effectiveTextAlign => shouldLeftAlign ? TextAlign.left : TextAlign.center;
}


