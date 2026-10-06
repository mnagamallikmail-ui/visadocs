// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void setupBeforeUnloadProtection(bool Function() shouldWarn) {
  try {
    html.window.onBeforeUnload.listen((event) {
      if (shouldWarn()) {
        (event as html.BeforeUnloadEvent).returnValue =
            'You have unsaved changes. Leaving now may interrupt synchronization.';
      }
    });
  } catch (_) {}
}
