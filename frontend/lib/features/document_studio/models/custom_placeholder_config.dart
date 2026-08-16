/// Supported input field types for intake questionnaire generation.
class PlaceholderFieldTypes {
  PlaceholderFieldTypes._();

  static const String text = 'TEXT';
  static const String number = 'NUMBER';
  static const String date = 'DATE';
  static const String dropdown = 'DROPDOWN';
  static const String boolean = 'BOOLEAN';
  static const String image = 'IMAGE';

  static const List<String> all = [
    text,
    number,
    date,
    dropdown,
    boolean,
    image,
  ];
}

/// Strongly typed configuration model for customized placeholder questions and validation rules.
class CustomPlaceholderConfig {
  final String label;
  final String? helpText;
  final String fieldType;
  final bool isRequired;
  final String? sectionGroup;

  const CustomPlaceholderConfig({
    required this.label,
    this.helpText,
    this.fieldType = PlaceholderFieldTypes.text,
    this.isRequired = false,
    this.sectionGroup,
  });

  factory CustomPlaceholderConfig.fromJson(Map<String, dynamic> json) {
    return CustomPlaceholderConfig(
      label: json['label'] as String? ?? '',
      helpText: json['helpText'] as String?,
      fieldType: json['fieldType'] as String? ?? PlaceholderFieldTypes.text,
      isRequired: json['isRequired'] as bool? ?? false,
      sectionGroup: json['sectionGroup'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        if (helpText != null && helpText!.trim().isNotEmpty) 'helpText': helpText!.trim(),
        'fieldType': fieldType,
        'isRequired': isRequired,
        if (sectionGroup != null && sectionGroup!.trim().isNotEmpty) 'sectionGroup': sectionGroup!.trim(),
      };

  CustomPlaceholderConfig copyWith({
    String? label,
    String? helpText,
    String? fieldType,
    bool? isRequired,
    String? sectionGroup,
  }) {
    return CustomPlaceholderConfig(
      label: label ?? this.label,
      helpText: helpText ?? this.helpText,
      fieldType: fieldType ?? this.fieldType,
      isRequired: isRequired ?? this.isRequired,
      sectionGroup: sectionGroup ?? this.sectionGroup,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomPlaceholderConfig &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          helpText == other.helpText &&
          fieldType == other.fieldType &&
          isRequired == other.isRequired &&
          sectionGroup == other.sectionGroup;

  @override
  int get hashCode =>
      label.hashCode ^
      (helpText?.hashCode ?? 0) ^
      fieldType.hashCode ^
      isRequired.hashCode ^
      (sectionGroup?.hashCode ?? 0);

  @override
  String toString() {
    return 'CustomPlaceholderConfig(label: $label, fieldType: $fieldType, isRequired: $isRequired, helpText: $helpText, sectionGroup: $sectionGroup)';
  }
}
