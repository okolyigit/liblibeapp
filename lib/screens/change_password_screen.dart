import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_notification.dart';
import '../widgets/neon_gradient_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ChangePasswordScreen({super.key, this.onBack});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _oldPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.pop(context);
    }
  }

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
          onPressed: _handleBack,
        ),
        title: Text(
          "Şifre Değiştir",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textLightPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),

                        // Lock Icon
                        _buildHeaderIcon(isDark),

                        const SizedBox(height: 40),

                        // Form Fields
                        _buildFormSection(isDark),

                        const SizedBox(height: 40),

                        // Action Buttons
                        _buildActionButtons(isDark),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(bool isDark) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.subtleTint,
          ),
          child: Icon(
            PhosphorIconsFill.lock,
            size: 40,
            color: context.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Güvenliğiniz için şifrenizi düzenli olarak değiştirin",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white54 : AppColors.textLightSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Old Password Field
        _buildPasswordField(
          controller: _oldPasswordController,
          label: "Eski Şifre",
          hint: "Mevcut şifrenizi girin",
          isDark: isDark,
          obscure: _obscureOld,
          onToggle: () => setState(() => _obscureOld = !_obscureOld),
          errorText: _oldPasswordError,
        ),

        const SizedBox(height: 24),

        // New Password Field
        _buildPasswordField(
          controller: _newPasswordController,
          label: "Yeni Şifre",
          hint: "En az 8 karakter",
          isDark: isDark,
          obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
          errorText: _newPasswordError,
        ),

        const SizedBox(height: 24),

        // Confirm Password Field
        _buildPasswordField(
          controller: _confirmPasswordController,
          label: "Yeni Şifre Tekrar",
          hint: "Yeni şifrenizi tekrar girin",
          isDark: isDark,
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          errorText: _confirmPasswordError,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required bool obscure,
    required VoidCallback onToggle,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : AppColors.textLightSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? context.surfaceColor.withValues(alpha: 0.5)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? Colors.red
                  : context.primaryColor.withValues(alpha: isDark ? 0.5 : 0.4),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textLightPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                PhosphorIconsRegular.lock,
                color: isDark ? Colors.white54 : AppColors.textLightSecondary,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? PhosphorIconsRegular.eye
                      : PhosphorIconsRegular.eyeSlash,
                  color: isDark ? Colors.white54 : AppColors.textLightSecondary,
                  size: 20,
                ),
                onPressed: onToggle,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white30 : Colors.black26,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: TextStyle(fontSize: 12, color: Colors.red[400]),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        // Vazgeç Button
        Expanded(
          child: NeonGradientButton(
            text: "Vazgeç",
            isSecondary: true,
            onPressed: _handleBack,
          ),
        ),
        const SizedBox(width: 16),
        // Kaydet Button
        Expanded(
          child: NeonGradientButton(
            text: "Kaydet",
            onPressed: _savePassword,
          ),
        ),
      ],
    );
  }

  Future<void> _savePassword() async {
    bool hasError = false;

    // Reset errors
    setState(() {
      _oldPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    // Validate old password
    if (_oldPasswordController.text.isEmpty) {
      setState(() => _oldPasswordError = "Eski şifre gerekli");
      hasError = true;
    }

    // Validate new password
    if (_newPasswordController.text.isEmpty) {
      setState(() => _newPasswordError = "Yeni şifre gerekli");
      hasError = true;
    } else if (_newPasswordController.text.length < 6) {
      setState(() => _newPasswordError = "Şifre en az 6 karakter olmalı");
      hasError = true;
    }

    // Validate confirm password
    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = "Şifre tekrarı gerekli");
      hasError = true;
    } else if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = "Şifreler eşleşmiyor");
      hasError = true;
    }

    if (hasError) return;

    try {
      await AuthService().changePassword(
        currentPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        AppNotification.success(context, 'Şifre başarıyla değiştirildi');
        _handleBack();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _oldPasswordError = e.toString());
      }
    }
  }
}
