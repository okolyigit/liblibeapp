// Bu dosya, kullanıcının e-posta/şifre veya Google ile giriş/kayıt yaptığı ekrandır.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../widgets/app_notification.dart';
import '../widgets/neon_gradient_button.dart';
import '../utils/validators.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  String _userEmail = '';
  String _userPassword = '';
  bool _isLoading = false;

  // Google ile Giriş Fonksiyonu
  Future<void> _googleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 1. Google Giriş penceresini tetikle
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (!mounted) return;

      // 2. Kullanıcı pencereyi kapattıysa (iptal ettiyse)
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return; // İşlemi durdur
      }

      // 3. Google'dan kimlik doğrulama bilgilerini al
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (!mounted) return;

      // 4. Bu bilgileri kullanarak bir Firebase kimlik bilgisi (credential) oluştur
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Firebase ile giriş yap
      await _auth.signInWithCredential(credential);
    } catch (err) {
      // Hata yönetimi
      debugPrint('Google sign in error: $err'); // Hatanın detayını konsolda gör
      if (mounted) {
        AppNotification.error(context, 'Google ile giriş başarısız oldu: $err');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // E-posta/Şifre ile giriş fonksiyonu
  void _trySubmit() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState!.save();
      UserCredential userCredential;

      try {
        setState(() {
          _isLoading = true;
        });

        if (_isLogin) {
          userCredential = await _auth.signInWithEmailAndPassword(
            email: _userEmail,
            password: _userPassword,
          );
        } else {
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: _userEmail,
            password: _userPassword,
          );

          // Yeni kayıt sonrası doğrulama e-postası gönder
          if (userCredential.user != null &&
              !userCredential.user!.emailVerified) {
            await userCredential.user!.sendEmailVerification();
            if (mounted) {
              AppNotification.success(
                context,
                'Kayıt başarılı! Lütfen e-posta adresinizi doğrulayın.',
              );
            }
          }
        }
      } on FirebaseAuthException catch (err) {
        var message = 'Bir hata oluştu, lütfen bilgilerinizi kontrol edin.';
        if (err.message != null) {
          message = err.message!;
        }
        if (mounted) {
          AppNotification.error(context, message);
        }
      } catch (err) {
        debugPrint('Authentication error: $err');
      } finally {
        // Hata olsa bile yükleme durumunu false yap
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        _isLogin ? 'Kitap Kurdu - Giriş' : 'Yeni Hesap Oluştur',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        key: const ValueKey('email'),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'E-posta Adresi',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.teal,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: Validators.validateEmail,
                        onSaved: (value) {
                          _userEmail = value!.trim();
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('password'),
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.teal,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Şifre en az 6 karakter olmalıdır.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _userPassword = value!.trim();
                        },
                      ),
                      const SizedBox(height: 20),
                      NeonGradientButton(
                        onPressed: _trySubmit,
                        text: _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                        isLoading: _isLoading,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin
                              ? 'Yeni hesap oluştur'
                              : 'Zaten bir hesabım var',
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('veya'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _googleSignIn,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/google_logo.png',
                                height: 24.0,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Google ile Giriş Yap',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
