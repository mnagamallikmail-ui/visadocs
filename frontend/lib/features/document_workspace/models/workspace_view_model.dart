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

    for (final s in dom.sections) {
      final List<TableVm> tables = [];
      final List<StudioParagraph> paragraphs = [];
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

          tables.add(TableVm(
            tableId: el.id,
            rowCount: el.rowCount,
            columnCount: el.columnCount,
            rows: rows,
          ));
        } else if (el is StudioParagraph) {
          paragraphs.add(el);
          for (final run in el.runs) {
            if (run.isPlaceholder && run.placeholderKey != null) {
              sectionKeys.add(run.placeholderKey!.toUpperCase());
            }
          }
        }
      }

      parsedSections.add(SectionVm(
        sectionIndex: s.sectionIndex,
        title: s.title,
        tables: tables,
        standaloneParagraphs: paragraphs,
        boundKeys: sectionKeys,
      ));
    }

    return DocumentWorkspaceVm(
      sections: parsedSections,
      placeholderCounts: counts,
      placeholderSummaries: summaries,
    );
  }
}

/// ViewModel for a logical document section (Cover, Summary, Property Details, etc.).
class SectionVm {
  final int sectionIndex;
  final String title;
  final List<TableVm> tables;
  final List<StudioParagraph> standaloneParagraphs;
  final Set<String> boundKeys;

  const SectionVm({
    required this.sectionIndex,
    required this.title,
    this.tables = const [],
    this.standaloneParagraphs = const [],
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
          final prompt = b.questionText.isNotEmpty
              ? b.questionText
              : (qText != null && qText.isNotEmpty ? qText : summaries[keyUpper]?.questionText ?? keyUpper);

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

/// ViewModel for an interactive input field slot within an answer cell.
class InputFieldVm {
  final String key;
  final String? serialNo;
  final String questionText;
  final String fieldType; // TEXT, NUMBER, DATE, SELECT, IMAGE
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
  bool get isImage => fieldType.toUpperCase() == 'IMAGE';
  bool get isDate => fieldType.toUpperCase() == 'DATE';
  bool get isNumber => fieldType.toUpperCase() == 'NUMBER';
}
