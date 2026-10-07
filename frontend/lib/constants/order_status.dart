/// Canonical Single Source of Truth for Order Statuses across ProValuer Frontend.
class OrderStatus {
  // Intake & Quote
  static const String draft = 'DRAFT';
  static const String quotePending = 'QUOTE_PENDING';
  static const String quoteProvided = 'QUOTE_PROVIDED';

  // Payment Lifecycle
  static const String paymentSubmitted = 'PAYMENT_SUBMITTED';
  static const String paymentVerified = 'PAYMENT_VERIFIED';
  static const String paymentRejected = 'PAYMENT_REJECTED';
  static const String paidIntake = 'PAID_INTAKE';

  // Valuation Workspace & Drafting
  static const String assigned = 'ASSIGNED';
  static const String workspaceReady = 'WORKSPACE_READY';
  static const String drafting = 'DRAFTING';
  static const String actionNeeded = 'ACTION_NEEDED';

  // SPA Review & Quality Gate
  static const String spaReview = 'SPA_REVIEW';
  static const String spaGate = 'SPA_GATE';
  static const String spaConfirmed = 'SPA_CONFIRMED';

  // Delivery & Client Lifecycle
  static const String onHoldPaymentPending = 'ON_HOLD_PAYMENT_PENDING';
  static const String deliveryReady = 'DELIVERY_READY';
  static const String finalDelivery = 'FINAL_DELIVERY';
  static const String clientDownloaded = 'CLIENT_DOWNLOADED';
  static const String deliveryDisputed = 'DELIVERY_DISPUTED';
  static const String closed = 'CLOSED';

  // Sets of states
  static const Set<String> deliveryStates = {
    finalDelivery,
    clientDownloaded,
    closed,
  };

  static const Set<String> openKpiStates = {
    paidIntake,
    assigned,
    workspaceReady,
    drafting,
    actionNeeded,
    spaReview,
    spaGate,
    spaConfirmed,
    paymentRejected,
    onHoldPaymentPending,
    deliveryReady,
  };

  /// Returns true if the order is in a delivery / completed state where download is allowed.
  static bool isDelivered(String? status) {
    if (status == null) return false;
    return deliveryStates.contains(status.trim().toUpperCase());
  }

  /// Alias for isDelivered, confirming the report is finalized and completed.
  static bool isCompleted(String? status) {
    if (status == null) return false;
    return deliveryStates.contains(status.trim().toUpperCase());
  }

  /// Checks if status is open/active
  static bool isOpen(String? status) {
    if (status == null) return false;
    return openKpiStates.contains(status.trim().toUpperCase());
  }
}
