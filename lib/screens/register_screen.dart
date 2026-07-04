import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_notification.dart';

import '../widgets/glass_card.dart';
import '../widgets/neon_gradient_button.dart';
import '../widgets/glass_dialog.dart';
import 'dashboard_screen.dart';
import 'privacy_security.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validation
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Lütfen tüm alanları doldurun');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Şifreler eşleşmiyor');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Şifre en az 6 karakter olmalı');
      return;
    }

    if (!_termsAccepted) {
      _showError('Lütfen kayıt olmak için koşulları kabul edin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      if (mounted) {
        await showGlassInfoDialog(
          context: context,
          title: "E-posta Doğrulama",
          icon: PhosphorIconsRegular.envelopeSimple,
          message: "Kayıt işleminiz başarılı!\n\nLütfen e-posta adresinize gönderilen doğrulama bağlantısına tıklayarak hesabınızı etkinleştirin. Ardından giriş yapabilirsiniz.",
          confirmText: "Tamam",
        );
        if (mounted) {
          Navigator.pop(context); // Go back to login
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService().signInWithGoogle();
      if (result != null && mounted) {
        unawaited(
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          ),
        );
      }
    } catch (e) {
      _showError('Google ile kayıt başarısız: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    AppNotification.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final textColor = isDark ? Colors.white : AppColors.textLightPrimary;
    final secondaryTextColor = isDark
        ? AppColors.textDarkSecondary
        : AppColors.textLightSecondary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 0,
                bottom: bottomInset > 0 ? bottomInset + 20 : 0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight - 100,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 360,
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                        Text(
                          "Hesap Oluştur",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Name Input
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: textColor),
                          decoration: _buildInputDecoration(
                            labelText: "Ad Soyad",
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email Input
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(color: textColor),
                          decoration: _buildInputDecoration(
                            labelText: "E-postanızı girin",
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Input
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: textColor),
                          decoration: _buildInputDecoration(
                            labelText: "Şifrenizi girin",
                            isDark: isDark,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? PhosphorIconsRegular.eye
                                    : PhosphorIconsRegular.eyeSlash,
                                color: secondaryTextColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Input
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: TextStyle(color: textColor),
                          decoration: _buildInputDecoration(
                            labelText: "Şifrenizi doğrulayın",
                            isDark: isDark,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? PhosphorIconsRegular.eye
                                    : PhosphorIconsRegular.eyeSlash,
                                color: secondaryTextColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Terms & Conditions Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _termsAccepted,
                                activeColor: context.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _termsAccepted = value ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: secondaryTextColor,
                                    height: 1.4,
                                  ),
                                  children: [
                                    const TextSpan(text: "Kayıt olarak "),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () => _showTermsDialog(context),
                                        child: Text(
                                          "Kullanım Koşulları",
                                          style: TextStyle(
                                            color: context.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const TextSpan(text: "'nı ve "),
                                    WidgetSpan(
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showPrivacyDialog(context),
                                        child: Text(
                                          "Gizlilik Politikası",
                                          style: TextStyle(
                                            color: context.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const TextSpan(
                                      text: "'nı kabul etmiş olursunuz.",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Register Button
                        NeonGradientButton(
                          text: "Kayıt Ol",
                          isLoading: _isLoading,
                          onPressed: _handleRegister,
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: secondaryTextColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                "veya",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: secondaryTextColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Social Login Buttons (Simplified)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButtonIcon(
                              logo: Icon(
                                PhosphorIconsBold.googleLogo,
                                size: 24,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF4285F4),
                              ),
                              isDark: isDark,
                              onTap: () => _handleGoogleSignIn(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Zaten hesabınız var mı?",
                              style: TextStyle(color: secondaryTextColor),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Giriş Yap",
                                style: TextStyle(
                                  color: context.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
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

  Widget _buildSocialButtonIcon({
    required Widget logo,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        width: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.subtleTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.primaryBorder),
        ),
        child: logo,
      ),
    );
  }


  InputDecoration _buildInputDecoration({
    required String labelText,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : AppColors.textLightSecondary,
      ),
      floatingLabelStyle: TextStyle(
        color: context.primaryColor,
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: context.subtleTint.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: context.primaryBorder.withValues(alpha: 0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: context.primaryBorder.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.primaryColor, width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          _buildContentDialog(context, "Kullanım Koşulları", kTermsOfUseText),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildContentDialog(
        context,
        "Gizlilik Politikası",
        kPrivacyPolicyText,
      ),
    );
  }

  Widget _buildContentDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    final isDark = context.isDark;
    return AlertDialog(
      backgroundColor: context.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textLightPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(
            content,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : AppColors.textLightSecondary,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Kapat", style: TextStyle(color: context.primaryColor)),
        ),
      ],
    );
  }
}
