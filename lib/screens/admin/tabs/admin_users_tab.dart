import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../theme/theme.dart';
import '../../../widgets/error_state_view.dart';
import '../admin_user_detail_screen.dart';

/// "Kullanıcılar" admin tab: lists all non-admin users with search, role
/// filtering and sorting (premium first by default). Tapping a row opens
/// [AdminUserDetailScreen].
///
/// The single admin account is never listed (console-managed). Users are read
/// in one pass and filtered/sorted client-side — fine for the app's scale and
/// gives consistent search/filter/sort (a hard cap guards runaway reads).
class AdminUsersTab extends StatefulWidget {
  /// Web dashboard: open the detail inside the content area (sidebar/top bar
  /// stay visible). Mobile: null → push.
  final void Function(String uid)? onUserSelected;

  const AdminUsersTab({super.key, this.onUserSelected});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  static const _cap = 1000;

  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _all = []; // admins excluded
  bool _loading = true;
  bool _capped = false;
  Object? _error;

  String _search = '';
  String _roleFilter = 'all'; // all | premium | user
  String _sort = 'premium'; // premium | name | newest

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await _firestore
          .collection('users')
          .orderBy('email')
          .limit(_cap)
          .get();
      if (!mounted) return;
      setState(() {
        _all
          ..clear()
          ..addAll(
            snap.docs
                .map((d) => {'uid': d.id, ...d.data()})
                // Never list the admin account.
                .where((u) => (u['role'] as String?) != 'admin'),
          );
        _capped = snap.docs.length >= _cap;
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

  List<Map<String, dynamic>> get _visible {
    final q = _search.trim().toLowerCase();
    final list = _all.where((u) {
      if (_roleFilter != 'all' &&
          ((u['role'] as String?) ?? 'user') != _roleFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      final email = (u['email'] as String?)?.toLowerCase() ?? '';
      final name = (u['displayName'] as String?)?.toLowerCase() ?? '';
      return email.contains(q) || name.contains(q);
    }).toList();

    int byName(Map a, Map b) =>
        ((a['displayName'] ?? a['email'] ?? '') as String)
            .toLowerCase()
            .compareTo(
              ((b['displayName'] ?? b['email'] ?? '') as String).toLowerCase(),
            );

    switch (_sort) {
      case 'name':
        list.sort(byName);
        break;
      case 'newest':
        int ms(Map u) => (u['createdAt'] is Timestamp)
            ? (u['createdAt'] as Timestamp).millisecondsSinceEpoch
            : 0;
        list.sort((a, b) => ms(b).compareTo(ms(a)));
        break;
      case 'premium':
      default:
        list.sort((a, b) {
          final ap = ((a['role'] as String?) == 'premium') ? 0 : 1;
          final bp = ((b['role'] as String?) == 'premium') ? 0 : 1;
          return ap != bp ? ap - bp : byName(a, b);
        });
    }
    return list;
  }

  Future<void> _openUser(String uid) async {
    if (widget.onUserSelected != null) {
      widget.onUserSelected!(uid);
      return;
    }
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminUserDetailScreen(uid: uid)),
    );
    if (changed == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textColor = isDark ? Colors.white : AppColors.textLightPrimary;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Ad veya e-posta ara',
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(PhosphorIconsRegular.x, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: [
                      _filterChip('Tümü', 'all', isDark, textColor),
                      _filterChip('Premium', 'premium', isDark, textColor),
                      _filterChip('Normal', 'user', isDark, textColor),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Sırala',
                  icon: const Icon(PhosphorIconsRegular.sortAscending),
                  initialValue: _sort,
                  onSelected: (v) => setState(() => _sort = v),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'premium', child: Text('Premium önce')),
                    PopupMenuItem(value: 'name', child: Text('İsim (A-Z)')),
                    PopupMenuItem(value: 'newest', child: Text('Yeni kayıt')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(isDark, textColor)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, bool isDark, Color textColor) {
    final selected = _roleFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _roleFilter = value),
      visualDensity: VisualDensity.compact,
      showCheckmark: false,
      selectedColor: context.primaryColor.withValues(alpha: 0.18),
      backgroundColor: isDark
          ? AppColors.bgDarkSurface.withValues(alpha: 0.5)
          : Colors.white,
      labelStyle: TextStyle(
        fontSize: 13,
        color: selected ? context.primaryColor : textColor,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? context.primaryColor : context.primaryBorder,
      ),
    );
  }

  Widget _buildBody(bool isDark, Color textColor) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorStateView(
        message: 'Kullanıcılar yüklenemedi',
        detail: '$_error',
        onRetry: _load,
      );
    }
    final visible = _visible;
    if (visible.isEmpty) {
      return Center(
        child: Text(
          'Kullanıcı bulunamadı',
          style: TextStyle(
            color: isDark
                ? AppColors.textDarkSecondary
                : AppColors.textLightSecondary,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: visible.length + (_capped ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= visible.length) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'İlk $_cap kullanıcı gösteriliyor.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
            );
          }
          return _userTile(visible[index], isDark, textColor);
        },
      ),
    );
  }

  Widget _userTile(Map<String, dynamic> user, bool isDark, Color textColor) {
    final uid = user['uid'] as String;
    final isPremium = (user['role'] as String?) == 'premium';
    final name = (user['displayName'] as String?)?.isNotEmpty == true
        ? user['displayName'] as String
        : '(isim yok)';
    final email = (user['email'] as String?) ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openUser(uid),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.bgDarkSurface.withValues(alpha: 0.5)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.primaryBorder),
          ),
          child: Row(
            children: [
              Icon(
                isPremium ? PhosphorIconsFill.star : PhosphorIconsRegular.user,
                size: 18,
                color: isPremium
                    ? context.primaryColor
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPremium)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    'Premium',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.primaryColor,
                    ),
                  ),
                ),
              Icon(
                PhosphorIconsRegular.caretRight,
                size: 16,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
