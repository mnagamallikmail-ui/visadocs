import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../theme/design_system.dart';
import 'valuation_model.dart';
import 'valuation_repository.dart';

class ValuationDirectoryWidget extends StatefulWidget {
  final String userRole;

  const ValuationDirectoryWidget({super.key, required this.userRole});

  @override
  State<ValuationDirectoryWidget> createState() => _ValuationDirectoryWidgetState();
}

class _ValuationDirectoryWidgetState extends State<ValuationDirectoryWidget> {
  ValuationRequest? _selectedRequest;

  Future<void> _openDocument(String filename) async {
    // Generate a temporary mock blob or file link for demonstration
    final Uri url = Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<ValuationRepository>(context);
    final list = repo.requests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Project Submissions Directory",
          style: DesignSystem.h2(color: DesignSystem.primary),
        ),
        const SizedBox(height: 8),
        Text(
          "Manage and verify high-priority commercial property valuation requests. Click on any row to view full details.",
          style: DesignSystem.body(color: DesignSystem.textSecondary),
        ),
        const SizedBox(height: 25),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Master Queue Table
              Expanded(
                flex: 3,
                child: Container(
                  decoration: DesignSystem.cardDecoration,
                  clipBehavior: Clip.antiAlias,
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 600,
                    columns: const [
                      DataColumn2(label: Text('Request ID'), size: ColumnSize.S),
                      DataColumn2(label: Text('Client Name'), size: ColumnSize.M),
                      DataColumn2(label: Text('Property Asset'), size: ColumnSize.M),
                      DataColumn2(label: Text('Purpose'), size: ColumnSize.M),
                      DataColumn2(label: Text('Submission Date'), size: ColumnSize.S),
                      DataColumn2(label: Text('Status Badge'), size: ColumnSize.S),
                    ],
                    rows: list.map((req) {
                      final isSelected = _selectedRequest?.id == req.id;
                      return DataRow2(
                        selected: isSelected,
                        onSelectChanged: (val) {
                          setState(() {
                            _selectedRequest = req;
                          });
                        },
                        cells: [
                          DataCell(Text(req.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(req.clientName)),
                          DataCell(Text(req.propertyType == "Others" && req.customPropertyType != null
                              ? "Others (${req.customPropertyType})"
                              : req.propertyType)),
                          DataCell(Text(req.purpose)),
                          DataCell(Text(DateFormat('dd MMM yyyy').format(req.submissionDate))),
                          DataCell(_buildStatusBadge(req.status)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Split-Pane Detail Panel
              if (_selectedRequest != null) ...[
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: DesignSystem.cardDecoration,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedRequest!.id,
                              style: DesignSystem.h3(color: DesignSystem.primary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedRequest = null;
                                });
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 15),
                        _buildDetailRow("Client Name", _selectedRequest!.clientName),
                        _buildDetailRow("Property Type", _selectedRequest!.propertyType),
                        if (_selectedRequest!.customPropertyType != null)
                          _buildDetailRow("Custom Detail", _selectedRequest!.customPropertyType!),
                        _buildDetailRow("Purpose", _selectedRequest!.purpose),
                        _buildDetailRow("Submission Date", DateFormat('yyyy-MM-dd HH:mm').format(_selectedRequest!.submissionDate)),
                        const SizedBox(height: 15),
                        Text(
                          "Uploaded Documents",
                          style: DesignSystem.body(fontWeight: FontWeight.bold, color: DesignSystem.primary),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _selectedRequest!.uploadedDocs.isEmpty
                              ? Text(
                                  "No documents uploaded.",
                                  style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13),
                                )
                              : ListView(
                                  children: _selectedRequest!.uploadedDocs.entries.map((entry) {
                                    return Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(color: DesignSystem.border),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        dense: true,
                                        leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                                        title: Text(
                                          entry.key,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          entry.value,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.open_in_new, size: 18),
                                          onPressed: () => _openDocument(entry.value),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 15),
                        if (widget.userRole != 'CLIENT') ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    repo.updateRequestStatus(_selectedRequest!.id, 'IN_PROGRESS');
                                    setState(() {
                                      _selectedRequest = _selectedRequest!.copyWith(status: 'IN_PROGRESS');
                                    });
                                  },
                                  child: const Text("Start Review"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    repo.updateRequestStatus(_selectedRequest!.id, 'COMPLETED');
                                    setState(() {
                                      _selectedRequest = _selectedRequest!.copyWith(status: 'COMPLETED');
                                    });
                                  },
                                  style: DesignSystem.primaryButton,
                                  child: const Text("Complete"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: DesignSystem.body(fontWeight: FontWeight.w600, color: DesignSystem.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey[200]!;
    Color text = Colors.grey[800]!;

    if (status == 'PENDING') {
      bg = Colors.orange[50]!;
      text = Colors.orange[800]!;
    } else if (status == 'IN_PROGRESS') {
      bg = Colors.blue[50]!;
      text = Colors.blue[800]!;
    } else if (status == 'COMPLETED') {
      bg = Colors.green[50]!;
      text = Colors.green[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
