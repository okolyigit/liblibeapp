import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../services/list_service.dart';
import '../theme/theme.dart';
import 'app_notification.dart';
import 'neon_gradient_button.dart';

void showCreateListBottomSheet({
  required BuildContext context,
  VoidCallback? onCreated,
}) {
  final isDark = context.isDark;
  final nameController = TextEditingController();
  final descController = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0.8),
                        Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0.95),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.75),
                        Colors.white.withValues(alpha: 0.9),
                      ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.list_alt_rounded,
                            color: context.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Yeni liste oluştur',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textLightPrimary,
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
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : AppColors.textLightPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Liste adı',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textLightSecondary,
                          ),
                          hintText: 'Örn: Bilim Kurgu',
                          hintStyle: TextStyle(
                            color: (isDark ? Colors.white24 : Colors.black12),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: context.primaryColor,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: (isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : AppColors.textLightPrimary,
                        ),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Açıklama (isteğe bağlı)',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textLightSecondary,
                          ),
                          hintText: 'Liste hakkında bir şeyler yazın...',
                          hintStyle: TextStyle(
                            color: (isDark ? Colors.white24 : Colors.black12),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: context.primaryColor,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: (isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          // Vazgeç button - Outlined green
                          Expanded(
                            child: NeonGradientButton(
                              text: 'Vazgeç',
                              onPressed: () => Navigator.pop(context),
                              isSecondary: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Oluştur button - Filled green
                          Expanded(
                            child: NeonGradientButton(
                              text: 'Oluştur',
                              onPressed: () async {
                                if (nameController.text.isNotEmpty) {
                                  try {
                                    await ListService().createList(
                                      name: nameController.text,
                                      description: descController.text.isEmpty
                                          ? null
                                          : descController.text,
                                    );

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      if (onCreated != null) onCreated();
                                      AppNotification.success(
                                        context,
                                        'Liste oluşturuldu',
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      AppNotification.error(
                                        context,
                                        'Hata: $e',
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
