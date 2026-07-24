import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:html' as html;
import '../../theme/design_system.dart';
import '../../providers/auth_provider.dart';
import 'valuation_model.dart';
import 'valuation_repository.dart';

class ValuationFormWidget extends StatefulWidget {
  final VoidCallback onSubmitSuccess;

  const ValuationFormWidget({super.key, required this.onSubmitSuccess});

  @override
  State<ValuationFormWidget> createState() => _ValuationFormWidgetState();
}

class _ValuationFormWidgetState extends State<ValuationFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _customTypeCtrl = TextEditingController();

  String? _selectedPropertyType;
  String? _selectedPurpose;

  // Track uploaded filenames per document category
  final Map<String, String> _uploadedDocs = {};

  final List<String> _propertyTypes = [
    "Open Plots",
    "Open Land",
    "Agricultural Land",
    "Non-Agricultural Land",
    "Residential Flat",
    "Independent Residential Land and Building",
    "Industrial Land and Building",
    "Others"
  ];

  final List<String> _purposes = [
    "Visa Purpose",
    "For the personal use",
    "For income tax purpose",
    "For loan availing purpose"
  ];

  final List<String> _requiredDocs = [
    "Sale Deed or other Title Deed",
    "Approved Plan",
    "Occupancy Certificate",
    "Copy of the latest Property Tax Paid Receipt",
    "Copy of latest Electricity Bill"
  ];

  void _pickDocument(String category) {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.pdf,.doc,.docx,.jpg,.jpeg,.png';
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        setState(() {
          _uploadedDocs[category] = file.name;
        });
      }
    });
  }

  void _submitForm() {
    if (_selectedPropertyType == null || _selectedPurpose == null) return;
    if (_selectedPropertyType == "Others" && _customTypeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Please specify the custom property type."),
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final repo = Provider.of<ValuationRepository>(context, listen: false);

    final newReq = ValuationRequest(
      id: "VAL-${DateTime.now().year}-${100 + repo.requests.length}",
      clientName: auth.fullName ?? auth.email ?? "Premium Client",
      propertyType: _selectedPropertyType!,
      customPropertyType: _selectedPropertyType == "Others" ? _customTypeCtrl.text.trim() : null,
      purpose: _selectedPurpose!,
      submissionDate: DateTime.now(),
      status: "PENDING",
      uploadedDocs: Map<String, String>.from(_uploadedDocs),
    );

    repo.submitRequest(newReq);

    // Show luxury feedback dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.verified, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(
              "Submission Received",
              style: DesignSystem.h3(color: DesignSystem.primary),
            ),
          ],
        ),
        content: Text(
          "Your request ${newReq.id} has been logged in our enterprise queue. An analyst will begin verification shortly.",
          style: DesignSystem.body(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSubmitSuccess();
            },
            style: DesignSystem.primaryButton,
            child: const Text("Go to Directory"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSection2 = _selectedPropertyType != null;
    final showSection3 = showSection2 && _selectedPurpose != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 60),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Description
            Text(
              "Premium Valuation Intake Portal",
              style: DesignSystem.h2(color: DesignSystem.primary),
            ),
            const SizedBox(height: 8),
            Text(
              "Complete the progressive intake verification below to submit a priority commercial valuation asset.",
              style: DesignSystem.body(color: DesignSystem.textSecondary),
            ),
            const SizedBox(height: 35),

            // SECTION 1: Property Type Selection
            _buildSectionHeader("1. Select Property Asset Type"),
            const SizedBox(height: 15),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
              ),
              itemCount: _propertyTypes.length,
              itemBuilder: (context, index) {
                final type = _propertyTypes[index];
                final isSelected = _selectedPropertyType == type;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPropertyType = type;
                      // reset subselections if needed
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? DesignSystem.primary.withOpacity(0.04) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? DesignSystem.primary : DesignSystem.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        type,
                        textAlign: TextAlign.center,
                        style: DesignSystem.body(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? DesignSystem.primary : DesignSystem.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            if (_selectedPropertyType == "Others") ...[
              const SizedBox(height: 15),
              TextFormField(
                controller: _customTypeCtrl,
                decoration: const InputDecoration(
                  labelText: "Custom Property Type",
                  hintText: "Please specify property type...",
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
            ],

            const SizedBox(height: 40),

            // SECTION 2: Purpose Selection (Reveals progressively)
            if (showSection2) ...[
              _buildSectionHeader("2. Specify Valuation Purpose"),
              const SizedBox(height: 15),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3.5,
                ),
                itemCount: _purposes.length,
                itemBuilder: (context, index) {
                  final purp = _purposes[index];
                  final isSelected = _selectedPurpose == purp;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPurpose = purp;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? DesignSystem.primary.withOpacity(0.04) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? DesignSystem.primary : DesignSystem.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: purp,
                            groupValue: _selectedPurpose,
                            activeColor: DesignSystem.primary,
                            onChanged: (val) {
                              setState(() {
                                _selectedPurpose = val;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              purp,
                              style: DesignSystem.body(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? DesignSystem.primary : DesignSystem.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ).animate().fadeIn().slideY(begin: 0.05),
            ],

            const SizedBox(height: 40),

            // SECTION 3: Document Vault Upload Zone
            if (showSection3) ...[
              _buildSectionHeader("3. Document Vault Upload Zone"),
              const SizedBox(height: 15),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _requiredDocs.length,
                itemBuilder: (context, index) {
                  final cat = _requiredDocs[index];
                  final fileName = _uploadedDocs[cat];
                  final isUploaded = fileName != null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: DesignSystem.background,
                      border: Border.all(color: DesignSystem.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                isUploaded ? Icons.check_circle : Icons.cloud_upload_outlined,
                                color: isUploaded ? Colors.green : DesignSystem.textSecondary,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat,
                                      style: DesignSystem.body(
                                        fontWeight: FontWeight.w600,
                                        color: DesignSystem.textPrimary,
                                      ),
                                    ),
                                    if (isUploaded)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          fileName,
                                          style: DesignSystem.body(
                                            color: Colors.green,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _pickDocument(cat),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isUploaded ? Colors.transparent : DesignSystem.primary,
                            foregroundColor: isUploaded ? DesignSystem.primary : Colors.white,
                            elevation: 0,
                            side: isUploaded ? const BorderSide(color: DesignSystem.primary) : null,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          icon: Icon(isUploaded ? Icons.refresh : Icons.file_upload, size: 16),
                          label: Text(isUploaded ? "Replace" : "Upload"),
                        ),
                      ],
                    ),
                  );
                },
              ).animate().fadeIn().slideY(begin: 0.05),

              const SizedBox(height: 35),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: DesignSystem.primaryButton,
                  child: Text(
                    "Submit Valuation Request",
                    style: DesignSystem.body(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DesignSystem.body(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: DesignSystem.primary,
          ),
        ),
        const SizedBox(height: 4),
        Container(width: 45, height: 3, color: DesignSystem.primary),
      ],
    );
  }
}
