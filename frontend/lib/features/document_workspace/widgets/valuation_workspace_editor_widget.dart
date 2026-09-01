import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/app_components.dart';
import '../../../utils/indian_currency_to_words.dart';
import '../../../utils/indian_number_formatter.dart';
import '../models/valuation_models.dart';
import '../services/valuation_calculator.dart';

class ValuationWorkspaceEditorWidget extends StatefulWidget {
  final int orderId;
  final bool readOnly;
  final Function(Map<String, String> updatedPlaceholders)? onValuationChanged;

  const ValuationWorkspaceEditorWidget({
    super.key,
    required this.orderId,
    this.readOnly = false,
    this.onValuationChanged,
  });

  @override
  State<ValuationWorkspaceEditorWidget> createState() => _ValuationWorkspaceEditorWidgetState();
}

class _ValuationWorkspaceEditorWidgetState extends State<ValuationWorkspaceEditorWidget> {
  final _api = ApiService();
  bool _loading = true;
  bool _saving = false;
  ValuationDataModel? _data;
  List<ValuationLandItemModel> _landItems = [];
  List<ValuationBuildingItemModel> _buildingItems = [];
  List<ValuationComparableSaleModel> _comparables = [];
  List<dynamic> _buildingTypeMasters = [];
  bool _isLocked = false;

  final List<String> _landUnits = ['Sq.Ft', 'Sq.M', 'Sq.Yd', 'Acres', 'Cents', 'Grounds', 'Hectares'];
  final List<String> _structureTypes = [
    'Basement', 'Stilt', 'Ground Floor', 'First Floor', 'Second Floor',
    'Third Floor', 'Fourth Floor', 'Fifth Floor', 'Terrace Structure',
    'Servant Quarters', 'Watchman Cabin', 'Security Cabin', 'Compound Wall',
    'Parking Block', 'Warehouse Block', 'Office Block', 'Other Structures'
  ];

  @override
  void initState() {
    super.initState();
    _loadValuationData();
    _loadBuildingTypes();
  }

  Future<void> _loadBuildingTypes() async {
    try {
      final res = await _api.dio.get('/api/v1/building-types');
      if (res.data is List) {
        setState(() => _buildingTypeMasters = res.data as List<dynamic>);
      }
    } catch (_) {}
  }

  Future<void> _loadValuationData() async {
    setState(() => _loading = true);
    try {
      final res = await _api.dio.get('/api/v1/orders/${widget.orderId}/valuation');
      final bundle = ValuationBundleModel.fromJson(res.data as Map<String, dynamic>);
      setState(() {
        _data = bundle.valuationData;
        _landItems = bundle.landItems;
        _buildingItems = bundle.buildingItems;
        _comparables = bundle.comparableSales;
        _isLocked = bundle.isLocked;

        // Ensure at least 1 parcel and 1 building exist
        if (_landItems.isEmpty) {
          _landItems.add(ValuationLandItemModel(description: 'Main Parcel', enteredArea: 2400, enteredUnit: 'Sq.Ft', rate: 2500));
        }
        if (_buildingItems.isEmpty) {
          _buildingItems.add(ValuationBuildingItemModel(structureType: 'Ground Floor', buildingType: 'RCC Residential', enteredArea: 1500, replacementRate: 2000, buildingAge: 5, buildingUsefulLife: 60));
        }
        _recalculateAll(notifyParent: true);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.brandRedDark,
        content: Text('Failed to load valuation: ${ApiService.getErrorMessage(e)}'),
      ));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _recalculateAll({bool notifyParent = true}) {
    if (_data == null) return;
    ValuationCalculator.recalculateSummary(_data!, _landItems, _buildingItems);
    setState(() {});

    if (notifyParent && widget.onValuationChanged != null) {
      final placeholders = ValuationCalculator.generatePlaceholders(
        orderInfo: {'id': widget.orderId},
        data: _data!,
        landItems: _landItems,
        buildingItems: _buildingItems,
        comparables: _comparables,
      );
      widget.onValuationChanged!(placeholders);
    }
  }

  Future<void> _saveValuation() async {
    if (_data == null) return;
    setState(() => _saving = true);
    try {
      final payload = {
        'realizablePercentage': _data!.realizablePercentage,
        'distressSalePercentage': _data!.distressSalePercentage,
        'defaultSalvagePercentage': _data!.defaultSalvagePercentage,
        'governmentValue': _data!.governmentValue,
        'landItems': _landItems.map((e) => e.toJson()).toList(),
        'buildingItems': _buildingItems.map((e) => e.toJson()).toList(),
        'comparableSales': _comparables.map((e) => e.toJson()).toList(),
        'reason': 'Saved from workspace editor',
      };

      final res = await _api.dio.post('/api/v1/orders/${widget.orderId}/valuation', data: payload);
      final bundle = ValuationBundleModel.fromJson(res.data as Map<String, dynamic>);
      setState(() {
        _data = bundle.valuationData;
        _isLocked = bundle.isLocked;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Valuation data synchronized and saved successfully!'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.brandRedDark,
        content: Text('Save failed: ${ApiService.getErrorMessage(e)}'),
      ));
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _finalizeValuation() async {
    setState(() => _saving = true);
    try {
      await _saveValuation();
      final res = await _api.dio.post('/api/v1/orders/${widget.orderId}/valuation/finalize', data: {'versionNotes': 'Report finalized by valuer'});
      final bundle = ValuationBundleModel.fromJson(res.data as Map<String, dynamic>);
      setState(() {
        _data = bundle.valuationData;
        _isLocked = bundle.isLocked;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Valuation finalized and immutable snapshot archived!'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.brandRedDark,
        content: Text('Finalization failed: ${ApiService.getErrorMessage(e)}'),
      ));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isReadOnly = widget.readOnly || _isLocked;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 26),
                      const SizedBox(width: 8),
                      Text('Dynamic Valuation Engine', style: AppTypography.heading3().copyWith(color: AppColors.ink)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Single source of truth for multi-parcel land, building area breakup, and certificates.', style: AppTypography.bodySm().copyWith(color: AppColors.slate)),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isLocked ? AppColors.brandRedDark.withValues(alpha: 0.1) : AppColors.tealLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(_isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 14, color: _isLocked ? AppColors.brandRedDark : AppColors.deepTeal),
                        const SizedBox(width: 6),
                        Text(_isLocked ? 'STATUS: LOCKED' : 'STATUS: ${_data?.valuationStatus ?? 'DRAFT'} (v${_data?.currentVersion ?? 1})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _isLocked ? AppColors.brandRedDark : AppColors.deepTeal)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!isReadOnly) ...[
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _saveValuation,
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: Text(_saving ? 'Saving...' : 'Save Values'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _finalizeValuation,
                      style: AppComponents.primaryButtonStyle(),
                      icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                      label: const Text('Finalize & Freeze', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 1. LAND VALUATION SECTION
          _buildSectionHeader('1. Land Parcels Valuation', Icons.landscape_rounded, onAdd: isReadOnly ? null : () {
            setState(() {
              _landItems.add(ValuationLandItemModel(description: 'Parcel #${_landItems.length + 1}', enteredArea: 1000, enteredUnit: 'Sq.Ft', rate: 2000));
              _recalculateAll();
            });
          }),
          const SizedBox(height: 12),
          _buildLandTable(isReadOnly),
          const SizedBox(height: 24),

          // 2. BUILDING VALUATION SECTION
          _buildSectionHeader('2. Building Structures & Area Breakup', Icons.apartment_rounded, onAdd: isReadOnly ? null : () {
            setState(() {
              _buildingItems.add(ValuationBuildingItemModel(description: 'Commercial Building', buildingType: 'RCC Commercial', enteredArea: 1000, replacementRate: 2000, buildingAge: 5, buildingUsefulLife: 60));
              _recalculateAll();
            });
          }),
          const SizedBox(height: 12),
          _buildBuildingTable(isReadOnly),
          const SizedBox(height: 24),

          // 3. COMPARABLE SALES SECTION
          _buildSectionHeader('3. Market Comparable Sales (Optional)', Icons.store_mall_directory_rounded, onAdd: isReadOnly ? null : () {
            setState(() {
              _comparables.add(ValuationComparableSaleModel(location: 'Locality', enteredArea: 2400, rate: 2400, saleValue: 5760000));
            });
          }),
          const SizedBox(height: 12),
          _buildComparablesTable(isReadOnly),
          const SizedBox(height: 24),

          // 4. SUMMARY & CERTIFICATE OUTPUTS CARD
          _buildSummaryCard(isReadOnly),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {VoidCallback? onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(title, style: AppTypography.heading4().copyWith(color: AppColors.ink)),
          ],
        ),
        if (onAdd != null)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Row'),
          ),
      ],
    );
  }

  Widget _buildLandTable(bool isReadOnly) {
    return Container(
      decoration: AppComponents.cardBase(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 44, child: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(flex: 4, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Standard Sq.Ft', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Rate (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Amount (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 40),
              ],
            ),
          ),
          ..._landItems.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairlineSoft))),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${idx + 1}',
                      style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(flex: 4, child: TextFormField(
                    initialValue: item.description.isNotEmpty ? item.description : (item.surveyNo.isNotEmpty ? 'Plot (Sy.No.${item.surveyNo})' : ''),
                    enabled: !isReadOnly,
                    decoration: const InputDecoration(hintText: 'e.g. Commercial Plot (Sy.No.42/A)', isDense: true, border: OutlineInputBorder()),
                    onChanged: (val) => item.description = val,
                  )),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: TextFormField(
                    initialValue: item.enteredArea.toString(),
                    enabled: !isReadOnly,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    onChanged: (val) {
                      item.enteredArea = double.tryParse(val) ?? 0;
                      _recalculateAll();
                    },
                  )),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: DropdownButtonFormField<String>(
                    value: _landUnits.contains(item.enteredUnit) ? item.enteredUnit : 'Sq.Ft',
                    items: _landUnits.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: isReadOnly ? null : (val) {
                      if (val != null) {
                        item.enteredUnit = val;
                        _recalculateAll();
                      }
                    },
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  )),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: Text(IndianNumberFormatter.format(item.standardAreaSqft, includeDecimals: true), style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: TextFormField(
                    initialValue: item.rate.toString(),
                    enabled: !isReadOnly,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    onChanged: (val) {
                      item.rate = double.tryParse(val) ?? 0;
                      _recalculateAll();
                    },
                  )),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: Text(IndianNumberFormatter.format(item.value), style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary))),
                  SizedBox(
                    width: 40,
                    child: isReadOnly || _landItems.length <= 1
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.brandRedDark),
                            onPressed: () {
                              setState(() {
                                _landItems.removeAt(idx);
                                _recalculateAll();
                              });
                            },
                          ),
                  ),
                ],
              ),
            );
          }),
          // Total Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.vertical(bottom: Radius.circular(10))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL LAND VALUE (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('INR ${IndianNumberFormatter.format(_data?.totalLandValue ?? 0)}', style: GoogleFonts.firaCode(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingTable(bool isReadOnly) {
    return Container(
      decoration: AppComponents.cardBase(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Building Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Area (Sq.Ft)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Repl Cost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text('Age', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text('Life', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text('Depr %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Depr Amt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Building Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 40),
              ],
            ),
          ),
          ..._buildingItems.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairlineSoft))),
              child: Row(
                children: [
                  Expanded(flex: 3, child: TextFormField(
                    initialValue: item.description.isNotEmpty ? item.description : (item.structureType != 'Ground Floor' && item.structureType.isNotEmpty ? item.structureType : 'Commercial Building'),
                    enabled: !isReadOnly,
                    decoration: const InputDecoration(hintText: 'e.g. Commercial Office Building', isDense: true, border: OutlineInputBorder()),
                    onChanged: (val) => item.description = val,
                  )),
                  const SizedBox(width: 6),
                  Expanded(flex: 2, child: DropdownButtonFormField<String>(
                    value: item.buildingType,
                    items: (_buildingTypeMasters.isNotEmpty
                            ? _buildingTypeMasters.map((b) => b['name'].toString()).toList()
                            : ['RCC Residential', 'RCC Commercial', 'Industrial Building', 'Warehouse', 'Steel Shed', 'PEB Structure'])
                        .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 11)))).toList(),
                    onChanged: isReadOnly ? null : (val) {
                      if (val != null) {
                        item.buildingType = val;
                        // Auto-populate useful life from master
                        final master = _buildingTypeMasters.firstWhere((m) => m['name'] == val, orElse: () => null);
                        if (master != null && master['defaultUsefulLife'] != null) {
                          item.buildingUsefulLife = master['defaultUsefulLife'] as int;
                        }
                        _recalculateAll();
                      }
                    },
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  )),
                  const SizedBox(width: 6),
                  Expanded(flex: 2, child: TextFormField(
                    initialValue: item.enteredArea.toString(),
                    enabled: !isReadOnly,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    onChanged: (val) {
                      item.enteredArea = double.tryParse(val) ?? 0;
                      _recalculateAll();
                    },
                  )),
                  const SizedBox(width: 6),
                  Expanded(flex: 2, child: TextFormField(
                    initialValue: item.replacementRate.toString(),
                    enabled: !isReadOnly,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    onChanged: (val) {
                      item.replacementRate = double.tryParse(val) ?? 0;
                      _recalculateAll();
                    },
                  )),
                  const SizedBox(width: 6),
                  Expanded(flex: 2, child: Text(IndianNumberFormatter.format(item.replacementCost), style: GoogleFonts.firaCode(fontSize: 11))),
                  const SizedBox(width: 6),
                  Expanded(flex: 1, child: TextFormField(
                    initialValue: item.buildingAge.toString(),
                    enabled: !isReadOnly,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    onChanged: (val) {
                      item.buildingAge = double.tryParse(val) ?? 0;
                      _recalculateAll();
                    },
                  )),
                  const SizedBox(width: 6),
                  Expanded(flex: 1, child: TextFormField(
                    initialValue: item.buildingUsefulLife.toString(),
                    enabled: !isReadOnly,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    onChanged: (val) {
                      item.buildingUsefulLife = int.tryParse(val) ?? 60;
                      _recalculateAll();
                    },
                  )),
                  const SizedBox(width: 6),
                  Expanded(flex: 1, child: Text('${item.depreciationPercentage.toStringAsFixed(1)}%', style: GoogleFonts.firaCode(fontSize: 11))),
                  const SizedBox(width: 6),
                  Expanded(flex: 2, child: Text(IndianNumberFormatter.format(item.depreciationAmount), style: GoogleFonts.firaCode(fontSize: 11, color: AppColors.brandRedDark))),
                  const SizedBox(width: 6),
                  Expanded(flex: 2, child: Text(IndianNumberFormatter.format(item.buildingValue), style: GoogleFonts.firaCode(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary))),
                  SizedBox(
                    width: 40,
                    child: isReadOnly || _buildingItems.length <= 1
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.brandRedDark),
                            onPressed: () {
                              setState(() {
                                _buildingItems.removeAt(idx);
                                _recalculateAll();
                              });
                            },
                          ),
                  ),
                ],
              ),
            );
          }),
          // Total Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.vertical(bottom: Radius.circular(10))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL BUILDING VALUE (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('INR ${IndianNumberFormatter.format(_data?.totalBuildingValue ?? 0)}', style: GoogleFonts.firaCode(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparablesTable(bool isReadOnly) {
    if (_comparables.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: AppComponents.cardBase(),
        child: Center(child: Text('No comparable sales records added.', style: AppTypography.bodySm().copyWith(color: AppColors.slate))),
      );
    }
    return Container(
      decoration: AppComponents.cardBase(),
      child: Column(
        children: _comparables.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(flex: 3, child: TextFormField(
                  initialValue: item.location,
                  enabled: !isReadOnly,
                  decoration: const InputDecoration(labelText: 'Location / Survey No', isDense: true, border: OutlineInputBorder()),
                  onChanged: (val) => item.location = val,
                )),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: TextFormField(
                  initialValue: item.enteredArea.toString(),
                  enabled: !isReadOnly,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Area (Sq.Ft)', isDense: true, border: OutlineInputBorder()),
                  onChanged: (val) {
                    item.enteredArea = double.tryParse(val) ?? 0;
                    item.saleValue = item.enteredArea * item.rate;
                    setState(() {});
                  },
                )),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: TextFormField(
                  initialValue: item.rate.toString(),
                  enabled: !isReadOnly,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rate / Sq.Ft', isDense: true, border: OutlineInputBorder()),
                  onChanged: (val) {
                    item.rate = double.tryParse(val) ?? 0;
                    item.saleValue = item.enteredArea * item.rate;
                    setState(() {});
                  },
                )),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: Text('INR ${IndianNumberFormatter.format(item.saleValue)}', style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold))),
                if (!isReadOnly)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.brandRedDark),
                    onPressed: () {
                      setState(() => _comparables.removeAt(idx));
                    },
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard(bool isReadOnly) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    final insurableVal = data.insurableValue > 0 ? data.insurableValue : data.totalReplacementCost;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.success, size: 22),
              const SizedBox(width: 8),
              Text('Consolidated Valuation Certificate Breakdown', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Total Land Value:', 'INR ${IndianNumberFormatter.format(data.totalLandValue)}', IndianCurrencyToWords.convertToWords(data.totalLandValue)),
          const Divider(height: 20),
          _buildSummaryRow('Total Building Value:', 'INR ${IndianNumberFormatter.format(data.totalBuildingValue)}', IndianCurrencyToWords.convertToWords(data.totalBuildingValue)),
          const Divider(height: 20),
          _buildSummaryRow('Total Fair Market Value:', 'INR ${IndianNumberFormatter.format(data.fairValue)}', IndianCurrencyToWords.convertToWords(data.fairValue), isHighlight: true),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryRow('Realizable Value (${data.realizablePercentage}%):', 'INR ${IndianNumberFormatter.format(data.realizableValue)}', IndianCurrencyToWords.convertToWords(data.realizableValue)),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildSummaryRow('Distress Sale Value (${data.distressSalePercentage}%):', 'INR ${IndianNumberFormatter.format(data.distressSaleValue)}', IndianCurrencyToWords.convertToWords(data.distressSaleValue)),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildSummaryRow('Insurable Value (Total Building Replacement Cost):', 'INR ${IndianNumberFormatter.format(insurableVal)}', IndianCurrencyToWords.convertToWords(insurableVal)),
          const Divider(height: 20),
          // Government / Guideline Value Input & Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: data.governmentValue > 0 ? data.governmentValue.toStringAsFixed(2) : '',
                  enabled: !isReadOnly,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Government / Guideline Value (INR)',
                    hintText: 'Enter statutory or guideline value',
                    isDense: true,
                    border: OutlineInputBorder(),
                    prefixText: 'INR ',
                  ),
                  onChanged: (val) {
                    data.governmentValue = double.tryParse(val) ?? 0;
                    _recalculateAll();
                  },
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: _buildSummaryRow(
                  'Assessed Government Value:',
                  'INR ${IndianNumberFormatter.format(data.governmentValue)}',
                  IndianCurrencyToWords.convertToWords(data.governmentValue),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildSummaryRow(
            'Say Value (Rounded Fair Value):',
            'INR ${IndianNumberFormatter.format(ValuationCalculator.computeSayValue(data.fairValue))}',
            IndianCurrencyToWords.convertToWords(ValuationCalculator.computeSayValue(data.fairValue)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, String words, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600, fontSize: isHighlight ? 15 : 13, color: isHighlight ? AppColors.primary : AppColors.ink)),
            Text(value, style: GoogleFonts.firaCode(fontWeight: FontWeight.bold, fontSize: isHighlight ? 18 : 14, color: isHighlight ? AppColors.primary : AppColors.ink)),
          ],
        ),
        const SizedBox(height: 2),
        Text(words, style: GoogleFonts.merriweather(fontStyle: FontStyle.italic, fontSize: 12, color: AppColors.slate)),
      ],
    );
  }
}
