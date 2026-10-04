import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../quotations/client_quote_view_modal.dart';
import 'service_taxonomy.dart';

/// Sprint 1: Client-Authenticated Valuation Request Intake Flow
/// Replaces legacy lead modal with a strict 7-screen authenticated pipeline:
/// Screen 1: Registration (if unauthenticated)
/// Screen 2: Login (if unauthenticated)
/// Screen 3: Service Category (Valuation / Net Worth / Chartered Engineer)
/// Screen 4: Asset Category (Land & Building / Plant & Machinery / Securities)
/// Screen 5: Purpose (Bank Collateral / Visa / Tax / Corporate / Customs / Dispute)
/// Screen 6: Document Upload (Title Deed, Plan, Tax Receipt mandatory)
/// Screen 7: Request Submitted (REQ-YYYY-XXXX, status: QUOTE_PENDING)
class ClientRequestIntakeModal extends StatefulWidget {
  final int initialStep;

  const ClientRequestIntakeModal({super.key, this.initialStep = 3});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => const ClientRequestIntakeModal(),
    );
  }

  @override
  State<ClientRequestIntakeModal> createState() => _ClientRequestIntakeModalState();
}

class _ClientRequestIntakeModalState extends State<ClientRequestIntakeModal> {
  // Current Active Screen Step: 1 to 7
  late int _currentStep;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Screen 1 & 2: Auth Controllers ──
  final _regFullNameCtrl = TextEditingController();
  final _regMobileCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regConfirmPasswordCtrl = TextEditingController();
  bool _regTcAccepted = false;
  bool _regObscurePassword = true;

  final _loginIdentifierCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  bool _loginObscurePassword = true;

  // ── Screen 3: Service Category ──
  String _selectedServiceCategory = 'VALUATION'; // VALUATION, NET_WORTH_CERTIFICATE, CHARTERED_ENGINEER

  // ── Screen 4: Submenu & Classification ──
  String _selectedPropertyCategory = 'REAL_ESTATE_VALUATION';
  String _selectedSubmenuItem = 'Residential Property';
  final _assetNameCtrl = TextEditingController();
  final _assetLocationCtrl = TextEditingController();
  final _estimatedValueCtrl = TextEditingController();

  // Specialized fields for Net Worth & Technical Assessment
  final _legalNameCtrl = TextEditingController();
  final _panNumberCtrl = TextEditingController();
  final _inspectionDateCtrl = TextEditingController();

  // ── Screen 5: Purpose ──
  String _selectedPurpose = 'BANK_COLLATERAL';
  final _targetBankCtrl = TextEditingController();
  String _selectedUrgencySla = 'STANDARD_3D';
  final _specialNotesCtrl = TextEditingController();

  // Draft Order Reference
  int? _createdOrderId;

  // ── Screen 6: Uploaded Documents Tracking ──
  final Map<String, PlatformFile> _uploadedFiles = {}; // category -> PlatformFile
  final Map<String, bool> _uploadingSlot = {}; // category -> bool

  // ── Screen 7: Submission Result ──
  String? _referenceCode;
  String? _submissionStatus;
  String? _submissionMessage;

  @override
  void initState() {
    super.initState();
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isAuthenticated) {
        _currentStep = 1; // Start at Registration for new visitors
      } else {
        _currentStep = widget.initialStep; // Direct to Service Category if already authenticated
      }
    } catch (_) {
      _currentStep = widget.initialStep;
    }
  }

  @override
  void dispose() {
    _regFullNameCtrl.dispose();
    _regMobileCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regConfirmPasswordCtrl.dispose();
    _loginIdentifierCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _assetNameCtrl.dispose();
    _assetLocationCtrl.dispose();
    _estimatedValueCtrl.dispose();
    _legalNameCtrl.dispose();
    _panNumberCtrl.dispose();
    _inspectionDateCtrl.dispose();
    _targetBankCtrl.dispose();
    _specialNotesCtrl.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  // ── Authentication Handlers ──
  Future<void> _handleRegister() async {
    _clearError();
    final name = _regFullNameCtrl.text.trim();
    final mobile = _regMobileCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final password = _regPasswordCtrl.text.trim();
    final confirm = _regConfirmPasswordCtrl.text.trim();

    if (name.length < 2) {
      setState(() => _errorMessage = "Please enter your full name (minimum 2 characters).");
      return;
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(mobile)) {
      setState(() => _errorMessage = "Please enter a valid 10-digit Indian mobile number.");
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = "Please enter a valid email address.");
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = "Password must be at least 8 characters long.");
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = "Passwords do not match.");
      return;
    }
    if (!_regTcAccepted) {
      setState(() => _errorMessage = "You must accept the Terms & Conditions to proceed.");
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(email, password, 'CLIENT', mobile, name);

    if (success) {
      // Auto login with registered credentials
      final loginSuccess = await auth.login(email, password);
      setState(() => _isLoading = false);
      if (loginSuccess) {
        setState(() => _currentStep = 3);
      } else {
        setState(() {
          _currentStep = 2;
          _loginIdentifierCtrl.text = email;
          _errorMessage = "Account created successfully. Please sign in.";
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Registration failed. Email or username may already be in use.";
      });
    }
  }

  Future<void> _handleLogin() async {
    _clearError();
    final identifier = _loginIdentifierCtrl.text.trim();
    final password = _loginPasswordCtrl.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter your username/email and password.");
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(identifier, password);
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _currentStep = 3);
    } else {
      setState(() => _errorMessage = "Invalid credentials. Please verify your email and password.");
    }
  }

  // ── Draft Persistence (Transitions to Document Upload) ──
  Future<void> _saveDraftAndProceedToUpload() async {
    _clearError();
    final assetName = _assetNameCtrl.text.trim();
    if (assetName.isEmpty) {
      setState(() => _errorMessage = "Please specify the asset / property name.");
      return;
    }

    setState(() => _isLoading = true);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    double estimatedVal = 0.0;
    try {
      if (_estimatedValueCtrl.text.trim().isNotEmpty) {
        estimatedVal = double.parse(_estimatedValueCtrl.text.replaceAll(',', '').trim());
      }
    } catch (_) {}

    final inputs = <String, String>{
      'SERVICE_CATEGORY': _selectedServiceCategory,
      'SUBMENU': _selectedPropertyCategory,
      'SUBMENU_ITEM': _selectedSubmenuItem,
      'ASSET_NAME': assetName,
      'ASSET_LOCATION': _assetLocationCtrl.text.trim(),
      'TARGET_BANK': _targetBankCtrl.text.trim(),
      'URGENCY_SLA': _selectedUrgencySla,
      'SPECIAL_NOTES': _specialNotesCtrl.text.trim(),
      'LEGAL_NAME': _legalNameCtrl.text.trim(),
      'PAN_NUMBER': _panNumberCtrl.text.trim(),
      'INSPECTION_DATE': _inspectionDateCtrl.text.trim(),
    };

    final result = await orderProvider.saveDraft(
      _selectedPropertyCategory,
      _selectedPurpose,
      estimatedVal,
      inputs,
      id: _createdOrderId,
      serviceCategory: _selectedServiceCategory,
    );

    setState(() => _isLoading = false);

    if (result != null && result['id'] != null) {
      setState(() {
        _createdOrderId = result['id'];
        _currentStep = 6; // Move to Document Upload
      });
    } else {
      setState(() => _errorMessage = "Failed to initialize request draft. Please try again.");
    }
  }

  // ── Document Slot Picker ──
  Future<void> _pickAndUploadDocument(String category) async {
    if (_createdOrderId == null) {
      setState(() => _errorMessage = "Request draft must be initialized first.");
      return;
    }

    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx', 'xlsx', 'doc', 'xls'],
        withData: true,
      );

      if (res != null && res.files.isNotEmpty) {
        final file = res.files.first;
        if (file.bytes == null) {
          setState(() => _errorMessage = "Could not read file data. Please try another file.");
          return;
        }

        if (file.size > 20 * 1024 * 1024) {
          setState(() => _errorMessage = "File size exceeds strict 20 MB limit.");
          return;
        }

        setState(() {
          _uploadingSlot[category] = true;
          _errorMessage = null;
        });

        if (!mounted) return;
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        final uploadRes = await orderProvider.uploadDocument(
          _createdOrderId!,
          category,
          file.name,
          file.bytes!,
        );

        setState(() => _uploadingSlot[category] = false);

        if (uploadRes.success) {
          setState(() {
            _uploadedFiles[category] = file;
          });
        } else {
          setState(() {
            _errorMessage = uploadRes.errorMessage ?? "Failed to upload document.";
          });
        }
      }
    } catch (e) {
      setState(() {
        _uploadingSlot[category] = false;
        _errorMessage = "File picker error: $e";
      });
    }
  }

  // ── Submit Request to Backend ──
  Future<void> _handleSubmitRequest() async {
    if (_createdOrderId == null) return;
    _clearError();

    // Check mandatory document slots dynamically based on active service
    final service = ServiceTaxonomy.parseService(_selectedServiceCategory);
    final mandatorySlots = ServiceTaxonomy.getDocumentSlots(service).where((s) => s['mandatory'] == true);
    for (final slot in mandatorySlots) {
      final key = slot['key'] as String;
      if (!_uploadedFiles.containsKey(key)) {
        setState(() => _errorMessage = "${slot['label']} is mandatory.");
        return;
      }
    }

    setState(() => _isLoading = true);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final res = await orderProvider.submitRequest(_createdOrderId!);
    setState(() => _isLoading = false);

    if (res != null && res['referenceCode'] != null) {
      setState(() {
        _referenceCode = res['referenceCode'];
        _submissionStatus = res['status'] ?? 'QUOTE_PENDING';
        _submissionMessage = res['message'];
        _currentStep = 7; // Screen 7: Request Submitted Confirmation
      });
    } else {
      final err = (res != null && res['error'] != null) ? res['error'].toString() : "Submission failed.";
      setState(() => _errorMessage = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 16 : 32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840, maxHeight: 860),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 32, offset: Offset(0, 12)),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(isMobile),
                if (_currentStep >= 3 && _currentStep <= 6) _buildStepIndicator(isMobile),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 20 : 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) _buildErrorBanner(),
                        _buildScreenBody(isMobile),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 28, vertical: 18),
      decoration: const BoxDecoration(
        color: AppColors.brandNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getHeaderTitle(),
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 15 : 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getHeaderSubtitle(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    final service = ServiceTaxonomy.parseService(_selectedServiceCategory);
    switch (_currentStep) {
      case 1: return "Client Registration";
      case 2: return "Client Sign In";
      case 3: return "Step 1 of 4: Service Category";
      case 4: return "Step 2 of 4: ${service.step2Label}";
      case 5: return "Step 3 of 4: ${service.step3Label}";
      case 6: return "Step 4 of 4: Document Upload";
      case 7: return "Request Confirmed";
      default: return "Request Valuation Report";
    }
  }

  String _getHeaderSubtitle() {
    switch (_currentStep) {
      case 1: return "Create an account to submit and track your valuation mandate";
      case 2: return "Sign in to your client account to continue";
      case 3: return "Select the professional service category";
      case 4: return "Identify asset classification and details";
      case 5: return "Specify purpose, SLA and directives";
      case 6: return "Upload mandatory ownership documents (PDF, JPG, PNG)";
      case 7: return "Your request has been officially recorded";
      default: return "Commercial Valuation Intake Portal";
    }
  }

  Widget _buildStepIndicator(bool isMobile) {
    final steps = [
      {'num': 3, 'label': 'Service'},
      {'num': 4, 'label': 'Asset'},
      {'num': 5, 'label': 'Purpose'},
      {'num': 6, 'label': 'Documents'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: steps.map((s) {
          final int stepNum = s['num'] as int;
          final bool isDone = _currentStep > stepNum;
          final bool isCurrent = _currentStep == stepNum;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? const Color(0xFF047857)
                      : (isCurrent ? AppColors.primaryBlue : const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${stepNum - 2}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              if (!isMobile)
                Text(
                  s['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent ? AppColors.brandNavy : const Color(0xFF64748B),
                  ),
                ),
              if (stepNum < 6)
                Container(
                  width: isMobile ? 18 : 36,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: isDone ? const Color(0xFF047857) : const Color(0xFFCBD5E1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB91C1C), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFB91C1C), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenBody(bool isMobile) {
    switch (_currentStep) {
      case 1:
        return _buildScreen1Registration(isMobile);
      case 2:
        return _buildScreen2Login(isMobile);
      case 3:
        return _buildScreen3ServiceCategory(isMobile);
      case 4:
        return _buildScreen4AssetCategory(isMobile);
      case 5:
        return _buildScreen5Purpose(isMobile);
      case 6:
        return _buildScreen6DocumentUpload(isMobile);
      case 7:
        return _buildScreen7RequestSubmitted(isMobile);
      default:
        return const SizedBox();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCREEN 1: Client Registration
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScreen1Registration(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Create Your Client Profile", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
        const SizedBox(height: 6),
        Text("Required to track your official valuation reports and compliance documents.", style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
        const SizedBox(height: 24),

        _buildTextField(label: "Full Name", controller: _regFullNameCtrl, hint: "Rajesh Kumar", icon: Icons.person_outline),
        const SizedBox(height: 16),

        _buildTextField(label: "Mobile Number", controller: _regMobileCtrl, hint: "10-digit mobile number", icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),

        _buildTextField(label: "Email Address", controller: _regEmailCtrl, hint: "rajesh@company.com", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),

        _buildTextField(
          label: "Password",
          controller: _regPasswordCtrl,
          hint: "Minimum 8 characters",
          icon: Icons.lock_outline,
          obscureText: _regObscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_regObscurePassword ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.slate),
            onPressed: () => setState(() => _regObscurePassword = !_regObscurePassword),
          ),
        ),
        const SizedBox(height: 16),

        _buildTextField(label: "Confirm Password", controller: _regConfirmPasswordCtrl, hint: "Re-enter password", icon: Icons.lock_outline, obscureText: _regObscurePassword),
        const SizedBox(height: 18),

        Row(
          children: [
            Checkbox(
              value: _regTcAccepted,
              activeColor: AppColors.primaryBlue,
              onChanged: (val) => setState(() => _regTcAccepted = val ?? false),
            ),
            Expanded(
              child: Text(
                "I agree to the Terms & Conditions and Valuation Mandate Guidelines (v1.0)",
                style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.slate),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("Create Account & Continue", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () {
              _clearError();
              setState(() => _currentStep = 2);
            },
            child: Text("Already have an account? Sign In", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCREEN 2: Client Login
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScreen2Login(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Client Sign In", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
        const SizedBox(height: 6),
        Text("Sign in with your registered username or email address.", style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
        const SizedBox(height: 24),

        _buildTextField(label: "Username or Email", controller: _loginIdentifierCtrl, hint: "name@company.com or username", icon: Icons.person_outline),
        const SizedBox(height: 16),

        _buildTextField(
          label: "Password",
          controller: _loginPasswordCtrl,
          hint: "Enter password",
          icon: Icons.lock_outline,
          obscureText: _loginObscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_loginObscurePassword ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.slate),
            onPressed: () => setState(() => _loginObscurePassword = !_loginObscurePassword),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("Sign In & Continue", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () {
              _clearError();
              setState(() => _currentStep = 1);
            },
            child: Text("Don't have an account? Register here", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCREEN 3: Service Category
  // Display ONLY: 1. Valuation Report, 2. Net Worth Certificate, 3. Chartered Engineer Certificate
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScreen3ServiceCategory(bool isMobile) {
    final services = [
      {
        'id': 'VALUATION',
        'title': '1. Asset Valuation',
        'desc': 'Formal asset appraisal conducted by an IBBI Registered Valuer / Government Approved Valuer for banks, statutory bodies, tax & courts.',
        'badge': 'IBBI Certified',
        'icon': Icons.apartment_rounded,
      },
      {
        'id': 'NET_WORTH_CERTIFICATE',
        'title': '2. Net Worth Certification',
        'desc': 'Certified family or individual asset net worth statement for Visa, Immigration, Embassy financial proof & Bank Solvency.',
        'badge': 'Embassy Standard',
        'icon': Icons.account_balance_wallet_outlined,
      },
      {
        'id': 'CHARTERED_ENGINEER',
        'title': '3. Technical Assessment',
        'desc': 'Technical inspection, equipment residual life evaluation, machinery fitness & customs clearance certification by an authorized CE.',
        'badge': 'IEI Authorized',
        'icon': Icons.engineering_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Service Category", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
        const SizedBox(height: 6),
        Text("Choose the primary engagement document type required for your mandate.", style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
        const SizedBox(height: 20),

        ...services.map((svc) {
          final isSelected = _selectedServiceCategory == svc['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              onTap: () => setState(() => _selectedServiceCategory = svc['id'] as String),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryBlue : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(svc['icon'] as IconData, color: isSelected ? Colors.white : AppColors.brandNavy, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(svc['title'] as String, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryBlue.withOpacity(0.12) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(svc['badge'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primaryBlue : AppColors.slate)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(svc['desc'] as String, style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.slate)),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: svc['id'] as String,
                      groupValue: _selectedServiceCategory,
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) => setState(() => _selectedServiceCategory = val!),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                _clearError();
                final service = ServiceTaxonomy.parseService(_selectedServiceCategory);
                final submenus = ServiceTaxonomy.getSubmenusForService(service);
                if (submenus.isNotEmpty) {
                  _selectedPropertyCategory = submenus.first.id;
                  _selectedSubmenuItem = submenus.first.items.first;
                }
                switch (service) {
                  case ServiceType.assetValuation:
                    _selectedPurpose = 'BANK_COLLATERAL';
                    break;
                  case ServiceType.netWorthCertification:
                    _selectedPurpose = 'VISA_IMMIGRATION';
                    break;
                  case ServiceType.technicalAssessment:
                    _selectedPurpose = 'RESIDENTIAL_COMPLEX';
                    break;
                }
                setState(() => _currentStep = 4);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Continue to ${ServiceTaxonomy.parseService(_selectedServiceCategory).step2Label}", style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCREEN 4: Submenu & Classification (Frozen Taxonomy Version 1.0)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScreen4AssetCategory(bool isMobile) {
    final service = ServiceTaxonomy.parseService(_selectedServiceCategory);
    final submenus = ServiceTaxonomy.getSubmenusForService(service);

    Widget specializedFields;
    switch (service) {
      case ServiceType.assetValuation:
        specializedFields = Column(
          children: [
            _buildTextField(label: "Asset / Property Name *", controller: _assetNameCtrl, hint: "e.g. Prestige Tech Cloud, Tower 2", icon: Icons.tag_outlined),
            const SizedBox(height: 14),
            _buildTextField(label: "Asset Location (City, State) *", controller: _assetLocationCtrl, hint: "e.g. Bengaluru, Karnataka", icon: Icons.place_outlined),
            const SizedBox(height: 14),
            _buildTextField(label: "Estimated Market Value (₹, optional)", controller: _estimatedValueCtrl, hint: "e.g. 4,50,00,000", icon: Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
          ],
        );
        break;
      case ServiceType.netWorthCertification:
        specializedFields = Column(
          children: [
            _buildTextField(label: "Applicant / Entity Legal Name *", controller: _legalNameCtrl, hint: "e.g. Ramesh Kumar Gupta / Apex Infra LLP", icon: Icons.person_outline_rounded),
            const SizedBox(height: 14),
            _buildTextField(label: "Permanent Account Number (PAN) / Tax ID *", controller: _panNumberCtrl, hint: "e.g. ABCDE1234F", icon: Icons.badge_outlined),
            const SizedBox(height: 14),
            _buildTextField(label: "City & State Jurisdiction *", controller: _assetLocationCtrl, hint: "e.g. Mumbai, Maharashtra", icon: Icons.place_outlined),
            const SizedBox(height: 14),
            _buildTextField(label: "Estimated Total Net Worth (₹) *", controller: _estimatedValueCtrl, hint: "e.g. 2,50,00,000", icon: Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
          ],
        );
        break;
      case ServiceType.technicalAssessment:
        specializedFields = Column(
          children: [
            _buildTextField(label: "Project / Facility / Site Name *", controller: _assetNameCtrl, hint: "e.g. Green Valley Solar Park & Plant", icon: Icons.business_outlined),
            const SizedBox(height: 14),
            _buildTextField(label: "Site Location & Landmark *", controller: _assetLocationCtrl, hint: "e.g. Survey No. 42, Bengaluru, Karnataka", icon: Icons.place_outlined),
            const SizedBox(height: 14),
            _buildTextField(label: "Target Inspection Date / SLA *", controller: _inspectionDateCtrl, hint: "e.g. Within 48 Hours / 12-Oct-2026", icon: Icons.calendar_today_outlined),
          ],
        );
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select ${service.step2Label}", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
        const SizedBox(height: 6),
        Text(service.step2Subhead, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
        const SizedBox(height: 20),

        ...submenus.map((opt) {
          final isSelected = _selectedPropertyCategory == opt.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() {
                _selectedPropertyCategory = opt.id;
                if (!opt.items.contains(_selectedSubmenuItem)) {
                  _selectedSubmenuItem = opt.items.first;
                }
              }),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(opt.icon, color: isSelected ? AppColors.primaryBlue : AppColors.slate, size: 22),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(opt.title, style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
                              const SizedBox(height: 2),
                              Text(opt.description, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                            ],
                          ),
                        ),
                        Radio<String>(
                          value: opt.id,
                          groupValue: _selectedPropertyCategory,
                          activeColor: AppColors.primaryBlue,
                          onChanged: (val) => setState(() {
                            _selectedPropertyCategory = val!;
                            if (!opt.items.contains(_selectedSubmenuItem)) {
                              _selectedSubmenuItem = opt.items.first;
                            }
                          }),
                        ),
                      ],
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 10),
                      Text("Select specific subtype:", style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.slate)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: opt.items.map((item) {
                          final isItemSelected = _selectedSubmenuItem == item;
                          return InkWell(
                            onTap: () => setState(() => _selectedSubmenuItem = item),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isItemSelected ? AppColors.brandNavy : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isItemSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isItemSelected ? Colors.white : AppColors.brandNavy,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 20),
        specializedFields,

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () {
                _clearError();
                setState(() => _currentStep = 3);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("← Back", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate)),
            ),
            ElevatedButton(
              onPressed: () {
                if (service == ServiceType.assetValuation && _assetNameCtrl.text.trim().isEmpty) {
                  setState(() => _errorMessage = "Asset / Property name is required.");
                  return;
                }
                if (service == ServiceType.netWorthCertification && _legalNameCtrl.text.trim().isEmpty) {
                  setState(() => _errorMessage = "Applicant / Entity legal name is required.");
                  return;
                }
                if (service == ServiceType.technicalAssessment && _assetNameCtrl.text.trim().isEmpty) {
                  setState(() => _errorMessage = "Project / Facility / Site name is required.");
                  return;
                }
                _clearError();
                setState(() => _currentStep = 5);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Continue to ${service.step3Label}", style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCREEN 5: Purpose / Property Type
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScreen5Purpose(bool isMobile) {
    final service = ServiceTaxonomy.parseService(_selectedServiceCategory);
    final List<Map<String, String>> purposeOptions;
    switch (service) {
      case ServiceType.assetValuation:
        purposeOptions = ServiceTaxonomy.assetValuationPurposes;
        break;
      case ServiceType.netWorthCertification:
        purposeOptions = ServiceTaxonomy.netWorthPurposes;
        break;
      case ServiceType.technicalAssessment:
        purposeOptions = ServiceTaxonomy.technicalPropertyTypes;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select ${service.step3Label}", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
        const SizedBox(height: 6),
        Text("Specify requirements for your mandate.", style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
        const SizedBox(height: 20),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: purposeOptions.map((p) {
            final isSelected = _selectedPurpose == p['key'];
            return InkWell(
              onTap: () => setState(() => _selectedPurpose = p['key'] as String),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: isMobile ? double.infinity : 360,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? AppColors.primaryBlue : const Color(0xFFCBD5E1), width: isSelected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: p['key'] as String,
                      groupValue: _selectedPurpose,
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) => setState(() => _selectedPurpose = val!),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['title'] as String, style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
                          const SizedBox(height: 2),
                          Text(p['sub'] as String, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.slate)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),
        _buildTextField(label: "Target Bank / Institution / Authority", controller: _targetBankCtrl, hint: "e.g. State Bank of India / US Embassy / HDFC", icon: Icons.account_balance_outlined),
        const SizedBox(height: 14),

        Text("Target Turnaround Priority", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandNavy)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text("Standard SLA (3–5 Business Days)")),
                selected: _selectedUrgencySla == 'STANDARD_3D',
                selectedColor: AppColors.primaryBlue.withOpacity(0.15),
                onSelected: (selected) => setState(() => _selectedUrgencySla = 'STANDARD_3D'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text("⚡ Express Priority (24–48 Hours)")),
                selected: _selectedUrgencySla == 'EXPRESS_24H',
                selectedColor: AppColors.primaryBlue.withOpacity(0.15),
                onSelected: (selected) => setState(() => _selectedUrgencySla = 'EXPRESS_24H'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () {
                _clearError();
                setState(() => _currentStep = 4);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("← Back", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate)),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveDraftAndProceedToUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Proceed to Upload Documents", style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCREEN 6: Document Upload (Service-Specific Slots)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScreen6DocumentUpload(bool isMobile) {
    final service = ServiceTaxonomy.parseService(_selectedServiceCategory);
    final slots = ServiceTaxonomy.getDocumentSlots(service);

    final mandatorySlots = slots.where((s) => s['mandatory'] == true);
    final bool allMandatoryDone = mandatorySlots.every((s) => _uploadedFiles.containsKey(s['key'] as String));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Upload Mandate Documents", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
                const SizedBox(height: 4),
                Text("Files are securely uploaded and stored with strict role-based encryption.", style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.slate)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: allMandatoryDone ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                allMandatoryDone ? "✓ Mandatory Ready" : "Mandatory Docs Required",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: allMandatoryDone ? const Color(0xFF047857) : const Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF475569)),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      "Allowed formats: PDF, JPG, JPEG, PNG, DOCX, XLSX",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandNavy),
                    ),
                    Text(
                      "Maximum file size: 20 MB",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...slots.map((s) {
          final key = s['key'] as String;
          final title = s['label'] as String;
          final desc = s['hint'] as String? ?? '';
          final mandatory = s['mandatory'] as bool? ?? false;
          final hasFile = _uploadedFiles.containsKey(key);
          final isUploading = _uploadingSlot[key] == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasFile ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFile ? const Color(0xFF86EFAC) : (mandatory ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
                width: hasFile ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasFile ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasFile ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                    color: hasFile ? const Color(0xFF16A34A) : AppColors.brandNavy,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title, style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
                          if (mandatory) ...[
                            const SizedBox(width: 6),
                            const Text('*', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (hasFile)
                        Text(
                          "Uploaded: ${_uploadedFiles[key]!.name} (${(_uploadedFiles[key]!.size / 1024).toStringAsFixed(1)} KB)",
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
                        )
                      else
                        Text(desc, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.slate)),
                    ],
                  ),
                ),
                if (isUploading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else if (hasFile)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF15803D)),
                    tooltip: 'Replace Document',
                    onPressed: () => _pickAndUploadDocument(key),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _pickAndUploadDocument(key),
                    icon: const Icon(Icons.attach_file_rounded, size: 14),
                    label: Text(mandatory ? "Upload *" : "Upload", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mandatory ? AppColors.brandNavy : const Color(0xFF475569),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () {
                _clearError();
                setState(() => _currentStep = 5);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("← Back", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate)),
            ),
            ElevatedButton(
              onPressed: (_isLoading || !allMandatoryDone) ? null : _handleSubmitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Submit Mandate Request", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        const Icon(Icons.send_rounded, size: 16),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCREEN 7: Request Submitted Confirmation
  // Displays Reference Code, Status QUOTE_PENDING, Message, Buttons
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScreen7RequestSubmitted(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 48),
        ),
        const SizedBox(height: 20),

        Text(
          "Valuation Request Submitted!",
          style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.brandNavy),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Reference Code Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Reference Code: ",
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate),
              ),
              SelectableText(
                _referenceCode ?? "REQ-PENDING",
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.slate),
                tooltip: 'Copy Reference Code',
                onPressed: () {
                  if (_referenceCode != null) {
                    Clipboard.setData(ClipboardData(text: _referenceCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Reference code copied to clipboard!")),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Status Badge: QUOTE_PENDING
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFB45309)),
              const SizedBox(width: 6),
              Text(
                "Current Status: ${_submissionStatus ?? 'QUOTE_PENDING'}",
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Official Notice Box
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Text(
                _submissionMessage ??
                    "Your request has been received and is under review.\n\nA quotation will be issued through the portal after document review.",
                style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: AppColors.brandNavy, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_active_outlined, size: 16, color: Color(0xFF047857)),
                  const SizedBox(width: 6),
                  Text(
                    "Telegram operations notification dispatched to company desk.",
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF047857), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Action Buttons
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            if (_submissionStatus == 'QUOTE_PROVIDED' && _createdOrderId != null)
              ElevatedButton.icon(
                onPressed: () {
                  ClientQuoteViewModal.show(
                    context: context,
                    orderId: _createdOrderId!,
                    initialRefCode: _referenceCode,
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                label: Text("View Quotation", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/client');
              },
              icon: const Icon(Icons.dashboard_rounded, size: 16),
              label: Text("Go To Dashboard", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/client');
              },
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: Text("View Request", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandNavy,
                side: const BorderSide(color: AppColors.brandNavy),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandNavy)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.brandNavy),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
