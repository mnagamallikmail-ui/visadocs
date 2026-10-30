// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation of the GA4 Telemetry bridge via window.proValuerTrackEvent
void trackEventWeb(String eventName, Map<String, dynamic> params) {
  try {
    if (js.context.hasProperty('proValuerTrackEvent')) {
      js.context.callMethod('proValuerTrackEvent', [eventName, js.JsObject.jsify(params)]);
    }
  } catch (_) {}
}

void trackPageViewWeb(String pagePath, String pageTitle) {
  try {
    if (js.context.hasProperty('proValuerTrackPageView')) {
      js.context.callMethod('proValuerTrackPageView', [pagePath, pageTitle]);
    }
  } catch (_) {}
}

String getCurrentUrlWeb() {
  try {
    return html.window.location.href;
  } catch (_) {
    return 'https://www.provaluer.in/';
  }
}
