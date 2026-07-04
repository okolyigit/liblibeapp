import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/migration_service.dart';
import '../theme/theme.dart';
import 'neon_gradient_button.dart';

/// Shows a dialog to migrate user reading progress from books to user_progress collection
class MigrationHelper {
  static Future<void> checkAndShowMigrationDialog(BuildContext context) async {
    try {
      final migrationService = MigrationService();

      // Check if migration is needed
      final stats = await migrationService.getMigrationStats();
      final needsMigration = stats['needsMigration'] ?? 0;

      if (needsMigration > 0 && context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _MigrationDialog(
            needsMigration: needsMigration,
            total: stats['total'] ?? 0,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking migration: $e');
    }
  }
}

class _MigrationDialog extends StatefulWidget {
  final int needsMigration;
  final int total;

  const _MigrationDialog({required this.needsMigration, required this.total});

  @override
  State<_MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends State<_MigrationDialog> {
  bool _isMigrating = false;
  String _currentStatus = '';
  int _migratedCount = 0;
  bool _isDone = false;

  Future<void> _runMigration() async {
    setState(() {
      _isMigrating = true;
      _currentStatus = 'Başlatılıyor...';
    });

    try {
      final result = await MigrationService().migrateUserProgress(
        onProgress: (status) {
          if (mounted) {
            setState(() {
              _currentStatus = status;
              _migratedCount++;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDone = true;
          _currentStatus = '${result['migrated']} kitap taşındı!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMigrating = false;
          _currentStatus = 'Hata: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return AlertDialog(
      backgroundColor: isDark ? context.surfaceColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            _isDone
                ? PhosphorIconsFill.checkCircle
                : PhosphorIconsRegular.database,
            color: _isDone ? Colors.green : context.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isDone ? 'Tamamlandı!' : 'Veri Güncelleme',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textLightPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isMigrating && !_isDone) ...[
            Text(
              'Okuma ilerlemeniz yeni sisteme taşınacak.',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.info,
                    color: context.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.needsMigration} kitabın okuma durumu taşınacak',
                      style: TextStyle(
                        color: context.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (_isMigrating && !_isDone)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: widget.needsMigration > 0
                        ? _migratedCount / widget.needsMigration
                        : null,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                    color: context.primaryColor,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            Text(
              _currentStatus,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textLightSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isMigrating && !_isDone) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Sonra',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ),
          NeonGradientButton(
            onPressed: _runMigration,
            text: 'Başlat',
            width: 100,
            height: 40,
          ),
        ],
        if (_isDone)
          NeonGradientButton(
            onPressed: () => Navigator.pop(context),
            text: 'Tamam',
            width: 100,
            height: 40,
          ),
      ],
    );
  }
}
