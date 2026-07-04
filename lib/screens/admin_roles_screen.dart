import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../widgets/app_back_button.dart';
import 'admin/tabs/admin_users_tab.dart';

/// Standalone "Rol Yönetimi" screen (thin wrapper around [AdminUsersTab]).
/// The same body is also hosted as the "Kullanıcılar" tab inside the admin
/// dashboard shell.
class AdminRolesScreen extends StatelessWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor =
        context.isDark ? Colors.white : AppColors.textLightPrimary;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Center(child: AppBackButton()),
        ),
        title: Text('Rol Yönetimi', style: TextStyle(color: textColor)),
      ),
      body: const AdminUsersTab(),
    );
  }
}
