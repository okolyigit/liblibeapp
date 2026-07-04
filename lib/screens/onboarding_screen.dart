import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../services/preferences_service.dart';
import '../widgets/neon_gradient_button.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      imagePath: 'assets/icon/library.png',
      title: "Dijital Kütüphanen",
      description: "Tüm kitaplarını tek bir yerde düzenle ve yönet.",
      color: AppColors.emerald,
    ),
    _OnboardingPage(
      imagePath: 'assets/icon/barcode.png',
      title: "Barkod ile Hızlı Ekle",
      description: "Kitaplarını barkod tarayarak saniyeler içinde ekle.",
      color: AppColors.lime,
    ),
    _OnboardingPage(
      imagePath: 'assets/icon/share.png',
      title: "Arkadaşlarınla Paylaş",
      description: "Kütüphanelerini arkadaşlarınla paylaş ve birlikte keşfet.",
      color: AppColors.emerald,
    ),
    _OnboardingPage(
      imagePath: 'assets/icon/price.png',
      title: "Fiyatları Karşılaştır",
      description:
          "Kitap fiyatlarını farklı platformlarda karşılaştır ve en uygun fiyatı bul.",
      color: AppColors.lime,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setHasSeenOnboarding(true);
    if (mounted) {
      unawaited(
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // FIXED: Header with logo, welcome text, and skip button
              Stack(
                children: [
                  // Logo and welcome text - centered
                  Padding(
                    padding: const EdgeInsets.only(top: 40, bottom: 16),
                    child: Center(
                      child: Column(
                        children: [
                          // Logo container
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/icon/icon.png',
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      PhosphorIconsFill.books,
                                      size: 32,
                                      color: context.primaryColor,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Welcome text
                          Text(
                            "Liblibe'ye Hoşgeldiniz",
                            style: TextStyle(
                              fontSize: isWide ? 24 : 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textLightPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtitle
                          Text(
                            "Kitap tutkunları için tasarlandı",
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textLightSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Skip button - top right
                  Positioned(
                    top: 8,
                    right: 0,
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        "Atla",
                        style: TextStyle(
                          color: isDark
                              ? Colors.white60
                              : AppColors.textLightSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // MIDDLE: Carousel content (only this part changes)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _buildCarouselContent(page, isDark, isWide);
                  },
                ),
              ),

              // FIXED: Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? context.primaryColor
                            : (isDark ? Colors.white24 : Colors.black12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // FIXED: Action button
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: NeonGradientButton(
                        text: _currentPage == _pages.length - 1 ? "Başla" : "Devam",
                        onPressed: _nextPage,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Carousel content - only this part scrolls/animates
  Widget _buildCarouselContent(_OnboardingPage page, bool isDark, bool isWide) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Feature icon
        Image.asset(
          page.imagePath,
          width: 240,
          height: 240,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 32),
        // Feature title
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isWide ? 28 : 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textLightPrimary,
          ),
        ),
        const SizedBox(height: 12),
        // Feature description
        Text(
          page.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isWide ? 16 : 15,
            color: isDark ? Colors.white60 : AppColors.textLightSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _OnboardingPage {
  final String imagePath;
  final String title;
  final String description;
  final Color color;

  _OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.color,
  });
}
