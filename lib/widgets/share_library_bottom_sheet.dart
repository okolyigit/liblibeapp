import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/theme.dart';
import '../models/library.dart';
import '../services/library_invite_service.dart';
import '../services/library_service.dart';
import 'app_notification.dart';
import 'neon_gradient_button.dart';

void showShareLibraryBottomSheet({
  required BuildContext context,
  required Library library,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ShareLibraryBottomSheet(library: library),
  );
}

class _ShareLibraryBottomSheet extends StatefulWidget {
  final Library library;

  const _ShareLibraryBottomSheet({required this.library});

  @override
  State<_ShareLibraryBottomSheet> createState() =>
      _ShareLibraryBottomSheetState();
}

class _ShareLibraryBottomSheetState extends State<_ShareLibraryBottomSheet> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isRemovingMember = false;

  // Get members excluding the owner
  List<String> get _otherMembers {
    return widget.library.members
        .where((uid) => uid != widget.library.ownerId)
        .toList();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await LibraryInviteService().sendInvite(
      email: _emailController.text.trim(),
      library: widget.library,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      AppNotification.success(context, result.message);
      _emailController.clear();
    } else {
      AppNotification.error(context, result.message);
    }
  }

  Future<void> _removeMember(String memberId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Üyeyi Çıkar'),
        content: const Text(
          'Bu üyeyi kütüphaneden çıkarmak istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          NeonGradientButton(
            onPressed: () => Navigator.pop(context, true),
            text: 'Çıkar',
            isDestructive: true,
            height: 40,
            width: 100,
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRemovingMember = true);

    try {
      await LibraryService().removeMember(widget.library.id, memberId);
      if (mounted) {
        AppNotification.success(context, 'Üye kütüphaneden çıkarıldı.');
        // Force rebuild to reflect changes
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        AppNotification.error(context, 'Bir hata oluştu.');
      }
    }

    setState(() => _isRemovingMember = false);
  }

  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Header
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            PhosphorIconsRegular.userPlus,
                            color: context.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Kütüphaneyi Paylaş",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textLightPrimary,
                                ),
                              ),
                              Text(
                                widget.library.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textLightSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          PhosphorIconsRegular.x,
                          size: 24,
                          color: isDark
                              ? Colors.white70
                              : AppColors.textLightSecondary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Email Input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textLightPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: "E-posta Adresi",
                    hintText: "ornek@email.com",
                    prefixIcon: Icon(
                      PhosphorIconsRegular.envelope,
                      color: context.primaryColor,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: context.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: context.primaryColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen bir e-posta adresi girin';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value.trim())) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _sendInvite(),
                ),
                const SizedBox(height: 16),

                // Send Button
                NeonGradientButton(
                  onPressed: _isLoading ? () {} : _sendInvite,
                  text: 'Davet Gönder',
                  isLoading: _isLoading,
                ),

                // Members Section (only show if there are other members)
                if (_otherMembers.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.users,
                        color: isDark ? Colors.white70 : Colors.black54,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mevcut Üyeler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : AppColors.textLightPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_otherMembers.length} üye',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_otherMembers.length, (index) {
                    final memberId = _otherMembers[index];
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _getUserData(memberId),
                      builder: (context, snapshot) {
                        final userData = snapshot.data;
                        final memberName =
                            userData?['displayName'] ??
                            userData?['email'] ??
                            'Kullanıcı';
                        final memberEmail = userData?['email'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: context.primaryColor
                                    .withValues(alpha: 0.2),
                                child: Text(
                                  memberName.isNotEmpty
                                      ? memberName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: context.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      memberName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.textLightPrimary,
                                      ),
                                    ),
                                    if (memberEmail.isNotEmpty)
                                      Text(
                                        memberEmail,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _isRemovingMember
                                    ? null
                                    : () => _removeMember(memberId),
                                icon: Icon(
                                  PhosphorIconsRegular.userMinus,
                                  color: Colors.red[400],
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
