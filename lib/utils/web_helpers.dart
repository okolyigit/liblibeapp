import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void hideWebLoadingScreen() {
  try {
    globalContext.callMethod('hideLoadingScreen'.toJS);
  } catch (_) {
    // ignore
  }
}

void resetWebViewport() {
  try {
    globalContext.callMethod('scrollTo'.toJS, 0.toJS, 0.toJS);
  } catch (_) {
    // ignore
  }
}

/// Bumps the resolution of the live camera track behind the barcode scanner.
///
/// mobile_scanner's web implementation calls `getUserMedia` with only a
/// `facingMode` constraint (no width/height — verified in its source through
/// v7.2.0), so the browser hands back its low default resolution (often
/// 640×480). That looks blurry when scaled up and rarely has enough pixels
/// across an EAN-13 barcode to decode. Here we reach the preview's `<video>`
/// element and re-negotiate the track to a high resolution via
/// `applyConstraints`. Best-effort: silently no-ops if the element/stream
/// isn't ready yet (call it again shortly after the scanner starts).
void upgradeWebCameraResolution() {
  try {
    final document = globalContext.getProperty<JSObject>('document'.toJS);
    final videos = document.callMethod<JSObject>(
      'querySelectorAll'.toJS,
      'video'.toJS,
    );
    final count = videos.getProperty<JSNumber>('length'.toJS).toDartInt;
    for (var i = 0; i < count; i++) {
      final video = videos.callMethod<JSObject?>('item'.toJS, i.toJS);
      final stream = video?.getProperty<JSObject?>('srcObject'.toJS);
      if (stream == null) continue;
      final tracks = stream.callMethod<JSObject>('getVideoTracks'.toJS);
      final trackCount = tracks.getProperty<JSNumber>('length'.toJS).toDartInt;
      for (var t = 0; t < trackCount; t++) {
        final track = tracks.getProperty<JSObject?>(t.toJS);
        if (track == null) continue;
        final width = JSObject()..setProperty('ideal'.toJS, 1920.toJS);
        final height = JSObject()..setProperty('ideal'.toJS, 1080.toJS);
        final constraints = JSObject()
          ..setProperty('width'.toJS, width)
          ..setProperty('height'.toJS, height);
        track.callMethod<JSAny?>('applyConstraints'.toJS, constraints);
      }
    }
  } catch (_) {
    // Best-effort; ignore if the DOM/stream isn't available.
  }
}

/// Polls a JS flag set by the visualViewport.resize handler in index.html.
/// When the flag is true (keyboard just closed), calls [onKeyboardClosed].
/// Returns a cleanup function to stop polling.
Function? onWebKeyboardClose(void Function() onKeyboardClosed) {
  final timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
    try {
      final closed = globalContext.getProperty<JSAny?>('__keyboardClosed'.toJS);
      if (closed != null &&
          closed.isA<JSBoolean>() &&
          (closed as JSBoolean).toDart) {
        globalContext.setProperty('__keyboardClosed'.toJS, false.toJS);
        onKeyboardClosed();
      }
    } catch (_) {
      // ignore
    }
  });

  return () => timer.cancel();
}
