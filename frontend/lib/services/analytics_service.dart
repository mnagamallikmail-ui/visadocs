import 'analytics_service_stub.dart'
    if (dart.library.html) 'analytics_service_web.dart';

/// Phase 4E: Authoritative Google Analytics 4 (GA4) Telemetry Service
/// Live Measurement ID: G-94DDGM6XDW
/// Emits route-based page_views and business-critical conversion telemetry.
class AnalyticsService {
  AnalyticsService._();

  static const String measurementId = 'G-94DDGM6XDW';

  /// Get the current window location or canonical fallback URL
  static String get currentUrl => getCurrentUrlWeb();

  /// Send a route-based page_view event to GA4
  static void trackPageView(String pagePath, [String? pageTitle]) {
    final title = pageTitle ?? _derivePageTitle(pagePath);
    trackPageViewWeb(pagePath, title);
  }

  /// General conversion / custom event dispatcher
  /// Enforces mandatory parameters: timestamp, service_type, page_url
  static void logEvent(
    String eventName, {
    required String serviceType,
    String? pageUrl,
    Map<String, dynamic>? additionalParams,
  }) {
    final params = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'service_type': serviceType,
      'page_url': pageUrl ?? getCurrentUrlWeb(),
      if (additionalParams != null) ...additionalParams,
    };
    trackEventWeb(eventName, params);
  }

  // ─── Business-Critical Conversion Events ───────────────────────────────────

  /// Event: lead_created
  static void logLeadCreated({
    required String serviceType,
    String? pageUrl,
    String? referenceCode,
    String? urgencySla,
    int? documentCount,
  }) {
    logEvent(
      'lead_created',
      serviceType: serviceType,
      pageUrl: pageUrl,
      additionalParams: {
        if (referenceCode != null) 'reference_code': referenceCode,
        if (urgencySla != null) 'urgency_sla': urgencySla,
        if (documentCount != null) 'document_count': documentCount,
      },
    );
  }

  /// Event: document_uploaded
  static void logDocumentUploaded({
    required String serviceType,
    String? pageUrl,
    String? fileName,
    int? count,
  }) {
    logEvent(
      'document_uploaded',
      serviceType: serviceType,
      pageUrl: pageUrl,
      additionalParams: {
        if (fileName != null) 'file_name': fileName,
        if (count != null) 'document_count': count,
      },
    );
  }

  /// Event: quote_requested
  static void logQuoteRequested({
    required String serviceType,
    String? pageUrl,
    String? mandatePurpose,
    String? valueBracket,
  }) {
    logEvent(
      'quote_requested',
      serviceType: serviceType,
      pageUrl: pageUrl,
      additionalParams: {
        if (mandatePurpose != null) 'mandate_purpose': mandatePurpose,
        if (valueBracket != null) 'value_bracket': valueBracket,
      },
    );
  }

  /// Event: quote_generated
  static void logQuoteGenerated({
    required String serviceType,
    String? pageUrl,
    required String quoteNumber,
    double? totalFee,
    int? slaDays,
  }) {
    logEvent(
      'quote_generated',
      serviceType: serviceType,
      pageUrl: pageUrl,
      additionalParams: {
        'quote_number': quoteNumber,
        if (totalFee != null) 'total_fee': totalFee,
        if (slaDays != null) 'turnaround_days': slaDays,
      },
    );
  }

  /// Event: status_changed
  static void logStatusChanged({
    required String serviceType,
    String? pageUrl,
    required String newStatus,
    String? referenceCode,
  }) {
    logEvent(
      'status_changed',
      serviceType: serviceType,
      pageUrl: pageUrl,
      additionalParams: {
        'new_status': newStatus,
        if (referenceCode != null) 'reference_code': referenceCode,
      },
    );
  }

  /// Event: contact_form_submitted
  static void logContactFormSubmitted({
    required String serviceType,
    String? pageUrl,
    String? channel,
  }) {
    logEvent(
      'contact_form_submitted',
      serviceType: serviceType,
      pageUrl: pageUrl,
      additionalParams: {
        if (channel != null) 'preferred_channel': channel,
      },
    );
  }

  /// Event: phone_clicked
  static void logPhoneClicked({
    required String serviceType,
    String? pageUrl,
    required String phoneNumber,
  }) {
    logEvent(
      'phone_clicked',
      serviceType: serviceType,
      pageUrl: pageUrl,
      additionalParams: {
        'phone_number': phoneNumber,
      },
    );
  }

  /// Event: email_clicked
  static void logEmailClicked({
    required String serviceType,
    String? pageUrl,
    required String emailAddress,
  }) {
    logEvent(
      'email_clicked',
      serviceType: serviceType,
      pageUrl: pageUrl,
      additionalParams: {
        'email_address': emailAddress,
      },
    );
  }

  /// Event: whatsapp_clicked
  static void logWhatsAppClicked({
    required String serviceType,
    String? pageUrl,
    required String whatsappTarget,
  }) {
    logEvent(
      'whatsapp_clicked',
      serviceType: serviceType,
      pageUrl: pageUrl,
      additionalParams: {
        'whatsapp_target': whatsappTarget,
      },
    );
  }

  /// Event: service_page_view
  static void logServicePageView({
    String? serviceTitle,
    required String serviceType,
    required String pageUrl,
  }) {
    logEvent(
      'service_page_view',
      serviceType: serviceType,
      pageUrl: pageUrl,
      additionalParams: serviceTitle != null ? {'service_title': serviceTitle} : null,
    );
  }

  /// Event: knowledge_article_view
  static void logKnowledgeArticleView({
    required String articleTitle,
    required String pageUrl,
    String? serviceType,
    String? category,
  }) {
    logEvent(
      'knowledge_article_view',
      serviceType: serviceType ?? 'KNOWLEDGE_BASE',
      pageUrl: pageUrl,
      additionalParams: {
        'article_title': articleTitle,
        if (category != null) 'category': category,
      },
    );
  }

  static String _derivePageTitle(String path) {
    if (path == '/') return 'Homepage | ProValuer Commercial';
    if (path == '/government-approved-valuers') return 'Government Approved Valuers | ProValuer';
    if (path.startsWith('/services/')) {
      final slug = path.replaceFirst('/services/', '');
      final formatted = slug.split('-').map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '').join(' ');
      return '$formatted Valuation | ProValuer Commercial';
    }
    if (path == '/login') return 'Account Sign In | ProValuer';
    if (path == '/client') return 'Client Mandate Dashboard | ProValuer';
    if (path == '/pa') return 'Partner Appraiser Dashboard | ProValuer';
    if (path == '/spa') return 'Senior Partner Review Dashboard | ProValuer';
    if (path == '/admin') return 'Super Admin Governance Console | ProValuer';
    if (path.startsWith('/admin/')) {
      final sub = path.replaceFirst('/admin/', '');
      return '${sub.toUpperCase()} | Admin Console';
    }
    return 'ProValuer Commercial';
  }
}
