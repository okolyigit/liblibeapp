import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_notification.dart';
import '../widgets/neon_gradient_button.dart';

class EditProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const EditProfileScreen({super.key, this.onBack});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _emailConfirmController = TextEditingController();

  // Available avatar icons
  final List<IconData> _avatarIcons = [
    PhosphorIconsFill.user,
    PhosphorIconsFill.cat,
    PhosphorIconsFill.dog,
    PhosphorIconsFill.alien,
    PhosphorIconsFill.robot,
  ];

  String? _googlePhotoUrl;

  int _selectedAvatarIndex = 0;
  String? _emailError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load Firebase user data
    final user = AuthService().currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');

    // Find custom Google photo URL
    for (var userInfo in user?.providerData ?? []) {
      if (userInfo.providerId == 'google.com' &&
          userInfo.photoURL != null &&
          userInfo.photoURL!.isNotEmpty) {
        _googlePhotoUrl = userInfo.photoURL;
        break;
      }
    }

    // Determine initial selection
    final currentPhotoUrl = user?.photoURL;
    if (currentPhotoUrl != null) {
      if (currentPhotoUrl.startsWith('asset:')) {
        // It's a predefined icon
        try {
          final index = int.parse(currentPhotoUrl.split(':')[1]);
          _selectedAvatarIndex = index;
        } catch (_) {
          _selectedAvatarIndex = 0;
        }
      } else if (currentPhotoUrl == _googlePhotoUrl) {
        // It's the Google photo
        _selectedAvatarIndex = -1;
      } else {
        // Unknown URL -> assume google or custom, map to google slot if possible or default
        _selectedAvatarIndex = -1;
        // If it's not the google url we found, but still a url, maybe we should treat it as 'google/custom' slot (-1)
        // But if _googlePhotoUrl is null, we can't show it.
        // Let's just default to 0 if we can't match it, unless we set _googlePhotoUrl to it?
        if (_googlePhotoUrl == null && currentPhotoUrl.startsWith("http")) {
          _googlePhotoUrl = currentPhotoUrl;
        }
      }
    } else {
      // Default to first icon
      _selectedAvatarIndex = 0;
    }

    // If we have a google photo but user has selected an asset, we are good.
    // If user has no photoURL set but has a google account linked, maybe default to google photo?
    // Let's stick to current logic: default 0 if no photoURL.
    if (currentPhotoUrl == null && _googlePhotoUrl != null) {
      _selectedAvatarIndex = -1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _emailConfirmController.dispose();
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          "Profili Düzenle",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textLightPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Avatar Selection
                  _buildAvatarSection(isDark),

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
      ),
    );
  }

  Widget _buildAvatarSection(bool isDark) {
    return Column(
      children: [
        // Current Avatar (Clickable)
        GestureDetector(
          onTap: () => _showAvatarPicker(isDark),
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: _selectedAvatarIndex == -1 && _googlePhotoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _googlePhotoUrl!,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                            errorBuilder: (_, _, _) => const Icon(
                              PhosphorIconsRegular.googleLogo,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          _avatarIcons[_selectedAvatarIndex],
                          size: 48,
                          color: Colors.white,
                        ),
                ),
              ),
              // Edit Badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.surfaceColor,
                    border: Border.all(color: context.primaryColor, width: 2),
                  ),
                  child: Icon(
                    PhosphorIconsFill.pencil,
                    size: 16,
                    color: context.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Resme tıklayarak değiştir",
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
        // Name Field
        _buildTextField(
          controller: _nameController,
          label: "Ad Soyad",
          hint: "Örn: Ahmet Yılmaz",
          icon: PhosphorIconsRegular.user,
          isDark: isDark,
        ),

        const SizedBox(height: 24),

        // Email Field
        _buildTextField(
          controller: _emailController,
          label: "E-posta",
          hint: "ornek@email.com",
          icon: PhosphorIconsRegular.envelope,
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 24),

        // Email Confirmation Field
        _buildTextField(
          controller: _emailConfirmController,
          label: "E-posta Tekrar",
          hint: "E-posta adresinizi tekrar girin",
          icon: PhosphorIconsRegular.envelope,
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
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
            keyboardType: keyboardType,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textLightPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: isDark ? Colors.white54 : AppColors.textLightSecondary,
                size: 20,
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
            isLoading: _isLoading,
            onPressed: _saveProfile,
          ),
        ),
      ],
    );
  }

  void _showAvatarPicker(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Theme.of(context).cardTheme.color ?? context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Avatar Seç",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textLightPrimary,
              ),
            ),
            const SizedBox(height: 24),
            // Avatar Options
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                // Google Photo Option (if available)
                if (_googlePhotoUrl != null)
                  _buildAvatarOption(
                    index: -1,
                    image: _googlePhotoUrl,
                    isDark: isDark,
                  ),

                // Predefined Icons
                ...List.generate(_avatarIcons.length, (index) {
                  return _buildAvatarOption(
                    index: index,
                    icon: _avatarIcons[index],
                    isDark: isDark,
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption({
    required int index,
    IconData? icon,
    String? image,
    required bool isDark,
  }) {
    final isSelected = _selectedAvatarIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedAvatarIndex = index);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? context.primaryColor
              : (isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05)),
          border: Border.all(
            color: isSelected ? context.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: image != null
              ? Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(
                    PhosphorIconsRegular.googleLogo, // Fallback if url fails
                    size: 28,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? Colors.white54
                              : AppColors.textLightSecondary),
                  ),
                )
              : Center(
                  child: Icon(
                    icon,
                    size: 28,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? Colors.white54
                              : AppColors.textLightSecondary),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    // Validate name
    if (_nameController.text.trim().isEmpty) {
      AppNotification.warning(context, 'Ad Soyad boş bırakılamaz');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Determine photoURL based on selected avatar
      String? photoURL;
      if (_selectedAvatarIndex == -1 && _googlePhotoUrl != null) {
        // Google photo selected
        photoURL = _googlePhotoUrl;
      } else if (_selectedAvatarIndex >= 0) {
        // Predefined icon selected - use asset: prefix
        photoURL = 'asset:$_selectedAvatarIndex';
      }

      // Update display name and photo
      await AuthService().updateProfile(
        displayName: _nameController.text.trim(),
        photoURL: photoURL,
      );

      if (mounted) {
        AppNotification.success(context, 'Profil güncellendi');
        _handleBack();
      }
    } catch (e) {
      if (mounted) {
        AppNotification.error(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
