import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../services/notification_service.dart';
import '../services/library_invite_service.dart';
import '../models/notification_model.dart';
import '../widgets/app_notification.dart';
import '../widgets/neon_gradient_button.dart';

class NotificationsScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const NotificationsScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            PhosphorIconsRegular.arrowLeft,
            color: isDark ? Colors.white : AppColors.textLightPrimary,
          ),
          onPressed: onBack ?? () => Navigator.pop(context),
        ),
        title: Text(
          "Bildirimler",
          style: TextStyle(
            fontSize: 20,
            color: isDark ? Colors.white : AppColors.textLightPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: NotificationService().unreadCount,
            builder: (context, count, _) {
              if (count == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => NotificationService().markAllAsRead(),
                child: Text(
                  "Tümünü Oku",
                  style: TextStyle(
                    color: context.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<NotificationModel>>(
        valueListenable: NotificationService().notifications,
        builder: (context, notifications, _) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIconsRegular.bellSlash,
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Henüz bildirim yok",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? Colors.white54
                          : AppColors.textLightSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                isDark: isDark,
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatefulWidget {
  final NotificationModel notification;
  final bool isDark;

  const _NotificationTile({required this.notification, required this.isDark});

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _isProcessing = false;

  bool get _isLibraryInvite => widget.notification.type == 'library_invite';

  String? get _inviteStatus => widget.notification.data?['status'] as String?;

  bool get _isPending => _inviteStatus == 'pending';

  IconData get _iconData {
    if (_isLibraryInvite) {
      return PhosphorIconsRegular.userPlus;
    }
    return PhosphorIconsRegular.bell;
  }

  Future<void> _acceptInvite() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final libraryId = widget.notification.data?['libraryId'] as String?;
    final libraryName = widget.notification.data?['libraryName'] as String?;
    final senderUid = widget.notification.data?['senderUid'] as String?;

    if (libraryId == null || senderUid == null || libraryName == null) {
      AppNotification.error(context, 'Davet bilgileri eksik.');
      setState(() => _isProcessing = false);
      return;
    }

    final success = await LibraryInviteService().acceptInvite(
      notificationId: widget.notification.id,
      libraryId: libraryId,
      libraryName: libraryName,
      senderUid: senderUid,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      AppNotification.success(
        context,
        'Davet kabul edildi! Kütüphane paylaşıldı.',
      );
    } else {
      AppNotification.error(context, 'Bir hata oluştu.');
    }
  }

  Future<void> _rejectInvite() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final libraryName = widget.notification.data?['libraryName'] as String?;
    final senderUid = widget.notification.data?['senderUid'] as String?;

    if (libraryName == null || senderUid == null) {
      AppNotification.error(context, 'Davet bilgileri eksik.');
      setState(() => _isProcessing = false);
      return;
    }

    final success = await LibraryInviteService().rejectInvite(
      notificationId: widget.notification.id,
      libraryName: libraryName,
      senderUid: senderUid,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      AppNotification.info(context, 'Davet reddedildi.');
    } else {
      AppNotification.error(context, 'Bir hata oluştu.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !widget.notification.isRead;
    final isDark = widget.isDark;

    return Dismissible(
      key: Key(widget.notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(PhosphorIconsRegular.trash, color: Colors.white),
      ),
      onDismissed: (_) {
        NotificationService().deleteNotification(widget.notification.id);
      },
      child: GestureDetector(
        onTap: () {
          if (isUnread && !_isLibraryInvite) {
            NotificationService().markAsRead(widget.notification.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread
                ? context.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08)
                : context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: isUnread
                ? Border.all(
                    color: context.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isUnread
                          ? context.primaryColor.withValues(alpha: 0.2)
                          : (isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconData,
                      size: 20,
                      color: isUnread
                          ? context.primaryColor
                          : (isDark
                                ? Colors.white54
                                : AppColors.textLightSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isUnread
                                ? (isDark
                                      ? Colors.white
                                      : AppColors.textLightPrimary)
                                : (isDark
                                      ? Colors.white60
                                      : AppColors.textLightSecondary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.notification.body,
                          style: TextStyle(
                            fontSize: 13,
                            color: isUnread
                                ? (isDark
                                      ? Colors.white70
                                      : AppColors.textLightSecondary)
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _formatTime(widget.notification.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                            ),
                            if (_isLibraryInvite && !_isPending) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _inviteStatus == 'accepted'
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _inviteStatus == 'accepted'
                                      ? 'Kabul Edildi'
                                      : 'Reddedildi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _inviteStatus == 'accepted'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Unread indicator
                  if (isUnread && !_isLibraryInvite)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              // Accept/Reject buttons for library invites
              if (_isLibraryInvite && _isPending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: NeonGradientButton(
                        text: 'Reddet',
                        isDestructive: true,
                        isLoading: _isProcessing,
                        onPressed: _rejectInvite,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeonGradientButton(
                        text: 'Kabul Et',
                        isLoading: _isProcessing,
                        onPressed: _acceptInvite,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return "Şimdi";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes} dakika önce";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} saat önce";
    } else if (diff.inDays < 7) {
      return "${diff.inDays} gün önce";
    } else {
      return "${time.day}/${time.month}/${time.year}";
    }
  }
}
