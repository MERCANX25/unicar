import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../widgets/scrollable_fill.dart';
import '../utils/app_config.dart';
import 'home_screen.dart';
import 'login_screen.dart';

///               Oturum açmış kullanıcı hangi ekranı görmeli.
/// - E-postası doğrulanmışsa: Ana Sayfa
/// - Doğrulanmamışsa: Doğrulama ekranı
///
///
Widget screenForSignedInUser() {
  // Doğrulama geçici olarak kapalıysa herkes doğrudan Ana Sayfa'ya gider.
  // Açmak için: lib/utils/app_config.dart -> requireEmailVerification = true
  if (!AppConfig.requireEmailVerification) return const HomeScreen();

  return AuthService.instance.isEmailVerified
      ? const HomeScreen()
      : const VerifyEmailScreen();
}

/// E-postası doğrulanmamış kullanıcıya gösterilen ekran.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  // İki ayrı bayrak: hangi butonun beklediğini bilip sadece onda
  // yükleniyor göstergesi göstermek için.
  bool _isChecking = false;
  bool _isSending = false;

  bool get _isBusy => _isChecking || _isSending;

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  /// "Doğrulamayı kontrol et": Firebase'den güncel bilgiyi çeker.
  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    try {
      final verified = await AuthService.instance.reloadAndCheckVerified();
      if (!mounted) return;

      if (verified) {
        // Doğrulandı: bu ekranı kapatıp Ana Sayfa'yı aç, geri dönülemesin.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        _showMessage(
          'Henüz doğrulanmamış. Maildeki bağlantıya tıkladıktan sonra tekrar dene.',
        );
      }
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  /// "Doğrulama mailini tekrar gönder"
  Future<void> _resendEmail() async {
    setState(() => _isSending = true);
    try {
      await AuthService.instance.resendVerificationEmail();
      if (mounted) _showMessage('Doğrulama maili tekrar gönderildi.');
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// "Çıkış yap": yanlış e-postayla kayıt olan kullanıcı bu ekranda kalmasın.
  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        // Yan çevrilince taşmasın: kısa ekranda kaydırılır, geniş ekranda ortalanır.
        child: ScrollableFill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.warning.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.warning, width: 2),
                  ),
                  child: Icon(
                    Icons.mark_email_unread_outlined,
                    size: 56,
                    color: AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'E-postan doğrulanmamış',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AuthService.instance.currentEmail,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondary, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Bu adrese gönderdiğimiz bağlantıya tıkla, sonra '
                '"Doğrulamayı kontrol et" butonuna bas. Mail gelmediyse '
                'Spam / Gereksiz klasörüne de bakmayı unutma.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isBusy ? null : _checkVerification,
                child: _isChecking
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Doğrulamayı kontrol et'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isBusy ? null : _resendEmail,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Doğrulama mailini tekrar gönder'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isBusy ? null : _logout,
                child: const Text('Çıkış yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
