import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../services/auth_service.dart';
import '../../../theme/theme.dart';
import '../../../widgets/error_state_view.dart';
import '../widgets/admin_stat_card.dart';

/// "Ana Sayfa" admin tab: a short welcome plus the three headline totals
/// (users / libraries / books). Detailed breakdown lives in the İstatistikler
/// tab.
class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  bool _loading = true;
  Object? _error;
  int _users = 0;
  int _libraries = 0;
  int _books = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('getAdminStats')
          .call();
      final data = Map<String, dynamic>.from(result.data as Map);
      if (!mounted) return;
      setState(() {
        _users = (data['users'] as num?)?.toInt() ?? 0;
        _libraries = (data['libraries'] as num?)?.toInt() ?? 0;
        _books = (data['books'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final email = AuthService().currentUser?.email ?? '';

    if (_error != null && !_loading) {
      return ErrorStateView(
        message: 'Veriler yüklenemedi',
        detail: '$_error',
        onRetry: _load,
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Hoş geldiniz',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textLightPrimary,
              ),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              AdminStatCard(
                icon: PhosphorIconsFill.users,
                label: 'Toplam Kullanıcı',
                value: _users,
              ),
              const SizedBox(height: 16),
              AdminStatCard(
                icon: PhosphorIconsFill.books,
                label: 'Toplam Kütüphane',
                value: _libraries,
              ),
              const SizedBox(height: 16),
              AdminStatCard(
                icon: PhosphorIconsFill.bookOpen,
                label: 'Toplam Kitap',
                value: _books,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
