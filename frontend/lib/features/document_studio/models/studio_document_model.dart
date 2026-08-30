/// Root model representing the parsed OpenXML document structure.
class StudioDocumentModel {
  final List<StudioSection> sections;
  final List<PlaceholderSummaryItem> placeholdersSummary;

  const StudioDocumentModel({
    this.sections = const [],
    this.placeholdersSummary = const [],
  });

  factory StudioDocumentModel.fromJson(Map<String, dynamic> json) {
    return StudioDocumentModel(
      sections: (json['sections'] as List<dynamic>?)
              ?.map((s) => StudioSection.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      placeholdersSummary: (json['placeholdersSummary'] as List<dynamic>?)
              ?.map((p) => PlaceholderSummaryItem.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'sections': sections.map((s) => s.toJson()).toList(),
        'placeholdersSummary': placeholdersSummary.map((p) => p.toJson()).toList(),
      };

  /// Returns a set of all unique placeholder keys found across the document summary.
  Set<String> getAllPlaceholderKeys() {
    return placeholdersSummary.map((p) => p.key).toSet();
  }

  /// Returns the total occurrence count for a specific placeholder key.
  int getPlaceholderCount(String key) {
    for (final item in placeholdersSummary) {
      if (item.key.toUpperCase() == key.toUpperCase()) {
        return item.occurrences;
      }
    }
    return 0;
  }
}

/// A logical section or chapter in the document.
class StudioSection {
  final int sectionIndex;
  final String title;
  final List<StudioElement> elements;

  const StudioSection({
    required this.sectionIndex,
    required this.title,
    this.elements = const [],
  });

  factory StudioSection.fromJson(Map<String, dynamic> json) {
    final rawElements = json['elements'] as List<dynamic>? ?? const [];
    final parsedElements = <StudioElement>[];

    for (final elem in rawElements) {
      if (elem is Map<String, dynamic>) {
        final type = elem['type']?.toString().toUpperCase() ?? 'PARAGRAPH';
        if (type == 'TABLE') {
          parsedElements.add(StudioTable.fromJson(elem));
        } else {
          parsedElements.add(StudioParagraph.fromJson(elem));
        }
      }
    }

    return StudioSection(
      sectionIndex: json['sectionIndex'] as int? ?? 0,
      title: json['title'] as String? ?? 'General Section',
      elements: parsedElements,
    );
  }

  Map<String, dynamic> toJson() => {
        'sectionIndex': sectionIndex,
        'title': title,
        'elements': elements.map((e) => e.toJson()).toList(),
      };
}

/// Base class for document body elements (Paragraphs, Tables).
abstract class StudioElement {
  final String id;
  final String type;

  const StudioElement({
    required this.id,
    required this.type,
  });

  Map<String, dynamic> toJson();
}

/// Represents a formatted paragraph element containing text runs or inline drawings.
class StudioParagraph extends StudioElement {
  final String alignment;
  final List<StudioRun> runs;

  const StudioParagraph({
    required super.id,
    this.alignment = 'LEFT',
    this.runs = const [],
  }) : super(type: 'PARAGRAPH');

  factory StudioParagraph.fromJson(Map<String, dynamic> json) {
    return StudioParagraph(
      id: json['id'] as String? ?? '',
      alignment: json['alignment'] as String? ?? 'LEFT',
      runs: (json['runs'] as List<dynamic>?)
              ?.map((r) => StudioRun.fromJson(r as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PARAGRAPH',
        'id': id,
        'alignment': alignment,
        'runs': runs.map((r) => r.toJson()).toList(),
      };

  /// Returns the concatenated plain text of this paragraph.
  String get plainText => runs.map((r) => r.text).join();
}

/// Represents a single styled text fragment or inline image slot within a paragraph.
class StudioRun {
  final String text;
  final bool isPlaceholder;
  final String? placeholderKey;
  final bool isBold;
  final bool isItalic;
  final double fontSizePt;
  final String? fontColor;
  final bool isImage;
  final bool isImagePresent;

  const StudioRun({
    this.text = '',
    this.isPlaceholder = false,
    this.placeholderKey,
    this.isBold = false,
    this.isItalic = false,
    this.fontSizePt = 11.0,
    this.fontColor,
    this.isImage = false,
    this.isImagePresent = false,
  });

  factory StudioRun.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString().toUpperCase();
    final fieldType = json['fieldType']?.toString().toUpperCase();
    final isPlaceholder = json['isPlaceholder'] as bool? ?? false;
    final placeholderKey = json['placeholderKey'] as String?;
    final isImage = type == 'IMAGE' ||
        fieldType == 'IMAGE' ||
        (placeholderKey != null &&
            (placeholderKey.toUpperCase().startsWith('IMG_') ||
                placeholderKey.toUpperCase().contains('PHOTO') ||
                placeholderKey.toUpperCase().contains('IMAGE')));

    return StudioRun(
      text: json['text'] as String? ?? (placeholderKey != null ? '<<$placeholderKey>>' : ''),
      isPlaceholder: isPlaceholder || placeholderKey != null,
      placeholderKey: placeholderKey,
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      fontSizePt: (json['fontSizePt'] as num?)?.toDouble() ?? 11.0,
      fontColor: json['fontColor'] as String?,
      isImage: isImage,
      isImagePresent: json['present'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isPlaceholder': isPlaceholder,
      if (placeholderKey != null) 'placeholderKey': placeholderKey,
      if (isImage) 'fieldType': 'IMAGE',
      if (isImage) 'present': isImagePresent,
      'isBold': isBold,
      'isItalic': isItalic,
      'fontSizePt': fontSizePt,
      if (fontColor != null) 'fontColor': fontColor,
    };
  }
}

/// Represents a structured table with rows and cells.
class StudioTable extends StudioElement {
  final int rowCount;
  final int columnCount;
  final List<StudioTableRow> rows;

  const StudioTable({
    required super.id,
    this.rowCount = 0,
    this.columnCount = 0,
    this.rows = const [],
  }) : super(type: 'TABLE');

  factory StudioTable.fromJson(Map<String, dynamic> json) {
    return StudioTable(
      id: json['id'] as String? ?? '',
      rowCount: json['rowCount'] as int? ?? 0,
      columnCount: json['columnCount'] as int? ?? 0,
      rows: (json['rows'] as List<dynamic>?)
              ?.map((r) => StudioTableRow.fromJson(r as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'TABLE',
        'id': id,
        'rowCount': rowCount,
        'columnCount': columnCount,
        'rows': rows.map((r) => r.toJson()).toList(),
      };
}

/// Represents a single row in a table.
class StudioTableRow {
  final int rowIndex;
  final String rowType; // QUESTION_ANSWER, TABLE_HEADER, SECTION_SUBHEADER, STATIC_ROW
  final List<StudioTableCell> cells;

  const StudioTableRow({
    required this.rowIndex,
    this.rowType = 'STATIC_ROW',
    this.cells = const [],
  });

  factory StudioTableRow.fromJson(Map<String, dynamic> json) {
    return StudioTableRow(
      rowIndex: json['rowIndex'] as int? ?? 0,
      rowType: json['rowType'] as String? ?? 'STATIC_ROW',
      cells: (json['cells'] as List<dynamic>?)
              ?.map((c) => StudioTableCell.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'rowIndex': rowIndex,
        'rowType': rowType,
        'cells': cells.map((c) => c.toJson()).toList(),
      };
}

/// Represents a placeholder binding within an answer cell.
class PlaceholderBinding {
  final String key;
  final String? serialNo;
  final String questionText;
  final String fieldType;

  const PlaceholderBinding({
    required this.key,
    this.serialNo,
    this.questionText = '',
    this.fieldType = 'TEXT',
  });

  factory PlaceholderBinding.fromJson(Map<String, dynamic> json) {
    return PlaceholderBinding(
      key: json['key'] as String? ?? '',
      serialNo: json['serialNo'] as String?,
      questionText: json['questionText'] as String? ?? '',
      fieldType: json['fieldType'] as String? ?? 'TEXT',
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        if (serialNo != null) 'serialNo': serialNo,
        'questionText': questionText,
        'fieldType': fieldType,
      };
}

/// Represents a cell inside a table row with column span, vertical merge status, and semantic role.
class StudioTableCell {
  final String cellId;
  final int colSpan;
  final String vMerge; // "restart", "continue", or "none"
  final String cellRole; // "HEADER", "INDEX", "QUESTION", "ANSWER", "STATIC_TEXT"
  final String plainText;
  final bool isHeader;
  final bool isSubHeader;
  final String? targetAnswerCellId;
  final String? sourceQuestionCellId;
  final List<PlaceholderBinding> placeholderBindings;
  final List<StudioParagraph> paragraphs;

  const StudioTableCell({
    required this.cellId,
    this.colSpan = 1,
    this.vMerge = 'none',
    this.cellRole = 'STATIC_TEXT',
    this.plainText = '',
    this.isHeader = false,
    this.isSubHeader = false,
    this.targetAnswerCellId,
    this.sourceQuestionCellId,
    this.placeholderBindings = const [],
    this.paragraphs = const [],
  });

  factory StudioTableCell.fromJson(Map<String, dynamic> json) {
    return StudioTableCell(
      cellId: json['cellId'] as String? ?? '',
      colSpan: json['colSpan'] as int? ?? 1,
      vMerge: json['vMerge'] as String? ?? 'none',
      cellRole: json['cellRole'] as String? ?? 'STATIC_TEXT',
      plainText: json['plainText'] as String? ?? '',
      isHeader: json['isHeader'] as bool? ?? false,
      isSubHeader: json['isSubHeader'] as bool? ?? false,
      targetAnswerCellId: json['targetAnswerCellId'] as String?,
      sourceQuestionCellId: json['sourceQuestionCellId'] as String?,
      placeholderBindings: (json['placeholderBindings'] as List<dynamic>?)
              ?.map((b) => PlaceholderBinding.fromJson(b as Map<String, dynamic>))
              .toList() ??
          const [],
      paragraphs: (json['paragraphs'] as List<dynamic>?)
              ?.map((p) => StudioParagraph.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'cellId': cellId,
        'colSpan': colSpan,
        'vMerge': vMerge,
        'cellRole': cellRole,
        'plainText': plainText,
        'isHeader': isHeader,
        'isSubHeader': isSubHeader,
        if (targetAnswerCellId != null) 'targetAnswerCellId': targetAnswerCellId,
        if (sourceQuestionCellId != null) 'sourceQuestionCellId': sourceQuestionCellId,
        'placeholderBindings': placeholderBindings.map((b) => b.toJson()).toList(),
        'paragraphs': paragraphs.map((p) => p.toJson()).toList(),
      };

  /// Whether this cell is the top master of a vertically merged set.
  bool get isVerticalMergeMaster => vMerge.toLowerCase() == 'restart';

  /// Whether this cell is an occluded continuation of a vertical merge from above.
  bool get isVerticalMergeContinuation => vMerge.toLowerCase() == 'continue';
}

/// Metadata item describing an extracted placeholder, occurrence count, and field type.
class PlaceholderSummaryItem {
  final String key;
  final String label;
  final String? questionText;
  final String? serialNo;
  final int occurrences;
  final String type; // TEXT, NUMBER, DATE, IMAGE
  final String source; // TABLE_ROW, PARAGRAPH
  final Map<String, dynamic>? tableContext;

  const PlaceholderSummaryItem({
    required this.key,
    required this.label,
    this.questionText,
    this.serialNo,
    this.occurrences = 1,
    this.type = 'TEXT',
    this.source = 'PARAGRAPH',
    this.tableContext,
  });

  factory PlaceholderSummaryItem.fromJson(Map<String, dynamic> json) {
    return PlaceholderSummaryItem(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      questionText: json['questionText'] as String?,
      serialNo: json['serialNo'] as String?,
      occurrences: json['occurrences'] as int? ?? 1,
      type: json['type'] as String? ?? 'TEXT',
      source: json['source'] as String? ?? 'PARAGRAPH',
      tableContext: json['tableContext'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        if (questionText != null) 'questionText': questionText,
        if (serialNo != null) 'serialNo': serialNo,
        'occurrences': occurrences,
        'type': type,
        'source': source,
        if (tableContext != null) 'tableContext': tableContext,
      };
}
