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

          // Check if this paragraph is a dynamic valuation table directive
          final upperPKeys = pKeys.map((k) => k.toUpperCase().trim()).toList();
          if (upperPKeys.contains('COMPOSITE_PROPERTY_TABLE') || upperPKeys.contains('DYNAMIC_COMPOSITE_PROPERTY_TABLE') || upperPKeys.contains('COMPOSITE_TABLE')) {
            orderedBlocks.add(ValuationCompositeBlockVm(el.id));
            compositeBlockAdded = true;
            continue;
          }

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

          if (pKeys.isNotEmpty) {
            final List<InputFieldVm> fields = [];
            for (final rawKey in pKeys) {
              final keyUpper = rawKey.toUpperCase().trim();
              // Filter out calculated outputs and dynamic directives so they do NOT render as questions
              if (isCalculatedValuationKey(keyUpper)) {
                continue;
              }

              sectionKeys.add(keyUpper);
              final occ = counts[keyUpper] ?? 1;
              final summaryItem = summaries[keyUpper];
              String prompt = summaryItem?.questionText ?? '';
              if (prompt.isEmpty ||
                  prompt.trim().length <= 1 ||
                  prompt.toLowerCase().startsWith('rectangle') ||
                  prompt.toLowerCase().startsWith('picture') ||
                  prompt.toLowerCase().startsWith('textbox') ||
                  prompt.trim() == '_') {
                prompt = _toHumanizedLabel(keyUpper);
              }

              String fieldType = summaryItem?.type ?? 'TEXT';
              if (fieldType.toUpperCase() == 'IMAGE' ||
                  keyUpper.startsWith('IMG_') ||
                  keyUpper.contains('IMAGE') ||
                  keyUpper.contains('PHOTO') ||
                  keyUpper.contains('PIC')) {
                fieldType = 'IMAGE';
              } else if (keyUpper.contains('DATE') || keyUpper.contains('DT')) {
                fieldType = 'DATE';
              } else if (keyUpper.contains('OBSERVATION') ||
                  keyUpper.contains('ADVANTAGE') ||
                  keyUpper.contains('DISADVANTAGE') ||
                  keyUpper.contains('DOCUMENT') ||
                  keyUpper.contains('DESCRIPTION') ||
                  keyUpper.contains('ADDRESS')) {
                fieldType = 'MULTILINE';
              }

              fields.add(InputFieldVm(
                key: keyUpper,
                questionText: prompt,
                fieldType: fieldType,
                occurrences: occ,
                currentValue: values[keyUpper] ?? '',
              ));
            }

            if (fields.isNotEmpty) {
              final block = ParagraphBlockVm(
                id: el.id,
                inputFields: fields,
                rawText: text,
              );
              paragraphBlocks.add(block);
              orderedBlocks.add(ParagraphBlockWrapperVm(block));
            } else {
              final cleanText = text.trim();
              if (cleanText.isNotEmpty &&
                  cleanText.length > 1 &&
                  !cleanText.startsWith('<<') &&
                  cleanText != '_' &&
                  cleanText != 'n' &&
                  cleanText != 'r') {
                final block = ParagraphBlockVm(
                  id: el.id,
                  staticText: cleanText,
                  rawText: text,
                );
                paragraphBlocks.add(block);
                orderedBlocks.add(ParagraphBlockWrapperVm(block));
              }
            }
          } else {
            final cleanText = text.trim();
            // Orphan text cleanup: do not create paragraph blocks for single-character parser artifacts or whitespace noise
            if (cleanText.isNotEmpty &&
                cleanText.length > 1 &&
                cleanText != '_' &&
                cleanText != 'n' &&
                cleanText != 'r') {
              final block = ParagraphBlockVm(
                id: el.id,
                staticText: cleanText,
                rawText: text,
              );
              paragraphBlocks.add(block);
              orderedBlocks.add(ParagraphBlockWrapperVm(block));
            }
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

  static String _toHumanizedLabel(String key) {
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
      upper == 'FAIR_VALUE' ||
      upper == 'FAIR_VALUE_WORDS' ||
      upper == 'RAW_FAIR_VALUE' ||
      upper == 'RAW_FAIR_VALUE_WORDS' ||
      upper == 'SAY_FAIR_VALUE' ||
      upper == 'SAY_FAIR_VALUE_WORDS' ||
      upper == 'SAY_VALUE' ||
      upper == 'SAY_VALUE_WORDS' ||
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

/// ViewModel for a paragraph block containing static text or interactive input fields.
class ParagraphBlockVm {
  final String id;
  final String? staticText;
  final String? rawText;
  final List<InputFieldVm> inputFields;

  const ParagraphBlockVm({
    required this.id,
    this.staticText,
    this.rawText,
    this.inputFields = const [],
  });

  bool get hasInputs => inputFields.isNotEmpty;
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

  bool get is3Column => isQuestionAnswer && serialNo != null && serialNo!.isNotEmpty;
  bool get is2Column => isQuestionAnswer && (serialNo == null || serialNo!.isEmpty);

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

  bool get isRepeated => occurrences > 1;
  
  bool get isImage =>
      fieldType.toUpperCase() == 'IMAGE' ||
      key.toUpperCase().startsWith('IMG_') ||
      key.toUpperCase().contains('IMAGE') ||
      key.toUpperCase().contains('PHOTO');

  bool get isDate =>
      fieldType.toUpperCase() == 'DATE' ||
      key.toUpperCase().contains('DATE') ||
      key.toUpperCase().startsWith('DT_') ||
      key.toUpperCase().endsWith('_DT');

  bool get isMultiline {
    if (fieldType.toUpperCase() == 'MULTILINE') return true;
    final k = key.toUpperCase();
    return k.contains('OBSERVATION') ||
        k.contains('ADVANTAGE') ||
        k.contains('DISADVANTAGE') ||
        k.contains('DOCUMENT') ||
        k.contains('DESCRIPTION') ||
        k.contains('REMARK') ||
        k.contains('NOTE') ||
        k.contains('ADDRESS') ||
        k.contains('SPECIFICATION') ||
        k.contains('BOUNDARY') ||
        k.contains('BOUNDARIES');
  }

  bool get isNumber =>
      !isDate &&
      !isMultiline &&
      !isImage &&
      (fieldType.toUpperCase() == 'NUMBER' ||
          key.toUpperCase().contains('AMOUNT') ||
          key.toUpperCase().contains('VALUE') ||
          key.toUpperCase().contains('RATE') ||
          key.toUpperCase().contains('AREA') ||
          key.toUpperCase().contains('SFT') ||
          key.toUpperCase().contains('SQFT') ||
          key.toUpperCase().contains('SQYD'));
}

