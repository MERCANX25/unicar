import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../widgets/scrollable_fill.dart';
import 'permission_screen.dart';

///        KAYIT BAŞARILI EKRANI
/// 
/// Önce tik işareti zıplayarak büyür, ardından metinler yavaşça belirir.
class RegisterSuccessScreen extends StatefulWidget {
  final String email;
  final bool emailSent; // doğrulama e-postası gönderilebildi mi?

  const RegisterSuccessScreen({
    super.key,
    required this.email,
    required this.emailSent,
  });

  @override
  State<RegisterSuccessScreen> createState() => _RegisterSuccessScreenState();
}

// SingleTickerProvider yerine TickerProvider: iki AnimationController kullanıyoruz.
class _RegisterSuccessScreenState extends State<RegisterSuccessScreen>
    with TickerProviderStateMixin {
  // AnimationController: 0.0'dan 1.0'a belirli sürede ilerleyen bir sayaç.
  late final AnimationController _scaleController;
  late final AnimationController _fadeController;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this, // ekran görünmüyorken animasyon boşuna çalışmasın
      duration: const Duration(milliseconds: 900),
    );
    // elasticOut: hedefi biraz aşıp yay gibi geri gelir, "zıplama" etkisi verir.
    _scale = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    // Tik animasyonu bitince metinlerin belirmesini başlat.
    _scaleController.forward().whenComplete(() {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    // Controller'lar dispose edilmezse bellekte kalır (memory leak).
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _continue() {
    // pushReplacement: bu ekran yığından çıkar, geri tuşuyla dönülmez.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PermissionScreen.onboardingFlow()),
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
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration( // Tik işareti dairesi
                    shape: BoxShape.circle,
                    color: AppColors.success.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.success, width: 3),
                  ),
                  child: Icon(Icons.check, size: 80, color: AppColors.success),// Tik işareti
                ),
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _fade,// metinlerin belirme animasyonu
                child: Column(
                  children: [
                    Text(
                      'Hesabın oluşturuldu!',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(// başlık metni
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    //            EPOSTA BİLGİSİ
                    Text(
                      widget.emailSent
                          ? 'Doğrulama bağlantısını e-posta adresine gönderdik.'
                          : 'Doğrulama e-postası şu an gönderilemedi. '
                              'Daha sonra tekrar deneyebilirsin.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              const Spacer(), // boşluk: tik ve metinler ortada, buton altta
              // Devam et butonu. FadeTransition ile metinlerle birlikte beliriyor.
              FadeTransition(
                opacity: _fade,
                child: ElevatedButton(
                  onPressed: _continue,
                  child: const Text('Devam et'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
