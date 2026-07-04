import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../widgets/error_state_view.dart';
import '../widgets/admin_stat_card.dart';

/// "İstatistikler" admin tab: detailed totals — users / libraries / books and
/// premium users — fetched from the admin-only `getAdminStats` Cloud Function
/// (counts can't be done client-side; security rules block listing those
/// collections).
class AdminStatsTab extends StatefulWidget {
  const AdminStatsTab({super.key});

  @override
  State<AdminStatsTab> createState() => _AdminStatsTabState();
}

class _AdminStatsTabState extends State<AdminStatsTab> {
  bool _loading = true;
  Object? _error;
  int _users = 0;
  int _libraries = 0;
  int _books = 0;
  int _premiumUsers = 0;

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
        _premiumUsers = (data['premiumUsers'] as num?)?.toInt() ?? 0;
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorStateView(
        message: 'İstatistikler yüklenemedi',
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
            AdminStatCard(
              icon: PhosphorIconsFill.users,
              label: 'Toplam Kullanıcı',
              value: _users,
            ),
            const SizedBox(height: 16),
            AdminStatCard(
              icon: PhosphorIconsFill.star,
              label: 'Premium Kullanıcı',
              value: _premiumUsers,
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
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(PhosphorIconsRegular.arrowClockwise, size: 18),
                label: const Text('Yenile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
