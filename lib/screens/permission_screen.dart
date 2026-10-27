import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/app_colors.dart';
import '../widgets/scrollable_fill.dart';
import 'verify_email_screen.dart';



///                İZİN İSTEĞİ EKRANI

/// Tek bir izni açıklayıp isteyen, tekrar kullanılabilir ekran.
/// Konum ve bildirim izinleri için aynı widget farklı parametrelerle kullanılır.
class PermissionScreen extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Permission permission; // permission_handler paketindeki izin türü

  
  /// Hazır bir widget yerine fonksiyon alıyoruz: böylece "hangi ekran?"
  /// kararı ekran açıldığı anda değil, geçiş yapılacağı anda verilir
  
  final Widget Function() nextScreen;

  const PermissionScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.permission,
    required this.nextScreen,
  });

  /// Kayıt sonrası izin akışı: konum bildirim eposta ana 
  
  static Widget onboardingFlow() {
    return PermissionScreen(
      icon: Icons.location_on, 
      title: 'Konum İzni',
      description:
          'Sana en yakın yolculukları ve kampüs içi rotaları gösterebilmemiz '
          'için konumuna ihtiyacımız var.',
      permission: Permission.locationWhenInUse,
      nextScreen: () => const PermissionScreen(
        icon: Icons.notifications_active,
        title: 'Bildirim İzni',
        description:
            'Sürücün talebini onayladığında veya yolculuk yaklaştığında '
            'haber verelim.',
        permission: Permission.notification,
        nextScreen: screenForSignedInUser,
      ),
    );
  }

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isRequesting = false;

  void _goNext() {
    // Yığındaki tüm ekranları kaldırıp sonraki ekranı açıyoruz;
    // geri tuşu bir önceki izin ekranına veya kayda dönmez.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => widget.nextScreen()),
      (route) => false,
    );
  }

  Future<void> _requestPermission() async { // İzin isteme işlemi başlatılıyor, kullanıcıya Android izin penceresi gösterilecek.
    setState(() => _isRequesting = true);

    // request(): Android'in izin penceresini açar ve kullanıcının cevabını döndürür.
    final status = await widget.permission.request();

    if (!mounted) return;
    setState(() => _isRequesting = false);

    if (status.isPermanentlyDenied) {
      // Kullanıcı daha önce "bir daha sorma" dediyse Android pencereyi
      // artık göstermez; tek yol uygulama ayarları.
      await _showSettingsDialog();
      return;
    }

    // İzin verildi ya da bu sefer reddedildi: iki durumda da devam ediyoruz.
    _goNext();
  }

  Future<void> _showSettingsDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('İzin kapalı'),
        content: Text(
          '${widget.title} daha önce reddedildi. Ayarlardan açabilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              openAppSettings(); // Telefonun ayarlarında bu uygulamanın sayfasını açar.
            },
            child: const Text('Ayarlara git'),
          ),
        ],
      ),
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
              // TweenAnimationBuilder: 0.6'dan 1.0'a giden bir değeri zaman
              // içinde üretir; ikonu bu değerle ölçekleyerek büyüterek getiriyoruz.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack, // sonda hafifçe taşıp yerine oturur
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Icon(widget.icon, size: 64, color: AppColors.secondary),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isRequesting ? null : _requestPermission,
                child: const Text('İzin ver'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isRequesting ? null : _goNext,
                child: const Text('Şimdi değil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
