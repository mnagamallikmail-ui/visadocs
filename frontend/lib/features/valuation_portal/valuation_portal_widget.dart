import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../services/web_file_picker.dart';
import 'service_intake_tracks.dart';
import '../../theme/design_system.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_components.dart';
import '../../theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../utils/report_list_helper.dart';
import '../document_workspace/document_workspace_screen.dart';

class ValuationPortalWidget extends StatefulWidget {
  final String role;
  final String email;
  final String fullName;
  final VoidCallback onLogout;
  final VoidCallback? onBackToAdmin;

  const ValuationPortalWidget({
    super.key,
    required this.role,
    required this.email,
    required this.fullName,
    required this.onLogout,
    this.onBackToAdmin,
  });

  @override
  State<ValuationPortalWidget> createState() => _ValuationPortalWidgetState();
}

class _ValuationPortalWidgetState extends State<ValuationPortalWidget> {
  String _selectedMenu = 'default';
  String? _selectedServiceType;

  // Valuation Form State
  int _currentValuationStep = 1;
  String? _selectedPropertyType;
  final TextEditingController _customPropertyTypeController = TextEditingController();
  final TextEditingController _estimatedValueController = TextEditingController();
  String? _selectedPurpose;
  final Map<String, String> _uploadedDocs = {};
  final Map<String, PlatformFile> _uploadedDocFiles = {};
  List<dynamic> _orderDocuments = [];

  // Selection/Detail State
  dynamic _selectedProject;

  // Dynamic template form state for PA/SPA
  int? _selectedTemplateId;
  Map<String, String> _entryValues = {};
  final Map<String, TextEditingController> _entryControllers = {};

  final List<String> _requiredDocsList = [
    "Sale/Title Deed",
    "Approved Plan",
    "Occupancy Certificate",
    "Property Tax Paid Receipt",
    "Electricity Bill"
  ];

  // Directory Search and Sort State
  final TextEditingController _portalSearchController = TextEditingController();
  String _portalSearchQuery = '';
  String _portalSortBy = 'date_desc';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });

    if (widget.role == 'CLIENT') {
      _selectedMenu = 'start_new';
    } else if (widget.role == 'PA') {
      _selectedMenu = 'unassigned';
    } else {
      _selectedMenu = 'under_review';
    }
  }

  @override
  void dispose() {
    _portalSearchController.dispose();
    _customPropertyTypeController.dispose();
    _estimatedValueController.dispose();
    _disposeEntryControllers();
    super.dispose();
  }

  void _disposeEntryControllers() {
    _entryControllers.forEach((_, c) => c.dispose());
    _entryControllers.clear();
  }

  void _refreshData() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    if (widget.role == 'CLIENT') {
      orderProvider.fetchClientOrders();
    } else if (widget.role == 'PA') {
      orderProvider.fetchUnassignedPool();
      orderProvider.fetchPaOrders();
      orderProvider.fetchActiveTemplates();
    } else {
      orderProvider.fetchAllOrders();
    }
  }

  Future<void> _deleteOrder(dynamic order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.hairlineSoft),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.brandRedDark, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Report',
                style: GoogleFonts.inter(
                  color: AppColors.brandRedDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to move this report to the Trash Bin?\n\nThis action can be reversed from the Trash Bin.',
          style: GoogleFonts.inter(color: AppColors.slate, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandRedDark,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ApiService();
      await api.dio.delete('/api/v1/orders/${order['id']}');
      setState(() {
        if (_selectedProject?['id'] == order['id']) {
          _selectedProject = null;
        }
      });
      _refreshData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            'Report moved to Trash Bin.',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.brandRedDark,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            'Failed to delete report: ${ApiService.getErrorMessage(e)}',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ));
      }
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'N/A';
    double? val;
    if (value is num) {
      val = value.toDouble();
    } else if (value is String) {
      val = double.tryParse(value);
    }
    if (val == null) return 'N/A';
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: 'INR ', decimalDigits: 0);
    return formatter.format(val);
  }

  void _resetForm() {
    setState(() {
      _selectedServiceType = null;
      _selectedPropertyType = null;
      _customPropertyTypeController.clear();
      _estimatedValueController.clear();
      _selectedPurpose = null;
      _uploadedDocs.clear();
    });
  }

  void _showCreateReportFlow() {
    final clientCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final branchCtrl = TextEditingController();
    int? selectedTemplateId;
    int step = 1;
    bool isCreating = false;

    Provider.of<OrderProvider>(context, listen: false).fetchActiveTemplates();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final orderProvider = Provider.of<OrderProvider>(context);
            final templates = orderProvider.activeTemplates;

            Widget content;
            List<Widget> actions;

            if (step == 1) {
              content = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Step 1: Enter Report Details",
                    style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: clientCtrl,
                    style: DesignSystem.body(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: "Name of the Client",
                      isDense: true,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bankCtrl,
                    style: DesignSystem.body(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: "Name of the Bank",
                      isDense: true,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: branchCtrl,
                    style: DesignSystem.body(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: "Name of the Branch",
                      isDense: true,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              );

              final nextEnabled = clientCtrl.text.trim().isNotEmpty &&
                  bankCtrl.text.trim().isNotEmpty &&
                  branchCtrl.text.trim().isNotEmpty;

              actions = [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 12)),
                ),
                ElevatedButton(
                  onPressed: nextEnabled
                      ? () {
                          setDialogState(() {
                            step = 2;
                          });
                        }
                      : null,
                  style: DesignSystem.primaryButton,
                  child: Text("Next", style: DesignSystem.body(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ];
            } else {
              content = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Step 2: Select Report Template",
                    style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (templates.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: selectedTemplateId,
                      hint: const Text("Choose a template..."),
                      items: templates.map<DropdownMenuItem<int>>((t) {
                        return DropdownMenuItem<int>(
                          value: t['id'],
                          child: Text(t['name'] ?? 'Template #${t['id']}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedTemplateId = val;
                        });
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                ],
              );

              final createEnabled = selectedTemplateId != null && !isCreating;

              actions = [
                TextButton(
                  onPressed: isCreating
                      ? null
                      : () {
                          setDialogState(() {
                            step = 1;
                          });
                        },
                  child: Text("Back", style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 12)),
                ),
                ElevatedButton(
                  onPressed: createEnabled
                      ? () async {
                          setDialogState(() {
                            isCreating = true;
                          });
                          try {
                            final order = await orderProvider.createStaffReport(
                              clientCtrl.text.trim(),
                              bankCtrl.text.trim(),
                              branchCtrl.text.trim(),
                              selectedTemplateId!,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              if (order != null) {
                                _refreshData();
                                setState(() {
                                  _selectedMenu = 'in_progress';
                                  _selectedProject = order;
                                  _selectedTemplateId = selectedTemplateId;
                                  _entryValues = {};
                                  _entryControllers.clear();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: DesignSystem.success,
                                    content: Text("Report ${order['reportNumber'] ?? ''} created successfully!"),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: DesignSystem.error,
                                    content: Text("Failed to create report."),
                                  ),
                                );
                              }
                            }
                          } catch (_) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: DesignSystem.error,
                                    content: Text("Error creating report."),
                                  ),
                                );
                            }
                          }
                        }
                      : null,
                  style: DesignSystem.primaryButton,
                  child: isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text("Create Report", style: DesignSystem.body(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ];
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: DesignSystem.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add_chart, color: DesignSystem.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Create New Report",
                    style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  key: ValueKey<int>(step),
                  width: 400,
                  child: content,
                ),
              ),
              actions: actions,
            );
          },
        );
      },
    );
  }

  void _openPopulateReportFullScreen(dynamic order, OrderProvider provider) {
    // Make sure controllers are initialized
    final snapshot = jsonDecode(order['fieldMappingSnapshot'] ?? '{}');
    final List<dynamic> fields = snapshot['fields'] ?? [];
    for (var f in fields) {
      final String key = f['key'] ?? '';
      _entryControllers[key] ??= TextEditingController(text: _entryValues[key] ?? '');
    }

    showGeneralDialog(
      context: context,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: DesignSystem.background,
              appBar: AppBar(
                backgroundColor: DesignSystem.sidebarBg, // Apple near-black
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: DesignSystem.sidebarText),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Populate Report — ${order['reportNumber'] ?? 'PV-' + order['id'].toString()}",
                      style: GoogleFonts.inter(
                        color: DesignSystem.sidebarText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Client: ${order['clientName'] ?? '—'}  ·  Bank: ${order['bankName'] ?? '—'}  ·  Branch: ${order['branchName'] ?? '—'}",
                      style: GoogleFonts.inter(
                        color: DesignSystem.sidebarMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close, color: DesignSystem.sidebarMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: DesignSystem.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "COMPILE REPORT DATA PLACEHOLDERS",
                                style: DesignSystem.body(
                                  color: DesignSystem.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Fill in the required information for the associated template. These placeholders will be dynamically populated in the final generated Word/PDF documents.",
                                style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 11),
                              ),
                              const Divider(height: 24),
                              _buildDynamicTemplateInputsForm(order),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: DesignSystem.border)),
                    ),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Cancel",
                                style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                              onPressed: () async {
                                // Gather controller values
                                _entryControllers.forEach((k, c) {
                                  _entryValues[k] = c.text;
                                });
                                final success = await provider.submitReportDraft(order['id'], _entryValues);
                                if (success) {
                                  Navigator.pop(context);
                                  _refreshData();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: DesignSystem.success,
                                      content: Text(
                                        (widget.role == 'SPA' || widget.role == 'SUPER_ADMIN' || widget.role == 'ADMIN')
                                            ? "Draft saved successfully!"
                                            : "Draft submitted to SPA for review!"
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Failed to submit draft.")),
                                  );
                                }
                              },
                              style: DesignSystem.primaryButton,
                              label: Text(
                                (widget.role == 'SPA' || widget.role == 'SUPER_ADMIN' || widget.role == 'ADMIN')
                                    ? "SAVE DRAFT MODIFICATIONS"
                                    : "SUBMIT TO SPA FOR REVIEW",
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _resetValuationFields() {
    setState(() {
      _currentValuationStep = 1;
      _selectedPropertyType = null;
      _customPropertyTypeController.clear();
      _selectedPurpose = null;
      _uploadedDocs.clear();
      _uploadedDocFiles.clear();
    });
  }

  Future<void> _submitForm() async {
    if (_selectedPropertyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a property category.")),
      );
      return;
    }
    if (_selectedPropertyType == 'Others' && _customPropertyTypeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please specify the custom property type.")),
      );
      return;
    }
    if (_selectedPurpose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valuation purpose.")),
      );
      return;
    }
    if (_uploadedDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload at least 1 document.")),
      );
      return;
    }

    final double? estVal = double.tryParse(_estimatedValueController.text.trim());
    if (estVal == null || estVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid approximate estimated value.")),
      );
      return;
    }

    // Pre-flight file validation (size <= 20MB)
    for (final entry in _uploadedDocFiles.entries) {
      final file = entry.value;
      if (file.bytes != null && file.bytes!.length > 20 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DesignSystem.error,
            content: Text("File '${file.name}' exceeds the 20 MB size limit. Please attach a smaller file."),
          ),
        );
        return;
      }
    }

    final provider = Provider.of<OrderProvider>(context, listen: false);
    final String propertyCategory = _selectedPropertyType == 'Others'
        ? _customPropertyTypeController.text.trim()
        : _selectedPropertyType!;

    // Step 1: Create the DRAFT order to obtain a stable orderId
    final draft = await provider.saveDraft(
      propertyCategory,
      _selectedPurpose!,
      estVal,
      {},  // inputs are empty at intake; documents are uploaded separately below
    );

    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create project draft.")),
      );
      return;
    }

    final int orderId = draft['id'];

    // Step 2: Upload each picked document to the order via the documents API
    for (final entry in _uploadedDocFiles.entries) {
      final String category = entry.key;
      final PlatformFile file = entry.value;
      if (file.bytes != null) {
        final res = await provider.uploadDocument(
          orderId,
          category,
          file.name,
          file.bytes!,
        );
        if (!res.success) {
          // Atomic rollback: delete draft order if any file fails to upload
          await provider.deleteDraft(orderId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: DesignSystem.error,
              content: Text("Upload failed for '${file.name}': ${res.errorMessage ?? 'Unknown error'}. Project initiation cancelled."),
            ),
          );
          return;
        }
      }
    }

    // Step 3: Submit the intake (marks order as PAID_INTAKE, generates report number)
    final success = await provider.submitIntake(orderId, 500.0);
    if (success) {
      _resetForm();
      setState(() {
        _selectedMenu = 'in_progress';
      });
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: DesignSystem.success,
          content: Text("Valuation Project initiated successfully! Report Number: ${draft['reportNumber'] ?? 'PV-' + orderId.toString()}"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit valuation intake.")),
      );
    }
  }

  Future<void> _pickFile(String category) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _uploadedDocs[category] = file.name;
            _uploadedDocFiles[category] = file;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not read file bytes. Please try again.")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking file: $e")),
      );
    }
  }

  Future<void> _pickAndUploadFinalReport(int orderId, String category, List<String> allowedExtensions, OrderProvider provider) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final res = await provider.uploadDocument(orderId, category, file.name, file.bytes!);
          if (res.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: DesignSystem.success,
                content: Text("${category.replaceAll('_', ' ')} uploaded successfully!"),
              ),
            );
            await _loadOrderInputs(orderId);
            _refreshData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: DesignSystem.error,
                content: Text(res.errorMessage ?? "Failed to upload document."),
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking file: $e")),
      );
    }
  }

  Future<void> _loadOrderInputs(int orderId) async {
    _disposeEntryControllers();
    _entryValues.clear();
    setState(() {
      _orderDocuments = [];
    });
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final docs = await provider.fetchOrderDocuments(orderId);
    if (docs != null) {
      setState(() {
        _orderDocuments = docs;
      });
    }
    final data = await provider.fetchOrderInputs(orderId);
    if (data != null) {
      setState(() {
        data.forEach((k, v) {
          _entryValues[k] = v.toString();
          _entryControllers[k] = TextEditingController(text: v.toString());
        });
      });
    }
  }

  Future<void> _downloadAndDecryptReport(int orderId) async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final data = await provider.downloadReport(orderId);
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to compile or download report.")),
      );
      return;
    }

    final String encryptedBase64 = data['dataStream'];
    final String password = data['encryptionPassword'];

    try {
      final keyHash = sha256.convert(utf8.encode(password)).bytes;
      final key = enc.Key(Uint8List.fromList(keyHash));

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb, padding: 'PKCS7'));
      final decryptedBytes = encrypter.decryptBytes(enc.Encrypted.fromBase64(encryptedBase64));

      final blob = html.Blob([decryptedBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'PV_REPORT_$orderId.pdf')
        ..style.display = 'none';
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: DesignSystem.success,
          content: Text("Report downloaded and decrypted successfully!"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Decryption failed: $e")),
      );
    }
  }

  Future<void> _downloadDocxReport(int orderId) async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final bytes = await provider.downloadReportDocx(orderId);
    if (bytes == null) {
      final errMsg = provider.lastDocxError ?? 'Failed to download DOCX report.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DesignSystem.error,
            content: Text(errMsg),
          ),
        );
      }
      return;
    }

    try {
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'PV_REPORT_$orderId.docx')
        ..style.display = 'none';
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: DesignSystem.success,
          content: Text("Hydrated DOCX downloaded successfully!"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving file: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SizedBox(
        height: viewportHeight,
        child: Row(
          children: [
            _buildSidebar(),
            Container(
              width: 1,
              color: AppColors.hairline,
            ),
            Expanded(
              child: SizedBox(
                height: viewportHeight,
                child: _buildMainCanvas(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    Map<String, List<Widget>> menuGroups = {};

    if (widget.role == 'CLIENT') {
      menuGroups['WORKSPACE'] = [
        _buildSidebarItem(key: 'start_new', label: "Start a New Project", icon: Icons.add_circle_outline),
        _buildSidebarItem(key: 'in_progress', label: "Projects in Progress", icon: Icons.hourglass_empty),
        _buildSidebarItem(key: 'completed', label: "Completed Projects", icon: Icons.check_circle_outline),
      ];
    } else if (widget.role == 'PA') {
      menuGroups['WORKSPACE'] = [
        _buildSidebarItem(key: 'in_progress', label: "My Active Tasks", icon: Icons.hourglass_empty),
        _buildSidebarItem(key: 'completed', label: "Completed Tasks", icon: Icons.check_circle_outline),
      ];
      menuGroups['OPERATIONS'] = [
        _buildSidebarItem(key: 'unassigned', label: "Unassigned Pool", icon: Icons.list_alt),
        _buildSidebarItem(key: 'create_report', label: "Create New Report", icon: Icons.add_chart),
      ];
    } else {
      menuGroups['WORKSPACE'] = [
        _buildSidebarItem(key: 'in_progress', label: "My Active Tasks", icon: Icons.hourglass_empty),
        _buildSidebarItem(key: 'completed', label: "Completed Reports", icon: Icons.check_circle_outline),
      ];
      menuGroups['OPERATIONS'] = [
        _buildSidebarItem(key: 'under_review', label: "Review Queue", icon: Icons.rate_review),
        _buildSidebarItem(key: 'approved', label: "Approved Reports", icon: Icons.verified_outlined),
        _buildSidebarItem(key: 'create_report', label: "Create New Report", icon: Icons.add_chart),
      ];
    }

    List<Widget> navList = [];
    menuGroups.forEach((groupName, items) {
      navList.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            groupName,
            style: AppTypography.microUppercase(color: AppColors.sidebarMuted),
          ),
        ),
      );
      navList.addAll(items);
    });

    return Container(
      width: 280.0,
      color: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo area
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignSystem.logo(fontSize: 18, darkMode: false),
                const SizedBox(height: 4),
                Text(
                  widget.role == 'CLIENT'
                      ? 'Client Portal'
                      : widget.role == 'PA'
                          ? 'Analyst Workspace'
                          : 'Review Workspace',
                  style: GoogleFonts.inter(
                    color: AppColors.sidebarMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: AppColors.hairlineSoft,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          const SizedBox(height: 8),
          
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: navList,
            ),
          ),
          
          // Profile footer — warm cream palette
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: AppRadius.brLg,
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.tealLight,
                        borderRadius: AppRadius.brMd,
                        border: Border.all(color: AppColors.deepTeal.withOpacity(0.2)),
                      ),
                      child: Center(
                        child: Text(
                          widget.fullName.isEmpty ? '?' : widget.fullName[0].toUpperCase(),
                          style: AppTypography.bodyMdMedium(
                            color: AppColors.deepTeal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fullName,
                            style: AppTypography.bodySmMedium(color: AppColors.sidebarText),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.email,
                            style: AppTypography.caption(color: AppColors.sidebarMuted).copyWith(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: AppColors.hairlineSoft,
                  margin: const EdgeInsets.only(bottom: 12),
                ),
                if ((widget.role == 'SUPER_ADMIN' || widget.role == 'ADMIN') && widget.onBackToAdmin != null) ...[
                  GestureDetector(
                    onTap: widget.onBackToAdmin,
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, color: AppColors.sidebarMuted, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Admin Console',
                          style: AppTypography.bodySmMedium(color: AppColors.sidebarMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onLogout,
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.brandRedDark, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Sign Out',
                          style: AppTypography.bodySmMedium(color: AppColors.brandRedDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({required String key, required String label, required IconData icon}) {
    final isSelected = _selectedMenu == key;

    final VoidCallback onTapFn = () {
      if (key == 'create_report') {
        _showCreateReportFlow();
      } else {
        setState(() {
          _selectedMenu = key;
          _selectedProject = null;
        });
        _refreshData();
      }
    };

    return _HoverablePortalSidebarItem(
      key: ValueKey(key),
      label: label,
      icon: icon,
      isSelected: isSelected,
      onTap: onTapFn,
    );
  }

  Widget _buildMainCanvas() {
    switch (_selectedMenu) {
      case 'start_new':
        return _buildStartNewProjectForm();
      case 'unassigned':
        return _buildUnassignedDirectory();
      case 'in_progress':
        return _buildRoleInProgressDirectory();
      case 'under_review':
        return _buildSpaReviewQueueDirectory();
      case 'approved':
        return _buildApprovedReportsDirectory();
      case 'completed':
        return _buildRoleCompletedDirectory();
      default:
        return _buildDefaultWelcome();
    }
  }

  Widget _buildDefaultWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Top KPI Section
          Text(
            "Welcome back, ${widget.fullName.split(' ').first}",
            style: AppTypography.pageTitle(color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            "${widget.role.replaceAll('_', ' ')} Workspace  ·  Here's what's happening today.",
            style: AppTypography.body(color: AppColors.slate),
          ),
          const SizedBox(height: 32),

          // KPI Cards (4 columns)
          LayoutBuilder(
            builder: (context, constraints) {
              int cols = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: cols == 4 ? (constraints.maxWidth > 1400 ? 2.1 : 1.6) : 2.0,
                children: [
                  _buildKpiCard(title: 'Active Tasks', value: '12', trend: '+2 this week', icon: Icons.hourglass_top, color: AppColors.brandBlue),
                  _buildKpiCard(title: 'Due Today', value: '3', trend: 'Needs attention', icon: Icons.warning_amber_rounded, color: AppColors.warning),
                  _buildKpiCard(title: 'Pending Review', value: '7', trend: 'Awaiting SPA', icon: Icons.pending_actions, color: AppColors.slate),
                  _buildKpiCard(title: 'Completed', value: '104', trend: '+15 this month', icon: Icons.check_circle_outline, color: AppColors.successAccent),
                ],
              );
            },
          ),
          
          const SizedBox(height: 32),

          // Lower section: 2 columns (Recent Assignments / Productivity)
          LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 900;
              return Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isDesktop ? 6 : 0,
                    child: _buildRecentAssignmentsSection(),
                  ),
                  if (isDesktop) const SizedBox(width: 24),
                  if (!isDesktop) const SizedBox(height: 24),
                  Expanded(
                    flex: isDesktop ? 4 : 0,
                    child: _buildProductivityOverview(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({required String title, required String value, required String trend, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppComponents.cardBase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.bodySmMedium(color: AppColors.slate)),
              Icon(icon, size: 20, color: color.withOpacity(0.8)),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: AppTypography.statDisplay(color: AppColors.ink)),
          const Spacer(),
          Text(trend, style: AppTypography.caption(color: AppColors.steel)),
        ],
      ),
    );
  }

  Widget _buildRecentAssignmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Assignments', style: AppTypography.sectionTitle(color: AppColors.ink)),
        const SizedBox(height: 24),
        Container(
          decoration: AppComponents.cardBase(),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.hairline),
            itemBuilder: (context, index) {
              // Dummy data for design redesign
              List<String> statuses = ['In Progress', 'In Progress', 'Pending Review', 'Completed'];
              List<String> titles = ['Commercial Plaza Valuation', 'Residential Plot Survey', 'Warehouse Asset Check', 'Downtown Office Space'];
              List<String> ids = ['PV-2310-4492', 'PV-2310-4493', 'PV-2310-4491', 'PV-2310-4485'];
              
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Icon(Icons.maps_home_work_outlined, color: AppColors.slate, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titles[index], style: AppTypography.bodyMdMedium(color: AppColors.ink)),
                          const SizedBox(height: 4),
                          Text('${ids[index]}  ·  Assigned 2h ago', style: AppTypography.caption(color: AppColors.slate)),
                        ],
                      ),
                    ),
                    AppComponents.statusBadge(statuses[index]),
                    const SizedBox(width: 16),
                    Icon(Icons.chevron_right, color: AppColors.stone),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductivityOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Productivity & Timeline', style: AppTypography.sectionTitle(color: AppColors.ink)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppComponents.cardBase(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mock chart area
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weekly Output', style: AppTypography.bodySmMedium(color: AppColors.slate)),
                  Icon(Icons.bar_chart, color: AppColors.slate),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int i = 0; i < 7; i++)
                    Container(
                      width: 24,
                      height: [40.0, 70.0, 30.0, 90.0, 60.0, 20.0, 50.0][i],
                      decoration: BoxDecoration(
                        color: i == 4 ? AppColors.brandBlue : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                ],
              ),
              const SizedBox(height: 32),
              Divider(height: 1, color: AppColors.hairline),
              const SizedBox(height: 32),
              
              // Timeline
              Text('Activity Timeline', style: AppTypography.bodySmMedium(color: AppColors.slate)),
              const SizedBox(height: 24),
              _buildTimelineItem('Submitted PV-2310-4485 to SPA', '10:42 AM', isLast: false),
              _buildTimelineItem('Claimed PV-2310-4492 from pool', '09:15 AM', isLast: false),
              _buildTimelineItem('Logged in to workspace', '09:00 AM', isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String text, String time, {required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.brandBlue,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: AppColors.hairline,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: AppTypography.bodySm(color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(time, style: AppTypography.caption(color: AppColors.slate)),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartNewProjectForm() {
    if (_selectedServiceType == 'networth') {
      return NetworthTrackWidget(
        clientName: widget.fullName,
        onBack: () => setState(() => _selectedServiceType = null),
        onSubmitted: () {
          setState(() { _selectedServiceType = null; _selectedMenu = 'in_progress'; });
          _refreshData();
        },
      );
    }
    if (_selectedServiceType == 'chartered') {
      return CharteredTrackWidget(
        clientName: widget.fullName,
        onBack: () => setState(() => _selectedServiceType = null),
        onSubmitted: () {
          setState(() { _selectedServiceType = null; _selectedMenu = 'in_progress'; });
          _refreshData();
        },
      );
    }
    if (_selectedServiceType == 'valuation') {
      return _buildValuationTrackForm();
    }

    final services = [
      {
        'key': 'valuation',
        'label': 'Valuation Report',
        'description': 'Generate certified valuation reports for assets, properties, and businesses.',
        'icon': Icons.assessment_outlined,
        'tooltip': 'Initiate a certified property or asset valuation report',
      },
      {
        'key': 'networth',
        'label': 'Networth Certificate',
        'description': 'Create and manage net worth certificates based on submitted financial documents.',
        'icon': Icons.account_balance_wallet_outlined,
        'tooltip': 'Create and manage a certified net worth certificate',
      },
      {
        'key': 'chartered',
        'label': 'Chartered Engineer Certificate',
        'description': 'Request professional engineering certification and technical assessment reports.',
        'icon': Icons.engineering_outlined,
        'tooltip': 'Request a professional engineering and technical assessment certificate',
      },
    ];

    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = 3;
      double aspectRatio = 1.0;
      if (constraints.maxWidth > 1200) {
        crossAxisCount = 4;
        aspectRatio = 1.1;
      } else if (constraints.maxWidth > 900) {
        crossAxisCount = 3;
        aspectRatio = 0.95;
      } else if (constraints.maxWidth > 600) {
        crossAxisCount = 2;
        aspectRatio = 1.0;
      } else {
        crossAxisCount = 1;
        aspectRatio = 1.35;
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page header — no wrapper card
            Text(
              'New Request',
              style: AppTypography.heading2(color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the service type you want to initiate.',
              style: AppTypography.bodyMd(color: AppColors.slate),
            ),
            const SizedBox(height: 32),
            // Service cards — clean grid, no outer wrapper
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: aspectRatio,
              ),
              itemCount: services.length,
              itemBuilder: (ctx, i) {
                final svc = services[i];
                final key = svc['key'] as String;

                return _ClientServiceCard(
                  title: svc['label'] as String,
                  description: svc['description'] as String,
                  icon: svc['icon'] as IconData,
                  isSelected: false,
                  tooltip: svc['tooltip'] as String,
                  onTap: () {
                    // Navigate immediately — no selection state, no Continue button
                    setState(() {
                      _selectedServiceType = key;
                    });
                  },
                );
              },
            ),
          ],
        ),
      );
    });
  }

  IconData _getPropertyIcon(String option) {
    switch (option) {
      case "Open Plots":
        return Icons.crop_free;
      case "Open Land":
        return Icons.terrain;
      case "Agricultural Land":
        return Icons.agriculture;
      case "Non-Agricultural Land":
        return Icons.map;
      case "Residential Flat":
        return Icons.apartment;
      case "Independent Residential Land & Building":
        return Icons.home;
      case "Industrial Land & Building":
        return Icons.business;
      case "Others":
      default:
        return Icons.more_horiz;
    }
  }

  IconData _getPurposeIcon(String option) {
    switch (option) {
      case "Visa Purpose":
        return Icons.assignment_ind;
      case "For the personal use":
        return Icons.person;
      case "For income tax purpose":
        return Icons.account_balance_wallet;
      case "For loan availing purpose":
        return Icons.monetization_on;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildValuationTrackForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProgressTracker(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: DesignSystem.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (_currentValuationStep > 1) {
                              setState(() {
                                _currentValuationStep--;
                              });
                            } else {
                              setState(() {
                                _selectedServiceType = null;
                                _resetValuationFields();
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: DesignSystem.border),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, size: 12, color: DesignSystem.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _getStepHeaderTitle(),
                          style: DesignSystem.label(color: DesignSystem.sidebarMuted),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _resetValuationFields();
                              _currentValuationStep = 1;
                            });
                          },
                          child: Text(
                            "Reset Form",
                            style: DesignSystem.body(
                              color: DesignSystem.error,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.01, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(_currentValuationStep),
                        child: _buildCurrentStepContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    String? description,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? DesignSystem.primary : DesignSystem.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: DesignSystem.primary.withOpacity(0.08),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? DesignSystem.primary.withOpacity(0.08) : DesignSystem.backgroundSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? DesignSystem.primary : DesignSystem.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: DesignSystem.textPrimary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: DesignSystem.body(
                        color: DesignSystem.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: DesignSystem.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTracker() {
    final steps = [
      {
        'title': 'Property Type',
        'value': _selectedPropertyType == 'Others'
            ? (_customPropertyTypeController.text.isNotEmpty ? _customPropertyTypeController.text : 'Custom')
            : _selectedPropertyType
      },
      {'title': 'Intended Purpose', 'value': _selectedPurpose},
      {
        'title': 'Valuation Value',
        'value': _estimatedValueController.text.isNotEmpty ? 'INR ${_estimatedValueController.text}' : null
      },
      {'title': 'Document Vault', 'value': _uploadedDocs.isNotEmpty ? '${_uploadedDocs.length} files' : null},
      {'title': 'Final Review', 'value': null},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: DesignSystem.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(steps.length, (index) {
          final stepNum = index + 1;
          final isCompleted = _currentValuationStep > stepNum;
          final isActive = _currentValuationStep == stepNum;
          final step = steps[index];

          return Expanded(
            child: Row(
              children: [
                InkWell(
                  onTap: isCompleted
                      ? () {
                          setState(() {
                            _currentValuationStep = stepNum;
                          });
                        }
                      : null,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? DesignSystem.primary
                              : isActive
                                  ? DesignSystem.primary.withOpacity(0.1)
                                  : DesignSystem.background,
                          border: Border.all(
                            color: isActive || isCompleted ? DesignSystem.primary : DesignSystem.border,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : Text(
                                  '$stepNum',
                                  style: GoogleFonts.montserrat(
                                    color: isActive ? DesignSystem.primary : DesignSystem.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            step['title']!,
                            style: GoogleFonts.montserrat(
                              color: isActive
                                  ? DesignSystem.textPrimary
                                  : isCompleted
                                      ? DesignSystem.primary
                                      : DesignSystem.textMuted,
                              fontSize: 11,
                              fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                          if (step['value'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                step['value']!,
                                style: DesignSystem.body(
                                  color: DesignSystem.textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: isCompleted ? DesignSystem.primary : DesignSystem.border,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getStepHeaderTitle() {
    switch (_currentValuationStep) {
      case 1:
        return "Step 1: Property Category";
      case 2:
        return "Step 2: Valuation Purpose";
      case 3:
        return "Step 3: Approximate Valuation Value";
      case 4:
        return "Step 4: Compliance Document Vault";
      case 5:
        return "Step 5: Final Review & Submission";
      default:
        return "Valuation Request Wizard";
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentValuationStep) {
      case 1:
        return _buildStepPropertyType();
      case 2:
        return _buildStepPurpose();
      case 3:
        return _buildStepValue();
      case 4:
        return _buildStepDocuments();
      case 5:
        return _buildStepReview();
      default:
        return _buildStepPropertyType();
    }
  }

  Widget _buildStepPropertyType() {
    final propertyOptions = [
      "Open Plots",
      "Open Land",
      "Agricultural Land",
      "Non-Agricultural Land",
      "Residential Flat",
      "Independent Residential Land & Building",
      "Industrial Land & Building",
      "Others"
    ];

    final propertyDescriptions = {
      "Open Plots": "Vacant plots for residential or commercial development.",
      "Open Land": "Large parcels of undeveloped real estate.",
      "Agricultural Land": "Farming fields, plantations, or cultivateable ground.",
      "Non-Agricultural Land": "Zoned land for industrial, retail or offices.",
      "Residential Flat": "Apartments, condominiums, or co-ops.",
      "Independent Residential Land & Building": "Houses, bungalows, duplexes, or villas.",
      "Industrial Land & Building": "Factories, warehouses, manufacturing sites.",
      "Others": "Specify a custom category."
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Choose the property category that aligns with your intake file.",
          style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.8,
          ),
          itemCount: propertyOptions.length,
          itemBuilder: (context, idx) {
            final opt = propertyOptions[idx];
            final isSel = _selectedPropertyType == opt;
            return _buildOptionCard(
              title: opt,
              icon: _getPropertyIcon(opt),
              isSelected: isSel,
              description: propertyDescriptions[opt],
              onTap: () {
                setState(() {
                  _selectedPropertyType = opt;
                  if (opt != 'Others') {
                    _customPropertyTypeController.clear();
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (mounted && _selectedPropertyType == opt) {
                        setState(() => _currentValuationStep = 2);
                      }
                    });
                  }
                });
              },
            );
          },
        ),
        if (_selectedPropertyType == 'Others') ...[
          const SizedBox(height: 20),
          Text(
            "Specify Custom Property Type",
            style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _customPropertyTypeController,
                    style: DesignSystem.body(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Enter custom property type...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: DesignSystem.border),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_customPropertyTypeController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter custom property type.")),
                    );
                    return;
                  }
                  setState(() => _currentValuationStep = 2);
                },
                style: DesignSystem.primaryButton,
                child: const Text("Continue"),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStepPurpose() {
    final purposeOptions = [
      "Visa Purpose",
      "For the personal use",
      "For income tax purpose",
      "For loan availing purpose"
    ];

    final purposeDescriptions = {
      "Visa Purpose": "Proof of financial standing for visa and travel applications.",
      "For the personal use": "Asset valuation for personal financial management.",
      "For income tax purpose": "Official declarations for capital gains or wealth taxes.",
      "For loan availing purpose": "Collateral valuation for banking and loans."
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select the primary intention for this property valuation request.",
          style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.8,
          ),
          itemCount: purposeOptions.length,
          itemBuilder: (context, idx) {
            final opt = purposeOptions[idx];
            final isSel = _selectedPurpose == opt;
            return _buildOptionCard(
              title: opt,
              icon: _getPurposeIcon(opt),
              isSelected: isSel,
              description: purposeDescriptions[opt],
              onTap: () {
                setState(() {
                  _selectedPurpose = opt;
                  Future.delayed(const Duration(milliseconds: 250), () {
                    if (mounted && _selectedPurpose == opt) {
                      setState(() => _currentValuationStep = 3);
                    }
                  });
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStepValue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "State the estimated or approximate valuation value in Indian Rupees (INR).",
          style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DesignSystem.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DesignSystem.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Estimated Value (INR)",
                  style: GoogleFonts.montserrat(
                    color: DesignSystem.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _estimatedValueController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.montserrat(
                      color: DesignSystem.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee, size: 18, color: DesignSystem.textSecondary),
                      hintText: "e.g., 5000000",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: DesignSystem.border),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      final double? estVal = double.tryParse(_estimatedValueController.text.trim());
                      if (estVal == null || estVal <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a valid approximate estimated value.")),
                        );
                        return;
                      }
                      setState(() => _currentValuationStep = 4);
                    },
                    style: DesignSystem.primaryButton,
                    child: Text(
                      "Continue to Document Vault",
                      style: DesignSystem.body(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Upload supporting documents to the compliance vault. At least one document is required.",
          style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 3.2,
          ),
          itemCount: _requiredDocsList.length,
          itemBuilder: (context, idx) {
            final category = _requiredDocsList[idx];
            final isUploaded = _uploadedDocs.containsKey(category);
            final filename = _uploadedDocs[category];

            String displayedName = "";
            if (isUploaded && filename != null) {
              displayedName = filename.length > 22
                  ? '${filename.substring(0, 12)}...${filename.substring(filename.length - 8)}'
                  : filename;
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: isUploaded ? DesignSystem.success : DesignSystem.border,
                  width: isUploaded ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUploaded ? const Color(0xFFDCFCE7) : DesignSystem.backgroundSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUploaded ? Icons.check : Icons.cloud_upload_outlined,
                      color: isUploaded ? DesignSystem.success : DesignSystem.textSecondary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: GoogleFonts.montserrat(
                            color: DesignSystem.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isUploaded ? displayedName : "Required for compliance",
                          style: DesignSystem.body(
                            color: isUploaded ? DesignSystem.success : DesignSystem.textMuted,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: isUploaded
                        ? () => setState(() {
                            _uploadedDocs.remove(category);
                            _uploadedDocFiles.remove(category);
                          })
                        : () => _pickFile(category),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: isUploaded ? const Color(0xFFFEE2E2) : DesignSystem.backgroundSecondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      isUploaded ? "Remove" : "Upload",
                      style: GoogleFonts.montserrat(
                        color: isUploaded ? DesignSystem.error : DesignSystem.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _uploadedDocs.isEmpty
                  ? null
                  : () {
                      setState(() => _currentValuationStep = 5);
                    },
              style: DesignSystem.primaryButton,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  "Continue to Review",
                  style: DesignSystem.body(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepReview() {
    final String propertyCategory = _selectedPropertyType == 'Others'
        ? (_customPropertyTypeController.text.isNotEmpty ? _customPropertyTypeController.text : 'Custom Type')
        : (_selectedPropertyType ?? 'Not selected');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Verify the details below before submitting the commercial valuation request.",
          style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: DesignSystem.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildReviewRow("Property Type", propertyCategory, Icons.home_outlined),
              const Divider(height: 24),
              _buildReviewRow("Valuation Purpose", _selectedPurpose ?? 'Not selected', Icons.assignment_outlined),
              const Divider(height: 24),
              _buildReviewRow(
                  "Estimated Value",
                  _estimatedValueController.text.isNotEmpty
                      ? _formatCurrency(double.tryParse(_estimatedValueController.text.trim()))
                      : 'Not specified',
                  Icons.currency_rupee),
              const Divider(height: 24),
              _buildReviewRow(
                "Document Vault",
                _uploadedDocs.isEmpty ? 'No documents uploaded' : '${_uploadedDocs.length} files successfully attached',
                Icons.folder_outlined,
                subText: _uploadedDocs.values.join(', '),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _currentValuationStep = 1;
                });
              },
              child: Text(
                "Edit Details",
                style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _submitForm,
              style: DesignSystem.primaryButton,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  "SUBMIT VALUATION REQUEST",
                  style: DesignSystem.body(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewRow(String title, String val, IconData icon, {String? subText}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DesignSystem.backgroundSecondary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: DesignSystem.primary, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                val,
                style: GoogleFonts.montserrat(
                  color: DesignSystem.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subText != null && subText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subText,
                  style: DesignSystem.body(color: DesignSystem.textMuted, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnassignedDirectory() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final list = provider.unassignedPool;
        return _buildDirectoryList(
          title: "UNASSIGNED VALUATION FILES POOL",
          orders: list,
        );
      },
    );
  }

  Widget _buildRoleInProgressDirectory() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        List<dynamic> list = [];
        if (widget.role == 'CLIENT') {
          list = provider.clientOrders.where((o) => o['status'] != 'FINAL_DELIVERY' && o['status'] != 'DRAFT').toList();
        } else if (widget.role == 'PA') {
          list = provider.paOrders.where((o) => o['status'] == 'ASSIGNED' || o['status'] == 'ACTION_NEEDED' || o['status'] == 'SPA_GATE' || o['status'] == 'SPA_CONFIRMED' || o['status'] == 'FINAL_DELIVERY').toList();
        } else if (widget.role == 'SPA') {
          list = provider.allOrders.where((o) => o['status'] == 'SPA_GATE' || o['status'] == 'SPA_CONFIRMED').toList();
        } else {
          list = provider.allOrders.where((o) => o['status'] != 'FINAL_DELIVERY' && o['status'] != 'DRAFT').toList();
        }
        return _buildDirectoryList(
          title: "IN-PROGRESS PIPELINE RECORDS",
          orders: list,
        );
      },
    );
  }

  Widget _buildSpaReviewQueueDirectory() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final list = provider.allOrders.where((o) {
          final String status = o['status'] ?? '';
          if (widget.role == 'SUPER_ADMIN' || widget.role == 'ADMIN') {
            return status == 'SPA_GATE' || status == 'SPA_CONFIRMED' || status == 'FINAL_DELIVERY';
          }
          return status == 'SPA_GATE' || status == 'SPA_CONFIRMED' || status == 'FINAL_DELIVERY';
        }).toList();
        return _buildDirectoryList(
          title: "VALUATION REPORTS REVIEW QUEUE",
          orders: list,
        );
      },
    );
  }

  Widget _buildRoleCompletedDirectory() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        List<dynamic> list = [];
        if (widget.role == 'CLIENT') {
          list = provider.clientOrders.where((o) => o['status'] == 'FINAL_DELIVERY').toList();
        } else if (widget.role == 'PA') {
          list = provider.paOrders.where((o) => o['status'] == 'FINAL_DELIVERY').toList();
        } else {
          list = provider.allOrders.where((o) => o['status'] == 'FINAL_DELIVERY').toList();
        }
        return _buildDirectoryList(
          title: "COMPLETED & SEALED REPORTS ARCHIVE",
          orders: list,
        );
      },
    );
  }

  Widget _buildApprovedReportsDirectory() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final list = provider.allOrders
            .where((o) => o['status'] == 'SPA_CONFIRMED')
            .toList();
        return _buildDirectoryList(
          title: "APPROVED REPORTS — AWAITING FINAL DELIVERY",
          orders: list,
        );
      },
    );
  }

  Widget _buildDirectoryList({required String title, required List<dynamic> orders}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final displayOrders = ReportListHelper.filterAndSortReports(orders, _portalSearchQuery, _portalSortBy);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12.0),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.montserrat(
              color: DesignSystem.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ReportSearchSortBar(
          searchController: _portalSearchController,
          searchQuery: _portalSearchQuery,
          sortBy: _portalSortBy,
          onSearchChanged: (val) => setState(() => _portalSearchQuery = val),
          onSearchCleared: () => setState(() {
            _portalSearchController.clear();
            _portalSearchQuery = '';
          }),
          onSortChanged: (val) {
            if (val != null) setState(() => _portalSortBy = val);
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Divider(height: 8),
        ),
        Expanded(
          child: displayOrders.isEmpty
              ? Center(
                  child: Text(
                    _portalSearchQuery.isNotEmpty
                        ? "No reports match '$_portalSearchQuery'."
                        : "No project records available.",
                    style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  itemCount: displayOrders.length,
                  itemBuilder: (context, idx) {
                    final order = displayOrders[idx];
                    final isSelected = _selectedProject?['id'] == order['id'];
                    final reportNum = order['reportNumber'] ?? 'PV-${order['id']}';
                    final String statusStr = order['status'] ?? 'PENDING';
                    final reportDateStr = ReportListHelper.formatReportDate(order['createdAt']);
                    final canDelete = ReportListHelper.canDeleteReport(order, authProvider);

                    return Consumer<OrderProvider>(
                      builder: (context, provider, _) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: isSelected ? DesignSystem.secondary : DesignSystem.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedProject = null;
                                    } else {
                                      _selectedProject = order;
                                      _selectedTemplateId = order['templateId'];
                                      _loadOrderInputs(order['id']);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusBgColor(statusStr),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          statusStr,
                                          style: GoogleFonts.montserrat(
                                            color: _getStatusTextColor(statusStr),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reportNum,
                                              style: GoogleFonts.montserrat(
                                                color: DesignSystem.textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              "Date: $reportDateStr",
                                              style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 5,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Client: ${order['clientName'] ?? '—'}",
                                              style: GoogleFonts.montserrat(
                                                color: DesignSystem.textPrimary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              "Bank: ${order['bankName'] ?? '—'}",
                                              style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 11),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      InkWell(
                                        onTap: () {
                                          if (order['templateId'] != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => DocumentWorkspaceScreen(
                                                  orderId: order['id'],
                                                  reportNumber: reportNum,
                                                  role: widget.role,
                                                ),
                                              ),
                                            ).then((_) => _refreshData());
                                          } else {
                                            _openPopulateReportFullScreen(order, provider);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.tealLight,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppColors.deepTeal.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.open_in_new_rounded, size: 12, color: AppColors.deepTeal),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Open',
                                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.deepTeal),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (canDelete) ...[
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () => _deleteOrder(order),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.errorBg,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: AppColors.brandRedDark.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.delete_outline_rounded, size: 12, color: AppColors.brandRedDark),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Delete',
                                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.brandRedDark),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 10),
                                      Icon(
                                        isSelected ? Icons.keyboard_arrow_down : Icons.chevron_right,
                                        size: 16,
                                        color: DesignSystem.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: _buildSideSheetContent(provider, order),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSideSheetContent(OrderProvider provider, dynamic order) {
    final String status = order['status'] ?? 'PENDING';
    final isCompleted = status == "FINAL_DELIVERY";
    final isUnassigned = status == "PAID_INTAKE";
    final isAssignedToMe = status == "ASSIGNED" && order['paId'] != null;

    final String reportNum = order['reportNumber'] ?? 'PV-${order['id']}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow("Report Number", reportNum),
        _buildDetailRow("Request ID", order['id'].toString()),
        _buildDetailRow("Property Category", order['propertyCategory'] ?? ''),
        _buildDetailRow("Purpose", order['purpose'] ?? ''),
        _buildDetailRow("Estimated Value", _formatCurrency(order['estimatedValue'])),
        if (order['finalValue'] != null)
          _buildDetailRow("Final Value", _formatCurrency(order['finalValue'])),
        if (order['feeCharged'] != null)
          _buildDetailRow("Fee Charged", _formatCurrency(order['feeCharged'])),
        if (order['slaExpiryTime'] != null)
          _buildDetailRow("SLA Expiry", order['slaExpiryTime'].toString().replaceAll("T", " ")),

        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Lifecycle status", style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusBgColor(status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: GoogleFonts.montserrat(
                  color: _getStatusTextColor(status),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 24),

        // Intake documents section (visible to all staff roles)
        if (widget.role != 'CLIENT') ...[
          _buildIntakeDocumentsSection(provider),
          const Divider(height: 24),
        ],

        // Action A: Claim Task (For PA)
        if (widget.role == 'PA' && isUnassigned)
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () async {
                final success = await provider.claimOrder(order['id']);
                if (success) {
                  setState(() {
                    _selectedProject = null;
                  });
                  _refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: DesignSystem.success,
                      content: Text("Task claimed successfully! Added to your Active Tasks."),
                    ),
                  );
                }
              },
              style: DesignSystem.primaryButton,
              child: const Text("CLAIM THIS VALUATION FILE", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),

        // Action B: Template selection and inputs form (For PA / SPA / Super Admin)
        if (isAssignedToMe && (widget.role == 'PA' || widget.role == 'SPA' || widget.role == 'SUPER_ADMIN' || widget.role == 'ADMIN')) ...[
          if (order['templateId'] == null) ...[
            Text(
              "SELECT ACTIVE REPORT TEMPLATE",
              style: GoogleFonts.montserrat(color: DesignSystem.secondary, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedTemplateId,
              hint: const Text("Choose a template..."),
              items: provider.activeTemplates.map<DropdownMenuItem<int>>((t) {
                return DropdownMenuItem<int>(
                  value: t['id'],
                  child: Text(t['name'] ?? 'Template #${t['id']}'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedTemplateId = val;
                });
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: _selectedTemplateId == null
                    ? null
                    : () async {
                        final success = await provider.associateTemplate(order['id'], _selectedTemplateId!);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Template associated successfully.")),
                          );
                          _refreshData();
                        }
                      },
                style: DesignSystem.primaryButton,
                child: const Text("ASSOCIATE TEMPLATE", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            Text(
              "REPORT DOCUMENT WORKSPACE",
              style: GoogleFonts.montserrat(color: DesignSystem.secondary, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.description_outlined, size: 16, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentWorkspaceScreen(
                        orderId: order['id'],
                        reportNumber: reportNum,
                        role: widget.role,
                      ),
                    ),
                  );
                  _refreshData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                label: const Text(
                  "OPEN DOCUMENT WORKSPACE",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_note, size: 16, color: DesignSystem.secondary),
                onPressed: () => _openPopulateReportFullScreen(order, provider),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DesignSystem.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                label: const Text(
                  "Legacy Form View",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DesignSystem.textSecondary),
                ),
              ),
            ),
          ]
        ],

        // Action C: Review and approval forms (For SPA / SUPER_ADMIN / ADMIN)
        // SPA and Admin have full edit rights on both SPA_GATE and SPA_CONFIRMED orders.
        if ((widget.role == 'SPA' || widget.role == 'SUPER_ADMIN' || widget.role == 'ADMIN') &&
            (status == 'SPA_GATE' || status == 'SPA_CONFIRMED' || (status == 'FINAL_DELIVERY' && (widget.role == 'SUPER_ADMIN' || widget.role == 'ADMIN')))) ...[
          if (status == 'SPA_GATE') ...[
            Text(
              "DOCUMENT WORKSPACE & VERIFICATION",
              style: GoogleFonts.montserrat(color: DesignSystem.secondary, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.verified_user_outlined, size: 16, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentWorkspaceScreen(
                        orderId: order['id'],
                        reportNumber: reportNum,
                        role: widget.role,
                      ),
                    ),
                  );
                  _refreshData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                label: const Text(
                  "OPEN DOCUMENT WORKSPACE (REVIEW)",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.zoom_in, size: 16, color: DesignSystem.secondary),
                onPressed: () => _openPopulateReportFullScreen(order, provider),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DesignSystem.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                label: const Text(
                  "Legacy Form View",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DesignSystem.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              "CONFIRM VALUATION REPORT DRAFT",
              style: GoogleFonts.montserrat(color: DesignSystem.secondary, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: () {
                  _generateReportAndFinalize(provider, order['id'], null);
                },
                style: DesignSystem.primaryButton.copyWith(
                  backgroundColor: WidgetStateProperty.all(DesignSystem.success),
                ),
                child: const Text("CONFIRM REPORT", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],

        // Action E: SPA / Admin Upload Final Reports (For SPA / SUPER_ADMIN / ADMIN under SPA_CONFIRMED status)
        if (status == 'SPA_CONFIRMED' && (widget.role == 'SPA' || widget.role == 'SUPER_ADMIN' || widget.role == 'ADMIN')) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),
          Text(
            "FINALIZED REPORT OPERATIONS",
            style: GoogleFonts.montserrat(color: DesignSystem.secondary, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.description, size: 14, color: Colors.white),
                    onPressed: () => _downloadDocxReport(order['id']),
                    style: DesignSystem.primaryButton,
                    label: const Text(
                      "DOWNLOAD DOCX",
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: _orderDocuments.any((d) => d['category'] == 'FINAL_DOCX')
                      ? Container(
                          decoration: BoxDecoration(
                            color: DesignSystem.successBg,
                            border: Border.all(color: DesignSystem.success),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: DesignSystem.success, size: 14),
                              SizedBox(width: 4),
                              Text(
                                "DOCX UPLOADED",
                                style: TextStyle(color: DesignSystem.success, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file, size: 14, color: Colors.white),
                          onPressed: () => _pickAndUploadFinalReport(order['id'], 'FINAL_DOCX', ['docx'], provider),
                          style: DesignSystem.primaryButton,
                          label: const Text(
                            "UPLOAD DOCX",
                            style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: _orderDocuments.any((d) => d['category'] == 'FINAL_SIGNED_PDF')
                      ? Container(
                          decoration: BoxDecoration(
                            color: DesignSystem.successBg,
                            border: Border.all(color: DesignSystem.success),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: DesignSystem.success, size: 14),
                              SizedBox(width: 4),
                              Text(
                                "PDF UPLOADED",
                                style: TextStyle(color: DesignSystem.success, fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file, size: 14, color: Colors.white),
                          onPressed: () => _pickAndUploadFinalReport(order['id'], 'FINAL_SIGNED_PDF', ['pdf'], provider),
                          style: DesignSystem.primaryButton,
                          label: const Text(
                            "UPLOAD PDF",
                            style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Super Admin Override: revert an approved report back to SPA review
          if (status == 'SPA_CONFIRMED' &&
              (widget.role == 'SUPER_ADMIN' || widget.role == 'ADMIN')) ...[    
            const Divider(),
            const SizedBox(height: 10),
            Text(
              "SUPER ADMIN OVERRIDE",
              style: GoogleFonts.montserrat(color: Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.undo, size: 16, color: Colors.white),
                onPressed: () async {
                  final ok = await provider.revertToReview(order['id']);
                  if (ok && mounted) {
                    _refreshData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.orange,
                        content: Text("Report reverted to SPA Review Queue."),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                label: const Text(
                  "OVERRIDE — REVERT TO SPA REVIEW",
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],

        if (isCompleted && widget.role == 'CLIENT') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () => _downloadAndDecryptReport(order['id']),
              style: DesignSystem.primaryButton.copyWith(
                backgroundColor: WidgetStateProperty.all(DesignSystem.success),
              ),
              child: const Text(
                "DOWNLOAD FINAL PDF REPORT",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],

        // Bottom Action Button: DOCX & PDF Download for Staff
        if ((status == 'FINAL_DELIVERY' || status == 'SPA_GATE' || status == 'SPA_CONFIRMED') &&
            (widget.role == 'PA' || widget.role == 'SPA' || widget.role == 'SUPER_ADMIN' || widget.role == 'ADMIN')) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.description, size: 16, color: Colors.white),
                    onPressed: () => _downloadDocxReport(order['id']),
                    style: DesignSystem.primaryButton,
                    label: const Text(
                      "DOWNLOAD DOCX",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              if (status == 'FINAL_DELIVERY') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                      onPressed: () => _downloadAndDecryptReport(order['id']),
                      style: DesignSystem.primaryButton.copyWith(
                        backgroundColor: WidgetStateProperty.all(DesignSystem.success),
                      ),
                      label: const Text(
                        "DOWNLOAD PDF",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (widget.role == 'SUPER_ADMIN' || widget.role == 'ADMIN') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.brandRedDark),
                onPressed: () => _deleteOrder(order),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.brandRedDark.withOpacity(0.5)),
                  foregroundColor: AppColors.brandRedDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                label: const Text(
                  "MOVE REPORT TO TRASH BIN",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandRedDark,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDynamicTemplateInputsForm(dynamic order) {
    if (order['fieldMappingSnapshot'] == null) {
      return const Text("No form metadata fields present.");
    }
    try {
      final snapshot = jsonDecode(order['fieldMappingSnapshot']);
      final List<dynamic> fields = snapshot['fields'] ?? [];
      if (fields.isEmpty) {
        return const Text("No placeholders inside associated template.");
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: fields.map<Widget>((f) {
          final String key = f['key'] ?? '';
          final String label = f['label'] ?? key;
          final String type = f['type'] ?? 'TEXT';

          final controller = _entryControllers[key] ??= TextEditingController(text: _entryValues[key] ?? '');

          Widget inputControl;

          if (type == 'IMAGE') {
            inputControl = StatefulBuilder(
              builder: (context, setStateItem) {
                final curFilename = _entryValues[key] ?? controller.text;
                String displayFilename = "No image uploaded";
                if (curFilename.isNotEmpty) {
                  if (curFilename.startsWith("data:image")) {
                    displayFilename = "Image associated (binary blob)";
                  } else {
                    displayFilename = curFilename;
                  }
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: DesignSystem.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.image_outlined, color: DesignSystem.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          displayFilename,
                          style: TextStyle(
                            color: curFilename.isNotEmpty
                                ? DesignSystem.success
                                : DesignSystem.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () async {
                          try {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['jpg', 'jpeg', 'png'],
                              withData: true,
                            );
                            if (result != null && result.files.isNotEmpty) {
                              final file = result.files.first;
                              if (file.bytes != null) {
                                final String base64Str = "data:image/png;base64," + base64Encode(file.bytes!);
                                setState(() {
                                  _entryValues[key] = base64Str;
                                  controller.text = base64Str;
                                });
                                setStateItem(() {});
                              }
                            }
                          } catch (e) {
                            // error picking file
                          }
                        },
                        child: Text(
                          curFilename.isNotEmpty ? "Replace" : "Upload",
                          style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }
            );
          } else if (type == 'DATE') {
            inputControl = TextFormField(
              controller: controller,
              readOnly: true,
              style: DesignSystem.body(fontSize: 13),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 16, color: DesignSystem.primary),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      content: SizedBox(
                        width: 320,
                        height: 320,
                        child: CalendarDatePicker(
                          initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          onDateChanged: (DateTime date) {
                            final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                            setState(() {
                              controller.text = dateStr;
                              _entryValues[key] = dateStr;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  }
                );
              },
            );
          } else {
            inputControl = TextFormField(
              controller: controller,
              style: DesignSystem.body(fontSize: 13),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    label,
                    style: DesignSystem.body(
                      color: DesignSystem.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 7,
                  child: inputControl,
                ),
              ],
            ),
          );
        }).toList(),
      );
    } catch (e) {
      return Text("Error rendering template mapping: $e");
    }
  }

  Future<void> _generateReportAndFinalize(OrderProvider provider, int orderId, double? finalValue) async {
    // Gather any in-memory edits made by the SPA/Admin via the full-page editor.
    _entryControllers.forEach((k, c) {
      if (k != 'FINAL_VALUE_INPUT') {
        _entryValues[k] = c.text;
      }
    });

    // FIX: Only call submitReportDraft when the SPA has actual in-memory edits to
    // persist. Calling it with an empty map would overwrite and wipe all field
    // inputs previously saved by the PA, which is the root cause of the Confirm
    // button silently breaking when the full-page editor was never opened.
    if (_entryValues.isNotEmpty) {
      final draftSuccess = await provider.submitReportDraft(orderId, _entryValues);
      if (!draftSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to save updated draft before finalization.")),
          );
        }
        return;
      }
    }

    final success = await provider.spaVerify(orderId, finalValue);
    if (success) {
      // FIX: Await the full data refresh so provider.allOrders is up to date
      // before we search it for the updated order reference.  The previous
      // addPostFrameCallback pattern fired before fetchAllOrders completed,
      // leaving _selectedProject pointing at the stale pre-confirm snapshot.
      await _loadOrderInputs(orderId);
      await provider.fetchAllOrders();

      if (!mounted) return;

      setState(() {
        dynamic updatedOrder;
        for (var o in provider.allOrders) {
          if (o['id'] == orderId) {
            updatedOrder = o;
            break;
          }
        }
        if (updatedOrder != null) {
          _selectedProject = updatedOrder;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: DesignSystem.success,
            content: Text("Report confirmed successfully! Download links are now active."),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to generate and finalize report.")),
        );
      }
    }
  }

  // ── Intake Document Helpers ──────────────────────────────────────────────

  Future<void> _downloadIntakeDocument(int docId, String filename) async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final bytes = await provider.downloadDocument(docId);
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download document.')),
        );
      }
      return;
    }
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  Widget _buildIntakeDocumentsSection(OrderProvider provider) {
    // Filter out final-report documents; show only client intake uploads
    final intakeDocs = _orderDocuments
        .where((d) =>
            d['category'] != 'FINAL_DOCX' &&
            d['category'] != 'FINAL_SIGNED_PDF')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CLIENT INTAKE DOCUMENTS',
          style: GoogleFonts.montserrat(
            color: DesignSystem.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        if (intakeDocs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: DesignSystem.backgroundSecondary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: DesignSystem.border),
            ),
            child: Text(
              'No intake documents uploaded yet.',
              style: DesignSystem.body(
                color: DesignSystem.textMuted,
                fontSize: 11,
              ),
            ),
          )
        else
          ...intakeDocs.map((doc) {
            final int docId = doc['id'] as int;
            final String filename = doc['filename'] as String? ?? 'document';
            final String category = doc['category'] as String? ?? '';
            final String uploader = doc['uploadedBy'] as String? ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: DesignSystem.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined,
                      size: 16, color: DesignSystem.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filename,
                          style: DesignSystem.body(
                            color: DesignSystem.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (uploader.isNotEmpty)
                          Text(
                            uploader,
                            style: DesignSystem.body(
                              color: DesignSystem.textMuted,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: DesignSystem.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.montserrat(
                          color: DesignSystem.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Download $filename',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => _downloadIntakeDocument(docId, filename),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: DesignSystem.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.download,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: GoogleFonts.montserrat(color: DesignSystem.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case "FINAL_DELIVERY":
        return DesignSystem.successBg;
      case "ASSIGNED":
        return DesignSystem.warningBg;
      case "SPA_GATE":
        return const Color(0xFFF3E8FF); // light purple
      case "SPA_CONFIRMED":
        return const Color(0xFFDBEAFE); // light blue
      case "PAID_INTAKE":
        return const Color(0xFFFFEDD5); // light orange
      case "DRAFT":
      default:
        return DesignSystem.structural;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case "FINAL_DELIVERY":
        return DesignSystem.success;
      case "ASSIGNED":
        return DesignSystem.warning;
      case "SPA_GATE":
        return const Color(0xFF7E3AF2); // purple
      case "SPA_CONFIRMED":
        return const Color(0xFF2563EB); // blue
      case "PAID_INTAKE":
        return const Color(0xFFEA580C); // orange
      case "DRAFT":
      default:
        return DesignSystem.textSecondary;
    }
  }
} // End of _ValuationPortalWidgetState

class _ClientServiceCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  const _ClientServiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<_ClientServiceCard> createState() => _ClientServiceCardState();
}

class _ClientServiceCardState extends State<_ClientServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.title,
      hint: widget.description,
      selected: widget.isSelected,
      button: true,
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(
              0,
              _isHovered && !widget.isSelected ? -2.0 : 0.0,
              0,
            ),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: widget.isSelected ? AppColors.yellowLight : AppColors.canvas,
                  borderRadius: AppRadius.brXxxl, // Matching landing page
                  border: Border.all(
                    color: widget.isSelected
                        ? AppColors.brandYellow
                        : (_isHovered ? AppColors.hairlineStrong : AppColors.hairlineSoft),
                    width: widget.isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        widget.isSelected ? 0.0 : (_isHovered ? 0.07 : 0.04),
                      ),
                      blurRadius: _isHovered ? 12 : 6,
                      spreadRadius: _isHovered ? 0 : -1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: widget.isSelected
                                  ? AppColors.brandYellow.withOpacity(0.2)
                                  : AppColors.surface,
                              borderRadius: AppRadius.brMd, // Matching landing page icons
                            ),
                            child: Center(
                              child: Icon(
                                widget.icon,
                                color: widget.isSelected ? AppColors.inkDeep : AppColors.slate,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: AppTypography.heading5(
                              color: widget.isSelected ? AppColors.inkDeep : AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.description,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySm(color: AppColors.slate).copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isSelected)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.brandYellow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                            size: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hoverable Portal Sidebar Item ───────────────────────────────────────────


class _HoverablePortalSidebarItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _HoverablePortalSidebarItem({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_HoverablePortalSidebarItem> createState() => _HoverablePortalSidebarItemState();
}

class _HoverablePortalSidebarItemState extends State<_HoverablePortalSidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.sidebarSelected
                : (_hovered ? AppColors.sidebarHover : Colors.transparent),
            borderRadius: AppRadius.brMd,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: isActive
                    ? AppColors.sidebarAccent
                    : ( _hovered ? AppColors.sidebarText : AppColors.sidebarMuted ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: AppTypography.bodySm(
                    color: isActive
                        ? AppColors.sidebarAccent
                        : ( _hovered ? AppColors.sidebarText : AppColors.sidebarMuted ),
                  ).copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
