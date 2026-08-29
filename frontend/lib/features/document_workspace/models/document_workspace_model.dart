import '../../document_studio/models/visual_preview_model.dart';

enum WorkspaceViewMode {
  overlayEdit,
  compiledPreview,
}

/// Root data model for Document Workspace
class DocumentWorkspaceModel {
  final int orderId;
  final String status;
  final String reportNumber;
  final VisualPreviewModel visualPreview;
  final Map<String, String> values;
  final bool readOnly;

  const DocumentWorkspaceModel({
    required this.orderId,
    required this.status,
    required this.reportNumber,
    required this.visualPreview,
    required this.values,
    this.readOnly = false,
  });

  factory DocumentWorkspaceModel.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] as Map<String, dynamic>? ?? {};
    final Map<String, String> stringValues = {};
    rawValues.forEach((key, val) {
      if (val != null) {
        stringValues[key.toUpperCase()] = val.toString();
      }
    });

    return DocumentWorkspaceModel(
      orderId: json['orderId'] as int? ?? 0,
      status: json['status'] as String? ?? 'ASSIGNED',
      reportNumber: json['reportNumber'] as String? ?? 'PV-REPORT',
      visualPreview: json['visualPreview'] != null
          ? VisualPreviewModel.fromJson(json['visualPreview'] as Map<String, dynamic>)
          : const VisualPreviewModel(
              templateId: 0,
              totalPages: 0,
              pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
              pages: [],
            ),
      values: stringValues,
      readOnly: json['readOnly'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'status': status,
        'reportNumber': reportNumber,
        'visualPreview': visualPreview.toJson(),
        'values': values,
        'readOnly': readOnly,
      };

  DocumentWorkspaceModel copyWith({
    int? orderId,
    String? status,
    String? reportNumber,
    VisualPreviewModel? visualPreview,
    Map<String, String>? values,
    bool? readOnly,
  }) {
    return DocumentWorkspaceModel(
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      reportNumber: reportNumber ?? this.reportNumber,
      visualPreview: visualPreview ?? this.visualPreview,
      values: values ?? this.values,
      readOnly: readOnly ?? this.readOnly,
    );
  }
}
