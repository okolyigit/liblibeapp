import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../theme/theme.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/app_notification.dart';
import '../../widgets/error_state_view.dart';

/// Admin-only user detail & management. Shows metadata + counts (KVKK: NO
/// content — never the user's book titles / list contents), premium dates, and
/// actions (edit name, send password reset, change role, set premium end,
/// delete). All mutations go through admin-only Cloud Functions.
class AdminUserDetailScreen extends StatefulWidget {
  final String uid;

  /// Web dashboard embeds this in the content area: [onBack] returns to the
  /// users list (kept visible behind the sidebar/top bar) and [onChanged] asks
  /// the list to refresh after a mutation. On mobile both are null (pushed
  /// route → pops with a `true` result when something changed).
  final VoidCallback? onBack;
  final VoidCallback? onChanged;

  const AdminUserDetailScreen({
    super.key,
    required this.uid,
    this.onBack,
    this.onChanged,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  // Admin is a single, console-managed account — not assignable from the app.
  static const _roles = ['user', 'premium'];

  bool _loading = true;
  bool _busy = false;
  bool _didChange = false;
  Object? _error;
  Map<String, dynamic> _data = {};

  /// Notify the embedding list (web) and remember for the mobile pop result.
  void _markChanged() {
    _didChange = true;
    widget.onChanged?.call();
  }

  void _back() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.pop(context, _didChange);
    }
  }

  FirebaseFunctions get _fns =>
      FirebaseFunctions.instanceFor(region: 'europe-west3');

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
      final res = await _fns
          .httpsCallable('getUserDetails')
          .call({'uid': widget.uid});
      if (!mounted) return;
      setState(() {
        _data = Map<String, dynamic>.from(res.data as Map);
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

  String _fmtDate(int? millis, {bool withTime = false}) {
    if (millis == null) return '—';
    final d = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${two(d.day)}.${two(d.month)}.${d.year}';
    return withTime ? '$date ${two(d.hour)}:${two(d.minute)}' : date;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setRole(String role, {int? premiumEndMillis}) => _run(() async {
    try {
      await _fns.httpsCallable('setUserRole').call({
        'uid': widget.uid,
        'role': role,
        if (premiumEndMillis != null) 'premiumEndMillis': premiumEndMillis,
      });
      if (mounted) AppNotification.success(context, 'Rol güncellendi: $role');
      _markChanged();
      await _load();
    } on FirebaseFunctionsException catch (e) {
      if (mounted) AppNotification.error(context, e.message ?? 'Hata');
    }
  });

  Future<void> _pickPremiumEnd() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      await _setRole('premium', premiumEndMillis: picked.millisecondsSinceEpoch);
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(
      text: (_data['displayName'] as String?) ?? '',
    );
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adı Düzenle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Görünen ad'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    await _run(() async {
      try {
        await _fns.httpsCallable('updateUserProfile').call({
          'uid': widget.uid,
          'displayName': newName,
        });
        if (mounted) AppNotification.success(context, 'Ad güncellendi');
        _markChanged();
        await _load();
      } on FirebaseFunctionsException catch (e) {
        if (mounted) AppNotification.error(context, e.message ?? 'Hata');
      }
    });
  }

  Future<void> _sendPasswordReset() async {
    final email = _data['email'] as String?;
    if (email == null) return;
    await _run(() async {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        if (mounted) {
          AppNotification.success(context, 'Sıfırlama e-postası gönderildi');
        }
      } catch (e) {
        if (mounted) AppNotification.error(context, 'Gönderilemedi: $e');
      }
    });
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: const Text(
          'Bu kullanıcı ve tüm verileri (kütüphaneler, kitaplar, listeler) '
          'kalıcı olarak silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sil', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      try {
        await _fns.httpsCallable('deleteUser').call({'uid': widget.uid});
        if (mounted) {
          AppNotification.success(context, 'Kullanıcı silindi');
          _markChanged();
          _back(); // web: back to list; mobile: pop(true)
        }
      } on FirebaseFunctionsException catch (e) {
        if (mounted) AppNotification.error(context, e.message ?? 'Hata');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textColor = isDark ? Colors.white : AppColors.textLightPrimary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(child: AppBackButton(onPressed: _back)),
        ),
        title: Text('Kullanıcı Detayı', style: TextStyle(color: textColor)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorStateView(
              message: 'Kullanıcı yüklenemedi',
              detail: '$_error',
              onRetry: _load,
            )
          : AbsorbPointer(
              absorbing: _busy,
              child: _buildBody(isDark, textColor),
            ),
    );
  }

  Widget _buildBody(bool isDark, Color textColor) {
    final role = (_data['role'] as String?) ?? 'user';
    final isTargetAdmin = role == 'admin';
    final secondary = isDark
        ? AppColors.textDarkSecondary
        : AppColors.textLightSecondary;

    final libCard = _miniStat(
      isDark,
      PhosphorIconsFill.books,
      '${(_data['libraryCount'] as num?)?.toInt() ?? 0}',
      'Kütüphane',
    );
    final bookCard = _miniStat(
      isDark,
      PhosphorIconsFill.bookOpen,
      '${(_data['bookCount'] as num?)?.toInt() ?? 0}',
      'Kitap',
    );

    // Header (full width, on top)
    final header = <Widget>[
      Text(
        (_data['displayName'] as String?)?.isNotEmpty == true
            ? _data['displayName']
            : '(isim yok)',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      const SizedBox(height: 2),
      Text(_data['email'] ?? '', style: TextStyle(color: secondary, fontSize: 13)),
      const SizedBox(height: 2),
      Text(
        'Rol: $role  •  Kayıt: ${_fmtDate(_data['createdAt'] as int?)}',
        style: TextStyle(color: secondary, fontSize: 12),
      ),
    ];

    // LEFT column: info (stats + role + premium)
    final info = <Widget>[
      Row(
        children: [
          Expanded(child: libCard),
          const SizedBox(width: 10),
          Expanded(child: bookCard),
        ],
      ),
      const SizedBox(height: 10),
      _infoTile(
        isDark,
        icon: PhosphorIconsRegular.clock,
        label: 'Son kitap ekleme',
        value: _fmtDate(_data['lastBookAddedAt'] as int?, withTime: true),
      ),
      if (isTargetAdmin) ...[
        const SizedBox(height: 16),
        _infoTile(
          isDark,
          icon: PhosphorIconsFill.shieldStar,
          label: 'Yönetici hesabı',
          value: 'Konsoldan yönetilir',
        ),
      ] else ...[
        const SizedBox(height: 16),
        _sectionLabel('Rol', textColor),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _roles
              .map((r) => _roleChip(r, role == r, isDark, textColor))
              .toList(),
        ),
        const SizedBox(height: 16),
        _sectionLabel('Premium', textColor),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _infoTile(
                isDark,
                icon: PhosphorIconsFill.star,
                label: 'Başlangıç',
                value: _fmtDate(_data['premiumStart'] as int?),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _infoTile(
                isDark,
                icon: PhosphorIconsRegular.calendarX,
                label: 'Bitiş',
                value: _data['premiumEnd'] == null && role == 'premium'
                    ? 'Süresiz'
                    : _fmtDate(_data['premiumEnd'] as int?),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _pickPremiumEnd,
            icon: const Icon(PhosphorIconsRegular.calendarPlus, size: 18),
            label: const Text('Premium yap / bitiş tarihi'),
          ),
        ),
      ],
    ];

    // RIGHT column: actions
    final actions = <Widget>[
      _sectionLabel('İşlemler', textColor),
      const SizedBox(height: 8),
      _actionTile(
        isDark,
        icon: PhosphorIconsRegular.pencilSimple,
        label: 'Adı Düzenle',
        onTap: _editName,
      ),
      _actionTile(
        isDark,
        icon: PhosphorIconsRegular.key,
        label: 'Şifre sıfırlama e-postası gönder',
        onTap: _sendPasswordReset,
      ),
      if (!isTargetAdmin)
        _actionTile(
          isDark,
          icon: PhosphorIconsRegular.trash,
          label: 'Kullanıcıyı Sil',
          color: Colors.red[400],
          onTap: _deleteUser,
        ),
    ];

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, c) {
          // Two columns on wide screens (info | actions); single column stacked
          // on mobile.
          if (c.maxWidth > 700) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...header,
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: info,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: actions,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...header,
              const SizedBox(height: 14),
              ...info,
              const SizedBox(height: 16),
              ...actions,
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Text(
    text,
    style: TextStyle(color: color, fontWeight: FontWeight.w600),
  );

  Widget _roleChip(String r, bool selected, bool isDark, Color textColor) {
    return ChoiceChip(
      label: Text(r),
      selected: selected,
      onSelected: _busy ? null : (_) => _setRole(r),
      showCheckmark: true,
      checkmarkColor: context.primaryColor,
      selectedColor: context.primaryColor.withValues(alpha: 0.18),
      backgroundColor: isDark
          ? AppColors.bgDarkSurface.withValues(alpha: 0.5)
          : Colors.white,
      labelStyle: TextStyle(
        color: selected ? context.primaryColor : textColor,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? context.primaryColor : context.primaryBorder,
      ),
    );
  }

  Widget _miniStat(bool isDark, IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.bgDarkSurface.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.primaryBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.primaryColor, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textLightPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.bgDarkSurface.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.primaryBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textLightPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    bool isDark, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? (isDark ? Colors.white : AppColors.textLightPrimary);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _busy ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.bgDarkSurface.withValues(alpha: 0.5)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.primaryBorder),
            ),
            child: Row(
              children: [
                Icon(icon, color: c, size: 20),
                const SizedBox(width: 12),
                Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
