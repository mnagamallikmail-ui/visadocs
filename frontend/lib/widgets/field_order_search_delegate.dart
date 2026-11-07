import 'package:flutter/material.dart';

class SearchableOrderItem {
  final String referenceNumber;
  final String borrowerName;
  final String propertyAddress;
  final String bankName;
  final String status;

  const SearchableOrderItem({
    required this.referenceNumber,
    required this.borrowerName,
    required this.propertyAddress,
    required this.bankName,
    required this.status,
  });
}

class FieldOrderSearchDelegate extends SearchDelegate<SearchableOrderItem?> {
  final List<SearchableOrderItem> allOrders;

  FieldOrderSearchDelegate({required this.allOrders})
      : super(
          searchFieldLabel: 'Search ref, borrower, bank, address...',
          searchFieldStyle: const TextStyle(fontSize: 14, color: Colors.white),
        );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded, color: Colors.white),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultsList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultsList(context);
  }

  Widget _buildResultsList(BuildContext context) {
    final cleanQuery = query.toLowerCase().trim();
    final matches = allOrders.where((item) {
      return item.referenceNumber.toLowerCase().contains(cleanQuery) ||
          item.borrowerName.toLowerCase().contains(cleanQuery) ||
          item.propertyAddress.toLowerCase().contains(cleanQuery) ||
          item.bankName.toLowerCase().contains(cleanQuery);
    }).toList();

    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? 'Type to search orders' : 'No dossiers found for "$query"',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (ctx, idx) {
        final item = matches[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          elevation: 0,
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.referenceNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status,
                    style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(item.borrowerName, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                Text(item.propertyAddress, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.account_balance_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(item.bankName, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
            onTap: () => close(context, item),
          ),
        );
      },
    );
  }
}

