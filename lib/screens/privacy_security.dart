import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme.dart';

class PrivacySecurityScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const PrivacySecurityScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                "Gizlilik ve Güvenlik",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textLightPrimary,
                ),
              ),
              const SizedBox(height: 32),

              // Menu Options
              _buildMenuOption(
                context,
                icon: PhosphorIconsRegular.fileText,
                title: "Gizlilik Politikası",
                onTap: () => onNavigate(12),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildMenuOption(
                context,
                icon: PhosphorIconsRegular.scroll,
                title: "Kullanım Koşulları",
                onTap: () => onNavigate(13),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textLightPrimary,
                ),
              ),
            ),
            Icon(
              PhosphorIconsRegular.caretRight,
              color: isDark ? Colors.white54 : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class TextContentScreen extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onBack;

  const TextContentScreen({
    super.key,
    required this.title,
    required this.content,
    required this.onBack,
  });

  Future<void> _launchEmail() async {
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
    const String email = 'info@liblibe.com.tr';

    // Split content by email to make it clickable
    final parts = content.split(email);

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
          onPressed: onBack,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textLightPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey[200]!,
            ),
          ),
          child: SelectableText.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: isDark ? Colors.white70 : AppColors.textLightSecondary,
              ),
              children: _buildTextSpans(parts, email, context),
            ),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildTextSpans(
    List<String> parts,
    String email,
    BuildContext context,
  ) {
    final List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: _launchEmail,
              child: Text(
                email,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: context.primaryColor,
                  decoration: TextDecoration.underline,
                  decorationColor: context.primaryColor,
                ),
              ),
            ),
          ),
        );
      }
    }
    return spans;
  }
}

const String kPrivacyPolicyText = """
GİZLİLİK POLİTİKASI

Son Güncelleme: 28 Aralık 2026

Liblibe ("biz", "bizim" veya "uygulama") olarak, kişisel verilerinizin güvenliğine ve gizliliğine büyük önem veriyoruz. Bu Gizlilik Politikası, uygulamamızı kullandığınızda verilerinizi nasıl topladığımızı, kullandığımızı ve koruduğumuzu açıklar.

1. Toplanan Veriler
   • Hesap Bilgileri: Uygulamayı kullanmak için oluşturduğunuz hesap bilgileri (Ad, E-posta, Profil Resmi).
   • Kullanıcı İçeriği: Oluşturduğunuz kütüphaneler, listeler, eklediğiniz kitaplar, okuma durumu ve notlar.
   • Cihaz Bilgileri: Uygulama performansı ve hata takibi için gerekli temel cihaz verileri.

2. Verilerin Kullanımı
   • Hizmetlerimizi sağlamak ve kişiselleştirmek.
   • Hesabınızı yönetmek ve güvenliğini sağlamak.
   • Uygulama performansını analiz etmek ve geliştirmek.

3. Veri Paylaşımı
   • Verileriniz, yasal zorunluluklar dışında üçüncü taraflarla satılmaz veya paylaşılmaz.
   • Hizmet sağlayıcılarımız (örn. sunucu hizmetleri), verilerinizi yalnızca bizim adımıza ve talimatlarımız doğrultusunda işler.

4. Kullanıcı Hakları
   • Verilerinize erişme, düzeltme ve silme hakkına sahipsiniz.
   • Hesabınızı ve ilişkili tüm verileri uygulama içerisinden silebilirsiniz.

5. İletişim
   • Gizlilik politikamızla ilgili soru ve talepleriniz için bize ulaşabilirsiniz.
   • E-posta: info@liblibe.com.tr
""";

const String kTermsOfUseText = """
KULLANIM KOŞULLARI

Son Güncelleme: 28 Aralık 2026

Liblibe uygulamasını kullanarak aşağıdaki koşulları kabul etmiş sayılırsınız. Lütfen dikkatlice okuyunuz.

1. Hizmetin Kullanımı
   • Uygulamayı yasalara uygun ve etik kurallar çerçevesinde kullanmalısınız.
   • Başkalarının haklarına zarar verecek, tehdit edici veya saldırgan içerikler oluşturamazsınız.

2. Hesap Güvenliği
   • Hesabınızın güvenliğinden ve şifrenizin gizliliğinden siz sorumlusunuz.
   • Hesabınızla yapılan tüm işlemlerden sorumlu olduğunuzu kabul edersiniz.

3. Fikri Mülkiyet
   • Uygulamanın tasarımı, logosu ve içeriği Liblibe'ye aittir. İzinsiz kopyalanamaz veya kullanılamaz.
   • Uygulama içerisindeki kitap verileri ve görselleri ilgili hak sahiplerine aittir ve yalnızca tanıtım/bilgi amaçlı kullanılır.

4. Sorumluluk Reddi
   • Uygulama "olduğu gibi" sunulmaktadır. Kesintisiz veya hatasız çalışacağı garanti edilmez.
   • Veri kaybı veya hizmet kesintilerinden doğabilecek zararlardan Liblibe sorumlu tutulamaz.

5. Değişiklikler
   • Kullanım koşullarını zaman zaman güncelleyebiliriz. Değişiklikler yayınlandığı tarihte yürürlüğe girer.

6. İletişim
   • Kullanım koşullarıyla ilgili sorularınız için:
   • E-posta: info@liblibe.com.tr
""";
