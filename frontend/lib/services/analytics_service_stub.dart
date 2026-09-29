/// Analytics Stub Implementation for non-web environments (e.g. Flutter tests / VM)

void trackEventWeb(String eventName, Map<String, dynamic> params) {
  // No-op in VM / test runner
}

void trackPageViewWeb(String pagePath, String pageTitle) {
  // No-op in VM / test runner
}

String getCurrentUrlWeb() {
  return 'https://www.provaluer.in/';
}
