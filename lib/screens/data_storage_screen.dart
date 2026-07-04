import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../services/book_service.dart';
import '../widgets/app_notification.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/neon_gradient_button.dart';

class DataStorageScreen extends StatefulWidget {
  const DataStorageScreen({super.key});

  @override
  State<DataStorageScreen> createState() => _DataStorageScreenState();
}

class _DataStorageScreenState extends State<DataStorageScreen> {
  final _bookService = BookService();
  bool _isProcessing = false;

  Future<void> _handleEnrichData() async {
    final confirm = await showGlassConfirmDialog(
      context: context,
      title: "Verileri Güncelle",
      message:
          "Bu işlem tüm kitaplarınızı tarayarak eksik bilgileri (kapak resmi, sayfa sayısı vb.) Google Books üzerinden tamamlamaya çalışır. İnternet bağlantısı gerektirir ve kütüphane boyutuna göre zaman alabilir.",
      icon: PhosphorIconsRegular.magicWand,
      confirmText: "Güncelle",
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    // Show progress dialog
    if (!mounted) return;
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _ProgressDialog(
          stream: (onProgress) =>
              _bookService.enrichBookData(onProgress: onProgress),
        ),
      ).then((_) {
        if (mounted) {
          setState(() => _isProcessing = false);
          AppNotification.success(context, 'Veri güncelleme tamamlandı!');
        }
      }),
    );
  }

  Future<void> _handleResetLibrary() async {
    final confirm = await showGlassDialog<bool>(
      context: context,
      title: "Kütüphaneyi Sıfırla",
      icon: PhosphorIconsRegular.warningCircle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DİKKAT! Bu işlem geri alınamaz.",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 12),
          const Text("Aşağıdaki tüm veriler kalıcı olarak silinecektir:"),
          const SizedBox(height: 8),
          _buildBulletPoint("Tüm kitaplarınız"),
          _buildBulletPoint("Okuma listeleriniz"),
          _buildBulletPoint("Okuma geçmişiniz (Takvim verileri)"),
          _buildBulletPoint("Favorileriniz"),
          _buildBulletPoint("Kitap notlarınız ve ilerleme durumlarınız"),
        ],
      ),
      cancelText: "Vazgeç",
      confirmText: "Sıfırla ve Sil",
      isDestructive: true,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );

    if (confirm != true) return;

    // Second confirmation for safety
    if (!mounted) return;
    final doubleConfirm = await showGlassConfirmDialog(
      context: context,
      title: "Son Karar",
      message: "Tüm kütüphaneniz tamamen boşaltılacak. Emin misiniz?",
      icon: PhosphorIconsRegular.warningCircle,
      cancelText: "Hayır",
      confirmText: "Evet, Hepsini Sil",
      isDestructive: true,
    );

    if (doubleConfirm != true) return;

    setState(() => _isProcessing = true);

    try {
      await _bookService.deleteAllUserData();
      if (mounted) {
        AppNotification.success(context, 'Kütüphane başarıyla sıfırlandı.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.error(context, 'Hata oluştu: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Veri ve Depolama",
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textLightPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: BackButton(
          color: isDark ? Colors.white : AppColors.textLightPrimary,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, "Veri İyileştirme"),
            _buildActionCard(
              context,
              icon: PhosphorIconsRegular.magicWand,
              title: "Kitap Verilerini Güncelle",
              description:
                  "ISBN numarası olan kitaplarınızın kapak resmi ve diğer eksik bilgilerini internetten bulup tamamlar.",
              buttonText: "Verileri Güncelle",
              onTap: _isProcessing ? null : _handleEnrichData,
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(context, "Tehlikeli Bölge", isDanger: true),
            _buildActionCard(
              context,
              icon: PhosphorIconsRegular.trash,
              title: "Kütüphaneyi Sıfırla",
              description:
                  "Tüm kitaplarınızı, listelerinizi ve okuma geçmişinizi kalıcı olarak siler ve hesabınızı başlangıç durumuna döndürür.",
              buttonText: "Kütüphaneyi Sıfırla",
              isDestructive: true,
              onTap: _isProcessing ? null : _handleResetLibrary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    bool isDanger = false,
  }) {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: isDanger
              ? Colors.red
              : (isDark ? Colors.white70 : AppColors.textLightSecondary),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: isDestructive
            ? Border.all(color: Colors.red.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withValues(alpha: 0.1)
                      : context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? Colors.red : context.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textLightPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.white70 : AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: NeonGradientButton(
              text: buttonText,
              isDestructive: isDestructive,
              onPressed: onTap ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDialog extends StatefulWidget {
  final Future<void> Function(Function(int, int, String) onProgress) stream;

  const _ProgressDialog({required this.stream});

  @override
  State<_ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  int _current = 0;
  int _total = 0;
  String _status = "Başlatılıyor...";

  @override
  void initState() {
    super.initState();
    _startProcess();
  }

  void _startProcess() {
    widget
        .stream((current, total, status) {
          if (mounted) {
            setState(() {
              _current = current;
              _total = total;
              _status = status;
            });
          }
        })
        .then((_) {
          if (mounted) {
            Navigator.pop(context);
          }
        })
        .catchError((e) {
          if (mounted) {
            Navigator.pop(context);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return AlertDialog(
      backgroundColor: context.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            "$_current / $_total",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textLightPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
