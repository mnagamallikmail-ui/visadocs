import 'package:flutter/material.dart';
import 'valuation_model.dart';

class ValuationRepository extends ChangeNotifier {
  bool useMockData = true;

  final List<ValuationRequest> _mockRequests = [
    ValuationRequest(
      id: "VAL-2026-001",
      clientName: "Reliance Industries Ltd.",
      propertyType: "Industrial Land and Building",
      customPropertyType: null,
      purpose: "For loan availing purpose",
      submissionDate: DateTime.now().subtract(const Duration(days: 3)),
      status: "IN_PROGRESS",
      uploadedDocs: {
        "Sale Deed or other Title Deed": "reliance_factory_deed.pdf",
        "Approved Plan": "factory_layout_approved.pdf",
        "Occupancy Certificate": "occupancy_certificate_phase1.pdf",
        "Copy of the latest Property Tax Paid Receipt": "property_tax_receipt_2025.pdf",
        "Copy of latest Electricity Bill": "electricity_bill_april2026.pdf",
      },
    ),
    ValuationRequest(
      id: "VAL-2026-002",
      clientName: "Adani Enterprises",
      propertyType: "Open Land",
      customPropertyType: null,
      purpose: "For income tax purpose",
      submissionDate: DateTime.now().subtract(const Duration(days: 5)),
      status: "COMPLETED",
      uploadedDocs: {
        "Sale Deed or other Title Deed": "adani_port_land_deed.pdf",
        "Approved Plan": "site_master_plan.pdf",
        "Copy of the latest Property Tax Paid Receipt": "land_tax_receipt.pdf",
      },
    ),
    ValuationRequest(
      id: "VAL-2026-003",
      clientName: "GMR Hyderabad International Airport",
      propertyType: "Others",
      customPropertyType: "Airport Commercial Terminal Complex",
      purpose: "For loan availing purpose",
      submissionDate: DateTime.now().subtract(const Duration(hours: 18)),
      status: "PENDING",
      uploadedDocs: {
        "Sale Deed or other Title Deed": "gmr_terminal3_deed.pdf",
        "Approved Plan": "terminal_expansion_plan.pdf",
      },
    ),
    ValuationRequest(
      id: "VAL-2026-004",
      clientName: "Tata Consultancy Services Ltd",
      propertyType: "Office Complex",
      customPropertyType: null,
      purpose: "For personal use",
      submissionDate: DateTime.now().subtract(const Duration(days: 1)),
      status: "PENDING",
      uploadedDocs: {
        "Sale Deed or other Title Deed": "tcs_synergy_park_deed.pdf",
        "Approved Plan": "campus_blueprint.pdf",
        "Occupancy Certificate": "oc_tcs_block_a.pdf",
        "Copy of the latest Property Tax Paid Receipt": "tax_receipt_tcs_2026.pdf",
      },
    ),
  ];

  final List<ValuationRequest> _customRequests = [];

  List<ValuationRequest> get requests {
    if (useMockData) {
      return [..._customRequests, ..._mockRequests];
    } else {
      return _customRequests;
    }
  }

  void submitRequest(ValuationRequest request) {
    _customRequests.insert(0, request);
    notifyListeners();
  }

  void updateRequestStatus(String id, String status) {
    final index = _customRequests.indexWhere((r) => r.id == id);
    if (index != -1) {
      _customRequests[index] = _customRequests[index].copyWith(status: status);
      notifyListeners();
      return;
    }

    final mockIndex = _mockRequests.indexWhere((r) => r.id == id);
    if (mockIndex != -1) {
      _mockRequests[mockIndex] = _mockRequests[mockIndex].copyWith(status: status);
      notifyListeners();
    }
  }
}
