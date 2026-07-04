import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../utils/web_helpers.dart'
    if (dart.library.io) '../utils/mobile_helpers.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8],
    // Request high resolution for better scanning (especially on web)
    cameraResolution: const Size(1920, 1080),
  );

  bool _isTorchOn = false;
  String? _scannedBarcode;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // mobile_scanner doesn't pass a resolution to getUserMedia on web, so
      // the browser starts a low-res (blurry) stream. Re-negotiate the live
      // track to a higher resolution once the preview <video> is attached —
      // retried a few times because the element appears asynchronously.
      for (final delayMs in const [600, 1400, 2600]) {
        Timer(Duration(milliseconds: delayMs), () {
          if (mounted) upgradeWebCameraResolution();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(String barcodeValue) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _scannedBarcode = barcodeValue;
    });

    unawaited(_controller.stop());

    // Wait 2 seconds so user can see what was scanned
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context, barcodeValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Camera preview + the scan-area overlay, kept together so the cutout
    // always lines up with the feed.
    final scannerView = Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          // Mobile: cover fills the screen. Web: contain shows the *whole*
          // camera frame un-cropped, so what the user aligns to the cutout is
          // exactly what the detector sees (cover would zoom/crop the preview
          // and throw away the horizontal pixels an EAN barcode needs).
          fit: kIsWeb ? BoxFit.contain : BoxFit.cover,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _handleBarcodeDetected(barcode.rawValue!);
                break;
              }
            }
          },
        ),
        // Dark overlay with cutout
        CustomPaint(
          size: Size.infinite,
          painter: _ScannerOverlayPainter(
            scanAreaWidth: 320,
            scanAreaHeight: 180,
            overlayColor: Colors.black.withValues(alpha: 0.6),
            borderColor: _scannedBarcode != null
                ? Colors.green
                : context.primaryColor,
            borderWidth: _scannedBarcode != null ? 3 : 2,
            borderRadius: 16,
          ),
        ),
      ],
    );

    // On web the preview is left unconstrained by default, so it fills the
    // (often very wide) browser window. BoxFit.cover then blows the feed up
    // and the barcode ends up too small/low-res in the frame to decode.
    // Constrain it to a sensible, centered box on web; keep full-screen on
    // mobile where it already works well.
    final Widget cameraArea = kIsWeb
        ? ConstrainedBox(
            // Landscape box matching a typical webcam's 4:3 frame so the
            // horizontal barcode keeps its full width (= more bars/pixels to
            // decode). Roomy enough to stay sharp without filling the window.
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 540),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: scannerView,
              ),
            ),
          )
        : scannerView;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.x, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Barkod Tara', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn
                  ? PhosphorIconsFill.lightning
                  : PhosphorIconsRegular.lightning,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
              _controller.toggleTorch();
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(child: Center(child: cameraArea)),
          // Green overlay when scanned
          if (_scannedBarcode != null)
            Center(
              child: Container(
                width: 320,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          // Scanned Barcode Display
          if (_scannedBarcode != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIconsBold.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Barkod Okundu!',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _scannedBarcode!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Instruction Text (only show if not scanned)
          if (_scannedBarcode == null)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Barkodu çerçevenin içine hizalayın',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for scanner overlay with cutout effect
class _ScannerOverlayPainter extends CustomPainter {
  final double scanAreaWidth;
  final double scanAreaHeight;
  final Color overlayColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  _ScannerOverlayPainter({
    required this.scanAreaWidth,
    required this.scanAreaHeight,
    required this.overlayColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Calculate scan area rect
    final scanRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: scanAreaWidth,
        height: scanAreaHeight,
      ),
      Radius.circular(borderRadius),
    );

    // Draw dark overlay with cutout
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(scanRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, Paint()..color = overlayColor);

    // Draw border around scan area
    canvas.drawRRect(
      scanRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    // Draw corner accents
    const cornerLength = 24.0;
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + 2
      ..strokeCap = StrokeCap.round;

    final left = center.dx - scanAreaWidth / 2;
    final right = center.dx + scanAreaWidth / 2;
    final top = center.dy - scanAreaHeight / 2;
    final bottom = center.dy + scanAreaHeight / 2;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top + borderRadius),
      Offset(left, top + borderRadius + cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + borderRadius, top),
      Offset(left + borderRadius + cornerLength, top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(right, top + borderRadius),
      Offset(right, top + borderRadius + cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(right - borderRadius, top),
      Offset(right - borderRadius - cornerLength, top),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, bottom - borderRadius),
      Offset(left, bottom - borderRadius - cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + borderRadius, bottom),
      Offset(left + borderRadius + cornerLength, bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(right, bottom - borderRadius),
      Offset(right, bottom - borderRadius - cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(right - borderRadius, bottom),
      Offset(right - borderRadius - cornerLength, bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanAreaWidth != scanAreaWidth ||
        oldDelegate.scanAreaHeight != scanAreaHeight ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
