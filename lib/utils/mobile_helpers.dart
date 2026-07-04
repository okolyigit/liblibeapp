void hideWebLoadingScreen() {
  // No-op on mobile
}

void upgradeWebCameraResolution() {
  // No-op on mobile — mobile_scanner honours cameraResolution natively.
}

void resetWebViewport() {
  // No-op on mobile
}

Function? onWebKeyboardClose(void Function() onKeyboardClosed) {
  // No-op on mobile
  return null;
}
