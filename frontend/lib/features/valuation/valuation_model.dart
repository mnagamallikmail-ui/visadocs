class ValuationRequest {
  final String id;
  final String clientName;
  final String propertyType;
  final String? customPropertyType;
  final String purpose;
  final DateTime submissionDate;
  final String status; // 'PENDING' | 'IN_PROGRESS' | 'COMPLETED'
  final Map<String, String> uploadedDocs; // documentCategory -> filename

  ValuationRequest({
    required this.id,
    required this.clientName,
    required this.propertyType,
    this.customPropertyType,
    required this.purpose,
    required this.submissionDate,
    required this.status,
    required this.uploadedDocs,
  });

  ValuationRequest copyWith({
    String? id,
    String? clientName,
    String? propertyType,
    String? customPropertyType,
    String? purpose,
    DateTime? submissionDate,
    String? status,
    Map<String, String>? uploadedDocs,
  }) {
    return ValuationRequest(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      propertyType: propertyType ?? this.propertyType,
      customPropertyType: customPropertyType ?? this.customPropertyType,
      purpose: purpose ?? this.purpose,
      submissionDate: submissionDate ?? this.submissionDate,
      status: status ?? this.status,
      uploadedDocs: uploadedDocs ?? this.uploadedDocs,
    );
  }
}
