import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme.dart';

class AboutScreen extends StatelessWidget {
  final VoidCallback onBack;

  const AboutScreen({super.key, required this.onBack});

  Future<void> _launchEmail(BuildContext context) async {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            PhosphorIconsRegular.arrowLeft,
            color: isDark ? Colors.white : AppColors.textLightPrimary,
          ),
          onPressed: onBack,
        ),
        title: Text(
          "Hakkında",
          style: TextStyle(
            fontSize: 20,
            color: isDark ? Colors.white : AppColors.textLightPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            SizedBox(
              width: 100,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Liblibe",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textLightPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sürüm 1.0.5",
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white54 : AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).cardTheme.color ?? context.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey[200]!,
                ),
              ),
              child: Text(
                "Liblibe, kitap tutkunları için tasarlanmış modern bir kütüphane yönetim uygulamasıdır. Okuduğunuz, okuyacağınız ve favori kitaplarınızı kolayca takip edin.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.white70 : AppColors.textLightSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Contact Info
            GestureDetector(
              onTap: () => _launchEmail(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsRegular.envelope,
                      size: 20,
                      color: context.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "info@liblibe.com.tr",
                      style: TextStyle(
                        fontSize: 14,
                        color: context.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            Text(
              "© 2026 Liblibe Team",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  final VoidCallback onBack;

  const HelpCenterScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final faqItems = [
      _FAQItem(
        question: "Kitap nasıl eklerim?",
        answer:
            "Ana sayfada veya Kitaplar sayfasında sağ altta bulunan (+) butonuna tıklayarak yeni kitap ekleyebilirsiniz. İster barkod okutarak, ister manuel olarak bilgileri girebilirsiniz.",
      ),
      _FAQItem(
        question: "Barkod okuma çalışmıyor, ne yapmalıyım?",
        answer:
            "Barkod okuyucunun çalışması için kamera izni vermeniz gerekmektedir. Ayrıca ortamın yeterince aydınlık olduğundan ve barkodun net göründüğünden emin olun.",
      ),
      _FAQItem(
        question: "Kütüphane ve Liste arasındaki fark nedir?",
        answer:
            "Kütüphaneler fiziksel veya mantıksal büyük gruplardır (Ev, Ofis vb.). Listeler ise daha özel koleksiyonlardır (Okuma Listesi, Favoriler vb.).",
      ),
      _FAQItem(
        question: "Verilerim nerede saklanıyor?",
        answer:
            "Tüm verileriniz güvenli bulut sunucularımızda şifrelenmiş olarak saklanmaktadır. Cihazınızı değiştirseniz bile hesabınıza giriş yaparak verilerinize ulaşabilirsiniz.",
      ),
      _FAQItem(
        question: "Hesabımı silebilir miyim?",
        answer:
            "Evet, Profil > Destek > Hesabımı Sil seçeneği ile hesabınızı ve tüm verilerinizi kalıcı olarak silebilirsiniz.",
      ),
    ];

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
          onPressed: onBack,
        ),
        title: Text(
          "Yardım Merkezi",
          style: TextStyle(
            fontSize: 20,
            color: isDark ? Colors.white : AppColors.textLightPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: faqItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) =>
            _buildFAQCard(context, faqItems[index]),
      ),
    );
  }

  Widget _buildFAQCard(BuildContext context, _FAQItem item) {
    final isDark = context.isDark;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey[200]!,
          ),
        ),
        child: ExpansionTile(
          iconColor: context.primaryColor,
          collapsedIconColor: isDark ? Colors.white54 : Colors.grey[400],
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Text(
            item.question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textLightPrimary,
            ),
          ),
          children: [
            Text(
              item.answer,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark ? Colors.white70 : AppColors.textLightSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FAQItem {
  final String question;
  final String answer;

  _FAQItem({required this.question, required this.answer});
}
