import 'package:flutter/material.dart';
import '../valuation/valuation_model.dart';

class PortalMockRepository extends ChangeNotifier {
  final List<ValuationRequest> _requests = [
    ValuationRequest(
      id: "VAL-2026-101",
      clientName: "Oberoi Realty Ltd.",
      propertyType: "Residential Flat",
      customPropertyType: null,
      purpose: "For loan availing purpose",
      submissionDate: DateTime.now().subtract(const Duration(days: 2)),
      status: "IN_PROGRESS",
      uploadedDocs: {
        "Sale/Title Deed": "oberoi_garden_deed.pdf",
        "Approved Plan": "tower_c_approved_plan.pdf",
        "Occupancy Certificate": "tower_c_oc.pdf",
        "Property Tax Paid Receipt": "tax_receipt_2025_26.pdf",
        "Electricity Bill": "elect_bill_april.pdf",
      },
    ),
    ValuationRequest(
      id: "VAL-2026-102",
      clientName: "Godrej Properties",
      propertyType: "Open Land",
      customPropertyType: null,
      purpose: "For income tax purpose",
      submissionDate: DateTime.now().subtract(const Duration(days: 4)),
      status: "COMPLETED",
      uploadedDocs: {
        "Sale/Title Deed": "godrej_vikhroli_deed.pdf",
        "Approved Plan": "vikhroli_layout.pdf",
        "Occupancy Certificate": "oc_godrej_site.pdf",
        "Property Tax Paid Receipt": "tax_godrej_receipt.pdf",
        "Electricity Bill": "elect_godrej_bill.pdf",
      },
    ),
    ValuationRequest(
      id: "VAL-2026-103",
      clientName: "L&T Realty",
      propertyType: "Others",
      customPropertyType: "Commercial IT Park Block",
      purpose: "Visa Purpose",
      submissionDate: DateTime.now().subtract(const Duration(hours: 12)),
      status: "PENDING",
      uploadedDocs: {
        "Sale/Title Deed": "lt_gate_deed.pdf",
        "Approved Plan": "it_park_plan_rev3.pdf",
      },
    ),
  ];

  List<ValuationRequest> get requests => _requests;

  void addRequest(ValuationRequest request) {
    _requests.insert(0, request);
    notifyListeners();
  }

  void updateStatus(String id, String newStatus) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void deleteRequest(String id) {
    _requests.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
