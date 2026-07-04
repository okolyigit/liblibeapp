import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/app_notification.dart';
import '../../widgets/neon_gradient_button.dart';

/// Admin-only "Kullanıcı Ekle": creates a new account (e-mail + temporary
/// password + role) via the `createUser` Cloud Function. Runs server-side with
/// the Admin SDK, so the admin's own session is not affected.
class AdminAddUserScreen extends StatefulWidget {
  /// Web dashboard embeds this in the content area: [onBack] returns to the
  /// users list and [onChanged] asks it to refresh. On mobile both are null
  /// (pushed route → pops with `true`).
  final VoidCallback? onBack;
  final VoidCallback? onChanged;

  const AdminAddUserScreen({super.key, this.onBack, this.onChanged});

  @override
  State<AdminAddUserScreen> createState() => _AdminAddUserScreenState();
}

class _AdminAddUserScreenState extends State<AdminAddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'user';
  bool _saving = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west3')
          .httpsCallable('createUser')
          .call({
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
            'role': _role,
          });
      if (mounted) {
        AppNotification.success(context, 'Kullanıcı oluşturuldu');
        widget.onChanged?.call();
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          Navigator.pop(context, true);
        }
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        AppNotification.error(context, 'Oluşturulamadı: ${e.message}');
      }
    } catch (e) {
      if (mounted) AppNotification.error(context, 'Oluşturulamadı: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textColor = isDark ? Colors.white : AppColors.textLightPrimary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(child: AppBackButton(onPressed: widget.onBack)),
        ),
        title: Text('Kullanıcı Ekle', style: TextStyle(color: textColor)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: textColor),
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  style: TextStyle(color: textColor),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Geçici şifre',
                    helperText: 'En az 6 karakter',
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('user')),
                    DropdownMenuItem(value: 'premium', child: Text('premium')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? 'user'),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: NeonGradientButton(
                    text: 'Oluştur',
                    isLoading: _saving,
                    onPressed: _saving ? () {} : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
