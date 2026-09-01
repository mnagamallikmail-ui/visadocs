class ValuationDataModel {
  int? id;
  int orderId;
  double totalLandValue;
  double totalBuildingValue;
  double totalReplacementCost;
  double totalDepreciationAmount;
  double totalSalvageValue;
  double fairValue;
  double realizablePercentage;
  double realizableValue;
  double distressSalePercentage;
  double distressSaleValue;
  double defaultSalvagePercentage;
  double governmentValue;
  double insurableValue;
  String valuationStatus;
  int currentVersion;

  ValuationDataModel({
    this.id,
    required this.orderId,
    this.totalLandValue = 0,
    this.totalBuildingValue = 0,
    this.totalReplacementCost = 0,
    this.totalDepreciationAmount = 0,
    this.totalSalvageValue = 0,
    this.fairValue = 0,
    this.realizablePercentage = 85.0,
    this.realizableValue = 0,
    this.distressSalePercentage = 75.0,
    this.distressSaleValue = 0,
    this.defaultSalvagePercentage = 10.0,
    this.governmentValue = 0,
    this.insurableValue = 0,
    this.valuationStatus = 'DRAFT',
    this.currentVersion = 1,
  });

  factory ValuationDataModel.fromJson(Map<String, dynamic> json) {
    return ValuationDataModel(
      id: json['id'] as int?,
      orderId: (json['orderId'] ?? 0) as int,
      totalLandValue: (json['totalLandValue'] as num?)?.toDouble() ?? 0,
      totalBuildingValue: (json['totalBuildingValue'] as num?)?.toDouble() ?? 0,
      totalReplacementCost: (json['totalReplacementCost'] as num?)?.toDouble() ?? 0,
      totalDepreciationAmount: (json['totalDepreciationAmount'] as num?)?.toDouble() ?? 0,
      totalSalvageValue: (json['totalSalvageValue'] as num?)?.toDouble() ?? 0,
      fairValue: (json['fairValue'] as num?)?.toDouble() ?? 0,
      realizablePercentage: (json['realizablePercentage'] as num?)?.toDouble() ?? 85.0,
      realizableValue: (json['realizableValue'] as num?)?.toDouble() ?? 0,
      distressSalePercentage: (json['distressSalePercentage'] as num?)?.toDouble() ?? 75.0,
      distressSaleValue: (json['distressSaleValue'] as num?)?.toDouble() ?? 0,
      defaultSalvagePercentage: (json['defaultSalvagePercentage'] as num?)?.toDouble() ?? 10.0,
      governmentValue: (json['governmentValue'] as num?)?.toDouble() ?? 0,
      insurableValue: (json['insurableValue'] as num?)?.toDouble() ?? (json['totalReplacementCost'] as num?)?.toDouble() ?? 0,
      valuationStatus: json['valuationStatus']?.toString() ?? 'DRAFT',
      currentVersion: (json['currentVersion'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'totalLandValue': totalLandValue,
    'totalBuildingValue': totalBuildingValue,
    'totalReplacementCost': totalReplacementCost,
    'totalDepreciationAmount': totalDepreciationAmount,
    'totalSalvageValue': totalSalvageValue,
    'fairValue': fairValue,
    'realizablePercentage': realizablePercentage,
    'realizableValue': realizableValue,
    'distressSalePercentage': distressSalePercentage,
    'distressSaleValue': distressSaleValue,
    'defaultSalvagePercentage': defaultSalvagePercentage,
    'governmentValue': governmentValue,
    'insurableValue': insurableValue,
    'valuationStatus': valuationStatus,
    'currentVersion': currentVersion,
  };
}

class ValuationLandItemModel {
  int? id;
  int? orderId;
  String description;
  String surveyNo;
  double enteredArea;
  String enteredUnit;
  double standardAreaSqft;
  double rate;
  double value;
  int sortOrder;

  ValuationLandItemModel({
    this.id,
    this.orderId,
    this.description = '',
    this.surveyNo = '',
    this.enteredArea = 0,
    this.enteredUnit = 'Sq.Ft',
    this.standardAreaSqft = 0,
    this.rate = 0,
    this.value = 0,
    this.sortOrder = 0,
  });

  factory ValuationLandItemModel.fromJson(Map<String, dynamic> json) {
    return ValuationLandItemModel(
      id: json['id'] as int?,
      orderId: json['orderId'] as int?,
      description: json['description']?.toString() ?? '',
      surveyNo: json['surveyNo']?.toString() ?? '',
      enteredArea: (json['enteredArea'] as num?)?.toDouble() ?? 0,
      enteredUnit: json['enteredUnit']?.toString() ?? 'Sq.Ft',
      standardAreaSqft: (json['standardAreaSqft'] as num?)?.toDouble() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      value: (json['value'] as num?)?.toDouble() ?? 0,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'description': description,
    'surveyNo': surveyNo,
    'enteredArea': enteredArea,
    'enteredUnit': enteredUnit,
    'standardAreaSqft': standardAreaSqft,
    'rate': rate,
    'value': value,
    'sortOrder': sortOrder,
  };
}

class ValuationBuildingItemModel {
  int? id;
  int? orderId;
  String structureType;
  String buildingType;
  String description;
  double enteredArea;
  String enteredUnit;
  double standardAreaSqft;
  double replacementRate;
  double replacementCost;
  double buildingAge;
  int buildingUsefulLife;
  double salvagePercentage;
  double depreciationPercentage;
  double depreciationAmount;
  double buildingValue;
  int sortOrder;

  ValuationBuildingItemModel({
    this.id,
    this.orderId,
    this.structureType = 'Ground Floor',
    this.buildingType = 'RCC Residential',
    this.description = '',
    this.enteredArea = 0,
    this.enteredUnit = 'Sq.Ft',
    this.standardAreaSqft = 0,
    this.replacementRate = 0,
    this.replacementCost = 0,
    this.buildingAge = 0,
    this.buildingUsefulLife = 60,
    this.salvagePercentage = 10.0,
    this.depreciationPercentage = 0,
    this.depreciationAmount = 0,
    this.buildingValue = 0,
    this.sortOrder = 0,
  });

  factory ValuationBuildingItemModel.fromJson(Map<String, dynamic> json) {
    return ValuationBuildingItemModel(
      id: json['id'] as int?,
      orderId: json['orderId'] as int?,
      structureType: json['structureType']?.toString() ?? 'Ground Floor',
      buildingType: json['buildingType']?.toString() ?? 'RCC Residential',
      description: json['description']?.toString() ?? '',
      enteredArea: (json['enteredArea'] as num?)?.toDouble() ?? 0,
      enteredUnit: json['enteredUnit']?.toString() ?? 'Sq.Ft',
      standardAreaSqft: (json['standardAreaSqft'] as num?)?.toDouble() ?? 0,
      replacementRate: (json['replacementRate'] as num?)?.toDouble() ?? 0,
      replacementCost: (json['replacementCost'] as num?)?.toDouble() ?? 0,
      buildingAge: (json['buildingAge'] as num?)?.toDouble() ?? 0,
      buildingUsefulLife: (json['buildingUsefulLife'] as num?)?.toInt() ?? 60,
      salvagePercentage: (json['salvagePercentage'] as num?)?.toDouble() ?? 10.0,
      depreciationPercentage: (json['depreciationPercentage'] as num?)?.toDouble() ?? 0,
      depreciationAmount: (json['depreciationAmount'] as num?)?.toDouble() ?? 0,
      buildingValue: (json['buildingValue'] as num?)?.toDouble() ?? 0,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'structureType': structureType,
    'buildingType': buildingType,
    'description': description,
    'enteredArea': enteredArea,
    'enteredUnit': enteredUnit,
    'standardAreaSqft': standardAreaSqft,
    'replacementRate': replacementRate,
    'replacementCost': replacementCost,
    'buildingAge': buildingAge,
    'buildingUsefulLife': buildingUsefulLife,
    'salvagePercentage': salvagePercentage,
    'depreciationPercentage': depreciationPercentage,
    'depreciationAmount': depreciationAmount,
    'buildingValue': buildingValue,
    'sortOrder': sortOrder,
  };
}

class ValuationComparableSaleModel {
  int? id;
  int? orderId;
  String location;
  String surveyNo;
  String extent;
  double enteredArea;
  String enteredUnit;
  double standardAreaSqft;
  double rate;
  double saleValue;
  String transactionDate;
  String source;
  String remarks;
  int sortOrder;

  ValuationComparableSaleModel({
    this.id,
    this.orderId,
    this.location = '',
    this.surveyNo = '',
    this.extent = '',
    this.enteredArea = 0,
    this.enteredUnit = 'Sq.Ft',
    this.standardAreaSqft = 0,
    this.rate = 0,
    this.saleValue = 0,
    this.transactionDate = '',
    this.source = '',
    this.remarks = '',
    this.sortOrder = 0,
  });

  factory ValuationComparableSaleModel.fromJson(Map<String, dynamic> json) {
    return ValuationComparableSaleModel(
      id: json['id'] as int?,
      orderId: json['orderId'] as int?,
      location: json['location']?.toString() ?? '',
      surveyNo: json['surveyNo']?.toString() ?? '',
      extent: json['extent']?.toString() ?? '',
      enteredArea: (json['enteredArea'] as num?)?.toDouble() ?? 0,
      enteredUnit: json['enteredUnit']?.toString() ?? 'Sq.Ft',
      standardAreaSqft: (json['standardAreaSqft'] as num?)?.toDouble() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      saleValue: (json['saleValue'] as num?)?.toDouble() ?? 0,
      transactionDate: json['transactionDate']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'location': location,
    'surveyNo': surveyNo,
    'extent': extent,
    'enteredArea': enteredArea,
    'enteredUnit': enteredUnit,
    'standardAreaSqft': standardAreaSqft,
    'rate': rate,
    'saleValue': saleValue,
    'transactionDate': transactionDate,
    'source': source,
    'remarks': remarks,
    'sortOrder': sortOrder,
  };
}

class ValuationBundleModel {
  ValuationDataModel valuationData;
  List<ValuationLandItemModel> landItems;
  List<ValuationBuildingItemModel> buildingItems;
  List<ValuationComparableSaleModel> comparableSales;
  Map<String, String> placeholders;
  bool isLocked;

  ValuationBundleModel({
    required this.valuationData,
    required this.landItems,
    required this.buildingItems,
    required this.comparableSales,
    required this.placeholders,
    this.isLocked = false,
  });

  factory ValuationBundleModel.fromJson(Map<String, dynamic> json) {
    return ValuationBundleModel(
      valuationData: ValuationDataModel.fromJson(json['valuationData'] as Map<String, dynamic>? ?? {}),
      landItems: (json['landItems'] as List<dynamic>?)
              ?.map((e) => ValuationLandItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      buildingItems: (json['buildingItems'] as List<dynamic>?)
              ?.map((e) => ValuationBuildingItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      comparableSales: (json['comparableSales'] as List<dynamic>?)
              ?.map((e) => ValuationComparableSaleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      placeholders: (json['placeholders'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v?.toString() ?? '')) ??
          {},
      isLocked: json['locked'] == true || json['isLocked'] == true,
    );
  }
}
