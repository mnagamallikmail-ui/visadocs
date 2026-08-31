import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_components.dart';

class PlaceholderCatalogScreen extends StatefulWidget {
  const PlaceholderCatalogScreen({super.key});

  @override
  State<PlaceholderCatalogScreen> createState() => _PlaceholderCatalogScreenState();
}

class _PlaceholderCatalogScreenState extends State<PlaceholderCatalogScreen> {
  final _api = ApiService();
  List<dynamic> _allPlaceholders = [];
  List<dynamic> _filteredPlaceholders = [];
  bool _loading = true;
  String _selectedCategory = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'ALL',
    'Property',
    'Land',
    'Building',
    'Valuation',
    'Dynamic Tables',
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() => _loading = true);
    try {
      final res = await _api.dio.get('/api/v1/templates/placeholder-catalog');
      if (res.data is List) {
        setState(() {
          _allPlaceholders = res.data as List<dynamic>;
          _filterCatalog();
        });
      }
    } catch (_) {
      // Fallback local catalog
      _allPlaceholders = _fallbackCatalog();
      _filterCatalog();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterCatalog() {
    setState(() {
      _filteredPlaceholders = _allPlaceholders.where((item) {
        final catMatch = _selectedCategory == 'ALL' ||
            (item['category']?.toString().toUpperCase() == _selectedCategory.toUpperCase());
        final searchMatch = _searchQuery.isEmpty ||
            item['placeholder'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item['sampleValue'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
        return catMatch && searchMatch;
      }).toList();
    });
  }

  List<Map<String, String>> _fallbackCatalog() {
    return [
      {'placeholder': '<<report_no>>', 'description': 'Report Number', 'sampleValue': 'PV-2026-0042', 'category': 'Property', 'usageNotes': 'Auto-assigned'},
      {'placeholder': '<<total_land_value>>', 'description': 'Total Land Value', 'sampleValue': '85,50,000', 'category': 'Land', 'usageNotes': 'Sum of parcels'},
      {'placeholder': '<<total_land_value_words>>', 'description': 'Land Value Words', 'sampleValue': 'Rupees Eighty Five Lakh Fifty Thousand Only', 'category': 'Land', 'usageNotes': 'Banking format'},
      {'placeholder': '<<total_replacement_cost>>', 'description': 'Replacement Cost', 'sampleValue': '1,20,00,000', 'category': 'Building', 'usageNotes': 'Gross reproduction cost'},
      {'placeholder': '<<total_depreciation_amount>>', 'description': 'Depreciation Amount', 'sampleValue': '18,00,000', 'category': 'Building', 'usageNotes': '10% salvage retention'},
      {'placeholder': '<<total_building_value>>', 'description': 'Total Building Value', 'sampleValue': '1,02,00,000', 'category': 'Building', 'usageNotes': 'Depreciated value'},
      {'placeholder': '<<fair_value>>', 'description': 'Fair Market Value', 'sampleValue': '1,87,50,000', 'category': 'Valuation', 'usageNotes': 'Land + Building sum'},
      {'placeholder': '<<fair_value_words>>', 'description': 'Fair Value Words', 'sampleValue': 'Rupees One Crore Eighty Seven Lakh Fifty Thousand Only', 'category': 'Valuation', 'usageNotes': 'Certified wording'},
      {'placeholder': '<<realizable_value>>', 'description': 'Realizable Value', 'sampleValue': '1,59,37,500', 'category': 'Valuation', 'usageNotes': 'Fair Value * 85%'},
      {'placeholder': '<<distress_sale_value>>', 'description': 'Distress Sale Value', 'sampleValue': '1,40,62,500', 'category': 'Valuation', 'usageNotes': 'Fair Value * 75%'},
      {'placeholder': '<<LAND_TABLE>>', 'description': 'Dynamic Land Table', 'sampleValue': 'Generated Table', 'category': 'Dynamic Tables', 'usageNotes': 'Repeating DOCX table'},
      {'placeholder': '<<BUILDING_TABLE>>', 'description': 'Dynamic Building Table', 'sampleValue': 'Generated Table', 'category': 'Dynamic Tables', 'usageNotes': 'Repeating DOCX table'},
      {'placeholder': '<<VALUATION_SUMMARY_TABLE>>', 'description': 'Summary Table', 'sampleValue': 'Generated Table', 'category': 'Dynamic Tables', 'usageNotes': 'Summary breakdown'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text('Template Author Placeholder Catalog', style: AppTypography.heading3().copyWith(color: AppColors.ink)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          _searchQuery = val;
                          _filterCatalog();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search placeholders, descriptions, or sample outputs...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.slate),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _filterCatalog();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surfaceSoft,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                      tooltip: 'Refresh Catalog',
                      onPressed: _loadCatalog,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Category Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : AppColors.ink, fontWeight: FontWeight.bold, fontSize: 13)),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceSoft,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = cat;
                                _filterCatalog();
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPlaceholders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: AppColors.slate),
                            const SizedBox(height: 12),
                            Text('No placeholders found matching your search.', style: AppTypography.bodySm().copyWith(color: AppColors.slate)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _filteredPlaceholders.length,
                        itemBuilder: (context, idx) {
                          final item = _filteredPlaceholders[idx];
                          final placeholder = item['placeholder']?.toString() ?? '';
                          final desc = item['description']?.toString() ?? '';
                          final sample = item['sampleValue']?.toString() ?? '';
                          final category = item['category']?.toString() ?? 'General';
                          final notes = item['usageNotes']?.toString() ?? '';
                          final isDynamicTable = category.contains('Dynamic Tables');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: AppComponents.cardBase(),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDynamicTable ? AppColors.featureOchre.withValues(alpha: 0.1) : AppColors.tealLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isDynamicTable ? Icons.table_chart_rounded : Icons.code_rounded,
                                    color: isDynamicTable ? AppColors.featureOchre : AppColors.deepTeal,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          SelectableText(
                                            placeholder,
                                            style: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceSoft,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(category, style: const TextStyle(fontSize: 10, color: AppColors.slate, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(desc, style: AppTypography.bodySm().copyWith(color: AppColors.ink)),
                                      if (notes.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text('Note: $notes', style: AppTypography.caption(color: AppColors.slate)),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceSoft,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.hairlineSoft),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('SAMPLE OUTPUT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate)),
                                        const SizedBox(height: 4),
                                        SelectableText(
                                          sample,
                                          style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                                  tooltip: 'Copy Placeholder',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: placeholder));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppColors.success,
                                        content: Text('Copied $placeholder to clipboard!'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
