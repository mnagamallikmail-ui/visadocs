import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/order_provider.dart';

class SiteInspectionModal extends StatefulWidget {
  final int orderId;
  final String referenceCode;
  final String orderStatus;
  final String role;
  final VoidCallback? onStatusChanged;

  const SiteInspectionModal({
    super.key,
    required this.orderId,
    required this.referenceCode,
    required this.orderStatus,
    required this.role,
    this.onStatusChanged,
  });

  static Future<void> show({
    required BuildContext context,
    required int orderId,
    required String referenceCode,
    required String orderStatus,
    required String role,
    VoidCallback? onStatusChanged,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SiteInspectionModal(
        orderId: orderId,
        referenceCode: referenceCode,
        orderStatus: orderStatus,
        role: role,
        onStatusChanged: onStatusChanged,
      ),
    );
  }

  @override
  State<SiteInspectionModal> createState() => _SiteInspectionModalState();
}

class _SiteInspectionModalState extends State<SiteInspectionModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  Map<String, dynamic>? _inspectionSummary;

  // Schedule controllers
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _accessNotesController = TextEditingController();

  // Reschedule controllers
  final TextEditingController _rescheduleDateController = TextEditingController();
  final TextEditingController _rescheduleTimeController = TextEditingController();
  final TextEditingController _rescheduleReasonController = TextEditingController();

  // Completion controllers
  final TextEditingController _remarksController = TextEditingController();
  String _selectedVisitStatus = "COMPLETED";

  // Photo upload
  String _selectedCategory = "FRONT_ELEVATION";

  final List<Map<String, dynamic>> _categories = [
    {"code": "FRONT_ELEVATION", "name": "Front Elevation", "mandatory": true, "min": 1},
    {"code": "REAR_ELEVATION", "name": "Rear Elevation", "mandatory": true, "min": 1},
    {"code": "SIDE_VIEW_LEFT", "name": "Left Side View", "mandatory": true, "min": 1},
    {"code": "SIDE_VIEW_RIGHT", "name": "Right Side View", "mandatory": true, "min": 1},
    {"code": "STREET_VIEW", "name": "Street / Road View", "mandatory": true, "min": 1},
    {"code": "ACCESS_ROAD", "name": "Access Road", "mandatory": true, "min": 1},
    {"code": "SURROUNDINGS", "name": "Surroundings", "mandatory": true, "min": 2},
    {"code": "BOUNDARY_NORTH", "name": "North Boundary", "mandatory": false, "min": 0},
    {"code": "BOUNDARY_SOUTH", "name": "South Boundary", "mandatory": false, "min": 0},
    {"code": "BOUNDARY_EAST", "name": "East Boundary", "mandatory": false, "min": 0},
    {"code": "BOUNDARY_WEST", "name": "West Boundary", "mandatory": false, "min": 0},
    {"code": "INTERIOR", "name": "Interior", "mandatory": false, "min": 0},
    {"code": "ADDITIONAL", "name": "Additional / Misc", "mandatory": false, "min": 0},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInspectionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _accessNotesController.dispose();
    _rescheduleDateController.dispose();
    _rescheduleTimeController.dispose();
    _rescheduleReasonController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadInspectionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = Provider.of<OrderProvider>(context, listen: false);
    final data = await provider.fetchInspectionSummary(widget.orderId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _inspectionSummary = data;
        if (data != null) {
          if (data['siteContactName'] != null) {
            _contactNameController.text = data['siteContactName'].toString();
          }
          if (data['siteContactNumber'] != null) {
            _contactPhoneController.text = data['siteContactNumber'].toString();
          }
          if (data['inspectionDate'] != null) {
            _dateController.text = data['inspectionDate'].toString();
          }
          if (data['inspectionTime'] != null) {
            _timeController.text = data['inspectionTime'].toString();
          }
          if (data['inspectionRemarks'] != null) {
            _remarksController.text = data['inspectionRemarks'].toString();
          }
        }
      });
    }
  }

  String get _currentStatus {
    return _inspectionSummary?['orderStatus'] ?? widget.orderStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 820,
        height: 680,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 28,
              offset: const Offset(0, 14),
            )
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildScheduleTab(),
                        _buildPhotosTab(),
                        _buildCompletionTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.explore_outlined, color: Color(0xFF38BDF8), size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SITE INSPECTION LIFECYCLE",
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                "Order Ref: ${widget.referenceCode}  |  Order #${widget.orderId}",
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          _buildStatusBadge(_currentStatus),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: "Close",
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case "ASSIGNED":
        bg = const Color(0xFFF59E0B).withOpacity(0.15);
        fg = const Color(0xFFF59E0B);
        break;
      case "INSPECTION_SCHEDULED":
        bg = const Color(0xFF818CF8).withOpacity(0.15);
        fg = const Color(0xFF818CF8);
        break;
      case "INSPECTION_IN_PROGRESS":
        bg = const Color(0xFFF97316).withOpacity(0.15);
        fg = const Color(0xFFF97316);
        break;
      case "INSPECTION_COMPLETED":
        bg = const Color(0xFF14B8A6).withOpacity(0.15);
        fg = const Color(0xFF14B8A6);
        break;
      case "ACTION_NEEDED":
        bg = const Color(0xFFEF4444).withOpacity(0.15);
        fg = const Color(0xFFEF4444);
        break;
      default:
        bg = const Color(0xFF64748B).withOpacity(0.15);
        fg = const Color(0xFF94A3B8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status,
        style: GoogleFonts.montserrat(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFF334155))),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF38BDF8),
        indicatorWeight: 3,
        labelColor: const Color(0xFF38BDF8),
        unselectedLabelColor: const Color(0xFF94A3B8),
        labelStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(icon: Icon(Icons.calendar_today_outlined, size: 16), text: "1. APPOINTMENT"),
          Tab(icon: Icon(Icons.photo_camera_outlined, size: 16), text: "2. EVIDENCE PHOTOS"),
          Tab(icon: Icon(Icons.check_circle_outline, size: 16), text: "3. COMPLETION GATE"),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: SCHEDULE & STATUS FLOW
  // =========================================================================

  Widget _buildScheduleTab() {
    final status = _currentStatus;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null) ...[
            _buildErrorBanner(_errorMessage!),
            const SizedBox(height: 16),
          ],

          // Status Action Banner
          if (status == "ACTION_NEEDED") ...[
            _buildActionNeededBanner(),
            const SizedBox(height: 20),
          ],

          if (status == "ASSIGNED") ...[
            _buildScheduleForm(),
          ] else if (status == "INSPECTION_SCHEDULED") ...[
            _buildScheduledCard(),
          ] else if (status == "INSPECTION_IN_PROGRESS") ...[
            _buildInProgressCard(),
          ] else if (status == "INSPECTION_COMPLETED") ...[
            _buildCompletedCard(),
          ],

          const SizedBox(height: 24),
          const Divider(color: Color(0xFF334155)),
          const SizedBox(height: 12),

          // Reschedule history section
          _buildRescheduleHistorySection(),
        ],
      ),
    );
  }

  Widget _buildActionNeededBanner() {
    final reason = _inspectionSummary?['pauseReason'] ?? "Field Blocker";
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ASSIGNMENT PAUSED: ACTION NEEDED",
                  style: GoogleFonts.montserrat(color: const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  "Reason: $reason. SLA timer is currently frozen.",
                  style: GoogleFonts.inter(color: const Color(0xFFFCA5A5), fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow, size: 16),
            onPressed: _isProcessing ? null : _handleResumeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            label: const Text("RESUME ASSIGNMENT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SCHEDULE SITE APPOINTMENT",
          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Enter site visit date, time, and point of contact to transition to INSPECTION_SCHEDULED.",
          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInputField("Inspection Date (YYYY-MM-DD)*", _dateController, "e.g. 2026-10-15"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInputField("Inspection Time (HH:mm)*", _timeController, "e.g. 10:30"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInputField("Site Contact Name*", _contactNameController, "Contact Person"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInputField("Site Contact Number*", _contactPhoneController, "+91-9876543210"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInputField("Property Access Notes (Optional)", _accessNotesController, "Gate code, keyholder notes..."),
        const SizedBox(height: 20),
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              onPressed: _isProcessing ? null : _handleScheduleInspection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              label: Text(
                _isProcessing ? "SCHEDULING..." : "CONFIRM & SCHEDULE INSPECTION",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.pause, size: 16, color: Color(0xFFEF4444)),
              onPressed: _isProcessing ? null : _showReportBlockerDialog,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              label: const Text("REPORT BLOCKER (PAUSE)", style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduledCard() {
    final date = _inspectionSummary?['inspectionDate'] ?? _dateController.text;
    final time = _inspectionSummary?['inspectionTime'] ?? _timeController.text;
    final contact = _inspectionSummary?['siteContactName'] ?? _contactNameController.text;
    final phone = _inspectionSummary?['siteContactNumber'] ?? _contactPhoneController.text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available, color: Color(0xFF818CF8), size: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "INSPECTION CONFIRMED",
                    style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Date: $date at $time | Contact: $contact ($phone)",
                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.directions_walk, size: 16),
                onPressed: _isProcessing ? null : _handleStartInspection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                label: const Text("START INSPECTION (ON-SITE ARRIVAL)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_calendar, size: 16, color: Color(0xFF38BDF8)),
                onPressed: _isProcessing ? null : _showRescheduleDialog,
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF38BDF8))),
                label: const Text("RESCHEDULE", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.pause, size: 16, color: Color(0xFFEF4444)),
                onPressed: _isProcessing ? null : _showReportBlockerDialog,
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF4444))),
                label: const Text("REPORT BLOCKER", style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressCard() {
    final startedAt = _inspectionSummary?['startedAt'] ?? "In progress";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF97316).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timelapse, color: Color(0xFFF97316), size: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SITE INSPECTION IN PROGRESS",
                    style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Started: $startedAt | Capture evidence photos and remarks to proceed to completion.",
                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library, size: 16),
                onPressed: () => _tabController.animateTo(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                label: const Text("UPLOAD EVIDENCE PHOTOS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 16),
                onPressed: () => _tabController.animateTo(2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                label: const Text("GO TO COMPLETION GATE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.pause, size: 16, color: Color(0xFFEF4444)),
                onPressed: _isProcessing ? null : _showReportBlockerDialog,
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF4444))),
                label: const Text("REPORT BLOCKER", style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard() {
    final completedAt = _inspectionSummary?['completedAt'] ?? "Completed";
    final totalPhotos = _inspectionSummary?['totalPhotos'] ?? 0;
    final remarks = _inspectionSummary?['inspectionRemarks'] ?? "";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF14B8A6).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: Color(0xFF14B8A6), size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SITE INSPECTION COMPLETED",
                    style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Completed: $completedAt | Total Evidence: $totalPhotos photos",
                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          if (remarks.toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Remarks: $remarks",
                style: GoogleFonts.inter(color: const Color(0xFFCBD5E1), fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRescheduleHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "RESCHEDULE & AUDIT HISTORY",
          style: GoogleFonts.montserrat(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Every appointment reschedule is tracked with immutable audit logging. SLA does not reset on reschedule.",
          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 2: EVIDENCE PHOTOS
  // =========================================================================

  Widget _buildPhotosTab() {
    final List<dynamic> photos = _inspectionSummary?['photos'] ?? [];
    final List<dynamic> catStatuses = _inspectionSummary?['categoryStatuses'] ?? [];

    return Column(
      children: [
        // Category Checklist Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF0F172A),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "MANDATORY EVIDENCE CHECKLIST",
                    style: GoogleFonts.montserrat(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_currentStatus != "INSPECTION_COMPLETED")
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_a_photo, size: 15),
                      onPressed: _isProcessing ? null : _handlePickAndUploadPhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      label: const Text("UPLOAD PHOTO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Category pills
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: catStatuses.map<Widget>((cat) {
                  final bool satisfied = cat['satisfied'] == true;
                  final bool mandatory = cat['mandatory'] == true;
                  final int minReq = cat['minRequired'] ?? 0;
                  final int count = cat['currentCount'] ?? 0;
                  final String name = cat['displayName'] ?? cat['category'];

                  Color bg = satisfied
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : (mandatory ? const Color(0xFFF59E0B).withOpacity(0.15) : const Color(0xFF334155));
                  Color border = satisfied
                      ? const Color(0xFF10B981)
                      : (mandatory ? const Color(0xFFF59E0B) : const Color(0xFF475569));
                  Color fg = satisfied
                      ? const Color(0xFF10B981)
                      : (mandatory ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8));

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: border, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(satisfied ? Icons.check_circle : (mandatory ? Icons.circle_outlined : Icons.remove), size: 11, color: fg),
                        const SizedBox(width: 4),
                        Text(
                          "$name ($count${mandatory ? '/$minReq' : ''})",
                          style: GoogleFonts.inter(color: fg, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Photo Grid
        Expanded(
          child: photos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF475569), size: 48),
                      const SizedBox(height: 12),
                      Text("No photos uploaded yet.", style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13)),
                      const SizedBox(height: 4),
                      Text("Click 'Upload Photo' above to capture site evidence.", style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return _buildPhotoCard(photo);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard(dynamic photo) {
    final String category = photo['category'] ?? '';
    final String filename = photo['filename'] ?? '';
    final int photoId = photo['id'] ?? 0;
    final int orderId = photo['orderId'] ?? widget.orderId;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Container(
                color: const Color(0xFF1E293B),
                child: Center(
                  child: Image.network(
                    "/api/v1/orders/$orderId/inspection/photos/$photoId/download",
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: GoogleFonts.montserrat(color: const Color(0xFF38BDF8), fontSize: 8, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        filename,
                        style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 8),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_currentStatus != "INSPECTION_COMPLETED")
                  InkWell(
                    onTap: () => _handleDeletePhoto(photoId),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline, size: 14, color: Color(0xFFEF4444)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 3: COMPLETION GATE
  // =========================================================================

  Widget _buildCompletionTab() {
    final bool ready = _inspectionSummary?['readyForCompletion'] == true;
    final List<dynamic> catStatuses = _inspectionSummary?['categoryStatuses'] ?? [];
    final unfulfilledMandatory = catStatuses.where((c) => c['mandatory'] == true && c['satisfied'] != true).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "COMPLETION GATE VERIFICATION",
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "To mark inspection complete, all mandatory photo categories must be satisfied and inspection remarks must be recorded.",
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 11),
          ),
          const SizedBox(height: 16),

          // Readiness banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: unfulfilledMandatory.isEmpty ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFF59E0B).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: unfulfilledMandatory.isEmpty ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFF59E0B).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  unfulfilledMandatory.isEmpty ? Icons.verified : Icons.warning_amber_rounded,
                  color: unfulfilledMandatory.isEmpty ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    unfulfilledMandatory.isEmpty
                        ? "All mandatory photo categories satisfied! Ready for completion."
                        : "Missing evidence in ${unfulfilledMandatory.length} mandatory categories.",
                    style: GoogleFonts.inter(
                      color: unfulfilledMandatory.isEmpty ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Outcome dropdown
          Text("Visit Outcome*", style: GoogleFonts.montserrat(color: const Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedVisitStatus,
                dropdownColor: const Color(0xFF0F172A),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: "COMPLETED", child: Text("COMPLETED — Full Site Inspection", style: TextStyle(color: Colors.white, fontSize: 12))),
                  DropdownMenuItem(value: "PARTIAL", child: Text("PARTIAL — Incomplete Access / Partial Visit", style: TextStyle(color: Colors.white, fontSize: 12))),
                  DropdownMenuItem(value: "ABORTED", child: Text("ABORTED — Blocked / Cancelled", style: TextStyle(color: Colors.white, fontSize: 12))),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedVisitStatus = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Remarks field
          Text("Inspection Remarks (Min 20 characters)*", style: GoogleFonts.montserrat(color: const Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _remarksController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: "Enter detailed observations regarding structure, condition, boundaries, accessibility...",
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              fillColor: const Color(0xFF0F172A),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF334155))),
            ),
          ),
          const SizedBox(height: 24),

          if (_currentStatus != "INSPECTION_COMPLETED")
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, size: 18),
              onPressed: _isProcessing ? null : _handleCompleteInspection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              label: Text(
                _isProcessing ? "COMPLETING..." : "MARK INSPECTION AS COMPLETED",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // ACTIONS & HANDLERS
  // =========================================================================

  Future<void> _handleScheduleInspection() async {
    if (_dateController.text.trim().isEmpty || _timeController.text.trim().isEmpty ||
        _contactNameController.text.trim().isEmpty || _contactPhoneController.text.trim().isEmpty) {
      setState(() => _errorMessage = "All required fields marked with * must be provided.");
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final provider = Provider.of<OrderProvider>(context, listen: false);
    final result = await provider.scheduleInspection(
      widget.orderId,
      inspectionDate: _dateController.text.trim(),
      inspectionTime: _timeController.text.trim(),
      siteContactName: _contactNameController.text.trim(),
      siteContactNumber: _contactPhoneController.text.trim(),
      propertyAccessNotes: _accessNotesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (result != null) {
        widget.onStatusChanged?.call();
        await _loadInspectionData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Color(0xFF10B981), content: Text("Site inspection scheduled successfully!")),
        );
      } else {
        setState(() => _errorMessage = provider.lastError ?? "Failed to schedule inspection.");
      }
    }
  }

  Future<void> _handleStartInspection() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final provider = Provider.of<OrderProvider>(context, listen: false);
    final result = await provider.startInspection(widget.orderId, accessConfirmed: true);

    if (mounted) {
      setState(() => _isProcessing = false);
      if (result != null) {
        widget.onStatusChanged?.call();
        await _loadInspectionData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Color(0xFFF97316), content: Text("Inspection marked in progress!")),
        );
      } else {
        setState(() => _errorMessage = provider.lastError ?? "Failed to start inspection.");
      }
    }
  }

  Future<void> _handlePickAndUploadPhoto() async {
    // Show category selection first
    String chosenCategory = _selectedCategory;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Select Photo Category", style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 320,
          child: DropdownButtonFormField<String>(
            value: chosenCategory,
            dropdownColor: const Color(0xFF0F172A),
            items: _categories.map((c) => DropdownMenuItem(value: c['code'].toString(), child: Text(c['name'].toString(), style: const TextStyle(color: Colors.white, fontSize: 11)))).toList(),
            onChanged: (v) {
              if (v != null) chosenCategory = v;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, chosenCategory), child: const Text("PROCEED")),
        ],
      ),
    );

    if (selected == null) return;

    final fileResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (fileResult != null && fileResult.files.isNotEmpty) {
      final file = fileResult.files.first;
      if (file.bytes == null) return;

      setState(() => _isProcessing = true);
      final provider = Provider.of<OrderProvider>(context, listen: false);
      final uploadRes = await provider.uploadInspectionPhoto(
        widget.orderId,
        bytes: file.bytes!,
        filename: file.name,
        category: selected,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (uploadRes.success) {
          await _loadInspectionData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Color(0xFF10B981), content: Text("Photo uploaded successfully!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: const Color(0xFFEF4444), content: Text(uploadRes.errorMessage ?? "Upload failed")),
          );
        }
      }
    }
  }

  Future<void> _handleDeletePhoto(int photoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Photo Evidence", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to soft delete this photo?", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      final success = await provider.deleteInspectionPhoto(widget.orderId, photoId, reason: "Deleted by analyst");
      if (success) {
        await _loadInspectionData();
      }
    }
  }

  Future<void> _handleCompleteInspection() async {
    if (_remarksController.text.trim().length < 20) {
      setState(() => _errorMessage = "Remarks must be at least 20 characters long.");
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final provider = Provider.of<OrderProvider>(context, listen: false);
    final result = await provider.completeInspection(
      widget.orderId,
      inspectionRemarks: _remarksController.text.trim(),
      visitStatus: _selectedVisitStatus,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (result != null) {
        widget.onStatusChanged?.call();
        await _loadInspectionData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Color(0xFF14B8A6), content: Text("Site inspection completed successfully!")),
        );
      } else {
        setState(() => _errorMessage = provider.lastError ?? "Failed to complete inspection.");
      }
    }
  }

  Future<void> _handleResumeOrder() async {
    setState(() => _isProcessing = true);
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final success = await provider.resumeOrder(widget.orderId);

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        widget.onStatusChanged?.call();
        await _loadInspectionData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Color(0xFF10B981), content: Text("Order resumed to active status!")),
        );
      }
    }
  }

  void _showReportBlockerDialog() {
    String selectedReason = "SITE_LOCKED";
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text("Report Blocker (ACTION_NEEDED)", style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  dropdownColor: const Color(0xFF0F172A),
                  decoration: const InputDecoration(labelText: "Reason Code"),
                  items: const [
                    DropdownMenuItem(value: "SITE_LOCKED", child: Text("SITE_LOCKED — Property locked")),
                    DropdownMenuItem(value: "MISSING_DOCUMENTS", child: Text("MISSING_DOCUMENTS — Incomplete papers")),
                    DropdownMenuItem(value: "CLIENT_UNREACHABLE", child: Text("CLIENT_UNREACHABLE — Cannot reach contact")),
                    DropdownMenuItem(value: "WRONG_PROPERTY", child: Text("WRONG_PROPERTY — Address mismatch")),
                    DropdownMenuItem(value: "ACCESS_DENIED", child: Text("ACCESS_DENIED — Security / occupant denied")),
                    DropdownMenuItem(value: "NATURAL_OBSTRUCTION", child: Text("NATURAL_OBSTRUCTION — Flooding / road blocked")),
                  ],
                  onChanged: (v) {
                    if (v != null) setDlgState(() => selectedReason = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  decoration: const InputDecoration(
                    labelText: "Description",
                    hintText: "Explain the blocker in detail...",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () async {
                Navigator.pop(ctx);
                final provider = Provider.of<OrderProvider>(context, listen: false);
                await provider.pauseOrder(widget.orderId, selectedReason, description: descCtrl.text.trim());
                widget.onStatusChanged?.call();
                await _loadInspectionData();
              },
              child: const Text("PAUSE ORDER"),
            ),
          ],
        ),
      ),
    );
  }

  void _showRescheduleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Reschedule Site Inspection", style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInputField("New Inspection Date (YYYY-MM-DD)*", _rescheduleDateController, "e.g. 2026-10-18"),
              const SizedBox(height: 10),
              _buildInputField("New Inspection Time (HH:mm)*", _rescheduleTimeController, "e.g. 14:00"),
              const SizedBox(height: 10),
              _buildInputField("Reason for Reschedule*", _rescheduleReasonController, "Client requested date change..."),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () async {
              if (_rescheduleDateController.text.trim().isEmpty ||
                  _rescheduleTimeController.text.trim().isEmpty ||
                  _rescheduleReasonController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(ctx);
              final provider = Provider.of<OrderProvider>(context, listen: false);
              await provider.rescheduleInspection(
                widget.orderId,
                newInspectionDate: _rescheduleDateController.text.trim(),
                newInspectionTime: _rescheduleTimeController.text.trim(),
                rescheduleReason: _rescheduleReasonController.text.trim(),
              );
              widget.onStatusChanged?.call();
              await _loadInspectionData();
            },
            child: const Text("CONFIRM RESCHEDULE"),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(color: const Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            fillColor: const Color(0xFF0F172A),
            filled: true,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF334155))),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11))),
        ],
      ),
    );
  }
}
