import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/theme.dart';
import '../constants/strings.dart';
import '../services/auth_service.dart';
import '../services/shopping_service.dart';
import '../services/book_api_service.dart';
import '../widgets/app_notification.dart';
import 'barcode_scanner_screen.dart';
import '../widgets/app_image.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/neon_gradient_button.dart';

class AddShoppingItemScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const AddShoppingItemScreen({super.key, this.onBack});

  @override
  State<AddShoppingItemScreen> createState() => _AddShoppingItemScreenState();
}

class _AddShoppingItemScreenState extends State<AddShoppingItemScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _isbnController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _yearController = TextEditingController();
  final _publisherController = TextEditingController();
  final _pageCountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _languageController = TextEditingController();
  final _purchaseLinkController = TextEditingController();
  String _selectedGenre = 'Roman';
  final List<String> _selectedCategories = [];
  TextEditingController? _activeCategoryController;

  final List<String> _allCategories = [
    "Öykü",
    "Polisiye & Dedektif",
    "Gerilim / Thriller",
    "Bilim Kurgu",
    "Fantastik",
    "Korku",
    "Tarihî Kurgu",
    "Romantik",
    "Edebiyat Klasikleri",
    "Grafik Roman / Çizgi Roman",
    "Biyografi / Anı",
    "Deneme",
    "Popüler Bilim",
    "Tarih",
    "Felsefe",
    "Psikoloji",
    "Sosyoloji",
    "Siyaset",
    "Ekonomi & Finans",
    "İş Dünyası & Yönetim",
    "Kişisel Gelişim",
    "Din & İnanç",
    "Gezi",
    "Okul Öncesi",
    "İlk Okuma",
    "Çocuk",
    "Gençlik",
    "Masal & Mitoloji",
    "Etkinlik / Bulmaca",
    "Eğitici",
  ];

  // State
  String? _coverUrl;
  Map<String, dynamic>? _apiBookData;
  bool _isSearching = false;

  final List<String> _genres = [
    'Roman',
    'Klasik',
    'Distopya',
    'Bilim Kurgu',
    'Tarih',
    'Psikoloji',
    'Felsefe',
    'Kişisel Gelişim',
    'Şiir',
    'Diğer',
  ];

  @override
  void dispose() {
    _isbnController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _yearController.dispose();
    _publisherController.dispose();
    _pageCountController.dispose();
    _descriptionController.dispose();
    _languageController.dispose();
    _purchaseLinkController.dispose();
    super.dispose();
  }

  Future<void> _performIsbnLookup() async {
    final isbn = _isbnController.text.trim();
    if (isbn.isEmpty) {
      AppNotification.warning(context, 'Lütfen bir ISBN numarası girin');
      return;
    }

    setState(() => _isSearching = true);

    try {
      final bookData = await BookApiService().searchByIsbn(
        isbn,
        titleHint: _titleController.text.trim(),
        authorHint: _authorController.text.trim(),
      );
      if (!mounted) return;

      if (bookData != null) {
        setState(() {
          _apiBookData = bookData;
          _titleController.text = bookData['title'] ?? _titleController.text;
          _authorController.text = bookData['author'] ?? _authorController.text;
          _yearController.text =
              bookData['publishedDate']?.substring(0, 4) ??
              _yearController.text;
          _publisherController.text =
              bookData['publisher'] ?? _publisherController.text;
          _pageCountController.text =
              bookData['pageCount']?.toString() ?? _pageCountController.text;
          _descriptionController.text =
              bookData['description'] ?? _descriptionController.text;
          _languageController.text =
              bookData['language'] ?? _languageController.text;
          _purchaseLinkController.text =
              bookData['purchaseLink'] ?? _purchaseLinkController.text;
          _coverUrl = bookData['coverUrl'] ?? _coverUrl;

          if (bookData['genre'] != null) {
            final apiGenre = bookData['genre'] as String;
            if (apiGenre.toLowerCase().contains('fiction')) {
              _selectedGenre = 'Roman';
            } else if (apiGenre.toLowerCase().contains('philosophy')) {
              _selectedGenre = 'Felsefe';
            } else if (apiGenre.toLowerCase().contains('history')) {
              _selectedGenre = 'Tarih';
            } else if (apiGenre.toLowerCase().contains('psychology')) {
              _selectedGenre = 'Psikoloji';
            } else if (apiGenre.toLowerCase().contains('poetry')) {
              _selectedGenre = 'Şiir';
            }
          }
        });

        if (mounted) {
          AppNotification.success(context, 'Kitap bilgileri bulundu!');
        }
      } else {
        if (mounted) {
          AppNotification.warning(context, 'Bu ISBN ile kitap bulunamadı');
        }
      }
    } catch (e) {
      if (mounted) {
        AppNotification.error(context, 'Hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _showCoverUrlDialog() {
    final controller = TextEditingController(text: _coverUrl);
    final isDark = context.isDark;
    showGlassDialog(
      context: context,
      title: 'Kitap Kapağı Linki',
      content: TextField(
        controller: controller,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textLightPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'https://...',
          labelText: 'Kapak Görseli URL',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          labelStyle: TextStyle(
            color: isDark ? Colors.white70 : AppColors.textLightSecondary,
          ),
        ),
        maxLines: 3,
      ),
      cancelText: 'İptal',
      confirmText: 'Kaydet',
      onCancel: () => Navigator.pop(context),
      onConfirm: () {
        setState(() {
          _coverUrl = controller.text.trim().isEmpty
              ? null
              : controller.text.trim();
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      if (user == null) {
        throw 'Kullanıcı oturumu bulunamadı';
      }

      await ShoppingService().addItem(
        title: _titleController.text,
        author: _authorController.text,
        genre: _selectedGenre,
        isbn: _isbnController.text.isNotEmpty ? _isbnController.text : null,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        pageCount: _pageCountController.text.isNotEmpty
            ? int.tryParse(_pageCountController.text)
            : null,
        publisher: _publisherController.text.isNotEmpty
            ? _publisherController.text
            : null,
        publishedDate: _yearController.text.isNotEmpty
            ? _yearController.text
            : null,
        language: _languageController.text.isNotEmpty
            ? _languageController.text
            : null,
        previewLink: _apiBookData?['previewLink'],
        purchaseLink: _purchaseLinkController.text.isNotEmpty
            ? _purchaseLinkController.text
            : null,
        coverUrl: _coverUrl,
        categories: _selectedCategories,
      );

      if (mounted) {
        AppNotification.success(
          context,
          'Alışveriş listesine eklendi. Yeni kayıt yapabilirsiniz.',
        );

        // Clear form for next entry
        setState(() {
          _isbnController.clear();
          _titleController.clear();
          _authorController.clear();
          _yearController.clear();
          _publisherController.clear();
          _pageCountController.clear();
          _descriptionController.clear();
          _languageController.clear();
          _purchaseLinkController.clear();
          _coverUrl = null;
          _selectedCategories.clear();
          _selectedGenre = 'Roman';
          _apiBookData = null;
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotification.error(context, 'Hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Alışveriş Listesine Ekle',
          style: TextStyle(
            fontSize: 20,
            color: isDark ? Colors.white : AppColors.textLightPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 160,
        child: NeonGradientButton(
          onPressed: _isLoading ? null : _saveItem,
          text: 'Kaydet',
          icon: PhosphorIconsRegular.floppyDisk,
          isLoading: _isLoading,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Shopping list badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIconsRegular.shoppingCart,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bu kitap alışveriş listenize eklenecek. Satın aldıktan sonra kütüphanenize taşıyabilirsiniz.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.orange[200]
                                    : Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Barkod Tara Button
                    NeonGradientButton(
                      onPressed: () async {
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const BarcodeScannerScreen(),
                          ),
                        );

                        if (result != null && result.isNotEmpty) {
                          setState(() {
                            _isbnController.text = result;
                          });
                          unawaited(_performIsbnLookup());
                        }
                      },
                      text: 'Barkod Tara',
                      icon: PhosphorIconsRegular.qrCode,
                    ),

                    const SizedBox(height: 32),

                    // Divider with text
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'veya manuel girin',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Cover Image Preview
                    Center(
                      child: InkWell(
                        onTap: _showCoverUrlDialog,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 180,
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _coverUrl != null
                                ? AppImage(
                                    imageUrl: _coverUrl,
                                    width: 120,
                                    height: 180,
                                    fit: BoxFit.cover,
                                    errorWidget: Container(
                                      color: Colors.grey[300],
                                      child: Icon(
                                        PhosphorIconsRegular.imageBroken,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: context.surfaceColor,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          PhosphorIconsRegular.image,
                                          size: 32,
                                          color: context.primaryColor,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Kapak Ekle',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ISBN Lookup Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            controller: _isbnController,
                            label: 'ISBN',
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 56,
                            child: NeonGradientButton(
                              onPressed: _isSearching
                                  ? () {}
                                  : _performIsbnLookup,
                              text: 'Bilgileri Getir',
                              isLoading: _isSearching,
                              isSecondary: true,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Required Fields
                    _buildTextField(
                      controller: _titleController,
                      label: 'Kitap Adı *',
                      isDark: isDark,
                      validator: (v) =>
                          (v?.isEmpty ?? true) ? AppStrings.emptyField : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _authorController,
                      label: 'Yazar Adı *',
                      isDark: isDark,
                      validator: (v) =>
                          (v?.isEmpty ?? true) ? AppStrings.emptyField : null,
                    ),

                    const SizedBox(height: 20),

                    // Genre Selection
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGenre,
                      dropdownColor: context.surfaceColor,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.textLightPrimary,
                      ),
                      decoration: _buildInputDecoration('Kitap Türü', isDark),
                      items: _genres.map((String genre) {
                        return DropdownMenuItem<String>(
                          value: genre,
                          child: Text(genre),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGenre = newValue!;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Categories Tag Section
                    _buildCategorySection(isDark, context),

                    const SizedBox(height: 32),

                    // Section Header - Additional Info
                    Text(
                      'Ek Bilgiler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white70
                            : AppColors.textLightSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Publisher
                    _buildTextField(
                      controller: _publisherController,
                      label: 'Yayınevi',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // Year and Page Count Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _yearController,
                            label: 'Yayın Yılı',
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _pageCountController,
                            label: 'Sayfa Sayısı',
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Language
                    _buildTextField(
                      controller: _languageController,
                      label: 'Dil (ör: tr, en)',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Açıklama / Özet',
                      isDark: isDark,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 20),

                    // Purchase Link
                    _buildTextField(
                      controller: _purchaseLinkController,
                      label: 'Satın Alma Linki (Opsiyonel)',
                      isDark: isDark,
                      keyboardType: TextInputType.url,
                    ),

                    const SizedBox(height: 48),

                    const SizedBox(height: 80), // Fab için boşluk
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      style: TextStyle(
        color: isDark
            ? (enabled ? Colors.white : Colors.white38)
            : (enabled
                  ? AppColors.textLightPrimary
                  : AppColors.textLightSecondary.withValues(alpha: 0.5)),
      ),
      decoration: _buildInputDecoration(label, isDark).copyWith(
        filled: true,
        fillColor: enabled
            ? context.surfaceColor.withValues(alpha: 0.8)
            : context.surfaceColor.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildCategorySection(bool isDark, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategoriler (Etiketler)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : AppColors.textLightSecondary,
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedCategories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedCategories.map((cat) {
                return Chip(
                  label: Text(
                    cat,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: context.primaryColor,
                  deleteIcon: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                  onDeleted: () {
                    setState(() {
                      _selectedCategories.remove(cat);
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _allCategories.where((String option) {
              return option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
            });
          },
          onSelected: (String selection) {
            if (!_selectedCategories.contains(selection)) {
              setState(() {
                _selectedCategories.add(selection);
              });
            }
            _activeCategoryController?.clear();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _activeCategoryController = controller;
            return Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textLightPrimary,
                    ),
                    decoration:
                        _buildInputDecoration(
                          'Kategori Etiketi...',
                          isDark,
                        ).copyWith(
                          filled: true,
                          fillColor: context.surfaceColor.withValues(
                            alpha: 0.8,
                          ),
                        ),
                    onFieldSubmitted: (value) {
                      final val = value.trim();
                      if (val.isNotEmpty &&
                          _allCategories.contains(val) &&
                          !_selectedCategories.contains(val)) {
                        setState(() {
                          _selectedCategories.add(val);
                        });
                        controller.clear();
                        focusNode.unfocus();
                      } else {
                        controller.clear();
                      }
                    },
                  ),
                ),
              ],
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: context.surfaceColor,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 250,
                    maxWidth: 300,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.textLightPrimary,
                          ),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? Colors.white60 : AppColors.textLightSecondary,
      ),
      filled: true,
      fillColor: context.surfaceColor.withValues(alpha: 0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.primaryColor, width: 2),
      ),
    );
  }
}
