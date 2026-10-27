import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';
import 'custom_text_field.dart';

/// "Şifremi unuttum" penceresi.
/// Kullanıcı e-postasını yazar, şifre sıfırlama bağlantısı gönderilir.
///
/// Kullanımı:
/// `showDialog(context: context, builder: (_) => ForgotPasswordDialog(initialEmail: ...))`
class ForgotPasswordDialog extends StatefulWidget {
  /// Giriş ekranındaki e-posta kutusunda yazan değer (varsa hazır gelir).
  final String initialEmail;

  const ForgotPasswordDialog({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController =
      TextEditingController(text: widget.initialEmail);

  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    try {
      await AuthService.instance.sendPasswordResetEmail(
        Validators.normalizeEmail(_emailController.text),
      );
      if (!mounted) return;
      // Mesaj gösterecek nesneyi pencere kapanmadan ÖNCE alıyoruz;
      // pencere kapandıktan sonra onun context'ini kullanmak güvenli değil.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Bu adrese kayıtlı bir hesap varsa şifre sıfırlama bağlantısı '
            'gönderildi. Gelen kutunu ve Spam klasörünü kontrol et.',
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Yatay ekranda klavye açılınca pencere taşmasın, kaydırılabilsin.
      scrollable: true,
      title: const Text('Şifremi unuttum'),
      // İçerik: kısa açıklama + e-posta alanı (alt alta → Column)
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min, // pencere içeriği kadar uzasın
          children: [
            Text(
              'E-posta adresini yaz, sana şifreni sıfırlaman için bir '
              'bağlantı gönderelim.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              label: 'E-posta',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: Validators.validateEmail,
            ),
          ],
        ),
      ),
      // Alt butonlar: Vazgeç ve Gönder
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: _isSending ? null : _send,
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Gönder'),
        ),
      ],
    );
  }
}
