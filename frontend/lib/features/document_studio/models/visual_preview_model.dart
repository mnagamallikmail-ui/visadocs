import 'package:flutter/foundation.dart';

/// Root model representing the pixel-perfect visual preview layout and page geometries.
class VisualPreviewModel {
  final int templateId;
  final int totalPages;
  final VisualPageDimensionsModel pageDimensions;
  final List<VisualPageModel> pages;

  const VisualPreviewModel({
    required this.templateId,
    required this.totalPages,
    required this.pageDimensions,
    required this.pages,
  });

  factory VisualPreviewModel.fromJson(Map<String, dynamic> json) {
    return VisualPreviewModel(
      templateId: json['templateId'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      pageDimensions: json['pageDimensions'] != null
          ? VisualPageDimensionsModel.fromJson(json['pageDimensions'] as Map<String, dynamic>)
          : const VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
      pages: (json['pages'] as List<dynamic>?)
              ?.map((p) => VisualPageModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'totalPages': totalPages,
        'pageDimensions': pageDimensions.toJson(),
        'pages': pages.map((p) => p.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisualPreviewModel &&
          runtimeType == other.runtimeType &&
          templateId == other.templateId &&
          totalPages == other.totalPages &&
          pageDimensions == other.pageDimensions &&
          listEquals(pages, other.pages);

  @override
  int get hashCode =>
      templateId.hashCode ^
      totalPages.hashCode ^
      pageDimensions.hashCode ^
      Object.hashAll(pages);
}

/// Dimensions and aspect ratio of standard template pages in points.
class VisualPageDimensionsModel {
  final double widthPt;
  final double heightPt;
  final double aspectRatio;

  const VisualPageDimensionsModel({
    required this.widthPt,
    required this.heightPt,
    required this.aspectRatio,
  });

  factory VisualPageDimensionsModel.fromJson(Map<String, dynamic> json) {
    final w = (json['widthPt'] as num?)?.toDouble() ?? 595.28;
    final h = (json['heightPt'] as num?)?.toDouble() ?? 841.89;
    final ratio = (json['aspectRatio'] as num?)?.toDouble() ?? (h > 0 ? w / h : 0.707);
    return VisualPageDimensionsModel(
      widthPt: w,
      heightPt: h,
      aspectRatio: ratio,
    );
  }

  Map<String, dynamic> toJson() => {
        'widthPt': widthPt,
        'heightPt': heightPt,
        'aspectRatio': aspectRatio,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisualPageDimensionsModel &&
          runtimeType == other.runtimeType &&
          widthPt == other.widthPt &&
          heightPt == other.heightPt &&
          aspectRatio == other.aspectRatio;

  @override
  int get hashCode => widthPt.hashCode ^ heightPt.hashCode ^ aspectRatio.hashCode;
}

/// Metadata and extracted bounding boxes for a single document page.
class VisualPageModel {
  final int pageIndex;
  final String pageImageUrl;
  final List<VisualPlaceholderModel> placeholders;

  const VisualPageModel({
    required this.pageIndex,
    required this.pageImageUrl,
    required this.placeholders,
  });

  factory VisualPageModel.fromJson(Map<String, dynamic> json) {
    return VisualPageModel(
      pageIndex: json['pageIndex'] as int? ?? 0,
      pageImageUrl: json['pageImageUrl'] as String? ?? '',
      placeholders: (json['placeholders'] as List<dynamic>?)
              ?.map((p) => VisualPlaceholderModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'pageIndex': pageIndex,
        'pageImageUrl': pageImageUrl,
        'placeholders': placeholders.map((p) => p.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisualPageModel &&
          runtimeType == other.runtimeType &&
          pageIndex == other.pageIndex &&
          pageImageUrl == other.pageImageUrl &&
          listEquals(placeholders, other.placeholders);

  @override
  int get hashCode =>
      pageIndex.hashCode ^ pageImageUrl.hashCode ^ Object.hashAll(placeholders);
}

/// Extracted spatial occurrence of a placeholder token on a specific page.
class VisualPlaceholderModel {
  final String key;
  final String rawText;
  final int occurrenceIndex;
  final List<NormalizedRectModel> rectangles;

  const VisualPlaceholderModel({
    required this.key,
    required this.rawText,
    required this.occurrenceIndex,
    required this.rectangles,
  });

  factory VisualPlaceholderModel.fromJson(Map<String, dynamic> json) {
    return VisualPlaceholderModel(
      key: (json['key'] as String? ?? '').toUpperCase(),
      rawText: json['rawText'] as String? ?? '',
      occurrenceIndex: json['occurrenceIndex'] as int? ?? 0,
      rectangles: (json['rectangles'] as List<dynamic>?)
              ?.map((r) => NormalizedRectModel.fromJson(r as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'rawText': rawText,
        'occurrenceIndex': occurrenceIndex,
        'rectangles': rectangles.map((r) => r.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisualPlaceholderModel &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          rawText == other.rawText &&
          occurrenceIndex == other.occurrenceIndex &&
          listEquals(rectangles, other.rectangles);

  @override
  int get hashCode =>
      key.hashCode ^
      rawText.hashCode ^
      occurrenceIndex.hashCode ^
      Object.hashAll(rectangles);
}

/// Normalized fractional bounding box coordinates (0.0 to 1.0).
class NormalizedRectModel {
  final double x;
  final double y;
  final double w;
  final double h;

  const NormalizedRectModel({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  factory NormalizedRectModel.fromJson(Map<String, dynamic> json) {
    return NormalizedRectModel(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      w: (json['w'] as num?)?.toDouble() ?? 0.0,
      h: (json['h'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'w': w,
        'h': h,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NormalizedRectModel &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          w == other.w &&
          h == other.h;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ w.hashCode ^ h.hashCode;
}
