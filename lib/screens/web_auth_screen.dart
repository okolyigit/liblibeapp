import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme.dart';
import '../utils/validators.dart';
import '../services/auth_service.dart';
import '../widgets/app_notification.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

import 'privacy_security.dart';
import '../utils/web_helpers.dart' if (dart.library.io) '../utils/mobile_helpers.dart';
import '../widgets/glass_card.dart';
import '../widgets/neon_gradient_button.dart';
import '../widgets/glass_dialog.dart';

/// Web-optimized authentication screen with split-screen layout
/// Left panel: Onboarding carousel with arrow navigation
/// Right panel: Login form
class WebAuthScreen extends StatefulWidget {
  const WebAuthScreen({super.key});

  @override
  State<WebAuthScreen> createState() => _WebAuthScreenState();
}

class _WebAuthScreenState extends State<WebAuthScreen> {
  // Login state
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============ Login Methods ============

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Lütfen e-posta ve şifrenizi girin');
      return;
    }
    final emailError = Validators.validateEmail(_emailController.text);
    if (emailError != null) {
      _showError(emailError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await AuthService().signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (credential?.user != null && !credential!.user!.emailVerified) {
        if (mounted) {
          await _showEmailVerificationDialog();
        }
        await AuthService().signOut();
        return;
      }

      if (mounted) {
        unawaited(
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showEmailVerificationDialog() async {
    await showGlassDialog(
      context: context,
      title: "E-posta Doğrulama",
      icon: PhosphorIconsRegular.envelopeSimple,
      barrierDismissible: false,
      content: Text(
        "Giriş yapabilmek için e-posta adresinizi doğrulamanız gerekmektedir.\n\nDoğrulama e-postası gelmediyse tekrar gönderebilirsiniz.",
        style: TextStyle(
          color: context.isDark
              ? Colors.white70
              : AppColors.textLightSecondary,
        ),
      ),
      cancelText: "Kapat",
      confirmText: "Tekrar Gönder",
      onCancel: () => Navigator.pop(context),
      onConfirm: () async {
        try {
          await AuthService().sendVerificationEmail();
          if (!mounted) return;
          AppNotification.success(
            context,
            "Doğrulama e-postası tekrar gönderildi",
          );
          Navigator.pop(context);
        } catch (e) {
          if (!mounted) return;
          _showError("Hata: $e");
        }
      },
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService().signInWithGoogle();
      if (result != null && mounted) {
        unawaited(
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          ),
        );
      }
    } on AccountExistsException catch (e) {
      if (mounted) {
        _showLinkAccountDialog(e.email);
      }
    } catch (e) {
      _showError('Google ile giriş başarısız: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLinkAccountDialog(String email) {

    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final dIsDark = Theme.of(dialogContext).brightness == Brightness.dark;
          return GlassDialog(
            title: 'Hesapları Birleştir',
            icon: PhosphorIconsRegular.link,
            barrierDismissible: false,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bu e-posta adresi zaten kayıtlı:',
                  style: TextStyle(
                    color: dIsDark ? Colors.white70 : AppColors.textLightSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: dIsDark ? Colors.white : AppColors.textLightPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Şifrenizi girerek Google hesabınızı bağlayın:',
                  style: TextStyle(
                    color: dIsDark ? Colors.white70 : AppColors.textLightSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: TextStyle(
                    color: dIsDark ? Colors.white : AppColors.textLightPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Şifreniz',
                    hintStyle: TextStyle(
                      color: dIsDark ? Colors.white38 : AppColors.textLightSecondary,
                    ),
                    filled: true,
                    fillColor: dialogContext.subtleTint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? PhosphorIconsRegular.eye
                            : PhosphorIconsRegular.eyeSlash,
                        color: dIsDark ? Colors.white54 : AppColors.textLightSecondary,
                      ),
                      onPressed: () => setDialogState(
                        () => obscurePassword = !obscurePassword,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            cancelText: 'İptal',
            confirmText: 'Bağla',
            onCancel: () {
              AuthService().cancelPendingLink();
              Navigator.pop(dialogContext);
            },
            onConfirm: () async {
              if (passwordController.text.isEmpty) {
                AppNotification.warning(dialogContext, 'Lütfen şifrenizi girin');
                return;
              }
              try {
                final result = await AuthService().completeGoogleLinking(
                  passwordController.text,
                );
                if (result == null) return;
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (!mounted) return;
                AppNotification.success(
                  context,
                  'Google hesabı başarıyla bağlandı!',
                );
                unawaited(
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                  ),
                );
              } catch (e) {
                if (dialogContext.mounted) {
                  AppNotification.error(dialogContext, e.toString());
                }
              }
            },
          );
        },
      ),
    );
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Lütfen e-posta adresinizi girin');
      return;
    }
    try {
      await AuthService().sendPasswordResetEmail(email);
      if (mounted) {
        AppNotification.success(
          context,
          'Şifre sıfırlama bağlantısı gönderildi',
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    AppNotification.error(context, message);
  }

  Future<void> _launchContactEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'info@liblibe.com.tr',
      queryParameters: {'subject': 'Liblibe Uygulama İletişim'},
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          resetWebViewport();
        },
        child: _buildLoginPanel(isDark),
      ),
    );
  }

  Widget _buildLoginPanel(bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textLightPrimary;
    final secondaryTextColor = isDark
        ? AppColors.textDarkSecondary
        : AppColors.textLightSecondary;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 750;
            final logoSize = isSmallScreen ? 60.0 : 80.0;
            final spacingLg = isSmallScreen ? 16.0 : 32.0;
            final spacingMd = isSmallScreen ? 16.0 : 24.0;
            final spacingSm = isSmallScreen ? 12.0 : 16.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: isSmallScreen ? 16 : 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (isSmallScreen ? 32 : 48),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: GlassCard(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 20 : 32,
                        vertical: isSmallScreen ? 24 : 32,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/icon/icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: spacingSm),

                          // App Name
                          Text(
                            "Liblibe",
                            style: GoogleFonts.outfit(
                              fontSize: isSmallScreen ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: spacingLg),

                          // Google Sign In Button
                          _buildSocialButton(
                            logo: _buildGoogleLogo(),
                            label: "Google ile devam et",
                            isDark: isDark,
                            onTap: _isLoading ? () {} : _handleGoogleSignIn,
                          ),
                          SizedBox(height: spacingMd),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color:
                                      secondaryTextColor.withValues(alpha: 0.2),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  "veya e-posta ile",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color:
                                      secondaryTextColor.withValues(alpha: 0.2),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacingMd),

                          // Email Input
                          TextField(
                            controller: _emailController,
                            onTapOutside: (event) {
                              FocusScope.of(context).unfocus();
                              resetWebViewport();
                            },
                            decoration: _buildInputDecoration(
                              labelText: "E-postanızı girin",
                              isDark: isDark,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: spacingSm),

                          // Password Input
                          TextField(
                            controller: _passwordController,
                            onTapOutside: (event) {
                              FocusScope.of(context).unfocus();
                              resetWebViewport();
                            },
                            obscureText: _obscurePassword,
                            style: TextStyle(color: textColor),
                            decoration: _buildInputDecoration(
                              labelText: "Şifre",
                              isDark: isDark,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? PhosphorIconsRegular.eye
                                      : PhosphorIconsRegular.eyeSlash,
                                  color: secondaryTextColor,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: spacingSm),

                          // Remember Me & Forgot Password
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: context.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (value) => setState(
                                    () => _rememberMe = value ?? false,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Beni Hatırla",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: secondaryTextColor,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: _handleForgotPassword,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  "Şifremi Unuttum?",
                                  style: TextStyle(
                                    color: context.primaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacingMd),

                          // Terms & Privacy
                          Padding(
                            padding: EdgeInsets.only(bottom: spacingSm),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryTextColor,
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(text: "Giriş yaparak "),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () => _showTermsDialog(context),
                                      child: Text(
                                        "Kullanım Koşulları",
                                        style: TextStyle(
                                          color: context.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: "'nı ve "),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () => _showPrivacyDialog(context),
                                      child: Text(
                                        "Gizlilik Politikası",
                                        style: TextStyle(
                                          color: context.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
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
                          SizedBox(height: spacingMd),

                          // Login Button
                          NeonGradientButton(
                            text: "Giriş Yap",
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                          ),
                          SizedBox(height: spacingMd),

                          // Register Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Hesabınız yok mu?",
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 13,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Hesap Oluştur",
                                  style: TextStyle(
                                    color: context.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacingSm),

                          // Contact Link
                          TextButton.icon(
                            onPressed: _launchContactEmail,
                            icon: Icon(
                              PhosphorIconsRegular.envelope,
                              size: 16,
                              color: secondaryTextColor,
                            ),
                            label: Text(
                              "İletişim",
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
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

  /// Custom Google logo widget
  Widget _buildGoogleLogo() {
    final isDark = context.isDark;
    return Icon(
      PhosphorIconsBold.googleLogo,
      size: 24,
      color: isDark ? Colors.white : const Color(0xFF4285F4),
    );
  }



  // ============ UI Helper Methods ============

  Widget _buildSocialButton({
    required Widget logo,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: context.subtleTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.primaryBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            logo,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
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

// ============ Helper Classes ============




